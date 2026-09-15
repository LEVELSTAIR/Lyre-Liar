extends TestCase

const GameProgressScript := preload("res://scripts/autoload/game_progress.gd")
const TEST_SAVE_PATH := "user://test_progress.cfg"

var progress: Node


func before_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	var catalog := LevelCatalog.new()
	for id in [&"one", &"two", &"three"]:
		var info := LevelInfo.new()
		info.id = id
		catalog.levels.append(info)
	progress = GameProgressScript.new()
	progress.save_path = TEST_SAVE_PATH
	progress.catalog = catalog
	progress.load_progress()


func after_each() -> void:
	progress.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))


func test_only_first_level_unlocked_initially() -> void:
	assert_true(progress.is_unlocked(&"one"))
	assert_false(progress.is_unlocked(&"two"))
	assert_false(progress.is_unlocked(&"missing"))


func test_completing_level_unlocks_next() -> void:
	progress.record_result(LevelResult.new(&"one", 42.0, 3, 5, 1))
	assert_true(progress.is_completed(&"one"))
	assert_true(progress.is_unlocked(&"two"))
	assert_false(progress.is_unlocked(&"three"))


func test_best_time_only_improves() -> void:
	assert_almost_eq(progress.best_time(&"one"), -1.0)
	assert_true(progress.record_result(LevelResult.new(&"one", 50.0, 1, 5, 0)), "first run is a best")
	assert_false(progress.record_result(LevelResult.new(&"one", 60.0, 5, 5, 0)), "slower run is not a best")
	assert_almost_eq(progress.best_time(&"one"), 50.0)
	assert_eq(progress.best_fruits(&"one"), 5, "best fruits tracked independently of time")


func test_progress_persists_to_disk() -> void:
	progress.record_result(LevelResult.new(&"one", 30.0, 2, 5, 0))
	progress.set_volumes(0.25, 0.5)
	var reloaded: Node = GameProgressScript.new()
	reloaded.save_path = TEST_SAVE_PATH
	reloaded.catalog = progress.catalog
	reloaded.load_progress()
	assert_true(reloaded.is_completed(&"one"))
	assert_almost_eq(reloaded.best_time(&"one"), 30.0)
	assert_almost_eq(reloaded.music_volume, 0.25)
	assert_almost_eq(reloaded.sfx_volume, 0.5)
	reloaded.free()


func test_volume_is_clamped() -> void:
	progress.music_volume = 3.0
	progress.sfx_volume = -1.0
	assert_almost_eq(progress.music_volume, 1.0)
	assert_almost_eq(progress.sfx_volume, 0.0)
