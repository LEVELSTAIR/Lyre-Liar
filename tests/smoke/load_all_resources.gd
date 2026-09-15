extends Node

## Loads every scene and resource under res:// (except addons and tools) and
## reports any that fail, e.g. after moving or deleting assets:
##   godot --headless --path . res://tests/smoke/load_all_resources.tscn

const SKIP_DIRS := ["res://.godot", "res://addons", "res://android"]

var _failures: Array[String] = []
var _count: int = 0


func _ready() -> void:
	_scan("res://")
	for failure in _failures:
		printerr("LOAD FAIL: ", failure)
	print("loaded %d resources, %d failures" % [_count, _failures.size()])
	get_tree().quit(1 if not _failures.is_empty() else 0)


func _scan(dir_path: String) -> void:
	if dir_path in SKIP_DIRS:
		return
	var dir := DirAccess.open(dir_path)
	for file in dir.get_files():
		if file.get_extension() in ["tscn", "tres"]:
			var path := dir_path.path_join(file)
			_count += 1
			if ResourceLoader.load(path) == null:
				_failures.append(path)
	for sub in dir.get_directories():
		_scan(dir_path.path_join(sub))
