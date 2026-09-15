@tool
class_name Fruit
extends Pickup

## Collectible fruit counted by the level. The kind only changes the art.

enum Kind { APPLE, BANANAS, CHERRIES, KIWI, MELON, ORANGE, PINEAPPLE, STRAWBERRY }

const FRAMES_PATH := "res://data/sprite_frames/fruit_%s.tres"

@export var kind: Kind = Kind.APPLE:
	set(value):
		kind = value
		_apply_kind()


func _ready() -> void:
	_apply_kind()
	if Engine.is_editor_hint():
		return
	add_to_group(&"fruits")
	super()


func _apply_kind() -> void:
	var animated_sprite := get_node_or_null(^"AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite == null:
		return
	var kind_name := String(Kind.find_key(kind)).to_lower()
	animated_sprite.sprite_frames = load(FRAMES_PATH % kind_name)
	animated_sprite.play(&"idle")
