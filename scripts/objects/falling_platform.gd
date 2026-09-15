class_name FallingPlatform
extends AnimatableBody2D

## One-way platform that shakes briefly after the player lands on it, falls,
## and reappears at its original position after `respawn_seconds`.

@export var shake_seconds: float = 0.5
@export var fall_speed_max: float = 320.0
@export var fall_gravity: float = 700.0
@export var respawn_seconds: float = 3.0

var _origin: Vector2
var _falling: bool = false
var _triggered: bool = false
var _fall_velocity: float = 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _detector: Area2D = $PlayerDetector


func _ready() -> void:
	_origin = position
	collision_layer = PhysicsLayers.WORLD
	sync_to_physics = false
	_detector.collision_layer = 0
	_detector.collision_mask = PhysicsLayers.PLAYER
	_detector.body_entered.connect(_on_player_detected)
	_sprite.play(&"on")


func _physics_process(delta: float) -> void:
	if not _falling:
		return
	_fall_velocity = minf(_fall_velocity + fall_gravity * delta, fall_speed_max)
	position.y += _fall_velocity * delta


func _on_player_detected(body: Node2D) -> void:
	var player := body as Player
	if _triggered or player == null or not player.is_local_player:
		return
	_triggered = true
	await _shake()
	_falling = true
	_sprite.play(&"off")
	await _wait(0.6)
	_collision.set_deferred(&"disabled", true)
	await _wait(respawn_seconds)
	_reset()


## Waits using a child Timer so it pauses with the game and stops when the
## platform is freed.
func _wait(seconds: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(timer)
	timer.start(seconds)
	await timer.timeout
	timer.queue_free()


func _shake() -> void:
	var tween := create_tween()
	for i in 5:
		tween.tween_property(_sprite, ^"position:x", 1.0, shake_seconds / 10.0)
		tween.tween_property(_sprite, ^"position:x", -1.0, shake_seconds / 10.0)
	tween.tween_property(_sprite, ^"position:x", 0.0, 0.0)
	await tween.finished


func _reset() -> void:
	_falling = false
	_fall_velocity = 0.0
	position = _origin
	_collision.set_deferred(&"disabled", false)
	_sprite.play(&"on")
	_triggered = false
