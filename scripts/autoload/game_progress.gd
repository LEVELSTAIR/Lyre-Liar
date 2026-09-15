extends Node

## Persists player progress (completed levels, best times, best fruit counts)
## and audio settings to a ConfigFile in user://.
##
## A level is unlocked when it is the first level in the catalog or when the
## level before it has been completed.

signal progress_changed
signal settings_changed

const SAVE_PATH := "user://progress.cfg"
const LEVELS_SECTION := "levels"
const SETTINGS_SECTION := "settings"

const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

## Overridable so tests can use a throwaway file.
var save_path: String = SAVE_PATH
var catalog: LevelCatalog

var music_volume: float = 0.8:
	set(value):
		music_volume = clampf(value, 0.0, 1.0)
		_apply_bus_volume(MUSIC_BUS, music_volume)
var sfx_volume: float = 0.8:
	set(value):
		sfx_volume = clampf(value, 0.0, 1.0)
		_apply_bus_volume(SFX_BUS, sfx_volume)

var _config := ConfigFile.new()


func _ready() -> void:
	if catalog == null:
		catalog = LevelCatalog.load_default()
	load_progress()


func load_progress() -> void:
	_config = ConfigFile.new()
	var error := _config.load(save_path)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning("GameProgress: could not read %s (error %d); starting fresh" % [save_path, error])
		_config = ConfigFile.new()
	music_volume = _config.get_value(SETTINGS_SECTION, "music_volume", 0.8)
	sfx_volume = _config.get_value(SETTINGS_SECTION, "sfx_volume", 0.8)


func save_progress() -> void:
	_config.set_value(SETTINGS_SECTION, "music_volume", music_volume)
	_config.set_value(SETTINGS_SECTION, "sfx_volume", sfx_volume)
	var error := _config.save(save_path)
	if error != OK:
		push_error("GameProgress: could not write %s (error %d)" % [save_path, error])


func is_unlocked(level_id: StringName) -> bool:
	var previous := catalog.previous_level(level_id)
	if previous == null:
		return catalog.index_of(level_id) == 0
	return is_completed(previous.id)


func is_completed(level_id: StringName) -> bool:
	return _config.get_value(LEVELS_SECTION, _key(level_id, "completed"), false)


## Best completion time in seconds, or -1.0 if the level was never completed.
func best_time(level_id: StringName) -> float:
	return _config.get_value(LEVELS_SECTION, _key(level_id, "best_time"), -1.0)


func best_fruits(level_id: StringName) -> int:
	return _config.get_value(LEVELS_SECTION, _key(level_id, "best_fruits"), 0)


## Stores a finished run. Returns true when it set a new best time.
func record_result(result: LevelResult) -> bool:
	var previous_best := best_time(result.level_id)
	var is_new_best := previous_best < 0.0 or result.time_seconds < previous_best
	_config.set_value(LEVELS_SECTION, _key(result.level_id, "completed"), true)
	if is_new_best:
		_config.set_value(LEVELS_SECTION, _key(result.level_id, "best_time"), result.time_seconds)
	if result.fruits > best_fruits(result.level_id):
		_config.set_value(LEVELS_SECTION, _key(result.level_id, "best_fruits"), result.fruits)
	save_progress()
	progress_changed.emit()
	return is_new_best


func set_volumes(music: float, sfx: float) -> void:
	music_volume = music
	sfx_volume = sfx
	save_progress()
	settings_changed.emit()


func reset_progress() -> void:
	if _config.has_section(LEVELS_SECTION):
		_config.erase_section(LEVELS_SECTION)
	save_progress()
	progress_changed.emit()


func _key(level_id: StringName, field: String) -> String:
	return "%s/%s" % [level_id, field]


func _apply_bus_volume(bus_name: StringName, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume))
	AudioServer.set_bus_mute(bus_index, volume <= 0.0)
