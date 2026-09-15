extends PlayerState


func enter(_previous_state: StringName) -> void:
	player.play_animation(&"fall")


func physics_update(delta: float) -> StringName:
	player.apply_gravity(delta)
	player.apply_horizontal_movement(delta)
	player.move()
	return airborne_transition()
