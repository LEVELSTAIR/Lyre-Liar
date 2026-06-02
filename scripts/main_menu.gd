extends Control

const BASE_TITLE_HALF_W: float = 300.0
const BASE_TITLE_BAR_H: float = 6.0
const BASE_VBOX_HALF_W: float = 140.0
const BASE_BUTTON_W: float = 280.0
const BASE_BUTTON_H: float = 56.0
const BASE_CARD_W: float = 131.0   # (280 - 18 h_separation) / 2 columns
const BASE_CARD_H: float = 96.0
# Visible viewport for the map scroll: 2 full rows + ~24 px peek of the next
# row so the affordance ("there's more — scroll") is obvious when the grid
# exceeds two rows.
const BASE_MAP_SCROLL_H: float = 234.0
const BASE_VBOX_SEP: float = 18.0

const BASE_FONT_TITLE: int = 52
const BASE_FONT_SUBTITLE: int = 18
const BASE_FONT_MODE: int = 14
const BASE_FONT_BUTTON: int = 22
const BASE_FONT_CARD_NAME: int = 22
const BASE_FONT_CARD_DESC: int = 11
const BASE_FONT_VERSION: int = 12

const MAP_GRID_COLUMNS: int = 2

const INTER_ITALIC := preload("res://asset/Fonts/Inter-Italic-VariableFont.ttf")

# Brand colors mirrored from docs/design-system/colors_and_type.css.
const BRASS_RULE := Color(0.78, 0.55, 0.18, 1)
const SHELL_VOID := Color(0.03, 0.06, 0.03, 1)
const BRASS_GLOW := Color(0.85, 0.7, 0.4, 1)

@onready var title_container: VBoxContainer = $TitleContainer
@onready var title_bar: ColorRect = $TitleContainer/TitleBar
@onready var title_bar_bot: ColorRect = $TitleContainer/TitleBarBottom
@onready var title_label: Label = $TitleContainer/TitleLabel
@onready var subtitle_label: Label = $TitleContainer/SubtitleLabel
@onready var vbox: VBoxContainer = $VBox
@onready var mode_label: Label = $VBox/ModeLabel
@onready var single_player_button: Button = $VBox/SinglePlayerButton
@onready var multiplayer_button: Button = $VBox/MultiplayerButton
@onready var map_scroll: ScrollContainer = $VBox/MapScroll
@onready var map_cards_grid: GridContainer = $VBox/MapScroll/MapCardsGrid
@onready var pink_monster_button: Button = $VBox/PinkMonsterButton
@onready var dude_monster_button: Button = $VBox/DudeMonsterButton
@onready var owlet_monster_button: Button = $VBox/OwletMonsterButton
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
var _selected_character: String = ""

# Populated by _build_map_cards(); used by _apply_layout() to scale fonts.
var _card_name_labels: Array[Label] = []
var _card_desc_labels: Array[Label] = []


func _ready() -> void:
	MultiplayerManager.leave()

	single_player_button.pressed.connect(_on_single_player_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_pressed)
	pink_monster_button.pressed.connect(_on_character_pressed.bind("pink"))
	dude_monster_button.pressed.connect(_on_character_pressed.bind("dude"))
	owlet_monster_button.pressed.connect(_on_character_pressed.bind("owlet"))
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

	_build_map_cards()

	ResponsiveUI.scale_changed.connect(_apply_layout)
	_apply_layout(ResponsiveUI.scale_factor)

	_update_ui_state()


# ─── Map cards ─────────────────────────────────────────────────────────────────
# The three map buttons are restyled at runtime into brass-bordered cards with
# a mood-colored name and an italic-Inter subtitle. Brass-rule top/bottom
# mirrors the title block per docs/design-system/README.md (Cards section).

func _build_map_cards() -> void:
	map_cards_grid.columns = MAP_GRID_COLUMNS
	for def in MultiplayerManager.MAP_REGISTRY:
		var card := Button.new()
		card.custom_minimum_size = Vector2(BASE_CARD_W, BASE_CARD_H)
		_apply_card_style(card, def["name"], def["desc"], def["mood"])
		card.pressed.connect(_on_map_card_pressed.bind(def["mode"]))
		map_cards_grid.add_child(card)


func _apply_card_style(btn: Button, name_text: String, desc_text: String, mood: Color) -> void:
	btn.text = ""
	btn.icon = null
	btn.add_theme_stylebox_override("normal",  _make_card_style(0.85, 1.0))
	btn.add_theme_stylebox_override("hover",   _make_card_style(0.95, 1.6))
	btn.add_theme_stylebox_override("pressed", _make_card_style(0.95, 0.55))

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 2)
	btn.add_child(content)

	var name_label := Label.new()
	name_label.text = name_text
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", BASE_FONT_CARD_NAME)
	name_label.add_theme_color_override("font_color", mood)
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	content.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = desc_text
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", BASE_FONT_CARD_DESC)
	desc_label.add_theme_color_override("font_color", BRASS_GLOW)
	desc_label.add_theme_font_override("font", INTER_ITALIC)
	content.add_child(desc_label)

	_card_name_labels.append(name_label)
	_card_desc_labels.append(desc_label)


func _make_card_style(alpha: float, brightness: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(SHELL_VOID.r * brightness, SHELL_VOID.g * brightness, SHELL_VOID.b * brightness, alpha)
	s.border_color = BRASS_RULE
	s.border_width_top = 6
	s.border_width_bottom = 6
	s.border_width_left = 0
	s.border_width_right = 0
	s.corner_radius_top_left = 0
	s.corner_radius_top_right = 0
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	return s


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

	for btn in [single_player_button, multiplayer_button,
			pink_monster_button, dude_monster_button, owlet_monster_button,
			host_button, join_button, quit_button]:
		btn.custom_minimum_size = Vector2(button_w, button_h)
		btn.add_theme_font_size_override("font_size", int(BASE_FONT_BUTTON * sf))

	# Map cards live in a GridContainer wrapped in a ScrollContainer, sized
	# per-cell. The scroll viewport is capped so adding more maps doesn't push
	# the QuitButton off-screen — overflow becomes scrollable instead.
	var card_w: float = BASE_CARD_W * sf
	var card_h: float = BASE_CARD_H * sf
	var grid_sep: int = int(18.0 * sf)
	map_scroll.custom_minimum_size = Vector2(button_w, BASE_MAP_SCROLL_H * sf)
	map_cards_grid.add_theme_constant_override("h_separation", grid_sep)
	map_cards_grid.add_theme_constant_override("v_separation", grid_sep)
	for card in map_cards_grid.get_children():
		if card is Control:
			card.custom_minimum_size = Vector2(card_w, card_h)
	for lbl in _card_name_labels:
		lbl.add_theme_font_size_override("font_size", int(BASE_FONT_CARD_NAME * sf))
	for lbl in _card_desc_labels:
		lbl.add_theme_font_size_override("font_size", int(BASE_FONT_CARD_DESC * sf))

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
		map_scroll.visible = false
		pink_monster_button.visible = false
		dude_monster_button.visible = false
		owlet_monster_button.visible = false
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
		map_scroll.visible = true
		pink_monster_button.visible = false
		dude_monster_button.visible = false
		owlet_monster_button.visible = false
		room_code_input.visible = false
		server_ip_input.visible = false
		server_ip_label.visible = false
		status_label.visible = false
		host_button.visible = false
		join_button.visible = false

	elif _selected_character.is_empty():
		# ── Screen 3: character selection ─────────────────────────
		mode_label.visible = true
		mode_label.text = "SELECT CHARACTER  (" + _selected_mode.to_upper() + ")"
		single_player_button.visible = false
		multiplayer_button.visible = false
		map_scroll.visible = false
		pink_monster_button.visible = true
		dude_monster_button.visible = true
		owlet_monster_button.visible = true
		room_code_input.visible = false
		server_ip_input.visible = false
		server_ip_label.visible = false
		status_label.visible = false
		host_button.visible = false
		join_button.visible = false

	else:
		# ── Screen 4: multiplayer options ─────────────────────────
		mode_label.visible = true
		mode_label.text = "MULTIPLAYER  (" + _selected_mode.to_upper() + ")"
		single_player_button.visible = false
		multiplayer_button.visible = false
		map_scroll.visible = false
		pink_monster_button.visible = false
		dude_monster_button.visible = false
		owlet_monster_button.visible = false
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

func _on_map_card_pressed(mode: String) -> void:
	_selected_mode = mode
	_after_map_selected()


func _after_map_selected() -> void:
	# Always advance to character select; map choice is locked in.
	_selected_character = ""
	_update_ui_state()


# ─── Character selection ──────────────────────────────────────────────────────

func _on_character_pressed(character: String) -> void:
	_selected_character = character
	MultiplayerManager.selected_character = character
	if _game_type == "single":
		pink_monster_button.disabled = true
		dude_monster_button.disabled = true
		owlet_monster_button.disabled = true
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
	get_tree().change_scene_to_file(MultiplayerManager.get_map(mode)["scene"])


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
