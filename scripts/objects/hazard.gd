class_name Hazard
extends Area2D

## Damages the local player while overlapping. Re-applies every physics frame
## so a player standing in a hazard is hit again once invincibility ends.
## Disable `monitoring` to switch the hazard off (e.g. fire trap off phase).

@export_range(1, 10) var damage: int = 1


func _ready() -> void:
	collision_layer = PhysicsLayers.HAZARDS
	collision_mask = PhysicsLayers.PLAYER


func _physics_process(_delta: float) -> void:
	if not monitoring:
		return
	for body in get_overlapping_bodies():
		var player := body as Player
		if player != null and player.is_local_player and player.is_alive():
			player.take_damage(damage, global_position)
