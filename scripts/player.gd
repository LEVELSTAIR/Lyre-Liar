extends CharacterBody2D

const SPEED         := 220.0
const JUMP_VELOCITY := -520.0
const GRAVITY       := 980.0
const WALK_FPS  := 8.0

## How often (in seconds) to send position to the server.
const SEND_INTERVAL := 1.0 / 15.0

## How fast remote players lerp to their target position.
const REMOTE_LERP_SPEED := 12.0

var spawn_point: Vector2

@onready var _sprite: Sprite2D = $Sprite2D

var _walk_timer := 0.0
var _tick := 0
var _send_timer := 0.0

var is_local_player := false
var session_id := ""

# Remote interpolation targets
var _remote_target_pos := Vector2.ZERO
var _remote_target_vel := Vector2.ZERO
var _remote_initialized := false


func _ready() -> void:
	spawn_point = global_position

	# Determine if this is the local player
	if session_id == MultiplayerManager.session_id:
		is_local_player = true
		print("Player '", session_id, "' is LOCAL player.")
	else:
		is_local_player = false
		print("Player '", session_id, "' is REMOTE player. Local session: '", MultiplayerManager.session_id, "'")

	if not is_local_player:
		# Disable physics and input for remote players
		$Camera2D.enabled = false
		set_physics_process(false)
		# Listen for state updates from the server
		MultiplayerManager.player_state_changed.connect(_on_player_state_changed)
	else:
		# Local player setup
		$Camera2D.enabled = true
		$Camera2D.make_current()
		$Camera2D.reset_smoothing()
		print("Camera activated for local player: ", session_id)


func _process(delta: float) -> void:
	if is_local_player:
		return

	# Smoothly interpolate remote players
	if _remote_initialized:
		global_position = global_position.lerp(_remote_target_pos, clampf(REMOTE_LERP_SPEED * delta, 0.0, 1.0))
		_update_sprite(_remote_target_vel.x, delta)


func _physics_process(delta: float) -> void:
	if not is_local_player:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED

	_tick += 1
	move_and_slide()
	_update_sprite(direction, delta)

	# Throttled movement send
	_send_timer += delta
	if _send_timer >= SEND_INTERVAL:
		_send_timer = 0.0
		MultiplayerManager.send_message("move", {
			"x": global_position.x,
			"y": global_position.y,
			"vx": velocity.x,
			"vy": velocity.y,
			"tick": _tick
		})


func _update_sprite(direction: float, delta: float) -> void:
	if direction != 0.0:
		_sprite.flip_h = direction < 0.0
		_walk_timer += delta
		if _walk_timer >= 1.0 / WALK_FPS:
			_walk_timer = 0.0
			_sprite.frame = (_sprite.frame + 1) % 4
	else:
		_sprite.frame = 0
		_walk_timer = 0.0


func respawn() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	if is_local_player:
		MultiplayerManager.send_message("move", {
			"x": global_position.x,
			"y": global_position.y,
			"vx": 0,
			"vy": 0,
			"tick": _tick
		})


func _on_player_state_changed(state_session_id: String, state: Dictionary) -> void:
	if state_session_id != session_id:
		return

	if state.has("x") and state.has("y"):
		_remote_target_pos = Vector2(state["x"], state["y"])
		if not _remote_initialized:
			global_position = _remote_target_pos
			_remote_initialized = true
	if state.has("vx") and state.has("vy"):
		_remote_target_vel = Vector2(state["vx"], state["vy"])
