extends MenuScreen

## Host a room on a chosen level, or join one with its 4-character code.
## The server address is remembered in user://server_config.cfg.

const SERVER_CONFIG_PATH := "user://server_config.cfg"
const ROOM_CODE_LENGTH := 4

var _levels: Array[LevelInfo] = []

@onready var _back_button: Button = %BackButton
@onready var _server_input: LineEdit = %ServerInput
@onready var _level_picker: OptionButton = %LevelPicker
@onready var _host_button: Button = %HostButton
@onready var _code_input: LineEdit = %CodeInput
@onready var _join_button: Button = %JoinButton
@onready var _status: Label = %Status


func _ready() -> void:
	back_scene = SceneRouter.CHARACTER_SELECT_SCENE
	_back_button.pressed.connect(go_back)
	_host_button.pressed.connect(_on_host_pressed)
	_join_button.pressed.connect(_on_join_pressed)
	_code_input.text_submitted.connect(func(_text: String) -> void: _on_join_pressed())
	_code_input.text_changed.connect(_on_code_changed)
	_code_input.max_length = ROOM_CODE_LENGTH

	for level in LevelCatalog.load_default().levels:
		_levels.append(level)
		_level_picker.add_item(level.title)

	var config := ConfigFile.new()
	if config.load(SERVER_CONFIG_PATH) == OK:
		MultiplayerManager.server_ip = config.get_value("network", "last_ip", MultiplayerManager.server_ip)
	_server_input.text = MultiplayerManager.server_ip

	MultiplayerManager.connection_failed.connect(_on_connection_failed)
	MultiplayerManager.connected_to_game.connect(_on_connected_to_game)
	initial_focus = _host_button
	super()


func go_back() -> void:
	MultiplayerManager.leave()
	super()


func _on_host_pressed() -> void:
	_set_busy(true, "hosting game...")
	_apply_server_address()
	MultiplayerManager.selected_mode = _levels[_level_picker.selected].id
	MultiplayerManager.host_game()


func _on_join_pressed() -> void:
	var code := _code_input.text.strip_edges().to_upper()
	if code.length() != ROOM_CODE_LENGTH:
		_status.text = "room code must be %d characters" % ROOM_CODE_LENGTH
		_code_input.grab_focus()
		return
	_set_busy(true, "joining room %s..." % code)
	_apply_server_address()
	MultiplayerManager.join_game(code)


func _on_code_changed(text: String) -> void:
	var caret := _code_input.caret_column
	_code_input.text = text.to_upper()
	_code_input.caret_column = caret


func _on_connected_to_game(mode: String) -> void:
	var catalog := LevelCatalog.load_default()
	var level := catalog.get_level(mode)
	SceneRouter.go_to_level(level if level != null else catalog.first_level())


func _on_connection_failed(reason: String) -> void:
	_set_busy(false, "connection failed: %s" % reason)


func _apply_server_address() -> void:
	var address := _server_input.text.strip_edges()
	if address.is_empty():
		address = "localhost"
	MultiplayerManager.server_ip = address
	var config := ConfigFile.new()
	config.set_value("network", "last_ip", address)
	config.save(SERVER_CONFIG_PATH)


func _set_busy(busy: bool, status_text: String) -> void:
	_status.text = status_text
	for control: Control in [_host_button, _join_button, _level_picker]:
		control.set(&"disabled", busy)
	_server_input.editable = not busy
	_code_input.editable = not busy
