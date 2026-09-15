extends SceneTree

## Regenerates data/characters/*.tres from the Pixel Adventure character
## sheets. Run after changing frame rates or adding a character:
##   godot --headless --path . -s res://tools/build_character_data.gd

const SHEET_DIR := "res://asset/Pixel Adventure/Main Characters/%s/%s (32x32).png"
const FRAME_SIZE := 32

## [animation, sheet name, fps, loop]
const ANIMATIONS := [
	[&"idle", "Idle", 20.0, true],
	[&"run", "Run", 20.0, true],
	[&"jump", "Jump", 10.0, false],
	[&"fall", "Fall", 10.0, false],
	[&"double_jump", "Double Jump", 20.0, false],
	[&"wall_slide", "Wall Jump", 20.0, true],
	[&"hit", "Hit", 20.0, false],
]

## [id, display name, sheet folder]. Ids are kept from the previous menu.
const CHARACTERS := [
	[&"pink", "Pink Man", "Pink Man"],
	[&"dude", "Mask Dude", "Mask Dude"],
	[&"owlet", "Ninja Frog", "Ninja Frog"],
	[&"virtual", "Virtual Guy", "Virtual Guy"],
]


func _init() -> void:
	var catalog := CharacterCatalog.new()
	for entry in CHARACTERS:
		var character := CharacterData.new()
		character.id = entry[0]
		character.display_name = entry[1]
		character.sprite_frames = _build_frames(entry[2])
		var path := "res://data/characters/%s.tres" % entry[0]
		_check(ResourceSaver.save(character, path), path)
		catalog.characters.append(load(path))
	_check(ResourceSaver.save(catalog, CharacterCatalog.DEFAULT_PATH), CharacterCatalog.DEFAULT_PATH)
	quit()


func _build_frames(folder: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for animation in ANIMATIONS:
		var texture: Texture2D = load(SHEET_DIR % [folder, animation[1]])
		frames.add_animation(animation[0])
		frames.set_animation_speed(animation[0], animation[2])
		frames.set_animation_loop(animation[0], animation[3])
		for i in texture.get_width() / FRAME_SIZE:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(animation[0], atlas)
	return frames


func _check(error: Error, path: String) -> void:
	if error != OK:
		push_error("build_character_data: failed to save %s (%d)" % [path, error])
