extends Node2D

var _spawn_points := [
	Vector2(50, 152), Vector2(100, 152), Vector2(200, 152), Vector2(300, 152),
	Vector2(400, 152), Vector2(500, 152), Vector2(600, 152), Vector2(700, 152),
]
var _spawn_index := 0
var _death_menu: CanvasLayer = null
var _level_complete_menu: CanvasLayer = null
var _timer_hud: CanvasLayer = null
var _health_hud: CanvasLayer = null
var _run_time: float = 0.0
var _deaths: int = 0

func _ready() -> void:
	add_child(preload("res://scenes/pause_menu.tscn").instantiate())
	_death_menu = preload("res://scenes/death_menu.tscn").instantiate()
	add_child(_death_menu)
	_level_complete_menu = preload("res://scenes/level_complete_menu.tscn").instantiate()
	add_child(_level_complete_menu)
	_timer_hud = preload("res://scenes/timer_hud.tscn").instantiate()
	add_child(_timer_hud)
	_health_hud = preload("res://scenes/health_hud.tscn").instantiate()
	add_child(_health_hud)

	# Tag every enemy in the scene so player.gd recognises them as damage
	# sources via the "enemies" group during slide-collision checks.
	_tag_enemies()

	$GoalZone.body_entered.connect(_on_goal_body_entered)
	$KillZone.body_entered.connect(_on_kill_zone_body_entered)

	MultiplayerManager.connection_failed.connect(_on_connection_failed)
	MultiplayerManager.player_connected.connect(_add_player)
	MultiplayerManager.player_disconnected.connect(_remove_player)

	for pid in MultiplayerManager.active_players:
		_add_player(pid)

	if MultiplayerManager.is_hosting_intent:
		MultiplayerManager.room_code_ready.connect(_on_room_code_ready)
		_display_room_code()
	else:
		_display_room_code(MultiplayerManager.join_intent_code)

func _on_room_code_ready(code: String) -> void:
	_display_room_code(code)

func _on_connection_failed(_reason: String) -> void:
	if MultiplayerManager.is_single_player:
		return
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _add_player(id: String) -> void:
	if has_node(id):
		return
	var player = preload("res://scenes/player.tscn").instantiate()
	player.session_id = id
	player.name = id
	player.position = _spawn_points[_spawn_index % _spawn_points.size()]
	# Forest: camera Y is locked at spawn (camera_lock_vertical defaults to
	# true), so the climb plays out inside a fixed vertical slice. The zoom
	# fits the 640 px tall viewport to the 480 px tall cave background
	# (offset_top=230.89, offset_bottom=710.89), so the visible slice
	# matches the bg height exactly — the whole climb (~84 px from
	# spawn.y=152 to goal.y=68) stays in frame without vertical scroll.
	#
	# camera_offset shifts the rendered view; +Y pushes platforms UP on
	# screen, +X pushes the player LEFT on screen (camera looks rightward,
	# showing more world to the right of the player).
	#
	# Zoom 0.85 widens the visible window to ~423 px (half-width ≈ 211)
	# so an offset.x of 200 keeps the player just on-screen at the far
	# left. Trade-off: visible height becomes ~753 px > the 480 px cave
	# bg, so there's some void above/below the cave.
	player.camera_zoom = Vector2(1.0, 1.0)
	player.camera_offset = Vector2(140, 160)
	_spawn_index += 1
	add_child(player)

	if player.is_local_player:
		if _health_hud:
			player.hp_changed.connect(_health_hud.set_hp)
			_health_hud.set_hp(player.current_hp, player.MAX_HP)
		player.died.connect(_on_player_died.bind(player))

	# Camera limits intentionally left at Godot's defaults (±10⁶) so
	# the camera follows the player anywhere — including into the death pit
	# — until the goal is reached.


func _on_player_died(player: Node2D) -> void:
	_deaths += 1
	if _death_menu and _death_menu.has_method("show_death"):
		_death_menu.show_death(player)


func _tag_enemies() -> void:
	var enemies := get_node_or_null("Enemies")
	if enemies == null:
		return
	for child in enemies.get_children():
		child.add_to_group("enemies")


func _remove_player(id: String) -> void:
	if has_node(id):
		get_node(id).queue_free()

func _process(delta: float) -> void:
	if MultiplayerManager.is_single_player:
		_run_time += delta


func _on_kill_zone_body_entered(body: Node2D) -> void:
	if not body.has_method("respawn"):
		return
	if "is_local_player" in body and body.is_local_player:
		_deaths += 1
		if _death_menu and _death_menu.has_method("show_death"):
			_death_menu.show_death(body)


func _on_goal_body_entered(body: Node2D) -> void:
	if _level_complete_menu == null:
		return
	if "is_local_player" in body and body.is_local_player:
		if _timer_hud and _timer_hud.has_method("stop"):
			_timer_hud.stop()
		_level_complete_menu.show_win(body, _run_time, _deaths)

func _display_room_code(custom_code: String = "") -> void:
	var room_code := custom_code
	if room_code.is_empty():
		room_code = MultiplayerManager.room_code
	if room_code.is_empty():
		return
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 100
	add_child(ui_layer)

	var panel := PanelContainer.new()
	panel.offset_left = 12
	panel.offset_top  = 12

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.08, 0.82)
	style.corner_radius_top_left     = 10
	style.corner_radius_top_right    = 10
	style.corner_radius_bottom_left  = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left   = 14
	style.content_margin_right  = 14
	style.content_margin_top    = 8
	style.content_margin_bottom = 8
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_color = Color(1.0, 0.8, 0.2, 0.4)
	panel.add_theme_stylebox_override("panel", style)
	ui_layer.add_child(panel)

	var label := Label.new()
	label.text = "Room: " + room_code
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	panel.add_child(label)
