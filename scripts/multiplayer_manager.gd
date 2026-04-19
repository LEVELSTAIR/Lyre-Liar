extends Node

signal room_code_ready(code: String)
signal connection_failed(reason: String)
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal server_disconnected
signal connected_to_game

enum State {
	IDLE,
	CONNECTING_SIGNAL,
	WAITING_PEERS,
	GAME_READY
}

const STUN_SERVER = "stun:stun.l.google.com:19302"
var signaling_server_url := "ws://localhost:8090"

var peer: WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
var _ws: WebSocketPeer = null
var _state: State = State.IDLE
var _is_host: bool = false
var _room_code: String = ""
var _rtc_peers: Dictionary = {}  # peer_id -> WebRTCPeerConnection
var _pending_ice: Dictionary = {}  # peer_id -> [candidates]

# Pass connection intent from MainMenu to Level Script
var is_hosting_intent: bool = false
var join_intent_code: String = ""

var room_code: String:
	get:
		return _room_code
	set(value):
		_room_code = value


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _process(_delta: float) -> void:
	if _ws == null:
		return

	_ws.poll()

	var state = _ws.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			_process_messages()
		WebSocketPeer.STATE_CLOSED:
			var was_active = _state != State.IDLE
			_ws = null
			_state = State.IDLE
			if was_active:
				connection_failed.emit("Signaling server disconnected")


func _process_messages() -> void:
	while _ws.get_available_packet_count() > 0:
		var data = _ws.get_packet()
		if data == null:
			continue

		var json_str = data if data is String else data.get_string_from_utf8()
		var msg = JSON.parse_string(json_str)
		if msg == null:
			continue

		_handle_signal_message(msg)


func _handle_signal_message(msg: Dictionary) -> void:
	match msg.get("type", ""):
		"room_created":
			_room_code = msg.get("room", "")
			_state = State.WAITING_PEERS
			room_code_ready.emit(_room_code)

		"peer_id":
			var my_id = int(msg.get("id", 0))
			print("Assigned peer ID: ", my_id, " (waiting for WebRTC to connect...)")
			# Don't emit connected_to_game here - wait for actual WebRTC connection
			# via multiplayer.connected_to_server → _on_connected_to_server

		"new_peer":
			var peer_id = int(msg.get("id", 0))
			print("Received new_peer: ", peer_id, " (is_host=", _is_host, ")")
			if _is_host:
				print("Creating RTC connection for peer: ", peer_id)
				_create_rtc_connection(peer_id, true)
			else:
				print("WARNING: Got new_peer but not host!")

		"offer":
			var from_id = int(msg.get("from", 0))
			var sdp = msg.get("sdp", "")
			print("Received offer from peer ", from_id, " (is_host=", _is_host, ")")
			if not _is_host:
				print("Creating RTC connection for offerer...")
				_create_rtc_connection(from_id, false)
				if _rtc_peers.has(from_id):
					print("Setting remote description (offer)...")
					var err = _rtc_peers[from_id].set_remote_description("offer", sdp)
					print("Set remote description result: ", err)
				else:
					print("ERROR: RTC peer not found after creation!")
			else:
				print("Got offer but I'm the host, ignoring")

		"answer":
			var from_id = int(msg.get("from", 0))
			var sdp = msg.get("sdp", "")
			if _is_host and _rtc_peers.has(from_id):
				_rtc_peers[from_id].set_remote_description("answer", sdp)

		"ice":
			var from_id = int(msg.get("from", 0))
			var candidate = msg.get("candidate", {})
			if _rtc_peers.has(from_id):
				var media = candidate.get("media", "")
				var index = candidate.get("index", 0)
				var candidate_name = candidate.get("name", "")
				_rtc_peers[from_id].add_ice_candidate(media, index, candidate_name)
			else:
				if not _pending_ice.has(from_id):
					_pending_ice[from_id] = []
				_pending_ice[from_id].append(candidate)

		"error":
			var reason = msg.get("message", "Unknown error")
			connection_failed.emit(reason)
			_state = State.IDLE


func _create_rtc_connection(peer_id: int, is_offerer: bool) -> void:
	if _rtc_peers.has(peer_id):
		print("RTC peer ", peer_id, " already exists, skipping")
		return

	print("Creating WebRTC connection for peer ", peer_id, " (offerer=", is_offerer, ")")
	var conn = WebRTCPeerConnection.new()
	print("WebRTCPeerConnection created, initializing...")
	var init_err = conn.initialize({
		"iceServers": [{"urls": ["stun:stun.l.google.com:19302"]}]
	})
	print("Initialize returned: ", init_err)
	if init_err != OK:
		push_error("WebRTC init failed: ", init_err, " — install webrtc-native plugin from https://github.com/godotengine/webrtc-native/releases")
		return

	print("Connecting signals for peer ", peer_id)
	conn.session_description_created.connect(func(type: String, sdp: String): _on_sdp_created(peer_id, conn, type, sdp))
	conn.ice_candidate_created.connect(func(media: String, index: int, candidate_name: String): _on_ice_created(peer_id, media, index, candidate_name))

	_rtc_peers[peer_id] = conn
	print("Adding peer to multiplayer: ", peer_id)
	peer.add_peer(conn, peer_id)

	if is_offerer:
		print("Creating offer for peer ", peer_id)
		conn.create_offer()
	print("RTC connection setup complete for peer ", peer_id)

	if _pending_ice.has(peer_id):
		for candidate in _pending_ice[peer_id]:
			var media = candidate.get("media", "")
			var index = candidate.get("index", 0)
			var candidate_name = candidate.get("name", "")
			conn.add_ice_candidate(media, index, candidate_name)
		_pending_ice.erase(peer_id)


func _on_sdp_created(peer_id: int, conn: WebRTCPeerConnection, type: String, sdp: String) -> void:
	print("SDP created for peer ", peer_id, " type=", type, " sdp_len=", sdp.length())
	conn.set_local_description(type, sdp)
	print("Local description set")

	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("WARNING: WebSocket not open, cannot send ", type)
		return

	var msg = {
		"type": type,
		"to": peer_id,
		"sdp": sdp
	}
	print("Sending ", type, " to peer ", peer_id, " via signaling server")
	_ws.send_text(JSON.stringify(msg))
	print("Sent ", type)


func _on_ice_created(peer_id: int, media: String, index: int, candidate_name: String) -> void:
	print("ICE candidate created for peer ", peer_id, ": ", candidate_name)
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("WARNING: WebSocket not open, buffering ICE candidate")
		return

	var msg = {
		"type": "ice",
		"to": peer_id,
		"candidate": {
			"media": media,
			"index": index,
			"name": candidate_name
		}
	}
	print("Sending ICE candidate to peer ", peer_id)
	_ws.send_text(JSON.stringify(msg))


func _reset_state() -> void:
	if _ws != null:
		_ws.close()
		_ws = null
	_rtc_peers.clear()
	_pending_ice.clear()
	multiplayer.multiplayer_peer = null
	peer = WebRTCMultiplayerPeer.new()
	_state = State.IDLE


func host_game() -> void:
	print("Hosting game...")
	_reset_state()
	_is_host = true

	var error = peer.create_server()
	if error != OK:
		print("Failed to create server: ", error)
		connection_failed.emit("Failed to create server")
		return

	multiplayer.multiplayer_peer = peer
	_state = State.CONNECTING_SIGNAL
	_connect_to_signaling()


func join_game(room_code: String) -> void:
	print("Joining game: ", room_code)
	if room_code.length() != 6 or room_code == "":
		connection_failed.emit("Invalid room code format")
		return

	_reset_state()
	_is_host = false
	_room_code = room_code

	var error = peer.create_client(2)
	if error != OK:
		print("Failed to create client: ", error)
		connection_failed.emit("Failed to create client")
		return

	multiplayer.multiplayer_peer = peer
	_state = State.CONNECTING_SIGNAL
	_connect_to_signaling()


func _connect_to_signaling() -> void:
	if _ws != null:
		_ws.close()

	_ws = WebSocketPeer.new()
	var error = _ws.connect_to_url(signaling_server_url)

	if error != OK:
		print("Failed to connect to signaling server: ", error)
		connection_failed.emit("Cannot reach signaling server")
		_state = State.IDLE
		return

	print("Connecting to signaling server at ", signaling_server_url)
	await _wait_for_websocket_open()
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_send_handshake()


func _wait_for_websocket_open() -> void:
	var timeout = 0
	var max_frames = 300
	var last_state = -1
	while timeout < max_frames:
		await get_tree().process_frame
		if _ws != null:
			var state = _ws.get_ready_state()
			# Log state changes
			if state != last_state:
				var state_names = ["CONNECTING", "OPEN", "CLOSING", "CLOSED"]
				print("WebSocket state: ", state_names[state] if state < 4 else "UNKNOWN")
				last_state = state

			if state == WebSocketPeer.STATE_OPEN:
				print("WebSocket connected (STATE_OPEN)")
				return
			if state == WebSocketPeer.STATE_CLOSED:
				print("WebSocket closed unexpectedly")
				connection_failed.emit("Connection lost to signaling server")
				return
			if state != WebSocketPeer.STATE_CLOSED:
				timeout += 1
			if timeout % 60 == 0:
				print("Waiting for WebSocket (attempt ", int(timeout / 60), ")")
		else:
			return
	print("WebSocket connection timeout - server unreachable")
	connection_failed.emit("Signaling server unreachable (timeout). Check internet connection.")


func _send_handshake() -> void:
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("WebSocket not open, aborting handshake")
		return

	var msg: Dictionary
	if _is_host:
		msg = {
			"type": "host",
			"room": _generate_room_code() if _room_code.is_empty() else _room_code
		}
	else:
		msg = {
			"type": "join",
			"room": _room_code
		}

	_ws.send_text(JSON.stringify(msg))
	print("Sent handshake: ", msg)


func _generate_room_code() -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	for i in range(6):
		code += chars[randi() % chars.length()]
	return code


func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)
	player_connected.emit(id)
	if _is_host and id != 1:
		_state = State.GAME_READY
		connected_to_game.emit()


func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: ", id)
	if _rtc_peers.has(id):
		_rtc_peers.erase(id)
	player_disconnected.emit(id)


func _on_connected_to_server() -> void:
	print("Connected to server")
	_state = State.GAME_READY
	connected_to_game.emit()


func _on_server_disconnected() -> void:
	print("Server disconnected")
	server_disconnected.emit()
	_state = State.IDLE
