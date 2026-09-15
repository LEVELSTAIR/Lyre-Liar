class_name Pig
extends CharacterBody2D

## Patrolling enemy (Kings and Pigs art). Walks until it meets a wall or a
## ledge, then turns around. Touching it hurts the player; landing on it
## (see Player._resolve_enemy_contacts) calls stomp() and defeats it.

signal defeated(pig: Pig)

@export var walk_speed: float = 30.0
## Start walking right (true) or left (false).
@export var start_right: bool = false
@export var gravity: float = 900.0

var _direction: float = -1.0
var _defeated: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _ledge_probe: RayCast2D = $LedgeProbe
@onready var _wall_probe: RayCast2D = $WallProbe


func _ready() -> void:
	add_to_group(&"enemies")
	collision_layer = PhysicsLayers.ENEMIES
	collision_mask = PhysicsLayers.WORLD
	_direction = 1.0 if start_right else -1.0
	_update_facing()
	_sprite.play(&"run")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 400.0)
	if _defeated:
		velocity.x = 0.0
		move_and_slide()
		return
	if is_on_floor() and (_wall_probe.is_colliding() or not _ledge_probe.is_colliding()):
		_direction *= -1.0
		_update_facing()
	velocity.x = _direction * walk_speed
	move_and_slide()


func stomp() -> void:
	if _defeated:
		return
	_defeated = true
	remove_from_group(&"enemies")
	# Stop colliding with the player so the bounce isn't blocked.
	set_deferred(&"collision_layer", 0)
	defeated.emit(self)
	_sprite.play(&"hit")
	await _sprite.animation_finished
	_sprite.play(&"dead")
	await _sprite.animation_finished
	var fade := create_tween()
	fade.tween_property(self, ^"modulate:a", 0.0, 0.3)
	await fade.finished
	queue_free()


func _update_facing() -> void:
	# Kings and Pigs art faces left by default.
	_sprite.flip_h = _direction > 0.0
	_ledge_probe.position.x = 10.0 * _direction
	_wall_probe.target_position.x = 12.0 * _direction
	_ledge_probe.force_raycast_update()
	_wall_probe.force_raycast_update()
