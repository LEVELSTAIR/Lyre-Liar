extends PlayerState


func enter(_previous_state: StringName) -> void:
	player.can_double_jump = true
	player.play_animation(&"run")


func physics_update(delta: float) -> StringName:
	player.apply_gravity(delta)
	player.apply_horizontal_movement(delta)
	player.move()
	if player.wants_jump() and player.can_ground_jump():
		return &"Jump"
	if not player.is_on_floor():
		return &"Fall"
	if player.input_direction() == 0.0 and is_zero_approx(player.velocity.x):
		return &"Idle"
	return &""
