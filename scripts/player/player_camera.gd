class_name PlayerCamera
extends Camera2D

## Follow camera for the local player: built-in position smoothing, optional
## world limits, and trauma-based screen shake on `offset`.

## Offset at maximum trauma, in pixels.
@export var max_shake_offset: Vector2 = Vector2(6.0, 4.0)
## Trauma lost per second (trauma ranges 0-1).
@export var trauma_decay: float = 2.5
@export var noise_speed: float = 40.0

var _trauma: float = 0.0
var _base_offset: Vector2 = Vector2.ZERO
var _noise := FastNoiseLite.new()
var _noise_time: float = 0.0


func _ready() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.seed = randi()
	set_process(false)


func activate() -> void:
	_base_offset = offset
	enabled = true
	make_current()
	reset_smoothing()


## Keeps the view inside `world_rect` (world pixels).
func apply_limits(world_rect: Rect2i) -> void:
	limit_left = world_rect.position.x
	limit_top = world_rect.position.y
	limit_right = world_rect.end.x
	limit_bottom = world_rect.end.y
	reset_smoothing()


## Adds screen shake. `amount` stacks and is clamped to 1.
func shake(amount: float = 0.6) -> void:
	_trauma = minf(_trauma + amount, 1.0)
	set_process(true)


func _process(delta: float) -> void:
	_trauma = maxf(_trauma - trauma_decay * delta, 0.0)
	_noise_time += delta * noise_speed
	var strength := _trauma * _trauma
	offset = _base_offset + Vector2(
		max_shake_offset.x * strength * _noise.get_noise_2d(_noise_time, 0.0),
		max_shake_offset.y * strength * _noise.get_noise_2d(0.0, _noise_time)
	)
	if _trauma == 0.0:
		offset = _base_offset
		set_process(false)
