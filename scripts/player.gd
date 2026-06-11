extends CharacterBody2D

## Emitted whenever the player's HP changes (damage, heal, or respawn). HUD
## listens to this to redraw the heart row.
signal hp_changed(current_hp: int, max_hp: int)

## Emitted when HP drops to 0. Levels listen to show the death menu.
signal died

# Player skins are from "Pixel Adventure" (CC0) by Pixel Frog. Every character
# ships full Idle / Run / Jump sheets laid out horizontally as 32x32 frames.
#   pink -> Pink Man, dude -> Mask Dude, owlet -> Ninja Frog
const PINK_IDLE := preload("res://asset/Pixel Adventure/Main Characters/Pink Man/Idle (32x32).png")
const PINK_WALK := preload("res://asset/Pixel Adventure/Main Characters/Pink Man/Run (32x32).png")
const PINK_JUMP := preload("res://asset/Pixel Adventure/Main Characters/Pink Man/Jump (32x32).png")

const DUDE_IDLE := preload("res://asset/Pixel Adventure/Main Characters/Mask Dude/Idle (32x32).png")
const DUDE_WALK := preload("res://asset/Pixel Adventure/Main Characters/Mask Dude/Run (32x32).png")
const DUDE_JUMP := preload("res://asset/Pixel Adventure/Main Characters/Mask Dude/Jump (32x32).png")

const OWLET_IDLE := preload("res://asset/Pixel Adventure/Main Characters/Ninja Frog/Idle (32x32).png")
const OWLET_WALK := preload("res://asset/Pixel Adventure/Main Characters/Ninja Frog/Run (32x32).png")
const OWLET_JUMP := preload("res://asset/Pixel Adventure/Main Characters/Ninja Frog/Jump (32x32).png")

enum AnimState { IDLE, WALK, JUMP }

# [sheet, frame_count, fps]. Pixel Adventure frame counts: Idle=11, Run=12, Jump=1.
const ANIM_BY_CHARACTER := {
	"pink": {
		AnimState.IDLE: [PINK_IDLE, 11, 20.0],
		AnimState.WALK: [PINK_WALK, 12, 20.0],
		AnimState.JUMP: [PINK_JUMP,  1, 10.0],
	},
	"dude": {
		AnimState.IDLE: [DUDE_IDLE, 11, 20.0],
		AnimState.WALK: [DUDE_WALK, 12, 20.0],
		AnimState.JUMP: [DUDE_JUMP,  1, 10.0],
	},
	"owlet": {
		AnimState.IDLE: [OWLET_IDLE, 11, 20.0],
		AnimState.WALK: [OWLET_WALK, 12, 20.0],
		AnimState.JUMP: [OWLET_JUMP,  1, 10.0],
	},
}

var _anim_data: Dictionary = ANIM_BY_CHARACTER["pink"]

const SPEED         := 220.0
const JUMP_VELOCITY := -380.0
const GRAVITY       := 980.0

## How often (in seconds) to send position to the server.
const SEND_INTERVAL := 1.0 / 15.0

## How fast remote players lerp to their target position.
const REMOTE_LERP_SPEED := 12.0

var spawn_point: Vector2

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _camera: Camera2D = $Camera2D

# Per-level camera config — assign on the player instance BEFORE add_child() so
# _ready() picks it up. Defaults match the side-scroller levels (day/night).
#   camera_lock_vertical = true  → camera pins Y at spawn, follows X only.
#   camera_lock_vertical = false → camera follows player on both axes.
#   camera_offset.y < 0          → view shifts up, player sits below screen
#                                  center (use for vertical-climb levels).
#   camera_zoom > 1              → zoomed in, visible world area shrinks.
#                                  (e.g. 640/480 ≈ 1.333 fits a 640 px tall
#                                  viewport to a 480 px tall background.)
var camera_lock_vertical: bool = true
var camera_offset: Vector2 = Vector2.ZERO
var camera_zoom: Vector2 = Vector2.ONE

# Y position the camera locks to (only used when camera_lock_vertical is true).
var _camera_locked_y: float = 0.0

var _walk_timer  := 0.0
var _anim_state  := AnimState.IDLE
var _tick        := 0
var _send_timer := 0.0

var is_local_player := false
var session_id := ""
var _spawn_safety_timer := 0.2

# ─── Health system ─────────────────────────────────────────────────────────────

## Max hit points. Player starts full and dies when current_hp reaches 0.
const MAX_HP: int = 3

## Seconds of damage immunity after taking a hit (also used as the sprite-flash
## duration). Prevents losing all HP from a single sustained collision.
const IFRAMES_DURATION: float = 1.0

var current_hp: int = MAX_HP
var _iframes_timer: float = 0.0


# Remote interpolation targets
var _remote_target_pos := Vector2.ZERO
var _remote_target_vel := Vector2.ZERO
var _remote_initialized := false


func _ready() -> void:
	spawn_point = global_position

	var character: String = MultiplayerManager.selected_character
	if not ANIM_BY_CHARACTER.has(character):
		character = "pink"
	_anim_data = ANIM_BY_CHARACTER[character]

	var initial: Array = _anim_data[AnimState.IDLE]
	_sprite.texture = initial[0]
	_sprite.hframes = initial[1]
	_sprite.frame = 0

	# Determine if this is the local player
	if session_id == MultiplayerManager.session_id:
		is_local_player = true
		print("Player '", session_id, "' is LOCAL player.")
	else:
		is_local_player = false
		print("Player '", session_id, "' is REMOTE player. Local session: '", MultiplayerManager.session_id, "'")

	if not is_local_player:
		# Disable physics and input for remote players
		_camera.enabled = false
		set_physics_process(false)
		# Listen for state updates from the server
		MultiplayerManager.player_state_changed.connect(_on_player_state_changed)
	else:
		# Local player camera setup. Two modes:
		#   lock_vertical=true  → top_level camera, we drive global_position
		#     in _process every frame (X tracks player, Y stays fixed).
		#   lock_vertical=false → camera stays as a child of the player and
		#     follows naturally on both axes; camera_offset shifts the view.
		_camera.offset = camera_offset
		_camera.zoom = camera_zoom
		if camera_lock_vertical:
			_camera_locked_y = global_position.y
			_camera.top_level = true
			_camera.global_position = Vector2(global_position.x, _camera_locked_y)
		else:
			_camera.top_level = false
		_camera.enabled = true
		_camera.make_current()
		_camera.reset_smoothing()
		print("Camera activated for local player: ", session_id)


func _process(delta: float) -> void:
	if is_local_player:
		# Horizontal-only camera follow when locked. Otherwise the camera is
		# a child of the player and tracks both axes via its parent transform.
		if camera_lock_vertical:
			_camera.global_position = Vector2(global_position.x, _camera_locked_y)
		return

	# Smoothly interpolate remote players
	if _remote_initialized:
		global_position = global_position.lerp(_remote_target_pos, clampf(REMOTE_LERP_SPEED * delta, 0.0, 1.0))
		_update_sprite(_remote_target_vel.x, _remote_target_vel.y, delta)


func _physics_process(delta: float) -> void:
	if not is_local_player:
		return

	# A dead local player stops moving and sending position packets until it
	# respawns (which restores HP). Without this guard the corpse keeps walking
	# and broadcasting "move" messages while the death overlay is up.
	if not is_alive():
		return

	if not is_on_floor():
		if _spawn_safety_timer > 0:
			_spawn_safety_timer -= delta
			velocity.y = 0
		else:
			velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED

	_tick += 1
	move_and_slide()
	_process_health(delta)
	_update_sprite(direction, velocity.y, delta)

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


func _update_sprite(direction: float, vel_y: float, delta: float) -> void:
	var intended: AnimState
	if vel_y < -0.1 or vel_y > 0.1:
		intended = AnimState.JUMP
	elif direction != 0.0:
		intended = AnimState.WALK
	else:
		intended = AnimState.IDLE

	if direction != 0.0:
		_sprite.flip_h = direction < 0.0

	if intended != _anim_state:
		_anim_state   = intended
		_walk_timer   = 0.0
		_sprite.frame = 0
		var anim_data: Array = _anim_data[_anim_state]
		_sprite.texture = anim_data[0]
		_sprite.hframes = anim_data[1]

	var data: Array      = _anim_data[_anim_state]
	var frame_count: int = data[1]
	var fps: float       = data[2]

	_walk_timer += delta
	if _walk_timer >= 1.0 / fps:
		_walk_timer   = 0.0
		_sprite.frame = (_sprite.frame + 1) % frame_count



func respawn() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	_spawn_safety_timer = 0.2
	current_hp = MAX_HP
	_iframes_timer = 0.0
	_sprite.modulate.a = 1.0
	hp_changed.emit(current_hp, MAX_HP)
	if is_local_player:
		MultiplayerManager.send_message("move", {
			"x": global_position.x,
			"y": global_position.y,
			"vx": 0,
			"vy": 0,
			"tick": _tick
		})


# ─── Health API ────────────────────────────────────────────────────────────────

## Returns true while the player still has HP > 0.
func is_alive() -> bool:
	return current_hp > 0


## Apply `amount` damage. No-op during invincibility frames or after death.
## Emits hp_changed (and `died` if HP hit zero) so HUD + level can react.
func take_damage(amount: int = 1) -> void:
	if not is_alive():
		return
	if _iframes_timer > 0.0:
		return
	current_hp = max(0, current_hp - amount)
	_iframes_timer = IFRAMES_DURATION
	hp_changed.emit(current_hp, MAX_HP)
	if current_hp == 0:
		_sprite.modulate.a = 1.0
		died.emit()


## Restore `amount` HP up to MAX_HP. Returns true only when HP actually changed,
## so callers (e.g. pickups) can avoid being consumed at full health or post-death.
func heal(amount: int = 1) -> bool:
	if not is_alive():
		return false
	var new_hp: int = min(MAX_HP, current_hp + amount)
	if new_hp == current_hp:
		return false
	current_hp = new_hp
	hp_changed.emit(current_hp, MAX_HP)
	return true


# Called from _physics_process for the local player. Walks the slide
# collisions reported by move_and_slide and applies damage if any of them is
# in the "enemies" group. Also ticks the i-frame timer and flashes the sprite.
func _process_health(delta: float) -> void:
	if _iframes_timer > 0.0:
		_iframes_timer = max(0.0, _iframes_timer - delta)
		# Blink ~6 Hz during i-frames so the hit is readable.
		var blink: float = 0.4 + 0.6 * (int(_iframes_timer * 12.0) % 2)
		_sprite.modulate.a = blink
		if _iframes_timer == 0.0:
			_sprite.modulate.a = 1.0

	if not is_alive():
		return
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if collider and collider is Node and (collider as Node).is_in_group("enemies"):
			take_damage(1)
			break


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
