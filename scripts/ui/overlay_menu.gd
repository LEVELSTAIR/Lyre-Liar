class_name OverlayMenu
extends CanvasLayer

## Base for in-level overlays (pause, death, level complete): fades in over
## the game, optionally pauses the tree, and focuses the first button.

var is_open: bool = false

@onready var root: Control = $Root
@onready var buttons: VBoxContainer = %Buttons


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false


func open(pause_game: bool) -> void:
	if is_open:
		return
	is_open = true
	root.visible = true
	root.modulate.a = 0.0
	create_tween().tween_property(root, ^"modulate:a", 1.0, 0.2)
	if pause_game:
		get_tree().paused = true
	_focus_first_button()


func close() -> void:
	is_open = false
	root.visible = false
	get_tree().paused = false


func _focus_first_button() -> void:
	for child in buttons.get_children():
		var button := child as Button
		if button != null and button.visible and not button.disabled:
			button.grab_focus.call_deferred()
			return


func _leave_to(scene_path: String) -> void:
	MultiplayerManager.leave()
	SceneRouter.go_to(scene_path)
