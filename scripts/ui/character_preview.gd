@tool
class_name CharacterPreview
extends Control

## Shows a character's animation scaled up inside a Control, for menus.

@export var character: CharacterData:
	set(value):
		character = value
		_refresh()
@export var animation: StringName = &"idle":
	set(value):
		animation = value
		_refresh()
@export_range(1, 8) var pixel_scale: int = 3:
	set(value):
		pixel_scale = value
		_refresh()

var _sprite: AnimatedSprite2D


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite, false, Node.INTERNAL_MODE_FRONT)
	resized.connect(_center_sprite)
	_refresh()


func _refresh() -> void:
	if _sprite == null or character == null:
		return
	_sprite.sprite_frames = character.sprite_frames
	_sprite.scale = Vector2.ONE * pixel_scale
	custom_minimum_size = Vector2(32, 32) * pixel_scale
	if _sprite.sprite_frames.has_animation(animation):
		_sprite.play(animation)
	_center_sprite()


func _center_sprite() -> void:
	if _sprite != null:
		_sprite.position = size / 2.0
