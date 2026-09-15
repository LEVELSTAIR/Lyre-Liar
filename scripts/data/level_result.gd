class_name LevelResult
extends RefCounted

## Outcome of one completed level run, passed to GameProgress and the
## level-complete screen.

var level_id: StringName
var time_seconds: float
var fruits: int
var total_fruits: int
var deaths: int


func _init(p_level_id: StringName, p_time_seconds: float, p_fruits: int, p_total_fruits: int, p_deaths: int) -> void:
	level_id = p_level_id
	time_seconds = p_time_seconds
	fruits = p_fruits
	total_fruits = p_total_fruits
	deaths = p_deaths
