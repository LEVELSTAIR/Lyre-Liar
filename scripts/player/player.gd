class_name Player
extends CharacterBody2D

## Platformer character. Movement rules live in the states under
## StateMachine; this script owns the shared physics helpers, health, and
## the public API used by levels, pickups, and hazards.
##
## Only the local player simulates physics. Remote players are positioned by
## NetworkSync from server state.

## Emitted whenever HP changes (damage, heal, or respawn).
signal hp_changed(current_hp: int, max_hp: int)
## Emitted when HP reaches 0.
signal died

const MAX_HP: int = 3

@export_group("Run")
@export var run_speed: float = 130.0
@export var ground_acceleration: float = 1100.0
@export var air_acceleration: float = 750.0

@export_group("Jump")
@export var jump_velocity: float = -300.0
@export var double_jump_velocity: float = -260.0
@export var gravity: float = 900.0
@export var max_fall_speed: float = 380.0

@export_group("Wall")
@export var wall_slide_speed: float = 55.0
@export var wall_jump_velocity: Vector2 = Vector2(150.0, -270.0)
## Seconds after a wall jump during which horizontal input is ignored, so the
## player actually leaves the wall.
@export var wall_jump_input_lock: float = 0.14

@export_group("Damage")
@export var knockback_velocity: Vector2 = Vector2(110.0, -170.0)
## Upward velocity applied when bouncing off an enemy or trampoline.
@export var bounce_velocity: float = -260.0

var session_id: String = ""
var is_local_player: bool = false
var spawn_point: Vector2
## Set by NetworkSync for remote players; drives their animation.
var remote_velocity: Vector2 = Vector2.ZERO
var facing: float = 1.0
## Horizontal direction (-1 or 1) the last hit pushes the player.
var knockback_direction: float = -1.0
var can_double_jump: bool = true
var input_lock_left: float = 0.0

## Camera settings a level may assign before add_child().
var camera_zoom: Vector2 = Vector2.ONE
var camera_offset: Vector2 = Vector2.ZERO

var current_hp: int:
	get:
		return health.current_health

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var camera: PlayerCamera = $PlayerCamera


func _ready() -> void:
	spawn_point = global_position
	is_local_player = session_id == MultiplayerManager.session_id
	var character := CharacterCatalog.load_default().get_character(MultiplayerManager.selected_character)
	sprite.sprite_frames = character.sprite_frames
	sprite.play(&"idle")

	health.max_health = MAX_HP
	health.reset()
	health.health_changed.connect(_on_health_changed)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)

	if is_local_player:
		camera.zoom = camera_zoom
		camera.offset = camera_offset
		camera.activate()
	else:
		camera.enabled = false
		state_machine.process_mode = Node.PROCESS_MODE_DISABLED
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	input_lock_left = maxf(0.0, input_lock_left - delta)
	_update_invincibility_blink()


# ─── Shared movement helpers (used by states) ─────────────────────────────────

func input_direction() -> float:
	if input_lock_left > 0.0:
		return 0.0
	return Input.get_axis("move_left", "move_right")


## True on the physics frame the jump action is pressed.
## Issue #37 hook: a jump buffer would remember this press for a short window.
func wants_jump() -> bool:
	return Input.is_action_just_pressed("jump")


## True when a ground jump is allowed.
## Issue #37 hook: coyote time would extend this shortly after leaving a ledge.
func can_ground_jump() -> bool:
	return is_on_floor()


## Issue #37 hook: variable jump height would cut upward velocity here when
## the jump action is released early. Called every airborne rising frame.
func on_jump_rising(_delta: float) -> void:
	pass


## move_and_slide() followed by enemy contact resolution. States call this
## instead of move_and_slide() directly.
func move() -> void:
	move_and_slide()
	_resolve_enemy_contacts()


func apply_gravity(delta: float, fall_speed_cap: float = max_fall_speed) -> void:
	velocity.y = minf(velocity.y + gravity * delta, fall_speed_cap)


func apply_horizontal_movement(delta: float) -> void:
	var direction := input_direction()
	var acceleration := ground_acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x, direction * run_speed, acceleration * delta)
	if direction != 0.0:
		set_facing(direction)


func set_facing(direction: float) -> void:
	facing = signf(direction)
	sprite.flip_h = facing < 0.0


## Wall the player is pressing into while airborne, as a direction (-1 or 1),
## or 0 when not wall-sliding.
func pressed_wall_direction() -> float:
	if is_on_floor() or not is_on_wall():
		return 0.0
	var wall_side := -signf(get_wall_normal().x)
	return wall_side if Input.get_axis("move_left", "move_right") * wall_side > 0.0 else 0.0


func play_animation(animation: StringName) -> void:
	if sprite.animation != animation or not sprite.is_playing():
		sprite.play(animation)


# ─── Public API (levels, pickups, hazards) ────────────────────────────────────

func is_alive() -> bool:
	return health.is_alive()


## Damages the player; `source_position` sets the knockback direction.
func take_damage(amount: int = 1, source_position: Variant = null) -> void:
	if not is_local_player:
		return
	var away := -facing
	if source_position is Vector2 and not is_equal_approx(global_position.x, source_position.x):
		away = signf(global_position.x - source_position.x)
	knockback_direction = away
	health.take_damage(amount)


## Restores HP. Returns true only when HP actually changed.
func heal(amount: int = 1) -> bool:
	return health.heal(amount)


## Launches the player upward (enemy stomp, trampoline) and restores the
## double jump.
func bounce(velocity_y: float = bounce_velocity) -> void:
	velocity.y = velocity_y
	can_double_jump = true
	state_machine.transition_to(&"Jump")


func respawn() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	can_double_jump = true
	health.reset()
	sprite.modulate.a = 1.0
	camera.reset_smoothing()
	state_machine.transition_to(&"Idle")
	Events.player_respawned.emit()


# ─── Internals ────────────────────────────────────────────────────────────────

func _on_health_changed(current: int, maximum: int) -> void:
	hp_changed.emit(current, maximum)
	if is_local_player:
		Events.player_hp_changed.emit(current, maximum)


func _on_damaged(_amount: int) -> void:
	camera.shake()
	if health.is_alive():
		state_machine.transition_to(&"Hit")


func _on_died() -> void:
	state_machine.transition_to(&"Dead")
	died.emit()
	if is_local_player:
		Events.player_died.emit()


## Landing on an enemy from above stomps it (if it supports stomping) and
## bounces the player; any other contact hurts the player.
func _resolve_enemy_contacts() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var enemy := collision.get_collider() as Node2D
		if enemy == null or not enemy.is_in_group(&"enemies"):
			continue
		if collision.get_normal().y < -0.6 and enemy.has_method(&"stomp"):
			enemy.stomp()
			bounce()
			return
		take_damage(1, enemy.global_position)


func _update_invincibility_blink() -> void:
	if health.is_invincible() and health.is_alive():
		sprite.modulate.a = 0.4 if int(Time.get_ticks_msec() / 80.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0
