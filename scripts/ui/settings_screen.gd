extends MenuScreen

## Display and input settings, plus resetting saved level progress.

@onready var _back_button: Button = %BackButton
@onready var _fullscreen: CheckButton = %Fullscreen
@onready var _touch_controls: OptionButton = %TouchControls
@onready var _reset_button: Button = %ResetButton
@onready var _reset_dialog: ConfirmationDialog = %ResetDialog
@onready var _status: Label = %Status


func _ready() -> void:
	back_scene = SceneRouter.TITLE_SCENE
	_back_button.pressed.connect(go_back)

	_fullscreen.button_pressed = GameProgress.fullscreen
	_fullscreen.visible = not (OS.has_feature("mobile") or OS.has_feature("web"))
	_fullscreen.toggled.connect(func(_on: bool) -> void: _save())

	_touch_controls.add_item("AUTO", GameProgress.TouchControls.AUTO)
	_touch_controls.add_item("ALWAYS", GameProgress.TouchControls.ALWAYS)
	_touch_controls.add_item("NEVER", GameProgress.TouchControls.NEVER)
	_touch_controls.select(_touch_controls.get_item_index(GameProgress.touch_controls))
	_touch_controls.item_selected.connect(func(_index: int) -> void: _save())

	_reset_button.pressed.connect(_reset_dialog.popup_centered)
	_reset_dialog.confirmed.connect(_on_reset_confirmed)
	initial_focus = _touch_controls
	super()


func _save() -> void:
	GameProgress.update_settings(_touch_controls.get_selected_id(), _fullscreen.button_pressed)


func _on_reset_confirmed() -> void:
	GameProgress.reset_progress()
	_status.text = "progress reset"
