extends PlayerState

## Rising after a ground jump or a bounce. Bounces (stomps, trampolines) set
## an upward velocity before entering, which is kept; otherwise this applies
## the ground jump impulse.


func enter(_previous_state: StringName) -> void:
	if player.velocity.y >= 0.0:
		player.velocity.y = player.jump_velocity
	player.play_animation(&"jump")


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
