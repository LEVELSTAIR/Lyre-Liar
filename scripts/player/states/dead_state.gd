extends PlayerState

## Player has no HP left. Movement stops until respawn() moves back to Idle.


func enter(_previous_state: StringName) -> void:
	player.velocity = Vector2.ZERO
	player.sprite.play(&"hit")


func physics_update(delta: float) -> StringName:
	# Keep gravity so a player killed mid-air settles on the ground.
	player.velocity.x = 0.0
	player.apply_gravity(delta)
	player.move_and_slide()
	return &""
