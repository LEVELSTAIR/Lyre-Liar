extends SceneTree

## Builds data/tilesets/pixel_adventure_terrain.tres from Pixel Adventure's
## "Terrain (16x16).png" (CC0):
##   godot --headless --path . -s res://tools/level_builder/build_tileset.gd
##
## - Ground blocks (grass, clay, candy): solid, with a "match sides" terrain
##   so they autotile when painted in the editor.
## - Thin platforms (gold, wood, chain): one-way collision on the top 5 px.
## - Bricks and block tiles: solid.

const TEXTURE_PATH := "res://asset/Pixel Adventure/Terrain/Terrain (16x16).png"
const OUTPUT_PATH := "res://data/tilesets/pixel_adventure_terrain.tres"
const TILE := 16
const HALF := 8.0

## [terrain name, top-left atlas coords of its 3x3 block, editor color]
const GROUND_BLOCKS := [
	["Grass", Vector2i(6, 0), Color(0.4, 0.75, 0.2)],
	["Clay", Vector2i(6, 4), Color(0.95, 0.55, 0.2)],
	["Candy", Vector2i(6, 8), Color(0.95, 0.45, 0.8)],
]
## Rows of left/middle/right platform pieces.
const PLATFORM_ROWS := [Vector2i(17, 0), Vector2i(17, 1), Vector2i(17, 2)]
## Rectangular regions of full solid tiles: [top-left, size].
const SOLID_REGIONS := [
	[Vector2i(17, 4), Vector2i(5, 3)],   # red bricks
	[Vector2i(12, 0), Vector2i(4, 3)],   # brown blocks
	[Vector2i(12, 4), Vector2i(4, 3)],   # metal blocks
	[Vector2i(12, 8), Vector2i(4, 3)],   # orange blocks
	[Vector2i(17, 8), Vector2i(4, 3)],   # gold blocks
]

var _image: Image


func _init() -> void:
	var texture: Texture2D = load(TEXTURE_PATH)
	_image = texture.get_image()

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, PhysicsLayers.WORLD)
	tile_set.set_physics_layer_collision_mask(0, 0)
	tile_set.add_terrain_set()
	tile_set.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE, TILE)
	source.use_texture_padding = true
	tile_set.add_source(source, 0)

	for terrain_index in GROUND_BLOCKS.size():
		var block: Array = GROUND_BLOCKS[terrain_index]
		tile_set.add_terrain(0)
		tile_set.set_terrain_name(0, terrain_index, block[0])
		tile_set.set_terrain_color(0, terrain_index, block[2])
		_add_ground_block(source, block[1], terrain_index)
	for row_start in PLATFORM_ROWS:
		for i in 3:
			_add_one_way(source, row_start + Vector2i(i, 0))
	for region in SOLID_REGIONS:
		for y in region[1].y:
			for x in region[1].x:
				var coords: Vector2i = region[0] + Vector2i(x, y)
				if not _is_empty(coords):
					_add_solid(source, coords)

	var error := ResourceSaver.save(tile_set, OUTPUT_PATH)
	if error != OK:
		push_error("build_tileset: failed to save %s (%d)" % [OUTPUT_PATH, error])
	quit()


func _add_ground_block(source: TileSetAtlasSource, top_left: Vector2i, terrain: int) -> void:
	for y in 3:
		for x in 3:
			var data := _add_solid(source, top_left + Vector2i(x, y))
			data.terrain_set = 0
			data.terrain = terrain
			# A side connects when the block continues in that direction.
			if x > 0:
				data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE, terrain)
			if x < 2:
				data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_RIGHT_SIDE, terrain)
			if y > 0:
				data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_SIDE, terrain)
			if y < 2:
				data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, terrain)


func _add_solid(source: TileSetAtlasSource, coords: Vector2i) -> TileData:
	source.create_tile(coords)
	var data := source.get_tile_data(coords, 0)
	data.add_collision_polygon(0)
	data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-HALF, -HALF), Vector2(HALF, -HALF), Vector2(HALF, HALF), Vector2(-HALF, HALF),
	]))
	return data


func _add_one_way(source: TileSetAtlasSource, coords: Vector2i) -> void:
	source.create_tile(coords)
	var data := source.get_tile_data(coords, 0)
	data.add_collision_polygon(0)
	data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-HALF, -HALF), Vector2(HALF, -HALF), Vector2(HALF, -3.0), Vector2(-HALF, -3.0),
	]))
	data.set_collision_polygon_one_way(0, 0, true)


func _is_empty(coords: Vector2i) -> bool:
	var region := Rect2i(coords * TILE, Vector2i(TILE, TILE))
	return _image.get_region(region).is_invisible()
