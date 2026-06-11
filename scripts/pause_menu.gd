extends CanvasLayer

## In-level pause overlay. Triggered by `ui_cancel` (ESC), the Android back
## button, or the small "II" button shown in the top-right corner. Pausing
## halts the local scene tree only — in multiplayer the server keeps running
## and remote players keep moving when you unpause.

@onready var _overlay: ColorRect = $Overlay
@onready var _resume_btn: Button = $Overlay/Panel/ResumeButton
@onready var _menu_btn: Button = $Overlay/Panel/MainMenuButton
@onready var _quit_btn: Button = $Overlay/Panel/QuitButton
@onready var _open_btn: Button = $PauseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.visible = false
	_resume_btn.pressed.connect(_resume)
	_menu_btn.pressed.connect(_to_main_menu)
	_quit_btn.pressed.connect(_quit)
	_open_btn.pressed.connect(_toggle)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_toggle()


func _toggle() -> void:
	if _overlay.visible:
		_resume()
	else:
		_open()


func _open() -> void:
	_overlay.visible = true
	get_tree().paused = true


func _resume() -> void:
	_overlay.visible = false
	get_tree().paused = false


func _to_main_menu() -> void:
	get_tree().paused = false
	MultiplayerManager.leave()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _quit() -> void:
	get_tree().paused = false
	MultiplayerManager.leave()
	get_tree().quit()
