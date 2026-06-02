## Run this once from the Godot editor:
##   Open this file in the Script editor, then press Ctrl+Shift+X  (or File → Run)
## It reads map.json, builds a TileMap, and saves the complete level_3.tscn.
@tool
extends EditorScript

const MAP_PATH     := "res://asset/terrain/Sunny-land-woods-files/Assets/Demo/assets/maps/map.json"
const TILESET_PATH := "res://asset/terrain/Sunny-land-woods-files/Assets/ENVIRONMENT/tileset.png"
const CLOUDS_PATH  := "res://asset/terrain/Sunny-land-woods-files/Assets/ENVIRONMENT/bg-clouds.png"
const MOUNTAINS_PATH := "res://asset/terrain/Sunny-land-woods-files/Assets/ENVIRONMENT/bg-mountains.png"
const TREES_PATH   := "res://asset/terrain/Sunny-land-woods-files/Assets/ENVIRONMENT/bg-trees.png"
const MOBILE_PATH  := "res://scenes/mobile_controls.tscn"
const OUT_PATH     := "res://scenes/level_3.tscn"

const MAP_WIDTH    := 40
const MAP_HEIGHT   := 60
const TILESET_COLS := 36
const TILE_PX      := 16
const SCALE_FACTOR := 4

func _run() -> void:
	print("=== Baking Level 3 ===")

	# ── Parse map.json ──────────────────────────────────────────────────────────
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	var vis_data: Array  = data["layers"][1]["data"]

	# ── TileSet + Atlas ─────────────────────────────────────────────────────────
	var atlas := TileSetAtlasSource.new()
	atlas.texture             = load(TILESET_PATH)
	atlas.texture_region_size = Vector2i(TILE_PX, TILE_PX)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_PX, TILE_PX)
	tile_set.add_source(atlas, 0)

	# ── TileMap ─────────────────────────────────────────────────────────────────
	var tilemap := TileMap.new()
	tilemap.name     = "TileMap"
	tilemap.tile_set = tile_set
	tilemap.scale    = Vector2(SCALE_FACTOR, SCALE_FACTOR)

	for row in range(MAP_HEIGHT):
		for col in range(MAP_WIDTH):
			var gid: int = vis_data[row * MAP_WIDTH + col]
			if gid > 0:
				var ac := Vector2i((gid - 1) % TILESET_COLS, (gid - 1) / TILESET_COLS)
				if not atlas.has_tile(ac):
					atlas.create_tile(ac)
				tilemap.set_cell(0, Vector2i(col, row), 0, ac)

	print("  TileMap populated with ", tilemap.get_used_cells(0).size(), " tiles")

	# ── Root node ───────────────────────────────────────────────────────────────
	var root := Node2D.new()
	root.name = "Level3"
	root.set_script(load("res://scripts/level_3.gd"))

	_own(root, tilemap)

	# ── Background CanvasLayer ──────────────────────────────────────────────────
	var bg := CanvasLayer.new()
	bg.name  = "BGLayer"
	bg.layer = -10
	_own(root, bg)

	var sky := ColorRect.new()
	sky.name         = "Sky"
	sky.offset_right  = 360.0
	sky.offset_bottom = 640.0
	sky.color = Color(0.7, 0.85, 1, 1)
	_own(bg, sky, root)

	_bg_rect(bg, root, "Clouds",    load(CLOUDS_PATH), 0.0)
	_bg_rect(bg, root, "Mountains", load(MOUNTAINS_PATH), 0.0)
	_bg_rect(bg, root, "Mountains2",load(MOUNTAINS_PATH), 360.0)
	_bg_rect(bg, root, "Trees",     load(TREES_PATH), 0.0)
	_bg_rect(bg, root, "Trees2",    load(TREES_PATH), 360.0)

	# ── KillZone ─────────────────────────────────────────────────────────────────
	var kill_zone := Area2D.new()
	kill_zone.name     = "KillZone"
	kill_zone.position = Vector2(1280, 3900)
	_own(root, kill_zone)

	var ks := CollisionShape2D.new()
	ks.name = "KillShape"
	var kr := RectangleShape2D.new()
	kr.size    = Vector2(2560, 128)
	ks.shape   = kr
	_own(kill_zone, ks, root)

	# ── MultiplayerSpawner ────────────────────────────────────────────────────────
	var spawner := MultiplayerSpawner.new()
	spawner.name       = "MultiplayerSpawner"
	spawner.spawn_path = NodePath("..")
	_own(root, spawner)

	# ── MobileControls ────────────────────────────────────────────────────────────
	var mc_scene := load(MOBILE_PATH) as PackedScene
	if mc_scene:
		var mc := mc_scene.instantiate()
		mc.name = "MobileControls"
		if mc is CanvasLayer:
			(mc as CanvasLayer).layer = 10
		root.add_child(mc)
		mc.owner = root

	# ── Pack & Save ──────────────────────────────────────────────────────────────
	var packed := PackedScene.new()
	var pack_err := packed.pack(root)
	if pack_err != OK:
		push_error("Pack failed: " + str(pack_err))
		root.queue_free()
		return

	var save_err := ResourceSaver.save(packed, OUT_PATH)
	if save_err == OK:
		print("✓ Saved to ", OUT_PATH)
		EditorInterface.get_resource_filesystem().scan()
	else:
		push_error("Save failed: " + str(save_err))

	root.queue_free()


# ── helpers ──────────────────────────────────────────────────────────────────────

func _own(parent: Node, child: Node, scene_root: Node = null) -> void:
	parent.add_child(child)
	child.owner = scene_root if scene_root else parent

func _bg_rect(parent: Node, scene_root: Node, node_name: String, tex: Texture2D, x_offset: float) -> void:
	var r := TextureRect.new()
	r.name          = node_name
	r.offset_left   = x_offset
	r.offset_right  = x_offset + 360.0
	r.offset_bottom = 640.0
	r.texture       = tex
	r.stretch_mode  = TextureRect.STRETCH_SCALE
	parent.add_child(r)
	r.owner = scene_root
