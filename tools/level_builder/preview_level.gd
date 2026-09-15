class_name PreviewLevel
extends Node

## Opens a level in single-player for quick visual checks, then tours the
## player through every checkpoint and the goal (two seconds each):
##   godot --path . res://tools/level_builder/preview_level.tscn -- --level=canyon
## Add --write-movie <file.png> --fixed-fps 10 to capture frames.

const TOUR_SECONDS := 2.0


func _ready() -> void:
	# This node is the current scene and is freed by the scene change, so the
	# tour runs on a separate node attached to the tree root.
	var runner := PreviewRunner.new()
	runner.level_id = _level_argument()
	get_tree().root.add_child.call_deferred(runner)


func _level_argument() -> StringName:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--level="):
			return StringName(argument.get_slice("=", 1))
	return LevelCatalog.load_default().first_level().id


class PreviewRunner extends Node:
	var level_id: StringName

	func _ready() -> void:
		var level_info := LevelCatalog.load_default().get_level(level_id)
		if level_info == null:
			push_error("preview_level: unknown level '%s'" % level_id)
			get_tree().quit(1)
			return
		MultiplayerManager.start_single_player(level_info.id)
		get_tree().change_scene_to_file(level_info.scene_path)
		await get_tree().scene_changed
		await _tour()
		get_tree().quit()

	func _tour() -> void:
		var level := get_tree().current_scene as Level
		var player := level.get_node("Players/local") as Player
		var stops: Array[Vector2] = [player.global_position]
		for checkpoint in level.get_node("Checkpoints").get_children():
			stops.append((checkpoint as Node2D).global_position)
		stops.append(level.level_goal.global_position + Vector2(-48, 0))
		for stop in stops:
			player.global_position = stop
			player.velocity = Vector2.ZERO
			player.camera.reset_smoothing()
			await get_tree().create_timer(PreviewLevel.TOUR_SECONDS).timeout
