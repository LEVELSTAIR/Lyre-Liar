@tool
class_name SpikedBall
extends Node2D

## Spiked ball on a chain swinging like a pendulum around this node.

const CHAIN_TEXTURE := preload("res://asset/Pixel Adventure/Traps/Spiked Ball/Chain.png")
const LINK_SPACING := 10.0

@export var chain_length: float = 56.0:
	set(value):
		chain_length = value
		_update_ball()
## Maximum swing angle either side of straight down, in degrees.
@export_range(0.0, 90.0) var swing_degrees: float = 60.0
## Seconds for a full left-right-left swing.
@export var period: float = 2.4
## Phase offset in seconds, to stagger neighbouring balls.
@export var time_offset: float = 0.0

var _time: float = 0.0
var _angle: float = 0.0

@onready var _ball: Node2D = $Ball


func _ready() -> void:
	_time = time_offset
	_update_ball()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	_angle = deg_to_rad(swing_degrees) * sin(TAU * _time / period)
	_update_ball()


func _update_ball() -> void:
	if _ball == null:
		return
	_ball.position = Vector2.DOWN.rotated(_angle) * chain_length
	queue_redraw()


func _draw() -> void:
	var links := int(chain_length / LINK_SPACING)
	for i in links:
		var point := Vector2.DOWN.rotated(_angle) * (i * LINK_SPACING)
		draw_texture(CHAIN_TEXTURE, point - CHAIN_TEXTURE.get_size() / 2.0)
