extends PlayerState


func enter(_previous_state: StringName) -> void:
	player.can_double_jump = false
	player.velocity.y = player.double_jump_velocity
	player.sprite.play(&"double_jump")


func physics_update(delta: float) -> StringName:
	player.on_jump_rising(delta)
	player.apply_gravity(delta)
	player.apply_horizontal_movement(delta)
	player.move()
	var next := airborne_transition()
	if next != &"":
		return next
	if player.velocity.y >= 0.0:
		return &"Fall"
	return &""
