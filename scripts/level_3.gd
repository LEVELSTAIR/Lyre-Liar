extends Node2D

const MAP_PATH     := "res://asset/terrain/Sunny-land-woods-files/Assets/Demo/assets/maps/map.json"
const MAP_WIDTH    := 40
const MAP_HEIGHT   := 60
const TILE_PX      := 16
const SCALE_FACTOR := 4
const TILE_WORLD   := TILE_PX * SCALE_FACTOR
const COL_SOLID    := 1
const COL_ONEWAY   := 2

var _spawn_points := [
	Vector2(128, 3264), Vector2(256, 3264), Vector2(384, 3264), Vector2(512, 3264),
	Vector2(640, 3264), Vector2(768, 3264), Vector2(896, 3264), Vector2(1024, 3264),
]
var _spawn_index := 0
var _mountain_x: float = 0.0
var _tree_x: float = 0.0

func _process(delta: float) -> void:
	_mountain_x -= delta * 6.0
	_tree_x -= delta * 18.0
	if _mountain_x <= -360.0:
		_mountain_x += 360.0
	if _tree_x <= -360.0:
		_tree_x += 360.0
	($BGLayer/Mountains  as TextureRect).position.x = _mountain_x
	($BGLayer/Mountains2 as TextureRect).position.x = _mountain_x + 360.0
	($BGLayer/Trees      as TextureRect).position.x = _tree_x
	($BGLayer/Trees2     as TextureRect).position.x = _tree_x + 360.0


func _ready() -> void:
	$KillZone.body_entered.connect(_on_kill_zone_body_entered)
	_build_collisions()
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


func _build_collisions() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	var col_data: Array  = data["layers"][0]["data"]

	for row in range(MAP_HEIGHT):
		var run_start := -1
		var run_type  := 0
		for col in range(MAP_WIDTH + 1):
			var val: int = col_data[row * MAP_WIDTH + col] if col < MAP_WIDTH else 0
			if val != run_type:
				if run_type != 0 and run_start >= 0:
					_spawn_run(run_start, row, col - run_start, run_type)
				run_start = col if val != 0 else -1
				run_type  = val


func _spawn_run(run_start: int, row: int, run_len: int, col_type: int) -> void:
	var body       := StaticBody2D.new()
	body.position   = Vector2((run_start + run_len * 0.5) * TILE_WORLD, (row + 0.5) * TILE_WORLD)
	var shape_node := CollisionShape2D.new()
	var rect       := RectangleShape2D.new()
	rect.size       = Vector2(run_len * TILE_WORLD, TILE_WORLD)
	shape_node.shape = rect
	if col_type == COL_ONEWAY:
		shape_node.one_way_collision        = true
		shape_node.one_way_collision_margin = 2.0
	body.add_child(shape_node)
	add_child(body)


func _add_player(id: String) -> void:
	if has_node(id):
		return
	var player = preload("res://scenes/player.tscn").instantiate()
	player.session_id = id
	player.name       = id
	player.position   = _spawn_points[_spawn_index % _spawn_points.size()]
	_spawn_index += 1
	add_child(player)
	# Camera limits intentionally left at Godot's defaults (±10⁶) so
	# the camera follows the player anywhere — including into the death pit
	# — until the goal is reached.


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
