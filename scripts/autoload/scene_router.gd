extends CanvasLayer

## Changes scenes behind a short fade so every transition in the game looks
## the same. Always unpauses the tree before switching.

signal transition_finished

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const FADE_SECONDS := 0.25

var is_transitioning: bool = false

var _fade: ColorRect


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


func go_to(scene_path: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	await _tween_fade(1.0)
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneRouter: failed to load %s (error %d)" % [scene_path, error])
	await get_tree().scene_changed
	await _tween_fade(0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
	transition_finished.emit()


func go_to_level(level: LevelInfo) -> void:
	go_to(level.scene_path)


func go_to_main_menu() -> void:
	go_to(MAIN_MENU_SCENE)


func reload_current() -> void:
	var current := get_tree().current_scene
	if current != null:
		go_to(current.scene_file_path)


func _tween_fade(target_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", target_alpha, FADE_SECONDS)
	await tween.finished
