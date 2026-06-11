extends Node

signal connected
signal disconnected
signal error(code: int, message: String)

var _connected := false  # True after HTTP server validation
var _socket: WebSocketPeer = null
var _ws_connecting := false
var _ws_connected := false
var _join_acknowledged := false  # True after receiving JOIN_ROOM from server
var _current_room: RefCounted = null
var _ping_sent_time: int = 0
var _latency: float = 0.0

# URL bases derived from connect_to_server URL
var _ws_base: String = ""
var _http_base: String = ""

func connect_to_server(url: String) -> void:
	print("[ColyseusSDK] Connecting to: %s" % url)
	_parse_url(url)

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_connect_response.bind(http))
	var err := http.request(_http_base)
	if err != OK:
		print("[ColyseusSDK] HTTP request failed to start: %d" % err)
		http.queue_free()
		error.emit(0, "Connection failed: HTTP request error")

func connect_and_join(url: String, room_name: String, options: Dictionary = {}) -> void:
	connect_to_server(url)
	await connected
	join(room_name, options)

func _parse_url(url: String) -> void:
	# Convert ws:// or wss:// to http:// or https://
	if url.begins_with("ws://"):
		_ws_base = url.rstrip("/")
		_http_base = "http://" + url.substr(5).rstrip("/")
	elif url.begins_with("wss://"):
		_ws_base = url.rstrip("/")
		_http_base = "https://" + url.substr(6).rstrip("/")
	elif url.begins_with("http://"):
		_http_base = url.rstrip("/")
		_ws_base = "ws://" + url.substr(7).rstrip("/")
	elif url.begins_with("https://"):
		_http_base = url.rstrip("/")
		_ws_base = "wss://" + url.substr(8).rstrip("/")
	else:
		_ws_base = "ws://" + url.rstrip("/")
		_http_base = "http://" + url.rstrip("/")

func _on_connect_response(result: int, _code: int, _headers: PackedStringArray, _body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result == HTTPRequest.RESULT_SUCCESS:
		print("[ColyseusSDK] Server reachable")
		_connected = true
		connected.emit()
	else:
		print("[ColyseusSDK] Server unreachable, result: %d" % result)
		error.emit(0, "Connection failed")

func join(room_name: String, options: Dictionary = {}) -> RefCounted:
	if not _connected:
		error.emit(0, "Not connected")
		return null

	var room: RefCounted = ColyseusRoom.new(self, room_name)
	_current_room = room

	# HTTP POST to matchmake endpoint
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_join_response.bind(http, room))

	var url := "%s/matchmake/joinOrCreate/%s" % [_http_base, room_name]
	var body := JSON.stringify(options)
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])

	print("[ColyseusSDK] Matchmaking: POST %s" % url)
	var err := http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("[ColyseusSDK] Matchmaking request failed to start: %d" % err)
		http.queue_free()
		error.emit(0, "Matchmaking failed")

	return room

func _on_join_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest, room: RefCounted) -> void:
	http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[ColyseusSDK] Matchmaking request failed, result: %d" % result)
		error.emit(0, "Matchmaking failed")
		return

	var body_str := body.get_string_from_utf8()
	var json := JSON.new()
	var parse_err := json.parse(body_str)
	if parse_err != OK:
		print("[ColyseusSDK] Invalid matchmaking response JSON")
		error.emit(0, "Invalid matchmaking response")
		return

	var response = json.data

	# Check for error response
	if response is Dictionary and response.has("error"):
		var err_code: int = response.get("code", 0)
		var msg: String = response.get("message", response.get("error", "Unknown error"))
		print("[ColyseusSDK] Matchmaking error: %s (code %d)" % [msg, err_code])
		error.emit(err_code, msg)
		return

	if code < 200 or code >= 300:
		print("[ColyseusSDK] Matchmaking HTTP error: %d" % code)
		error.emit(code, "Matchmaking failed: HTTP %d" % code)
		return

	# Extract seat reservation — Colyseus nests room info in "room" object
	var session_id: String = response.get("sessionId", "")
	var room_data = response.get("room", {})
	var room_id: String = room_data.get("roomId", "") if room_data is Dictionary else ""
	var process_id: String = room_data.get("processId", "") if room_data is Dictionary else ""

	if session_id.is_empty() or room_id.is_empty():
		print("[ColyseusSDK] Invalid seat reservation")
		error.emit(0, "Invalid seat reservation")
		return

	# Set room properties from HTTP response
	room.set_session_id(session_id)
	room._room_id = room_id

	# Build WebSocket URL
	var ws_url := "%s/%s/%s?sessionId=%s" % [_ws_base, process_id, room_id, session_id]
	if room.get("_pending_reconnection_token") and not room._pending_reconnection_token.is_empty():
		ws_url += "&reconnectionToken=%s" % room._pending_reconnection_token
		room._pending_reconnection_token = ""
	print("[ColyseusSDK] Connecting WebSocket: %s" % ws_url)

	_socket = WebSocketPeer.new()
	var ws_err := _socket.connect_to_url(ws_url)
	if ws_err != OK:
		print("[ColyseusSDK] WebSocket connection failed: %d" % ws_err)
		error.emit(0, "WebSocket connection failed")
		_socket = null
		return

	_ws_connecting = true
	_join_acknowledged = false

func reconnect(reconnection_token: String) -> RefCounted:
	if not _connected:
		error.emit(0, "Not connected")
		return null

	var parts := reconnection_token.split(":")
	if parts.size() < 2:
		error.emit(0, "Invalid reconnection token format")
		return null

	var room_id := parts[0]
	var token := parts[1]

	var room: RefCounted = ColyseusRoom.new(self, "")
	room._room_id = room_id
	room._pending_reconnection_token = token
	_current_room = room

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_join_response.bind(http, room))

	var url := "%s/matchmake/reconnect/%s" % [_http_base, room_id]
	var body := JSON.stringify({"reconnectionToken": token})
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])

	print("[ColyseusSDK] Reconnecting: POST %s" % url)
	var err := http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("[ColyseusSDK] Reconnect request failed to start: %d" % err)
		http.queue_free()
		error.emit(0, "Reconnect failed")

	return room

func close_connection() -> void:
	# Send LEAVE_ROOM before closing so the server treats this as a consented leave
	if _socket and _ws_connected and _current_room:
		var msg := PackedByteArray([Protocol.MessageType.LEAVE_ROOM])
		_socket.send(msg)
	if _socket:
		_socket.close()
		_socket = null
	_connected = false
	_ws_connecting = false
	_ws_connected = false
	_join_acknowledged = false
	_current_room = null
	disconnected.emit()

func is_server_connected() -> bool:
	return _connected

func get_current_room() -> RefCounted:
	return _current_room

func _process(_delta: float) -> void:
	if _socket == null:
		return

	_socket.poll()
	var ws_state := _socket.get_ready_state()

	if _ws_connecting:
		if ws_state == WebSocketPeer.STATE_OPEN:
			print("[ColyseusSDK] WebSocket connected")
			_ws_connecting = false
			_ws_connected = true
		elif ws_state == WebSocketPeer.STATE_CLOSED:
			print("[ColyseusSDK] WebSocket connection failed")
			_ws_connecting = false
			_socket = null
			error.emit(0, "WebSocket connection failed")
			return

	if _ws_connected:
		if ws_state == WebSocketPeer.STATE_CLOSED:
			print("[ColyseusSDK] WebSocket closed")
			_ws_connected = false
			_connected = false
			_socket = null
			disconnected.emit()
		else:
			_read_messages()

func _read_messages() -> void:
	while _socket.get_available_packet_count() > 0:
		var packet := _socket.get_packet()
		_handle_message(packet)

func _handle_message(packet: PackedByteArray) -> void:
	if packet.is_empty():
		return

	var msg_type := packet[0]
	match msg_type:
		Protocol.MessageType.JOIN_ROOM:
			_handle_join_room(packet.slice(1))
		Protocol.MessageType.ROOM_STATE:
			_handle_room_state(packet.slice(1))
		Protocol.MessageType.ROOM_STATE_PATCH:
			_handle_room_state_patch(packet.slice(1))
		Protocol.MessageType.ROOM_DATA:
			_handle_room_data(packet.slice(1))
		Protocol.MessageType.ROOM_DATA_BYTES:
			_handle_room_data_bytes(packet.slice(1))
		Protocol.MessageType.ERROR:
			_handle_error(packet.slice(1))
		Protocol.MessageType.PING:
			_handle_ping()
		_:
			print("[ColyseusClient] Received message type: %d" % msg_type)

func _handle_join_room(data: PackedByteArray) -> void:
	# Format: [reconnToken_len (1 byte)][reconnToken (utf8)][serializerId_len (1 byte)][serializerId (utf8)][handshake...]
	var offset := 0
	if data.size() < 2:
		print("[ColyseusClient] JOIN_ROOM packet too short")
		return

	# Read reconnection token
	var token_len := data[offset]
	offset += 1
	if token_len < 0 or offset + token_len > data.size():
		print("[ColyseusClient] JOIN_ROOM token_len out of bounds: %d" % token_len)
		return
	var reconnection_token := data.slice(offset, offset + token_len).get_string_from_utf8()
	offset += token_len

	# Read serializer ID
	if offset >= data.size():
		print("[ColyseusClient] JOIN_ROOM packet truncated before serializer_len")
		return
	var serializer_len := data[offset]
	offset += 1
	if serializer_len < 0 or offset + serializer_len > data.size():
		print("[ColyseusClient] JOIN_ROOM serializer_len out of bounds: %d" % serializer_len)
		return
	var serializer_id := data.slice(offset, offset + serializer_len).get_string_from_utf8()
	offset += serializer_len

	print("[ColyseusClient] JOIN_ROOM: token=%s, serializer=%s" % [reconnection_token, serializer_id])

	if _current_room:
		# Store reconnection token as roomId:token
		_current_room.set_reconnection_token("%s:%s" % [_current_room._room_id, reconnection_token])

	_join_acknowledged = true

	# If there's remaining handshake data (schema reflection), handle it
	# (Schema reflection handling can be added later if needed)

	# Send JOIN_ROOM acknowledgment (single byte)
	if _socket and _ws_connected:
		var ack := PackedByteArray([Protocol.MessageType.JOIN_ROOM])
		_socket.send(ack)
		print("[ColyseusClient] Sent JOIN_ROOM ack")

func _handle_room_state(data: PackedByteArray) -> void:
	print("[ColyseusClient] Received ROOM_STATE, %d bytes" % data.size())
	if _current_room:
		_current_room._on_room_state(data)

func _handle_room_state_patch(data: PackedByteArray) -> void:
	print("[ColyseusClient] Received ROOM_STATE_PATCH, %d bytes" % data.size())
	if _current_room:
		_current_room._on_state_patch(data)

func _handle_room_data(data: PackedByteArray) -> void:
	# Format: [msgpack_string_or_number(type, LE)][msgpack(payload, BE)]
	if data.is_empty():
		return

	# Decode the type field using the LE decoder (matches @colyseus/schema)
	var decoder := Decoder.new(data)
	var msg_type
	if Decoder.string_check(data, 0):
		msg_type = decoder.decode_string()
	else:
		msg_type = decoder.decode_number()

	# Decode the payload using BE decoder (matches msgpackr)
	var offset: int = decoder.get_position()
	var payload = null
	if offset < data.size():
		var result := Decoder.decode_value(data, offset)
		payload = result[0]

	if _current_room:
		_current_room._on_message(msg_type, payload)

func _handle_room_data_bytes(data: PackedByteArray) -> void:
	if _current_room:
		_current_room._on_data_bytes(data)

func _handle_error(data: PackedByteArray) -> void:
	# Format: [msgpack_number(code, LE)][msgpack_string(message, LE)]
	if data.is_empty():
		return

	var decoder := Decoder.new(data)
	var code = decoder.decode_number()
	var message: String = decoder.decode_string()

	print("[ColyseusClient] Error: code=%s, message=%s" % [code, message])
	error.emit(code, message)
	if _current_room:
		_current_room.error_received.emit(code, message)

func _handle_ping() -> void:
	if _ping_sent_time > 0:
		# This is a latency echo — compute round-trip time
		_latency = float(Time.get_ticks_msec() - _ping_sent_time)
		_ping_sent_time = 0

func ping() -> void:
	if not _ws_connected or _socket == null:
		return
	_ping_sent_time = Time.get_ticks_msec()
	_socket.send(PackedByteArray([Protocol.MessageType.PING]))

func get_latency() -> float:
	return _latency

func send_room_data(type: String, data = null) -> void:
	if not _ws_connected or _socket == null:
		return

	# Format: [13][msgpack_string(type, LE)][msgpack(payload, BE)]
	var encoder := Encoder.new()
	encoder.encode_uint8(Protocol.MessageType.ROOM_DATA)
	encoder.encode_string(type)
	var msg := encoder.get_data()

	if data != null:
		var payload := Encoder.encode_value(data)
		msg.append_array(payload)

	_socket.send(msg)

func send_leave_room() -> void:
	if not _ws_connected or _socket == null:
		return

	# Single byte: [12]
	var msg := PackedByteArray([Protocol.MessageType.LEAVE_ROOM])
	_socket.send(msg)
	_current_room = null
