extends Node

## Colyseus-backed multiplayer manager (autoload).
##
## Wraps the pure-GDScript Colyseus SDK at res://addons/colyseus/ and exposes
## the same signals/properties/methods the rest of the game already uses, so
## level_1..4, main_menu, and player.gd don't need changes.

signal room_code_ready(code: String)
signal connection_failed(reason: String)
signal player_connected(session_id: String)
signal player_disconnected(session_id: String)
signal connected_to_game(mode: String)
signal server_disconnected
signal player_state_changed(session_id: String, state: Dictionary)

const ColyseusClientScript := preload("res://addons/colyseus/src/client/ColyseusClient.gd")

const ROOM_NAME := "werewolf"
const ROOM_CODE_CHARS := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const HOST_RETRY_LIMIT := 3

var active_players: Array[String] = []
var session_id: String = ""
var room_code: String = ""
var is_hosting_intent: bool = false
var join_intent_code: String = ""
var selected_mode: String = "day"
var server_ip: String = "localhost"
var is_single_player: bool = false

var _client: Node = null
var _room: ColyseusRoom = null
var _state: WerewolfRoomState = null
var _host_retries := 0
var _suppress_disconnect_signal := false

var _server_url: String:
	get:
		return "ws://" + server_ip + ":2567"


func host_game() -> void:
	is_single_player = false
	is_hosting_intent = true
	join_intent_code = ""
	_host_retries = 0
	_start_host_attempt()


## Skip Colyseus entirely and start a local-only session. The destination scene
## reads `active_players` in _ready so it sees the local player even though the
## `player_connected` signal fired before the scene loaded.
func start_single_player(mode: String) -> void:
	_teardown_client()
	_reset_local_state()
	is_single_player = true
	is_hosting_intent = false
	join_intent_code = ""
	selected_mode = mode
	session_id = "local"
	active_players = ["local"] as Array[String]
	player_connected.emit("local")
	connected_to_game.emit(mode)


func join_game(code: String) -> void:
	is_single_player = false
	is_hosting_intent = false
	join_intent_code = code.to_upper()
	_connect_then(func():
		_join_room({"roomCode": join_intent_code})
	)


func send_message(type: String, data) -> void:
	if _room and _room.is_joined():
		_room.send(type, data)


func leave() -> void:
	_suppress_disconnect_signal = true
	if _room:
		_room.leave(true)
		_room = null
	_teardown_client()
	_reset_local_state()
	is_single_player = false
	_suppress_disconnect_signal = false


# ─── Host flow ─────────────────────────────────────────────────────────

func _start_host_attempt() -> void:
	var code := _generate_room_code()
	join_intent_code = code
	_connect_then(func():
		_join_room({
			"host": true,
			"roomCode": code,
			"mode": selected_mode,
		})
	)


func _generate_room_code() -> String:
	var code := ""
	for i in 4:
		code += ROOM_CODE_CHARS[randi() % ROOM_CODE_CHARS.length()]
	return code


# ─── Client lifecycle ──────────────────────────────────────────────────

func _connect_then(after_connect: Callable) -> void:
	_reset_local_state()
	_teardown_client()

	_client = ColyseusClientScript.new()
	add_child(_client)

	_client.connected.connect(after_connect, CONNECT_ONE_SHOT)
	_client.error.connect(_handle_error)
	_client.disconnected.connect(_on_disconnected)

	_client.connect_to_server(_server_url)


func _join_room(options: Dictionary) -> void:
	if _client == null:
		print("[MP] _join_room called with null client")
		return

	print("[MP] Matchmaking with options=", options)
	_state = WerewolfRoomState.new()

	_room = _client.join(ROOM_NAME, options)
	if _room == null:
		print("[MP] _client.join returned null")
		connection_failed.emit("Failed to start matchmaking")
		return

	_room.set_state(_state)
	_room.joined.connect(_on_room_joined)
	_room.left.connect(_on_room_left)
	_room.error_received.connect(_handle_error)


func _on_room_joined() -> void:
	# After the initial state decode, _state.players is the *real* decoded
	# MapSchema (the constructor's instance was replaced). Register callbacks
	# now; trigger_all=true means on_add fires once for every player already
	# in the room — including ourselves.
	session_id = _room.get_session_id()
	room_code = _state.roomCode
	if _state.mode != "":
		selected_mode = _state.mode
	print("[MP] Joined room=", room_code, " session=", session_id, " mode=", selected_mode,
		" players_in_state=", _state.players.size() if _state.players else -1)

	_state.players.on_add(func(player, key):
		var pid := String(key)
		if not active_players.has(pid):
			active_players.append(pid)
		player_connected.emit(pid)
		player.on_change(func():
			_on_player_changed(pid, player)
		)
	)
	_state.players.on_remove(func(_player, key):
		var pid := String(key)
		active_players.erase(pid)
		player_disconnected.emit(pid)
	)

	print("[MP] Emitting room_code_ready('", room_code, "') and connected_to_game('", selected_mode, "')")
	room_code_ready.emit(room_code)
	connected_to_game.emit(selected_mode)


func _on_room_left(code: int, reason: String) -> void:
	print("[MP] Room left code=", code, " reason=", reason)
	if _suppress_disconnect_signal:
		return
	_handle_disconnect()


func _on_disconnected() -> void:
	print("[MP] Client disconnected (suppressed=", _suppress_disconnect_signal, ")")
	if _suppress_disconnect_signal:
		return
	_handle_disconnect()


func _handle_disconnect() -> void:
	if session_id == "":
		# Never managed to join — surface as a connection failure.
		connection_failed.emit("Disconnected before joining")
	else:
		server_disconnected.emit()
	_teardown_client()
	_reset_local_state()


func _handle_error(code: int, message: String) -> void:
	print("[MP] _handle_error code=", code, " message=", message)
	# Host collision (409): regenerate a code and try again.
	if code == 409 and is_hosting_intent and _host_retries < HOST_RETRY_LIMIT:
		_host_retries += 1
		print("[MP] Room code collision, retry #", _host_retries)
		_teardown_client()
		_start_host_attempt()
		return

	var reason := message if message != "" else "Connection error"
	_teardown_client()
	_reset_local_state()
	connection_failed.emit(reason)


func _teardown_client() -> void:
	_room = null
	_state = null
	if _client:
		_client.close_connection()
		_client.queue_free()
		_client = null


func _reset_local_state() -> void:
	session_id = ""
	room_code = ""
	active_players.clear()


func _on_player_changed(pid: String, player) -> void:
	# Don't echo our own moves back to ourselves.
	if pid == session_id:
		return
	player_state_changed.emit(pid, {
		"x": player.x,
		"y": player.y,
		"vx": player.vx,
		"vy": player.vy,
		"tick": player.tick,
	})
