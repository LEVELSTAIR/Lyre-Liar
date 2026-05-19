extends Node2D

## Level scene. Terrain, spawn points, and camera bounds come from the scene,
## not from this script — paint geometry (e.g. with a TileMapLayer) in the
## editor and add Marker2D children under a `SpawnPoints` node for spawns.

@export var world_size: Vector2 = Vector2(3840, 1536)

var _spawn_index := 0

# Elevated platforms generated at runtime on top of the base floor tiles.
# Base floor sits at rows 6–7 (world y ≈ 443–467).
# Mid platforms (rows 3–4) are reachable in one jump (~73 px max height).
# High platforms (rows 1–2) are reachable from mid platforms.
const PLATFORMS := [
	{"rs": 3, "re": 4, "cs": 10, "ce": 22},
	{"rs": 3, "re": 4, "cs": 35, "ce": 47},
	{"rs": 3, "re": 4, "cs": 60, "ce": 72},
	{"rs": 1, "re": 2, "cs": 22, "ce": 34},
	{"rs": 1, "re": 2, "cs": 48, "ce": 60},
]


func _create_platform_tiles() -> void:
	var tilemap := get_node_or_null("TileMap") as TileMap
	if tilemap == null:
		return
	for p in PLATFORMS:
		for row in range(p.rs, p.re + 1):
			for col in range(p.cs, p.ce + 1):
				var coords := Vector2i(col, row)
				var atlas := Vector2i(14 + col % 2, 23 + row % 2)
				if tilemap.get_cell_source_id(0, coords) != 1 \
						or tilemap.get_cell_atlas_coords(0, coords) != atlas:
					tilemap.set_cell(0, coords, 1, atlas)


func _ready() -> void:
	_create_platform_tiles()

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


# ─── Players ──────────────────────────────────────────────────────────────────
func _add_player(id: String) -> void:
	if has_node(id):
		return
	var player = preload("res://scenes/player.tscn").instantiate()
	player.session_id = id
	player.name = id
	player.position = _next_spawn_position()
	_spawn_index += 1
	add_child(player)

	if player.is_local_player:
		var cam: Camera2D = player.get_node("Camera2D")
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = int(world_size.x)
		cam.limit_bottom = int(world_size.y)


func _remove_player(id: String) -> void:
	if has_node(id):
		get_node(id).queue_free()


func _next_spawn_position() -> Vector2:
	var positions := _spawn_positions()
	if positions.is_empty():
		push_warning("Level2: no Marker2D children under 'SpawnPoints'; spawning at (0, 0)")
		return Vector2.ZERO
	return positions[_spawn_index % positions.size()]


func _spawn_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var holder := get_node_or_null("SpawnPoints")
	if holder == null:
		return positions
	for child in holder.get_children():
		if child is Node2D:
			positions.append((child as Node2D).position)
	return positions


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
