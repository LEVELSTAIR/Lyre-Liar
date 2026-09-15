extends SceneTree

## Regenerates data/sprite_frames/*.tres for gameplay objects from their CC0
## sprite sheets (Pixel Adventure 1, Kings and Pigs):
##   godot --headless --path . -s res://tools/build_object_frames.gd

const PA := "res://asset/Pixel Adventure/"
const KP := "res://asset/Kings and Pigs/Sprites/"
const FRUITS := ["Apple", "Bananas", "Cherries", "Kiwi", "Melon", "Orange", "Pineapple", "Strawberry"]

## output name -> [[animation, sheet path, frame width, fps, loop], ...]
func _definitions() -> Dictionary:
	var defs := {
		"checkpoint": [
			[&"no_flag", PA + "Items/Checkpoints/Checkpoint/Checkpoint (No Flag).png", 64, 1.0, false],
			[&"flag_out", PA + "Items/Checkpoints/Checkpoint/Checkpoint (Flag Out) (64x64).png", 64, 30.0, false],
			[&"flag_idle", PA + "Items/Checkpoints/Checkpoint/Checkpoint (Flag Idle)(64x64).png", 64, 15.0, true],
		],
		"goal_trophy": [
			[&"idle", PA + "Items/Checkpoints/End/End (Idle).png", 64, 1.0, false],
			[&"pressed", PA + "Items/Checkpoints/End/End (Pressed) (64x64).png", 64, 15.0, false],
		],
		"start_marker": [
			[&"idle", PA + "Items/Checkpoints/Start/Start (Idle).png", 64, 1.0, false],
			[&"moving", PA + "Items/Checkpoints/Start/Start (Moving) (64x64).png", 64, 20.0, true],
		],
		"saw": [[&"on", PA + "Traps/Saw/On (38x38).png", 38, 20.0, true]],
		"fire_trap": [
			[&"off", PA + "Traps/Fire/Off.png", 16, 1.0, false],
			[&"ignite", PA + "Traps/Fire/Hit (16x32).png", 16, 15.0, false],
			[&"on", PA + "Traps/Fire/On (16x32).png", 16, 15.0, true],
		],
		"trampoline": [
			[&"idle", PA + "Traps/Trampoline/Idle.png", 28, 1.0, false],
			[&"jump", PA + "Traps/Trampoline/Jump (28x28).png", 28, 30.0, false],
		],
		"falling_platform": [
			[&"on", PA + "Traps/Falling Platforms/On (32x10).png", 32, 15.0, true],
			[&"off", PA + "Traps/Falling Platforms/Off.png", 32, 1.0, false],
		],
		"moving_platform": [[&"on", PA + "Traps/Platforms/Brown On (32x8).png", 32, 15.0, true]],
		"fan": [
			[&"on", PA + "Traps/Fan/On (24x8).png", 24, 20.0, true],
			[&"off", PA + "Traps/Fan/Off.png", 24, 1.0, false],
		],
		"pig": [
			[&"idle", KP + "03-Pig/Idle (34x28).png", 34, 10.0, true],
			[&"run", KP + "03-Pig/Run (34x28).png", 34, 12.0, true],
			[&"hit", KP + "03-Pig/Hit (34x28).png", 34, 10.0, false],
			[&"dead", KP + "03-Pig/Dead (34x28).png", 34, 10.0, false],
		],
		"heart": [
			[&"idle", KP + "12-Live and Coins/Big Heart Idle (18x14).png", 18, 10.0, true],
			[&"collected", KP + "12-Live and Coins/Big Heart Hit (18x14).png", 18, 10.0, false],
		],
	}
	for fruit in FRUITS:
		defs["fruit_" + fruit.to_lower()] = [
			[&"idle", PA + "Items/Fruits/%s.png" % fruit, 32, 20.0, true],
			[&"collected", PA + "Items/Fruits/Collected.png", 32, 20.0, false],
		]
	return defs


func _init() -> void:
	var definitions := _definitions()
	for output_name in definitions:
		var frames := SpriteFrames.new()
		frames.remove_animation(&"default")
		for animation in definitions[output_name]:
			_add_animation(frames, animation)
		var path := "res://data/sprite_frames/%s.tres" % output_name
		var error := ResourceSaver.save(frames, path)
		if error != OK:
			push_error("build_object_frames: failed to save %s (%d)" % [path, error])
	quit()


func _add_animation(frames: SpriteFrames, animation: Array) -> void:
	var texture: Texture2D = load(animation[1])
	var frame_width: int = animation[2]
	frames.add_animation(animation[0])
	frames.set_animation_speed(animation[0], animation[3])
	frames.set_animation_loop(animation[0], animation[4])
	for i in texture.get_width() / frame_width:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 0, frame_width, texture.get_height())
		frames.add_frame(animation[0], atlas)
