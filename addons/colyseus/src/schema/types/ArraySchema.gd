class_name ArraySchema
extends Schema

var _items: Array = []
var _child_type: String = ""

var _add_callbacks: Array = []
var _remove_callbacks: Array = []

func on_add(callback: Callable, trigger_all: bool = true) -> Callable:
	_add_callbacks.append(callback)
	if trigger_all:
		for i in range(size()):
			callback.call(get_item(i), i)
	return func(): _add_callbacks.erase(callback)

func on_remove(callback: Callable) -> Callable:
	_remove_callbacks.append(callback)
	return func(): _remove_callbacks.erase(callback)

func _init(child_type: String = ""):
	super()
	_child_type = child_type

func is_collection() -> bool:
	return true

func push(value: Variant) -> void:
	_items.append(value)

func set_at(index: int, value: Variant) -> void:
	while _items.size() <= index:
		_items.append(null)
	_items[index] = value

func get_item(index: int) -> Variant:
	if index < 0 or index >= _items.size():
		return null
	return _items[index]

func delete_at(index: int) -> void:
	if index >= 0 and index < _items.size():
		_items.remove_at(index)

func clear_items() -> void:
	_items.clear()

func size() -> int:
	return _items.size()

func get_child_type() -> String:
	return _child_type
