extends SceneTree

## Headless test runner. Usage:
##   godot --headless --path . -s res://tests/run_tests.gd
## Loads every `test_*.gd` under res://tests/unit, runs each `test_*` method on
## a fresh instance, prints a summary, and exits with code 1 on any failure.

const UNIT_DIR := "res://tests/unit"


func _initialize() -> void:
	# Wait one frame so autoloads have finished _ready() before tests use them.
	await process_frame
	var passed := 0
	var failed := 0
	for script_path in _test_scripts():
		var script: GDScript = load(script_path)
		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var test: TestCase = script.new()
			test.tree = self
			test.before_each()
			await test.call(method_name)
			test.after_each()
			var label := "%s::%s" % [script_path.get_file().get_basename(), method_name]
			if test.failures.is_empty():
				passed += 1
				print("  PASS  ", label)
			else:
				failed += 1
				print("  FAIL  ", label)
				for failure in test.failures:
					print("        - ", failure)
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _test_scripts() -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(UNIT_DIR)
	if dir == null:
		push_error("run_tests: %s not found" % UNIT_DIR)
		return paths
	for file in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			paths.append(UNIT_DIR.path_join(file))
	paths.sort()
	return paths
