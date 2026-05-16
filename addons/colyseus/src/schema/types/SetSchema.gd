class_name SetSchema
extends Schema

var _items := {}  # Dictionary as set (keys only, values = true)
var _indexes := {}  # fieldIndex -> value (for binary decode)
var _child_type: String = ""

var _add_callbacks: Array = []
var _remove_callbacks: Array = []

func on_add(callback: Callable, trigger_all: bool = true) -> Callable:
	_add_callbacks.append(callback)
	if trigger_all:
		for key in keys():
			callback.call(key, key)
	return func(): _add_callbacks.erase(callback)

func on_remove(callback: Callable) -> Callable:
	_remove_callbacks.append(callback)
	return func(): _remove_callbacks.erase(callback)

func _init(child_type: String = ""):
	super()
	_child_type = child_type

func is_collection() -> bool:
	return true

func add(value: Variant) -> void:
	_items[value] = true

func has(value: Variant) -> bool:
	return value in _items

func erase(value: Variant) -> void:
	_items.erase(value)

func get_item(index: int) -> Variant:
	return _indexes.get(index)

func set_at(index: int, value: Variant) -> void:
	_indexes[index] = value
	_items[value] = true

func delete_at(index: int) -> void:
	var value = _indexes.get(index)
	if value != null:
		_items.erase(value)
		_indexes.erase(index)

func clear_items() -> void:
	_items.clear()
	_indexes.clear()

func size() -> int:
	return _items.size()

func keys() -> Array:
	return _items.keys()

func get_child_type() -> String:
	return _child_type
