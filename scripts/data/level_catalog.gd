class_name LevelCatalog
extends Resource

## Ordered list of every level the game ships. Array order is play order:
## completing a level unlocks the next entry.

const DEFAULT_PATH := "res://data/levels/level_catalog.tres"

@export var levels: Array[LevelInfo] = []


static func load_default() -> LevelCatalog:
	return load(DEFAULT_PATH) as LevelCatalog


func get_level(id: StringName) -> LevelInfo:
	var index := index_of(id)
	return levels[index] if index >= 0 else null


func index_of(id: StringName) -> int:
	for i in levels.size():
		if levels[i].id == id:
			return i
	return -1


## Returns the level after `id`, or null when `id` is the last (or unknown).
func next_level(id: StringName) -> LevelInfo:
	var index := index_of(id)
	if index < 0 or index + 1 >= levels.size():
		return null
	return levels[index + 1]


## Returns the level before `id`, or null when `id` is the first (or unknown).
func previous_level(id: StringName) -> LevelInfo:
	var index := index_of(id)
	if index <= 0:
		return null
	return levels[index - 1]


func first_level() -> LevelInfo:
	return levels[0] if not levels.is_empty() else null
