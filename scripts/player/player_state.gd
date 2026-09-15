class_name PlayerState
extends State

## Base for player movement states. Provides typed access to the Player and
## the transitions shared by every airborne state.

@onready var player: Player = owner as Player


## Next state for an airborne player after this frame's movement, or &"" to
## let the caller decide. Handles landing, double jump, and wall slide.
func airborne_transition() -> StringName:
	if player.is_on_floor():
		return &"Run" if player.input_direction() != 0.0 else &"Idle"
	if player.wants_jump() and player.can_double_jump:
		return &"DoubleJump"
	if player.velocity.y > 0.0 and player.pressed_wall_direction() != 0.0:
		return &"WallSlide"
	return &""
