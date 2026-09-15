extends Node

## End-to-end smoke test. Launched by smoke_flow.tscn, which attaches this
## runner to the tree root so it survives scene changes:
##   godot --headless --path . res://tests/smoke/smoke_flow.tscn
## Starts single-player on every catalog level, checks the local player
## spawns, touches the goal, and verifies progress is recorded and the
## level-complete screen can advance. Exits with code 1 on failure.

const STEP_TIMEOUT_FRAMES := 600
const EMPTY_SCENE := "res://tests/smoke/empty.tscn"
const PlayerMovementChecks := preload("res://tests/smoke/player_movement_checks.gd")
const GameplayObjectChecks := preload("res://tests/smoke/gameplay_object_checks.gd")

var _failures: Array[String] = []


func _ready() -> void:
	GameProgress.save_path = "user://smoke_progress.cfg"
	GameProgress.reset_progress()
	_run.call_deferred()


func _run() -> void:
	var catalog := LevelCatalog.load_default()
	for level in catalog.levels:
		await _check_level(level)
	await SceneRouter.go_to(EMPTY_SCENE)
	var player_checks := PlayerMovementChecks.new()
	await player_checks.run(get_tree())
	_failures.append_array(player_checks.failures)
	var object_checks := GameplayObjectChecks.new()
	await object_checks.run(get_tree())
	_failures.append_array(object_checks.failures)
	GameProgress.reset_progress()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameProgress.save_path))
	for failure in _failures:
		printerr("SMOKE FAIL: ", failure)
	print("SMOKE %s (%d failures)" % ["PASSED" if _failures.is_empty() else "FAILED", _failures.size()])
	get_tree().quit(1 if not _failures.is_empty() else 0)


func _check_level(level: LevelInfo) -> void:
	print("smoke: level ", level.id)
	MultiplayerManager.start_single_player(level.id)
	SceneRouter.go_to_level(level)
	if not await _wait_until(func() -> bool: return _current_scene_path() == level.scene_path and not SceneRouter.is_transitioning):
		_failures.append("%s: scene %s did not load" % [level.id, level.scene_path])
		return

	var scene := get_tree().current_scene as Level
	if scene == null:
		_failures.append("%s: scene root is not a Level" % level.id)
		return
	if scene.level_id != level.id:
		_failures.append("%s: scene level_id is '%s'" % [level.id, scene.level_id])
	if scene.fruits_total == 0:
		_failures.append("%s: level has no fruits" % level.id)
	var player := scene.get_node_or_null("Players/local") as Player
	if player == null:
		_failures.append("%s: local player was not spawned" % level.id)
		return

	# The player must land on solid ground at the start and survive idling.
	var died := [false]
	player.died.connect(func() -> void: died[0] = true)
	await _frames(120)
	if not is_instance_valid(player):
		_failures.append("%s: local player was freed after spawning" % level.id)
		return
	if not player.is_on_floor():
		_failures.append("%s: player is not standing on ground at the start (pos %s)" % [level.id, player.global_position])
	if died[0]:
		_failures.append("%s: player died while idling at the start" % level.id)

	player.global_position = scene.level_goal.global_position
	if not await _wait_until(func() -> bool: return GameProgress.is_completed(level.id)):
		_failures.append("%s: reaching the goal did not record completion" % level.id)
		return
	var next := LevelCatalog.load_default().next_level(level.id)
	if next != null and not GameProgress.is_unlocked(next.id):
		_failures.append("%s: completing it did not unlock %s" % [level.id, next.id])


func _current_scene_path() -> String:
	var scene := get_tree().current_scene
	return scene.scene_file_path if scene != null else ""


func _wait_until(condition: Callable) -> bool:
	for i in STEP_TIMEOUT_FRAMES:
		if condition.call():
			return true
		await get_tree().process_frame
	return false


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
