extends Node2D

## Day map — a sunny outdoor platformer built procedurally from the existing
## res://asset/terrain/generated/ tiles. Replaces the prior JSON loader that
## relied on the (removed) Sunny-land-woods asset pack.

# ─── Tile types ───────────────────────────────────────────────────────────────
const EMPTY := 0
const GRASS := 1   # grass_surface — used for ground top
const DIRT  := 2   # dirt_body    — used under grass
const STONE := 3   # stone_surface — floating platforms
const ROCK  := 4   # stone_body   — solid stone (decoration / bottom layer)

const TILE_SIZE := 128

# 30 columns × 12 rows = 3840 × 1536 px world.
# 0=sky, 1=grass top, 2=dirt body, 3=stone surface platform, 4=stone body
const LEVEL: Array = [
	[0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,3,3,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,3,3,3,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,3,3, 3,0,0,0,0,0,0,0,3,3, 0,0,0,0,0,0,0,0,0,0],
	[0,0,3,3,0,0,0,0,0,0, 0,0,0,3,3,3,0,0,0,0, 0,0,0,0,0,0,3,3,0,0],
	[1,1,1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,1,1],
	[2,2,2,2,2,2,2,2,2,2, 2,2,2,2,2,2,2,2,2,2, 2,2,2,2,2,2,2,2,2,2],
	[2,2,2,2,2,2,2,2,2,2, 2,2,2,2,2,2,2,2,2,2, 2,2,2,2,2,2,2,2,2,2],
]

# ─── Textures ─────────────────────────────────────────────────────────────────
const TEX_BASE := "res://asset/terrain/generated/"
const TEX_PATHS := {
	GRASS: TEX_BASE + "grass_surface.png",
	DIRT:  TEX_BASE + "dirt_body.png",
	STONE: TEX_BASE + "stone_surface.png",
	ROCK:  TEX_BASE + "stone_body.png",
}
const MODULATE := {
	GRASS: Color(1.00, 1.00, 1.00, 1),
	DIRT:  Color(0.95, 0.85, 0.65, 1),
	STONE: Color(1.00, 1.00, 1.00, 1),
	ROCK:  Color(0.85, 0.85, 0.85, 1),
}

var _tex: Dictionary = {}
var _spawn_points := [
	Vector2(256, 900),  Vector2(640, 900),  Vector2(1024, 900),
	Vector2(1408, 900), Vector2(1792, 900), Vector2(2176, 900),
	Vector2(2560, 900), Vector2(3072, 900),
]
var _spawn_index := 0


func _ready() -> void:
	for tile_type in TEX_PATHS:
		_tex[tile_type] = load(TEX_PATHS[tile_type])

	$KillZone.body_entered.connect(_on_kill_zone_body_entered)

	_build_level()

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


# ─── Level builder ────────────────────────────────────────────────────────────
func _build_level() -> void:
	var width := LEVEL[0].size()
	_spawn_wall(-20, LEVEL.size() * TILE_SIZE)
	_spawn_wall(width * TILE_SIZE + 20, LEVEL.size() * TILE_SIZE)

	for row in LEVEL.size():
		for col in LEVEL[row].size():
			var tile_type: int = LEVEL[row][col]
			if tile_type == EMPTY:
				continue
			_spawn_tile(col, row, tile_type)


func _spawn_tile(col: int, row: int, tile_type: int) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(col * TILE_SIZE + TILE_SIZE * 0.5,
							row * TILE_SIZE + TILE_SIZE * 0.5)

	var sprite := Sprite2D.new()
	sprite.texture = _tex[tile_type]
	sprite.modulate = MODULATE.get(tile_type, Color.WHITE)
	body.add_child(sprite)

	var col_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE_SIZE, TILE_SIZE)
	col_shape.shape = rect
	body.add_child(col_shape)

	add_child(body)


func _spawn_wall(x_pos: float, height: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x_pos, height * 0.5)
	var col_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, height)
	col_shape.shape = rect
	body.add_child(col_shape)
	add_child(body)


# ─── Players ──────────────────────────────────────────────────────────────────
func _add_player(id: String) -> void:
	if has_node(id):
		return
	var player = preload("res://scenes/player.tscn").instantiate()
	player.session_id = id
	player.name = id
	player.position = _spawn_points[_spawn_index % _spawn_points.size()]
	_spawn_index += 1
	add_child(player)

	if player.is_local_player:
		var cam: Camera2D = player.get_node("Camera2D")
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = LEVEL[0].size() * TILE_SIZE
		cam.limit_bottom = LEVEL.size() * TILE_SIZE


func _remove_player(id: String) -> void:
	if has_node(id):
		get_node(id).queue_free()


func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body.has_method("respawn"):
		body.respawn()


# ─── HUD ──────────────────────────────────────────────────────────────────────
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
	label.offset_top = 20
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	ui_layer.add_child(label)
