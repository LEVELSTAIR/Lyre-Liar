extends MenuScreen

## First screen: brand title, character parade, and the main choices.

@onready var _play_button: Button = %PlayButton
@onready var _multiplayer_button: Button = %MultiplayerButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _parade: HBoxContainer = %Parade
@onready var _version_label: Label = %VersionLabel


func _ready() -> void:
	super()
	MultiplayerManager.leave()
	_play_button.pressed.connect(_on_play_pressed)
	_multiplayer_button.pressed.connect(_on_multiplayer_pressed)
	_settings_button.pressed.connect(SceneRouter.go_to.bind(SceneRouter.SETTINGS_SCENE))
	_quit_button.pressed.connect(get_tree().quit)
	# Mobile and web builds are closed by the OS, not from inside the game.
	_quit_button.visible = not (OS.has_feature("mobile") or OS.has_feature("web"))
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	_version_label.text = "v%s" % version
	_version_label.visible = not version.is_empty()
	_build_parade()


func _build_parade() -> void:
	for character in CharacterCatalog.load_default().characters:
		var preview := CharacterPreview.new()
		preview.pixel_scale = 2
		preview.character = character
		preview.animation = &"run" if character.id == GameProgress.last_character else &"idle"
		_parade.add_child(preview)


func _on_play_pressed() -> void:
	MenuFlow.mode = MenuFlow.Mode.SINGLE_PLAYER
	SceneRouter.go_to_level_select()


func _on_multiplayer_pressed() -> void:
	MenuFlow.mode = MenuFlow.Mode.MULTIPLAYER
	SceneRouter.go_to(SceneRouter.CHARACTER_SELECT_SCENE)
