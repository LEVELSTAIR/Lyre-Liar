extends Node

## Pure GDScript WebSocket multiplayer manager.
## No addons needed — uses Godot's built-in WebSocketPeer.

signal room_code_ready(code: String)
signal connection_failed(reason: String)
signal player_connected(session_id: String)
signal player_disconnected(session_id: String)
signal connected_to_game(mode: String)
signal server_disconnected
signal player_state_changed(session_id: String, state: Dictionary)

var active_players: Array[String] = []

var session_id: String = ""

var room_code: String = ""
var is_hosting_intent: bool = false
var join_intent_code: String = ""
var selected_mode: String = "day"


var _ws: WebSocketPeer = null
var server_ip: String = "localhost"
var _server_url: String:
	get:
		return "ws://" + server_ip + ":2567"
var _connected := false


var _connection_timer: float = 0.0

func _process(delta: float) -> void:
	if _ws == null:
		return

	_ws.poll()

	var state := _ws.get_ready_state()

	if state == WebSocketPeer.STATE_CONNECTING:
		_connection_timer += delta
		if _connection_timer > 5.0:
			print("Connection timeout!")
			_ws.close()
			_ws = null
			connection_failed.emit("Connection timed out (Check Firewall)")
			return
	else:
		_connection_timer = 0.0


	if state == WebSocketPeer.STATE_OPEN:
		if not _connected:
			_connected = true
			print("WebSocket connected to server")
			# Send host or join request
			if is_hosting_intent:
				_send({"type": "host", "mode": selected_mode})
			elif join_intent_code != "":
				_send({"type": "join", "roomCode": join_intent_code})

		# Process all queued messages
		while _ws.get_available_packet_count() > 0:
			var raw := _ws.get_packet().get_string_from_utf8()
			_handle_message(raw)

	elif state == WebSocketPeer.STATE_CLOSING:
		pass # Wait for it to close

	elif state == WebSocketPeer.STATE_CLOSED:
		var code := _ws.get_close_code()
		var reason := _ws.get_close_reason()
		print("WebSocket closed [", code, "]: ", reason)
		_ws = null
		
		if _connected:
			_connected = false
			session_id = ""
			room_code = ""
			active_players.clear()
			server_disconnected.emit()
		else:
			# If it closed without ever connecting, it's a connection failure
			connection_failed.emit("Server unreachable or refused connection")


func host_game() -> void:
	print("Hosting game...")
	_connect_to_server()


func join_game(code: String) -> void:
	print("Joining game with code: ", code)
	join_intent_code = code
	_connect_to_server()


func _connect_to_server() -> void:
	_connected = false
	_ws = WebSocketPeer.new()
	var err := _ws.connect_to_url(_server_url)
	if err != OK:
		print("ERROR: Failed to connect to ", _server_url, " (error ", err, ")")
		_ws = null
		connection_failed.emit("Cannot reach server")


func _send(data: Dictionary) -> void:
	if _ws and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(data))


func send_message(type: String, data) -> void:
	_send({"type": type, "data": data})


func _handle_message(raw: String) -> void:
	var json := JSON.new()
	if json.parse(raw) != OK:
		print("ERROR: Failed to parse server message: ", raw)
		return

	var msg: Dictionary = json.data
	var msg_type: String = msg.get("type", "")

	match msg_type:
		"hosted":
			session_id = msg["sessionId"]
			room_code = msg["roomCode"]
			selected_mode = msg.get("mode", "day")
			print("Hosted room: ", room_code, " (session: ", session_id, ") Mode: ", selected_mode)
			room_code_ready.emit(room_code)
			connected_to_game.emit(selected_mode)
			# Spawn ourselves — server doesn't send player_joined to self
			if not active_players.has(session_id):
				active_players.append(session_id)
			player_connected.emit(session_id)

		"joined":
			session_id = msg["sessionId"]
			room_code = msg["roomCode"]
			selected_mode = msg.get("mode", "day")
			print("Joined room: ", room_code, " (session: ", session_id, ") Mode: ", selected_mode)
			room_code_ready.emit(room_code)
			connected_to_game.emit(selected_mode)
			# Spawn ourselves — server doesn't send player_joined to self
			if not active_players.has(session_id):
				active_players.append(session_id)
			player_connected.emit(session_id)

		"player_joined":
			var pid: String = msg["sessionId"]
			print("Player joined: ", pid)
			if not active_players.has(pid):
				active_players.append(pid)
			player_connected.emit(pid)

		"player_left":
			var pid: String = msg["sessionId"]
			print("Player left: ", pid)
			active_players.erase(pid)
			player_disconnected.emit(pid)

		"player_moved":
			var pid: String = msg["sessionId"]
			var pstate: Dictionary = msg.get("state", {})
			player_state_changed.emit(pid, pstate)

		"error":
			var error_msg: String = msg.get("message", "Unknown error")
			print("Server error: ", error_msg)
			connection_failed.emit(error_msg)


func leave() -> void:
	if _ws:
		_ws.close()
		_ws = null
	_connected = false
	session_id = ""
	room_code = ""
	active_players.clear()
