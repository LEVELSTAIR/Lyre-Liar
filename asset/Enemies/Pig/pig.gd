extends CharacterBody2D

## Ground patrol enemy (Kings & Pigs art, CC0 by Pixel Frog). Walks in a
## straight line and reverses when its forward raycast hits a wall. The level
## adds every enemy to the "enemies" group so the player takes damage on touch.

const SPEED = 24.0
var direction = 1

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = direction * SPEED
	move_and_slide()

	# Reverse at walls.
	if $RayCast2D.is_colliding():
		direction *= -1

	$RayCast2D.target_position.x = 20 * direction
	$AnimatedSprite2D.flip_h = direction > 0
