extends PlayerState

## Sliding down a wall while pressing into it. Fall speed is capped and a
## jump kicks the player away from the wall.

var _wall_direction: float = 0.0


func enter(_previous_state: StringName) -> void:
	_wall_direction = player.pressed_wall_direction()
	player.can_double_jump = true
	player.set_facing(-_wall_direction)
	player.play_animation(&"wall_slide")


func physics_update(delta: float) -> StringName:
	if player.wants_jump():
		return &"WallJump"
	player.apply_gravity(delta, player.wall_slide_speed)
	player.apply_horizontal_movement(delta)
	# Keep the facing pointed away from the wall while sliding.
	player.set_facing(-_wall_direction)
	player.move()
	if player.is_on_floor():
		return &"Idle"
	if player.pressed_wall_direction() == 0.0:
		return &"Fall"
	return &""


func exit() -> void:
	player.set_facing(-_wall_direction)
