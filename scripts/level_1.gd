extends Node2D

# ─── Tile type constants ──────────────────────────────────────────────────────
const EMPTY   := 0
const GRASS   := 1
const DIRT    := 2
const STONE   := 3
const ROCK    := 4
const BEDROCK := 5
const FUNGUS  := 6
const GLOW    := 7

# ─── World geometry ───────────────────────────────────────────────────────────
const TILE_SIZE := 128

const LEVEL: Array = [
	[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
	[ 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 ],
	[ 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 ],
	[ 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 ],
	[ 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 ],
]

# ─── Texture map ──────────────────────────────────────────────────────────────
const TEX_BASE := "res://asset/terrain/generated/"

const TEX_PATHS := {
	GRASS:   TEX_BASE + "grass_surface.png",
	DIRT:    TEX_BASE + "dirt_body.png",
	STONE:   TEX_BASE + "stone_surface.png",
	ROCK:    TEX_BASE + "stone_body.png",
	BEDROCK: TEX_BASE + "bedrock.png",
	FUNGUS:  TEX_BASE + "fungus_surface.png",
	GLOW:    TEX_BASE + "glow_surface.png",
}

const MODULATE := {
	GRASS:   Color(1.00, 1.00, 1.00, 1),
	DIRT:    Color(0.88, 0.84, 0.80, 1),
	STONE:   Color(0.95, 0.95, 1.00, 1),
	ROCK:    Color(0.72, 0.72, 0.76, 1),
	BEDROCK: Color(0.55, 0.55, 0.58, 1),
	FUNGUS:  Color(1.00, 0.95, 0.90, 1),
	GLOW:    Color(1.00, 1.00, 1.00, 1),
}

# ─── State ────────────────────────────────────────────────────────────────────
var _tex: Dictionary = {}
var _spawn_points := [
	Vector2(512, -100), Vector2(832, -100), Vector2(1152, -100), Vector2(1472, -100),
	Vector2(512, -180), Vector2(832, -180), Vector2(1152, -180), Vector2(1472, -180)
]
var _spawn_index := 0


# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	for tile_type in TEX_PATHS:
		_tex[tile_type] = load(TEX_PATHS[tile_type])

	var kill_zone: Area2D = $KillZone
	kill_zone.body_entered.connect(_on_kill_zone_body_entered)

	_build_level()
	MultiplayerManager.connection_failed.connect(_on_connection_failed)

	# Connect Colyseus signals for future players
	MultiplayerManager.player_connected.connect(_add_player)
	MultiplayerManager.player_disconnected.connect(_remove_player)

	# Spawn players that already connected before the scene loaded
	for pid in MultiplayerManager.active_players:
		_add_player(pid)

	if MultiplayerManager.is_hosting_intent:
		MultiplayerManager.room_code_ready.connect(_on_room_code_ready)
		_display_room_code()
	else:
		_display_room_code(MultiplayerManager.join_intent_code)
		print("Level: Join completed")


func _on_room_code_ready(code: String) -> void:
	_display_room_code(code)


func _on_connection_failed(reason: String) -> void:
	print("Connection failed: ", reason)
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _add_player(session_id: String) -> void:
	if has_node(session_id):
		print("Player ", session_id, " already exists")
		return

	print("Spawning player with session_id '", session_id, "'")
	var player = preload("res://scenes/player.tscn").instantiate()
	player.session_id = session_id
	player.name = session_id
	player.position = _spawn_points[_spawn_index % _spawn_points.size()]
	_spawn_index += 1

	add_child(player)
	print("Player ", session_id, " spawned at ", player.position)


func _remove_player(session_id: String) -> void:
	if has_node(session_id):
		get_node(session_id).queue_free()
		print("Player ", session_id, " removed")


# ─── Level builder ────────────────────────────────────────────────────────────
func _build_level() -> void:
	# Add boundary walls
	_spawn_wall(-20, 1000) # Left wall
	_spawn_wall(LEVEL[0].size() * TILE_SIZE + 20, 1000) # Right wall

	for row in LEVEL.size():
		for col in LEVEL[row].size():
			var tile_type: int = LEVEL[row][col]
			if tile_type == EMPTY:
				continue
			_spawn_tile(col, row, tile_type)


func _spawn_tile(col: int, row: int, tile_type: int) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(
		col * TILE_SIZE + TILE_SIZE * 0.5,
		row * TILE_SIZE + TILE_SIZE * 0.5
	)

	var sprite := Sprite2D.new()
	sprite.texture  = _tex[tile_type]
	sprite.modulate = MODULATE.get(tile_type, Color.WHITE)
	body.add_child(sprite)

	var col_shape := CollisionShape2D.new()
	var rect      := RectangleShape2D.new()
	rect.size      = Vector2(TILE_SIZE, TILE_SIZE)
	col_shape.shape = rect
	body.add_child(col_shape)

	add_child(body)


func _spawn_wall(x_pos: float, height: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x_pos, 0)
	var col_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, height * 2.0)
	col_shape.shape = rect
	body.add_child(col_shape)
	add_child(body)


func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body.has_method("respawn"):
		body.respawn()


func _display_room_code(custom_code: String = "") -> void:
	var room_code = custom_code

	if room_code.is_empty():
		room_code = MultiplayerManager.room_code

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
