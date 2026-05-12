extends Node2D

var _spawn_points := [
	Vector2(50, 152), Vector2(100, 152), Vector2(200, 152), Vector2(300, 152),
	Vector2(400, 152), Vector2(500, 152), Vector2(600, 152), Vector2(700, 152),
]
var _spawn_index := 0

func _ready() -> void:
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
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _add_player(id: String) -> void:
	if has_node(id):
		return
	var player = preload("res://scenes/player.tscn").instantiate()
	player.session_id = id
	player.name = id
	player.position = _spawn_points[_spawn_index % _spawn_points.size()]
	_spawn_index += 1
	add_child(player)
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left   = 0
	cam.limit_top    = 0
	cam.limit_right  = 1124
	cam.limit_bottom = 240

func _remove_player(id: String) -> void:
	if has_node(id):
		get_node(id).queue_free()

func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body.has_method("respawn"):
		body.respawn()

func _display_room_code(custom_code: String = "") -> void:
	var room_code := custom_code
	if room_code.is_empty():
		room_code = MultiplayerManager.room_code
	if room_code.is_empty():
		return
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 100
	add_child(ui_layer)
	var label := Label.new()
	label.text = "Room: " + room_code
	label.offset_left = 20
	label.offset_top  = 20
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	ui_layer.add_child(label)
