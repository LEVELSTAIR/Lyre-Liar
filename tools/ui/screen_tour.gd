extends Node

## Visits every menu and in-level overlay for two seconds each so they can
## be captured for review:
##   godot --path . res://tools/ui/screen_tour.tscn --write-movie tour.png --fixed-fps 5

const HOLD_SECONDS := 2.0


func _ready() -> void:
	# This node is the current scene; run the tour on a node that survives
	# scene changes.
	var runner := TourRunner.new()
	get_tree().root.add_child.call_deferred(runner)


class TourRunner extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for scene in [SceneRouter.TITLE_SCENE, SceneRouter.LEVEL_SELECT_SCENE]:
			await _show(scene)
		MenuFlow.level_id = LevelCatalog.load_default().first_level().id
		await _show(SceneRouter.CHARACTER_SELECT_SCENE)
		await _show(SceneRouter.SETTINGS_SCENE)
		MenuFlow.mode = MenuFlow.Mode.MULTIPLAYER
		await _show(SceneRouter.MULTIPLAYER_SCENE)
		MenuFlow.mode = MenuFlow.Mode.SINGLE_PLAYER

		var level_info := LevelCatalog.load_default().first_level()
		MultiplayerManager.start_single_player(level_info.id)
		await _show(level_info.scene_path)
		var level := get_tree().current_scene as Level
		Events.pause_requested.emit()
		await _hold()
		(level.get_node("PauseMenu") as PauseMenu).close()
		(level.get_node("Players/local") as Player).kill()
		await _hold()
		(level.get_node("DeathMenu") as DeathMenu).close()
		(level.get_node("Players/local") as Player).respawn()
		level.get_node("Players/local").global_position = level.level_goal.global_position
		await _hold()
		get_tree().quit()

	func _show(scene_path: String) -> void:
		SceneRouter.go_to(scene_path)
		await SceneRouter.transition_finished
		await _hold()

	func _hold() -> void:
		await get_tree().create_timer(HOLD_SECONDS, true).timeout
