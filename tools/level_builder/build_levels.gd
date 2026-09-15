extends Node

## Generates scenes/levels/<name>.tscn from tools/level_builder/layouts/*.txt.
## Runs as a scene (not with -s) so the autoloads level scripts use exist:
##   godot --headless --path . res://tools/level_builder/build_levels.tscn
##
## Each generated scene inherits scenes/levels/level_base.tscn. After
## generation the .tscn files can be edited in the Godot editor; re-running
## this tool overwrites those edits, so change the layout text instead when
## a level needs a larger rework.
##
## Layout file format:
##   key=value header lines (level_id, background)
##   ---
##   grid rows, one character per 16 px tile (legend below)
##   ---
##   optional overrides: "<char><n>: property=value ..." where n counts that
##   character's occurrences in reading order (left to right, top to bottom).
##   Values "x,y" become Vector2, numbers become float.
##
## Legend
##   Terrain   G grass  O clay  P candy  B bricks  M metal block  W wood block
##   Platforms =  wood   -  gold   ~  chain  (one-way)
##   Flow      S start  E goal  C checkpoint
##   Pickups   a b c k m o p s  fruits (apple bananas cherries kiwi melon
##             orange pineapple strawberry)   h heart
##   Hazards   ^ spikes  X saw  @ spiked ball  f fire trap
##   Movement  T trampoline  F fan  L moving platform  _ falling platform
##   Enemies   g pig walking left  r pig walking right

const LAYOUT_DIR := "res://tools/level_builder/layouts"
const OUTPUT_DIR := "res://scenes/levels"
const BASE_SCENE := preload("res://scenes/levels/level_base.tscn")
const BACKGROUND_PATH := "res://asset/Pixel Adventure/Background/%s.png"
const OBJECT_PATH := "res://scenes/objects/%s.tscn"
const TILE := 16

const GROUND_BLOCKS := {"G": Vector2i(6, 0), "O": Vector2i(6, 4), "P": Vector2i(6, 8)}
const PLATFORM_ROWS := {"-": 0, "=": 1, "~": 2}
const FRUIT_KINDS := {
	"a": Fruit.Kind.APPLE, "b": Fruit.Kind.BANANAS, "c": Fruit.Kind.CHERRIES, "k": Fruit.Kind.KIWI,
	"m": Fruit.Kind.MELON, "o": Fruit.Kind.ORANGE, "p": Fruit.Kind.PINEAPPLE, "s": Fruit.Kind.STRAWBERRY,
}
## char -> [scene name, parent node, anchor]; anchor "bottom" = cell bottom
## center, "center" = cell center, "wide" = 32 px object starting at the cell.
const OBJECTS := {
	"C": ["checkpoint", "Checkpoints", "bottom"],
	"h": ["heart_pickup", "Pickups", "center"],
	"^": ["spikes", "Objects", "bottom"],
	"X": ["saw", "Objects", "center"],
	"@": ["spiked_ball", "Objects", "center"],
	"f": ["fire_trap", "Objects", "bottom"],
	"T": ["trampoline", "Objects", "bottom"],
	"F": ["fan", "Objects", "bottom"],
	"L": ["moving_platform", "Objects", "wide"],
	"_": ["falling_platform", "Objects", "wide"],
	"g": ["pig", "Enemies", "bottom"],
	"r": ["pig", "Enemies", "bottom"],
}


## Per-level counters for readable node names (Fruit1, Fruit2, Saw1 ...).
var _name_counts := {}
var _ext_resources: Array[Dictionary] = []
## Override blocks for nodes that already exist in the base scene.
var _fixed_node_overrides: Array[String] = []


func _ready() -> void:
	var dir := DirAccess.open(LAYOUT_DIR)
	for file in dir.get_files():
		if file.ends_with(".txt"):
			_build(LAYOUT_DIR.path_join(file))
	get_tree().quit()


func _build(layout_path: String) -> void:
	var layout := _parse(FileAccess.get_file_as_string(layout_path))
	var grid: Array[String] = layout["grid"]
	var header: Dictionary = layout["header"]
	var level_id: String = header["level_id"]
	_name_counts.clear()
	_ext_resources.clear()
	_fixed_node_overrides.clear()
	var base_id := _ext_resource("PackedScene", BASE_SCENE.resource_path)
	var background_id := _ext_resource("Texture2D", BACKGROUND_PATH % header.get("background", "Blue"))

	# Paint terrain into a throwaway layer to get the encoded tile data.
	var terrain := TileMapLayer.new()
	terrain.tile_set = (BASE_SCENE.instantiate().get_node("Terrain") as TileMapLayer).tile_set
	var entities: Array[String] = []
	var occurrences := {}
	for y in grid.size():
		for x in grid[y].length():
			var ch := grid[y][x]
			if ch == " ":
				continue
			occurrences[ch] = occurrences.get(ch, 0) + 1
			var overrides: Dictionary = layout["params"].get("%s%d" % [ch, occurrences[ch]], {})
			var atlas := _tile_for(grid, x, y)
			if atlas != Vector2i(-1, -1):
				terrain.set_cell(Vector2i(x, y), 0, atlas)
			else:
				entities.append(_entity_block(ch, Vector2i(x, y), overrides))

	var lines: Array[String] = ["[gd_scene format=4]", ""]
	for resource in _ext_resources:
		lines.append('[ext_resource type="%s" path="%s" id="%s"]' % [resource["type"], resource["path"], resource["id"]])
	lines.append_array([
		"",
		'[node name="%s" instance=ExtResource("%s")]' % [level_id.to_pascal_case(), base_id],
		"level_id = &\"%s\"" % level_id,
		"",
		'[node name="Background" parent="."]',
		'texture = ExtResource("%s")' % background_id,
		"",
		'[node name="Tiles" parent="Background"]',
		'texture = ExtResource("%s")' % background_id,
		"",
		'[node name="Terrain" parent="."]',
		'tile_map_data = PackedByteArray("%s")' % Marshalls.raw_to_base64(terrain.tile_map_data),
		"",
		'[node name="KillZone" parent="."]',
		"position = Vector2(0, %d)" % (grid.size() * TILE + 64),
		"",
	])
	for block in _fixed_node_overrides:
		lines.append(block)
	lines.append_array(entities)
	terrain.free()

	var output := OUTPUT_DIR.path_join(layout_path.get_file().get_basename() + ".tscn")
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("build_levels: cannot write %s" % output)
		return
	file.store_string("\n".join(lines))
	file.close()


## Returns the [node] block for one layout character.
func _entity_block(ch: String, cell: Vector2i, overrides: Dictionary) -> String:
	var bottom := Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)
	var center := Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)
	match ch:
		"S":
			_fixed_node_overrides.append('[node name="LevelStart" parent="."]\nposition = %s\n' % var_to_str(bottom))
			return ""
		"E":
			_fixed_node_overrides.append('[node name="LevelGoal" parent="."]\nposition = %s\n' % var_to_str(bottom))
			return ""
	var scene_name: String
	var parent_name: String
	var properties := {}
	if FRUIT_KINDS.has(ch):
		scene_name = "fruit"
		parent_name = "Pickups"
		properties["position"] = center
		properties["kind"] = FRUIT_KINDS[ch]
	elif OBJECTS.has(ch):
		var definition: Array = OBJECTS[ch]
		scene_name = definition[0]
		parent_name = definition[1]
		match definition[2]:
			"bottom":
				properties["position"] = bottom
			"center":
				properties["position"] = center
			"wide":
				# Platform collision tops sit 4 px below the tile top.
				properties["position"] = Vector2(cell.x * TILE + TILE, cell.y * TILE + TILE / 2.0)
		if ch == "r":
			properties["start_right"] = true
	else:
		push_warning("build_levels: unknown layout character '%s' at %s" % [ch, cell])
		return ""
	properties.merge(overrides, true)
	var resource_id := _ext_resource("PackedScene", OBJECT_PATH % scene_name)
	var node_name := scene_name.to_pascal_case()
	_name_counts[node_name] = _name_counts.get(node_name, 0) + 1
	var block := '[node name="%s%d" parent="%s" instance=ExtResource("%s")]\n' % [node_name, _name_counts[node_name], parent_name, resource_id]
	for property in properties:
		block += "%s = %s\n" % [property, var_to_str(properties[property])]
	return block


func _ext_resource(type: String, path: String) -> String:
	for resource in _ext_resources:
		if resource["path"] == path:
			return resource["id"]
	var id := "%d_%s" % [_ext_resources.size() + 1, path.get_file().get_basename().to_snake_case().replace(" ", "_")]
	_ext_resources.append({"type": type, "path": path, "id": id})
	return id


func _tile_for(grid: Array[String], x: int, y: int) -> Vector2i:
	var ch := grid[y][x]
	if GROUND_BLOCKS.has(ch):
		var left := _cell(grid, x - 1, y) == ch
		var right := _cell(grid, x + 1, y) == ch
		var up := _cell(grid, x, y - 1) == ch
		var down := y + 1 >= grid.size() or _cell(grid, x, y + 1) == ch
		var column := 0 if (not left and right) else (2 if (not right and left) else 1)
		var row := 0 if not up else (2 if not down else 1)
		return GROUND_BLOCKS[ch] + Vector2i(column, row)
	if PLATFORM_ROWS.has(ch):
		var left := _cell(grid, x - 1, y) == ch
		var right := _cell(grid, x + 1, y) == ch
		var column := 1 if (left == right) else (0 if right else 2)
		return Vector2i(17 + column, PLATFORM_ROWS[ch])
	match ch:
		"B":
			return Vector2i(17 + x % 3, 4 + y % 3)
		"M":
			return Vector2i(12, 5)
		"W":
			return Vector2i(12, 1)
	return Vector2i(-1, -1)


func _cell(grid: Array[String], x: int, y: int) -> String:
	if y < 0 or y >= grid.size() or x < 0 or x >= grid[y].length():
		return " "
	return grid[y][x]


func _parse(text: String) -> Dictionary:
	var header := {}
	var grid: Array[String] = []
	var params := {}
	var section := 0
	for line in text.split("\n"):
		if line.strip_edges() == "---":
			section += 1
			continue
		match section:
			0:
				if "=" in line:
					header[line.get_slice("=", 0).strip_edges()] = line.get_slice("=", 1).strip_edges()
			1:
				grid.append(line)
			_:
				if line.strip_edges().is_empty():
					continue
				var values := {}
				for pair in line.get_slice(":", 1).strip_edges().split(" ", false):
					values[pair.get_slice("=", 0)] = _parse_value(pair.get_slice("=", 1))
				params[line.get_slice(":", 0).strip_edges()] = values
	while not grid.is_empty() and grid[-1].strip_edges().is_empty():
		grid.pop_back()
	return {"header": header, "grid": grid, "params": params}


func _parse_value(text: String) -> Variant:
	if "," in text:
		return Vector2(text.get_slice(",", 0).to_float(), text.get_slice(",", 1).to_float())
	if text.is_valid_float():
		return text.to_float()
	return text
