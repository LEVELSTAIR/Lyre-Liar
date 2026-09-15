class_name Trampoline
extends Area2D

## Launches the local player upward when they land on it.

@export var launch_velocity: float = -430.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	collision_layer = PhysicsLayers.TRIGGERS
	collision_mask = PhysicsLayers.PLAYER
	body_entered.connect(_on_body_entered)
	_sprite.play(&"idle")


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or not player.is_local_player or not player.is_alive():
		return
	# Only trigger when coming down onto the pad, not when brushing its side.
	if player.velocity.y < 0.0:
		return
	player.bounce(launch_velocity)
	_sprite.play(&"jump")
	await _sprite.animation_finished
	_sprite.play(&"idle")
