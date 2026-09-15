extends PlayerState

## Kick off a wall. Horizontal input is briefly locked so the player clears
## the wall before regaining control.


func enter(_previous_state: StringName) -> void:
	var away := signf(player.get_wall_normal().x)
	if away == 0.0:
		away = -player.facing
	player.velocity = Vector2(player.wall_jump_velocity.x * away, player.wall_jump_velocity.y)
	player.input_lock_left = player.wall_jump_input_lock
	player.set_facing(away)
	player.play_animation(&"jump")


func physics_update(delta: float) -> StringName:
	player.on_jump_rising(delta)
	player.apply_gravity(delta)
	if player.input_lock_left <= 0.0:
		player.apply_horizontal_movement(delta)
	player.move()
	var next := airborne_transition()
	if next != &"":
		return next
	if player.velocity.y >= 0.0:
		return &"Fall"
	return &""
