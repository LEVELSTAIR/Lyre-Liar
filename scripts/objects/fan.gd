@tool
class_name Fan
extends Node2D

## Floor fan that pushes the local player upward inside its updraft column.

@export var column_height: float = 96.0:
	set(value):
		column_height = value
		_update_column()
## Upward acceleration applied inside the column (must beat gravity).
@export var lift_acceleration: float = 1500.0
@export var max_rise_speed: float = 200.0

@onready var _updraft: Area2D = $Updraft
@onready var _column_shape: CollisionShape2D = $Updraft/CollisionShape2D


func _ready() -> void:
	_update_column()
	if Engine.is_editor_hint():
		return
	_updraft.collision_layer = PhysicsLayers.TRIGGERS
	_updraft.collision_mask = PhysicsLayers.PLAYER
	($AnimatedSprite2D as AnimatedSprite2D).play(&"on")


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for body in _updraft.get_overlapping_bodies():
		var player := body as Player
		if player != null and player.is_local_player and player.is_alive():
			player.velocity.y = maxf(player.velocity.y - lift_acceleration * delta, -max_rise_speed)


func _update_column() -> void:
	if _column_shape == null:
		return
	var rect := _column_shape.shape as RectangleShape2D
	rect.size.y = column_height
	_column_shape.position.y = -column_height / 2.0
