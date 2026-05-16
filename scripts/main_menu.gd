extends Control

const BASE_TITLE_HALF_W: float = 300.0
const BASE_TITLE_BAR_H: float = 6.0
const BASE_VBOX_HALF_W: float = 140.0
const BASE_BUTTON_W: float = 280.0
const BASE_BUTTON_H: float = 56.0
const BASE_VBOX_SEP: float = 18.0

const BASE_FONT_TITLE: int = 52
const BASE_FONT_SUBTITLE: int = 18
const BASE_FONT_MODE: int = 14
const BASE_FONT_BUTTON: int = 22
const BASE_FONT_VERSION: int = 12

@onready var title_container: VBoxContainer = $TitleContainer
@onready var title_bar: ColorRect = $TitleContainer/TitleBar
@onready var title_bar_bot: ColorRect = $TitleContainer/TitleBarBottom
@onready var title_label: Label = $TitleContainer/TitleLabel
@onready var subtitle_label: Label = $TitleContainer/SubtitleLabel
@onready var vbox: VBoxContainer = $VBox
@onready var mode_label: Label = $VBox/ModeLabel
@onready var single_player_button: Button = $VBox/SinglePlayerButton
@onready var multiplayer_button: Button = $VBox/MultiplayerButton
@onready var day_button: Button = $VBox/DayButton
@onready var night_button: Button = $VBox/NightButton
@onready var forest_button: Button = $VBox/ForestButton
@onready var room_code_input: LineEdit = $VBox/RoomCodeInput
@onready var status_label: Label = $VBox/StatusLabel
@onready var host_button: Button = $VBox/HostButton
@onready var join_button: Button = $VBox/JoinButton
@onready var quit_button: Button = $VBox/QuitButton
@onready var version_label: Label = $VersionLabel

const SAVE_PATH = "user://server_config.cfg"
var server_ip_input: LineEdit
var server_ip_label: Label

# "" = initial  |  "single" = single-player picked  |  "multi" = multiplayer picked
var _game_type: String = ""
var _selected_mode: String = ""


func _ready() -> void:
	MultiplayerManager.leave()

	single_player_button.pressed.connect(_on_single_player_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_pressed)
	day_button.pressed.connect(_on_day_pressed)
	night_button.pressed.connect(_on_night_pressed)
	forest_button.pressed.connect(_on_forest_pressed)
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	room_code_input.text_submitted.connect(_on_room_code_submitted)

	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		MultiplayerManager.server_ip = config.get_value("network", "last_ip", "localhost")

	server_ip_label = Label.new()
	server_ip_label.text = "SERVER ADDRESS"
	server_ip_label.horizontal_alignment = 1 as HorizontalAlignment
	vbox.add_child(server_ip_label)

	server_ip_input = LineEdit.new()
	server_ip_input.placeholder_text = "e.g. 192.168.1.10"
	server_ip_input.text = MultiplayerManager.server_ip
	server_ip_input.alignment = 1 as HorizontalAlignment
	vbox.add_child(server_ip_input)

	var room_idx = room_code_input.get_index()
	vbox.move_child(server_ip_label, room_idx)
	vbox.move_child(server_ip_input, room_idx + 1)

	MultiplayerManager.room_code_ready.connect(_on_room_code_ready)
	MultiplayerManager.connection_failed.connect(_on_connection_failed)
	MultiplayerManager.connected_to_game.connect(_on_connected_to_game)

	ResponsiveUI.scale_changed.connect(_apply_layout)
	_apply_layout(ResponsiveUI.scale_factor)

	_update_ui_state()


func _apply_layout(sf: float) -> void:
	var half_title_w: float = BASE_TITLE_HALF_W * sf
	var half_vbox_w: float = BASE_VBOX_HALF_W * sf
	var button_w: float = BASE_BUTTON_W * sf
	var button_h: float = BASE_BUTTON_H * sf
	var title_bar_h: float = BASE_TITLE_BAR_H * sf

	title_container.offset_left = -half_title_w
	title_container.offset_right = half_title_w

	title_bar.custom_minimum_size = Vector2(half_title_w * 2.0, title_bar_h)
	title_bar_bot.custom_minimum_size = Vector2(half_title_w * 2.0, title_bar_h)

	vbox.offset_left = -half_vbox_w
	vbox.offset_right = half_vbox_w
	vbox.add_theme_constant_override("separation", int(BASE_VBOX_SEP * sf))

	for btn in [single_player_button, multiplayer_button, day_button, night_button,
			forest_button, host_button, join_button, quit_button]:
		btn.custom_minimum_size = Vector2(button_w, button_h)
		btn.add_theme_font_size_override("font_size", int(BASE_FONT_BUTTON * sf))

	room_code_input.custom_minimum_size = Vector2(button_w, button_h * 0.7)
	server_ip_input.custom_minimum_size = Vector2(button_w, button_h * 0.7)
	status_label.custom_minimum_size = Vector2(button_w, button_h * 0.8)

	title_label.add_theme_font_size_override("font_size", int(BASE_FONT_TITLE * sf))
	subtitle_label.add_theme_font_size_override("font_size", int(BASE_FONT_SUBTITLE * sf))
	mode_label.add_theme_font_size_override("font_size", int(BASE_FONT_MODE * sf))
	server_ip_label.add_theme_font_size_override("font_size", int(BASE_FONT_MODE * sf))
	room_code_input.add_theme_font_size_override("font_size", int(BASE_FONT_MODE * sf))
	server_ip_input.add_theme_font_size_override("font_size", int(BASE_FONT_MODE * sf))
	status_label.add_theme_font_size_override("font_size", int(BASE_FONT_MODE * sf))
	version_label.add_theme_font_size_override("font_size", int(BASE_FONT_VERSION * sf))


func _update_ui_state() -> void:
	if _game_type.is_empty():
		# ── Screen 1: initial ─────────────────────────────────────
		mode_label.visible = false
		single_player_button.visible = true
		multiplayer_button.visible = true
		day_button.visible = false
		night_button.visible = false
		forest_button.visible = false
		room_code_input.visible = false
		server_ip_input.visible = false
		server_ip_label.visible = false
		status_label.visible = false
		host_button.visible = false
		join_button.visible = false

	elif _selected_mode.is_empty():
		# ── Screen 2: map selection ───────────────────────────────
		mode_label.visible = true
		mode_label.text = "SELECT MAP"
		single_player_button.visible = false
		multiplayer_button.visible = false
		day_button.visible = true
		night_button.visible = true
		forest_button.visible = true
		room_code_input.visible = false
		server_ip_input.visible = false
		server_ip_label.visible = false
		status_label.visible = false
		host_button.visible = false
		join_button.visible = false

	else:
		# ── Screen 3: multiplayer options ─────────────────────────
		mode_label.visible = true
		mode_label.text = "MULTIPLAYER  (" + _selected_mode.to_upper() + ")"
		single_player_button.visible = false
		multiplayer_button.visible = false
		day_button.visible = false
		night_button.visible = false
		forest_button.visible = false
		room_code_input.visible = true
		server_ip_input.visible = true
		server_ip_label.visible = true
		status_label.visible = true
		host_button.visible = true
		join_button.visible = true


# ─── Initial screen ────────────────────────────────────────────────────────────

func _on_single_player_pressed() -> void:
	_game_type = "single"
	_selected_mode = ""
	_update_ui_state()


func _on_multiplayer_pressed() -> void:
	_game_type = "multi"
	_selected_mode = ""
	_update_ui_state()


# ─── Map selection ─────────────────────────────────────────────────────────────

func _on_day_pressed() -> void:
	_selected_mode = "day"
	_after_map_selected()


func _on_night_pressed() -> void:
	_selected_mode = "night"
	_after_map_selected()


func _on_forest_pressed() -> void:
	_selected_mode = "forest"
	_after_map_selected()


func _after_map_selected() -> void:
	if _game_type == "single":
		single_player_button.disabled = true
		multiplayer_button.disabled = true
		MultiplayerManager.start_single_player(_selected_mode)
	else:
		_update_ui_state()


# ─── Multiplayer options ───────────────────────────────────────────────────────

func _on_host_pressed() -> void:
	if _selected_mode.is_empty():
		return
	host_button.disabled = true
	join_button.disabled = true
	room_code_input.visible = false
	status_label.text = "Hosting game..."

	var ip = server_ip_input.text.strip_edges()
	if ip.is_empty(): ip = "localhost"
	MultiplayerManager.server_ip = ip
	_save_config(ip)
	server_ip_input.editable = false

	MultiplayerManager.is_hosting_intent = true
	MultiplayerManager.join_intent_code = ""
	MultiplayerManager.selected_mode = _selected_mode
	MultiplayerManager.host_game()


func _on_join_pressed() -> void:
	if room_code_input.visible and not room_code_input.text.strip_edges().is_empty():
		_on_room_code_submitted(room_code_input.text)
		return
	room_code_input.visible = true
	room_code_input.grab_focus()
	room_code_input.clear()
	room_code_input.placeholder_text = "Enter room code"
	status_label.text = "Waiting for room code..."


func _on_room_code_submitted(new_text: String) -> void:
	_attempt_join(new_text.strip_edges().to_upper())


func _attempt_join(code: String) -> void:
	if code.length() != 4:
		status_label.text = "Room code must be 4 characters"
		return
	if host_button.disabled:
		return
	host_button.disabled = true
	join_button.disabled = true
	room_code_input.editable = false
	status_label.text = "Loading game..."
	print("Preparing to join room: ", code)

	MultiplayerManager.is_hosting_intent = false
	MultiplayerManager.join_intent_code = code

	var ip = server_ip_input.text.strip_edges()
	if ip.is_empty(): ip = "localhost"
	MultiplayerManager.server_ip = ip
	server_ip_input.editable = false
	_save_config(ip)

	MultiplayerManager.join_game(code)


# ─── Multiplayer callbacks ─────────────────────────────────────────────────────

func _on_room_code_ready(code: String) -> void:
	MultiplayerManager.room_code = code
	var local_ip = IP.get_local_addresses()
	var ip_str = ""
	for ip in local_ip:
		if ip.begins_with("192.168.") or ip.begins_with("10."):
			ip_str = ip
			break
		if ip.begins_with("172."):
			var parts := ip.split(".")
			if parts.size() >= 2 and parts[1].is_valid_int():
				var octet := parts[1].to_int()
				if octet >= 16 and octet <= 31:
					ip_str = ip
					break
	if ip_str == "": ip_str = local_ip[0] if local_ip.size() > 0 else "Unknown"
	status_label.text = "Room: " + code + "\nYour IP: " + ip_str + "\nWaiting for players..."


func _on_connected_to_game(mode: String) -> void:
	var scene_path = "res://scenes/level_1.tscn"
	if mode == "day":
		scene_path = "res://scenes/level_2.tscn"
	elif mode == "forest":
		scene_path = "res://scenes/level_4.tscn"
	get_tree().change_scene_to_file(scene_path)


func _on_connection_failed(reason: String) -> void:
	print("Connection failed: ", reason)
	status_label.text = "Error: " + reason
	host_button.disabled = false
	join_button.disabled = false
	room_code_input.editable = true
	server_ip_input.editable = true
	if room_code_input.visible:
		status_label.text = "Failed: " + reason + " (Check room code and try again)"


func _on_quit_pressed() -> void:
	get_tree().quit()


func _save_config(ip: String) -> void:
	var config = ConfigFile.new()
	config.set_value("network", "last_ip", ip)
	config.save(SAVE_PATH)
