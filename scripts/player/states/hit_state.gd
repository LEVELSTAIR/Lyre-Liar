extends PlayerState

## Short knockback after taking damage. Input is ignored until it ends.

@export var duration: float = 0.35

var _time_left: float = 0.0


func enter(_previous_state: StringName) -> void:
	_time_left = duration
	player.velocity = Vector2(player.knockback_velocity.x * player.knockback_direction, player.knockback_velocity.y)
	player.set_facing(-player.knockback_direction)
	player.sprite.play(&"hit")


func physics_update(delta: float) -> StringName:
	_time_left -= delta
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.air_acceleration * 0.5 * delta)
	player.move()
	if _time_left > 0.0:
		return &""
	if player.is_on_floor():
		return &"Idle"
	return &"Fall"
