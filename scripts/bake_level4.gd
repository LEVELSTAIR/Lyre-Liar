## Run this once from the Godot editor:
##   Open this file in the Script editor, then press Ctrl+Shift+X  (or File → Run)
## It reads the level layout, builds a TileMap with SunnyLandForest assets, and saves level_4.tscn.
@tool
extends EditorScript

const TILESET_PATH := "res://asset/SunnyLandForest/tileset.png"
const BG_PATH      := "res://asset/SunnyLandForest/background.png"
const MG_PATH      := "res://asset/SunnyLandForest/middleground.png"
const MOBILE_PATH  := "res://scenes/mobile_controls.tscn"
const OUT_PATH     := "res://scenes/level_4.tscn"

const MAP_WIDTH    := 40
const MAP_HEIGHT   := 30
const TILESET_COLS := 20
const TILE_PX      := 16
const SCALE_FACTOR := 4

const _COL_RUNS := [
	[29, 0,  40, 1],  # ground floor
	[28, 0,  40, 1],  # second ground row
	[26, 2,  8,  2],  [26, 12, 18, 2], [26, 22, 28, 2], [26, 32, 38, 2],
	[22, 0,  6,  2],  [22, 10, 16, 2], [22, 20, 26, 2], [22, 30, 36, 2],
	[18, 3,  9,  2],  [18, 13, 19, 2], [18, 23, 29, 2], [18, 33, 39, 2],
	[14, 1,  7,  2],  [14, 11, 17, 2], [14, 21, 27, 2], [14, 31, 37, 2],
	[10, 4,  9,  2],  [10, 12, 18, 2], [10, 20, 26, 2], [10, 28, 34, 2],
	[6,  2,  7,  2],  [6,  14, 20, 2], [6,  26, 32, 2], [6,  35, 40, 2],
]

func _run() -> void:
	print("=== Baking Level 4 ===")

	# ── Build TileMap from collision runs ────────────────────────────────────────
	var atlas := TileSetAtlasSource.new()
	atlas.texture             = load(TILESET_PATH)
	atlas.texture_region_size = Vector2i(TILE_PX, TILE_PX)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_PX, TILE_PX)
	tile_set.add_source(atlas, 0)

	var tilemap := TileMap.new()
	tilemap.name     = "TileMap"
	tilemap.tile_set = tile_set
	tilemap.scale    = Vector2(SCALE_FACTOR, SCALE_FACTOR)

	for run in _COL_RUNS:
		var row := run[0]
		var col_start := run[1]
		var col_end := run[2]
		var col_type := run[3]

		for col in range(col_start, col_end):
			if col_type == 1:
				if col == col_start:
					_set_tile(tilemap, atlas, col, row, 7, 3)
				elif col == col_end - 1:
					_set_tile(tilemap, atlas, col, row, 10, 3)
				else:
					_set_tile(tilemap, atlas, col, row, 8, 3)
			elif col_type == 2:
				if col == col_start:
					_set_tile(tilemap, atlas, col, row, 4, 0)
				elif col == col_end - 1:
					_set_tile(tilemap, atlas, col, row, 6, 0)
				else:
					_set_tile(tilemap, atlas, col, row, 5, 0)

	print("  TileMap populated with ", tilemap.get_used_cells(0).size(), " tiles")

	# ── Root node ───────────────────────────────────────────────────────────────
	var root := Node2D.new()
	root.name = "Level4"
	root.set_script(load("res://scripts/level_4.gd"))

	_own(root, tilemap)

	# ── Background CanvasLayer ──────────────────────────────────────────────────
	var bg := CanvasLayer.new()
	bg.name  = "BGLayer"
	bg.layer = -10
	_own(root, bg)

	var sky := ColorRect.new()
	sky.name           = "Sky"
	sky.anchor_right   = 1.0
	sky.anchor_bottom  = 1.0
	sky.color = Color(0.25, 0.45, 0.2, 1)
	_own(bg, sky, root)

	_bg_rect(bg, root, "Background",    load(BG_PATH))
	_bg_rect(bg, root, "Middleground",  load(MG_PATH))

	# ── KillZone ─────────────────────────────────────────────────────────────────
	var kill_zone := Area2D.new()
	kill_zone.name     = "KillZone"
	kill_zone.position = Vector2(1280, 1984)
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


func _set_tile(tilemap: TileMap, atlas: TileSetAtlasSource, col: int, row: int, atlas_col: int, atlas_row: int) -> void:
	var ac := Vector2i(atlas_col, atlas_row)
	if not atlas.has_tile(ac):
		atlas.create_tile(ac)
	tilemap.set_cell(0, Vector2i(col, row), 0, ac)

func _own(parent: Node, child: Node, scene_root: Node = null) -> void:
	parent.add_child(child)
	child.owner = scene_root if scene_root else parent

func _bg_rect(parent: Node, scene_root: Node, node_name: String, tex: Texture2D) -> void:
	var r := TextureRect.new()
	r.name           = node_name
	r.anchor_right   = 1.0
	r.anchor_bottom  = 1.0
	r.texture        = tex
	parent.add_child(r)
	r.owner = scene_root
