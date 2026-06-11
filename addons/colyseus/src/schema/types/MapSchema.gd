class_name MapSchema
extends Schema

var _items := {}  # key -> value
var _indexes := {}  # fieldIndex -> key
var _child_type: String = ""

var _add_callbacks: Array = []
var _remove_callbacks: Array = []

func on_add(callback: Callable, trigger_all: bool = true) -> Callable:
	_add_callbacks.append(callback)
	if trigger_all:
		for key in keys():
			callback.call(get_item(key), key)
	return func(): _add_callbacks.erase(callback)

func on_remove(callback: Callable) -> Callable:
	_remove_callbacks.append(callback)
	return func(): _remove_callbacks.erase(callback)

func _init(child_type: String = ""):
	super()
	_child_type = child_type

func is_collection() -> bool:
	return true

func is_map_collection() -> bool:
	return true

func add_item(key: String, value: Variant) -> void:
	_items[key] = value

func set_index(field_index: int, key: String) -> void:
	_indexes[field_index] = key

func get_index(field_index: int) -> String:
	return _indexes.get(field_index, "")

func set_by_index(field_index: int, value: Variant) -> void:
	var key = _indexes.get(field_index, "")
	if key != "":
		_items[key] = value

func delete_by_index(field_index: int) -> void:
	var key = _indexes.get(field_index, "")
	if key != "":
		_items.erase(key)
		_indexes.erase(field_index)

func get_item(key: String) -> Variant:
	return _items.get(key, null)

func erase(key: String) -> void:
	_items.erase(key)

func has(key: String) -> bool:
	return key in _items

func keys() -> Array:
	return _items.keys()

func clear_items() -> void:
	_items.clear()
	_indexes.clear()

func size() -> int:
	return _items.size()

func get_child_type() -> String:
	return _child_type
