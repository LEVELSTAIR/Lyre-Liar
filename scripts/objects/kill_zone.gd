class_name KillZone
extends Area2D

## Instantly kills the local player on contact (bottomless pits, lava).


func _ready() -> void:
	collision_layer = PhysicsLayers.TRIGGERS
	collision_mask = PhysicsLayers.PLAYER
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player != null and player.is_local_player:
		player.kill()
