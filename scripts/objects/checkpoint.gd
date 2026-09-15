class_name Checkpoint
extends Area2D

## Raises its flag the first time the local player touches it and moves the
## player's respawn point here.

signal activated(checkpoint: Checkpoint)

var is_active: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	collision_layer = PhysicsLayers.TRIGGERS
	collision_mask = PhysicsLayers.PLAYER
	body_entered.connect(_on_body_entered)
	sprite.play(&"no_flag")


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if is_active or player == null or not player.is_local_player or not player.is_alive():
		return
	is_active = true
	player.spawn_point = global_position
	activated.emit(self)
	Events.checkpoint_reached.emit(global_position)
	sprite.play(&"flag_out")
	await sprite.animation_finished
	sprite.play(&"flag_idle")
