class_name ColyseusRoomState
extends RefCounted

signal field_changed(field_name: String, value: Variant)
signal state_changed(changes: Array)

var _root: Schema = null

func set_root(schema: Schema) -> void:
	_root = schema

func get_root() -> Schema:
	return _root

func apply_full_state(data: PackedByteArray) -> void:
	if _root == null:
		push_error("RoomState: no root schema set")
		return
	var changes := _root.decode(data)
	if changes.size() > 0:
		for change in changes:
			field_changed.emit(change.field, change.get("value"))
		state_changed.emit(changes)

func apply_patch(patch_data: PackedByteArray) -> void:
	if _root == null:
		push_error("RoomState: no root schema set")
		return
	var changes := _root.decode(patch_data)
	if changes.size() > 0:
		for change in changes:
			field_changed.emit(change.field, change.get("value"))
		state_changed.emit(changes)
