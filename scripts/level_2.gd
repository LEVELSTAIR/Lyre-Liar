extends Node2D

const MAP_PATH     := "res://asset/terrain/Sunny-land-woods-files/Assets/Demo/assets/maps/map.json"
const TILESET_PATH := "res://asset/terrain/Sunny-land-woods-files/Assets/ENVIRONMENT/tileset.png"
const MAP_WIDTH    := 40
const MAP_HEIGHT   := 60
const TILESET_COLS := 36
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
	var kill_zone: Area2D = $KillZone
	kill_zone.body_entered.connect(_on_kill_zone_body_entered)

	_build_from_map()
	_decorate_world()
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


func _build_from_map() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	var col_data: Array  = data["layers"][0]["data"]
	var vis_data: Array  = data["layers"][1]["data"]

	var tile_set := TileSet.new()
	var atlas    := TileSetAtlasSource.new()
	atlas.texture             = load(TILESET_PATH)
	atlas.texture_region_size = Vector2i(TILE_PX, TILE_PX)
	tile_set.add_source(atlas, 0)

	var tilemap := TileMap.new()
	tilemap.tile_set = tile_set
	tilemap.scale    = Vector2(SCALE_FACTOR, SCALE_FACTOR)
	add_child(tilemap)

	for row in range(MAP_HEIGHT):
		for col in range(MAP_WIDTH):
			var gid: int = vis_data[row * MAP_WIDTH + col]
			if gid > 0:
				var ac := Vector2i((gid - 1) % TILESET_COLS, (gid - 1) / TILESET_COLS)
				if not atlas.has_tile(ac):
					atlas.create_tile(ac)
				tilemap.set_cell(0, Vector2i(col, row), 0, ac)

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


func _decorate_world() -> void:
	const PROPS_PATH := "res://asset/terrain/Sunny-land-woods-files/Assets/Demo/assets/atlas/atlas-props.png"
	const LEAVES  := Rect2(506, 2, 150, 103)
	const BR_01   := Rect2(2,   2, 54,  56)
	const BR_03   := Rect2(140, 2, 94,  53)
	const BR_05   := Rect2(374, 2, 130, 37)
	var tex := load(PROPS_PATH) as Texture2D
	if not tex:
		return
	var leaf_positions := [
		Vector2(4, 50), Vector2(25, 52), Vector2(34, 48), Vector2(33, 53),
		Vector2(27, 44), Vector2(36, 32), Vector2(2, 5),  Vector2(3, 7),
		Vector2(36, 5),  Vector2(3, 0),  Vector2(12, 2),
	]
	for tp in leaf_positions:
		_add_prop(tex, tp.x * TILE_WORLD, tp.y * TILE_WORLD, LEAVES)
	_add_prop(tex, 33 * TILE_WORLD, 33 * TILE_WORLD, BR_05, true)
	_add_prop(tex, 12 * TILE_WORLD, 32 * TILE_WORLD, BR_01)
	_add_prop(tex, 31 * TILE_WORLD, 21 * TILE_WORLD, BR_01)
	_add_prop(tex,  5 * TILE_WORLD,  7 * TILE_WORLD, BR_01)
	_add_prop(tex,  9 * TILE_WORLD, 40 * TILE_WORLD, BR_03)


func _add_prop(tex: Texture2D, wx: float, wy: float, region: Rect2, flip_x: bool = false) -> void:
	var s := Sprite2D.new()
	s.texture        = tex
	s.region_enabled = true
	s.region_rect    = region
	s.scale          = Vector2(SCALE_FACTOR, SCALE_FACTOR)
	s.position       = Vector2(wx, wy)
	s.flip_h         = flip_x
	add_child(s)


func _add_player(id: String) -> void:
	if has_node(id):
		return

	print("Spawning player with session ID '", id, "'")
	var player = preload("res://scenes/player.tscn").instantiate()
	player.session_id = id
	player.name = id

	player.position = _spawn_points[_spawn_index % _spawn_points.size()]
	_spawn_index += 1

	add_child(player)

	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left   = 0
	cam.limit_top    = 0
	cam.limit_right  = MAP_WIDTH  * TILE_WORLD
	cam.limit_bottom = MAP_HEIGHT * TILE_WORLD


func _remove_player(id: String) -> void:
	if has_node(id):
		get_node(id).queue_free()


func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body.has_method("respawn"):
		body.respawn()


func _display_room_code(custom_code: String = "") -> void:
	var room_code = custom_code

	if room_code.is_empty():
		room_code = MultiplayerManager.room_code
<<<<<<< HEAD

=======
		
>>>>>>> upstream/dev
	print("Room code to display: '", room_code, "'")

	if room_code.is_empty():
		print("WARNING: Room code is empty!")
		return

	var ui_layer = CanvasLayer.new()
	ui_layer.layer = 100
	add_child(ui_layer)

	var label = Label.new()
	label.text = "Room: " + room_code
	label.anchor_left = 0
	label.anchor_top = 0
	label.offset_left = 20
	label.offset_top = 20
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	ui_layer.add_child(label)
	print("Room code label created: ", room_code)
