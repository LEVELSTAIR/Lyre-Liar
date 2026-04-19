extends CharacterBody2D

const SPEED         := 220.0
const JUMP_VELOCITY := -520.0
const GRAVITY       := 980.0

const WALK_FPS  := 8.0

const MAX_SPEED_SQ := (SPEED * 1.5) * (SPEED * 1.5)
const INPUT_BUFFER_SIZE := 64

var spawn_point: Vector2

@onready var _sprite: Sprite2D = $Sprite2D

var _walk_timer := 0.0
var _tick := 0
var _input_buffer: Array[Dictionary] = []
func _enter_tree() -> void:
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())


func _ready() -> void:
	spawn_point = global_position
	
	# Only enable camera and input for the local player
	if multiplayer.has_multiplayer_peer():
		if not is_multiplayer_authority():
			$Camera2D.enabled = false
			set_physics_process(false)
			set_process_input(false)
		else:
			$Camera2D.make_current()
			$Camera2D.reset_smoothing()


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED

	var input_frame = {"tick": _tick, "dir": direction, "jump": Input.is_action_just_pressed("ui_accept"), "delta": delta}
	_tick += 1
	_input_buffer.append(input_frame)
	if _input_buffer.size() > INPUT_BUFFER_SIZE:
		_input_buffer.pop_front()

	move_and_slide()
	_update_sprite(direction, delta)

	_sync_position.rpc(global_position, velocity)
	
	if not multiplayer.is_server():
		_report_state.rpc_id(1, global_position, velocity, _tick - 1)


func _update_sprite(direction: float, delta: float) -> void:
	if direction != 0.0:
		# Face the direction of travel
		_sprite.flip_h = direction < 0.0
		# Advance walk cycle
		_walk_timer += delta
		if _walk_timer >= 1.0 / WALK_FPS:
			_walk_timer = 0.0
			_sprite.frame = (_sprite.frame + 1) % 4
	else:
		# Return to idle frame
		_sprite.frame = 0
		_walk_timer  = 0.0


@rpc("any_peer", "unreliable_ordered")
func _report_state(pos: Vector2, vel: Vector2, tick: int) -> void:
	if not multiplayer.is_server():
		return
	var sender = multiplayer.get_remote_sender_id()
	if sender != int(name):
		return

	global_position = pos
	velocity = vel


@rpc("authority", "unreliable_ordered")
func _sync_position(pos: Vector2, vel: Vector2) -> void:
	if is_multiplayer_authority():
		return
	global_position = pos
	velocity = vel


@rpc("any_peer", "unreliable_ordered")
func _force_correction(corrected_pos: Vector2, corrected_vel: Vector2) -> void:
	if not is_multiplayer_authority():
		return
	global_position = corrected_pos
	velocity = corrected_vel
	_input_buffer.clear()


func respawn() -> void:
	if multiplayer.is_server():
		global_position = spawn_point
		velocity = Vector2.ZERO
		_force_correction.rpc_id(int(name), spawn_point, Vector2.ZERO)
	elif is_multiplayer_authority():
		global_position = spawn_point
		velocity = Vector2.ZERO


@rpc("any_peer", "call_local", "reliable")
func setup_spawn(pos: Vector2) -> void:
	global_position = pos
	spawn_point = pos
	velocity = Vector2.ZERO
	_input_buffer.clear()
