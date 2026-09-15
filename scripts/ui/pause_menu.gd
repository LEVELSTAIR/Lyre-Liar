class_name PauseMenu
extends OverlayMenu

## Pause overlay. Opened by the `pause` action, the HUD pause button, the
## Android back button, or the app losing focus.

@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _levels_button: Button = %LevelsButton
@onready var _leave_button: Button = %LeaveButton


func _ready() -> void:
	super()
	_resume_button.pressed.connect(close)
	_restart_button.pressed.connect(SceneRouter.reload_current)
	_levels_button.pressed.connect(_leave_to.bind(SceneRouter.LEVEL_SELECT_SCENE))
	_leave_button.pressed.connect(_leave_to.bind(SceneRouter.TITLE_SCENE))
	var single_player := MultiplayerManager.is_single_player
	_restart_button.visible = single_player
	_levels_button.visible = single_player
	_leave_button.text = "MAIN MENU" if single_player else "LEAVE ROOM"
	Events.pause_requested.connect(_open_if_allowed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") or (is_open and event.is_action_pressed(&"ui_cancel")):
		get_viewport().set_input_as_handled()
		_toggle()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_toggle()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_open_if_allowed()


func _toggle() -> void:
	if is_open:
		close()
	else:
		_open_if_allowed()


## Doesn't open over another overlay that already paused the game.
func _open_if_allowed() -> void:
	if is_open or get_tree().paused:
		return
	open(true)
	Events.pause_toggled.emit(true)


func close() -> void:
	super()
	Events.pause_toggled.emit(false)
