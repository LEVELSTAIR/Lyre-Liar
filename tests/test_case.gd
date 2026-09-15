class_name TestCase
extends RefCounted

## Base class for headless unit tests run by tests/run_tests.gd.
## Every method whose name starts with `test_` is executed on a fresh instance.

var failures: Array[String] = []
var tree: SceneTree


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func assert_true(condition: bool, message: String = "expected true") -> void:
	if not condition:
		failures.append(message)


func assert_false(condition: bool, message: String = "expected false") -> void:
	if condition:
		failures.append(message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%sexpected <%s> but got <%s>" % [_prefix(message), expected, actual])


func assert_almost_eq(actual: float, expected: float, tolerance: float = 0.001, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%sexpected <%s> ± %s but got <%s>" % [_prefix(message), expected, tolerance, actual])


func assert_null(value: Variant, message: String = "expected null") -> void:
	if value != null:
		failures.append("%s (got <%s>)" % [message, value])


func assert_not_null(value: Variant, message: String = "expected a value, got null") -> void:
	if value == null:
		failures.append(message)


func _prefix(message: String) -> String:
	return "" if message.is_empty() else message + ": "
