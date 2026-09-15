@tool
class_name Saw
extends Node2D

## Spinning saw that travels back and forth between its start position and
## `travel` (relative). A dotted chain shows the path. Leave `travel` at zero
## for a stationary saw.

const CHAIN_TEXTURE := preload("res://asset/Pixel Adventure/Traps/Saw/Chain.png")
const CHAIN_SPACING := 12.0

@export var travel: Vector2 = Vector2(64, 0):
	set(value):
		travel = value
		queue_redraw()
## Pixels per second along the path.
@export var speed: float = 50.0
## Starting point along the path, 0 = start, 1 = end.
@export_range(0.0, 1.0) var start_progress: float = 0.0

var _progress: float
var _direction: float = 1.0

@onready var _blade: Node2D = $Blade


func _ready() -> void:
	_progress = start_progress
	_update_blade()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or travel.is_zero_approx():
		return
	_progress += _direction * speed * delta / travel.length()
	if _progress >= 1.0 or _progress <= 0.0:
		_progress = clampf(_progress, 0.0, 1.0)
		_direction *= -1.0
	_update_blade()


func _update_blade() -> void:
	if _blade != null:
		_blade.position = travel * _progress


func _draw() -> void:
	if travel.is_zero_approx():
		return
	var steps := int(travel.length() / CHAIN_SPACING)
	for i in steps + 1:
		var point := travel * (float(i) / maxf(steps, 1))
		draw_texture(CHAIN_TEXTURE, point - CHAIN_TEXTURE.get_size() / 2.0)
