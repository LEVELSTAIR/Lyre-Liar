class_name FireTrap
extends StaticBody2D

## Solid block that periodically shoots fire upward. The flame hazard is only
## active during the "on" phase; a short ignition animation warns the player.

@export var off_seconds: float = 1.6
@export var on_seconds: float = 1.2
## Delay before the first cycle, to stagger traps placed in a row.
@export var start_delay: float = 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _flame: Hazard = $Flame


func _ready() -> void:
	_set_flame(false)
	_run_cycle()


func _run_cycle() -> void:
	if start_delay > 0.0:
		await _wait(start_delay)
	while true:
		_sprite.play(&"off")
		await _wait(off_seconds)
		_sprite.play(&"ignite")
		await _sprite.animation_finished
		_set_flame(true)
		_sprite.play(&"on")
		await _wait(on_seconds)
		_set_flame(false)


## Waits using a child Timer so the cycle pauses with the game and simply
## stops when the trap is freed.
func _wait(seconds: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(timer)
	timer.start(seconds)
	await timer.timeout
	timer.queue_free()


func _set_flame(active: bool) -> void:
	_flame.set_deferred(&"monitoring", active)
