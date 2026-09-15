@tool
class_name MovingPlatform
extends AnimatableBody2D

## One-way platform that moves back and forth between its start position and
## `travel` (relative), easing at both ends. Players standing on it are
## carried because sync_to_physics is enabled.

const CHAIN_TEXTURE := preload("res://asset/Pixel Adventure/Traps/Platforms/Chain.png")
const CHAIN_SPACING := 12.0

@export var travel: Vector2 = Vector2(64, 0):
	set(value):
		travel = value
		queue_redraw()
## Seconds for one trip from start to end.
@export var trip_seconds: float = 2.0
@export var pause_seconds: float = 0.4

var _origin: Vector2


func _ready() -> void:
	_origin = position
	if Engine.is_editor_hint():
		return
	collision_layer = PhysicsLayers.WORLD
	sync_to_physics = true
	($AnimatedSprite2D as AnimatedSprite2D).play(&"on")
	_start_motion()


func _start_motion() -> void:
	if travel.is_zero_approx():
		return
	var tween := create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, ^"position", _origin + travel, trip_seconds)
	tween.tween_interval(pause_seconds)
	tween.tween_property(self, ^"position", _origin, trip_seconds)
	tween.tween_interval(pause_seconds)


func _draw() -> void:
	# Chain markers along the path, drawn relative to the start position.
	if not Engine.is_editor_hint() or travel.is_zero_approx():
		return
	var steps := int(travel.length() / CHAIN_SPACING)
	for i in steps + 1:
		var point := travel * (float(i) / maxf(steps, 1))
		draw_texture(CHAIN_TEXTURE, point - CHAIN_TEXTURE.get_size() / 2.0)
