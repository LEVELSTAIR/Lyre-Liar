extends Node

## Entry scene for the smoke test. Moves the runner under the tree root so
## it keeps running while the test changes scenes.

const SmokeRunner := preload("res://tests/smoke/smoke_runner.gd")


func _ready() -> void:
	var runner := SmokeRunner.new()
	runner.name = "SmokeRunner"
	get_tree().root.add_child.call_deferred(runner)
