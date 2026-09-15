class_name MenuScreen
extends Control

## Base for full-screen menus: gives keyboard/gamepad focus to
## `initial_focus` and handles "back" (Esc, gamepad B, Android back).

## Scene opened by the back action; leave empty for screens without back.
@export_file("*.tscn") var back_scene: String = ""
@export var initial_focus: Control


func _ready() -> void:
	if initial_focus != null:
		initial_focus.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		go_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


func go_back() -> void:
	if not back_scene.is_empty():
		SceneRouter.go_to(back_scene)
