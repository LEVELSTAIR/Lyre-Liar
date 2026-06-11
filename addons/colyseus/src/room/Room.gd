class_name ColyseusRoom
extends RefCounted

signal joined
signal left(code: int, reason: String)
signal error_received(code: int, message: String)
signal state_changed(changes: Array)
signal message_received(type, data)
signal data_bytes_received(data: PackedByteArray)

var _client: Node
var _room_name: String
var _room_id: String = ""
var _session_id: String = ""
var _reconnection_token: String = ""
var _pending_reconnection_token: String = ""  # Used during reconnect flow
var _state: RefCounted = null  # Schema instance (root state)
var _joined: bool = false

func _init(client: Node, room_name: String):
	_client = client
	_room_name = room_name

func set_state(schema: RefCounted) -> void:
	_state = schema

# Internal callback from ColyseusClient when ROOM_STATE is received
func _on_room_state(data: PackedByteArray) -> void:
	print("[Room] Received initial state, %d bytes" % data.size())

	if _state and _state.has_method("decode"):
		var changes: Array = _state.decode(data)
		_trigger_callbacks(changes)
		if changes.size() > 0:
			state_changed.emit(changes)

	_joined = true
	joined.emit()

# Internal callback from ColyseusClient when ROOM_STATE_PATCH is received
func _on_state_patch(data: PackedByteArray) -> void:
	print("[Room] Received state patch, %d bytes" % data.size())
	if _state and _state.has_method("decode"):
		var changes: Array = _state.decode(data)
		_trigger_callbacks(changes)
		if changes.size() > 0:
			state_changed.emit(changes)

func _trigger_callbacks(changes: Array) -> void:
	# Track which schema refs had changes, to fire on_change once per ref
	var changed_schemas: Array = []

	for change in changes:
		var ref = change.get("ref")
		if ref == null:
			continue

		if not ref.is_collection():
			# Schema property change — fire listen() callbacks
			var field_name: String = change.get("field", "")
			if field_name in ref._prop_callbacks:
				for cb in ref._prop_callbacks[field_name]:
					cb.call(change.get("value"), change.get("previous"))
			# Track for on_change (deduplicate per ref)
			if ref._change_callbacks.size() > 0 and ref not in changed_schemas:
				changed_schemas.append(ref)
		else:
			# Collection operation — fire on_add/on_remove/on_change
			var op: String = change.get("op", "")
			var key = change.get("key", change.get("field_index"))
			if op == "add":
				for cb in ref._add_callbacks:
					cb.call(change.get("value"), key)
			elif op == "delete":
				for cb in ref._remove_callbacks:
					cb.call(change.get("previous"), key)
			elif op == "replace":
				for cb in ref._change_callbacks:
					cb.call(change.get("value"), key)

	# Fire schema on_change once per ref that had any changes
	for ref in changed_schemas:
		for cb in ref._change_callbacks:
			cb.call()

# Internal callback from ColyseusClient when ROOM_DATA is received
func _on_message(type, data = null) -> void:
	print("[Room] Received message: %s - %s" % [type, data])
	message_received.emit(type, data)

# Internal callback from ColyseusClient when ROOM_DATA_BYTES is received
func _on_data_bytes(data: PackedByteArray) -> void:
	data_bytes_received.emit(data)

func set_session_id(id: String) -> void:
	_session_id = id
	print("[Room] Session ID set to: %s" % id)

func set_reconnection_token(token: String) -> void:
	_reconnection_token = token

func get_reconnection_token() -> String:
	return _reconnection_token

func get_id() -> String:
	return _room_id

func get_session_id() -> String:
	return _session_id

func get_name() -> String:
	return _room_name

func is_joined() -> bool:
	return _joined

func get_state() -> RefCounted:
	return _state

func send(type: String, data = null) -> void:
	if _client and _client.has_method("send_room_data"):
		_client.send_room_data(type, data)

func leave(consented: bool = true) -> void:
	_joined = false
	if _client and _client.has_method("send_leave_room"):
		_client.send_leave_room()
	var code := Protocol.CloseCode.CONSENTED if consented else Protocol.CloseCode.NORMAL
	var reason := "consented" if consented else ""
	left.emit(code, reason)
