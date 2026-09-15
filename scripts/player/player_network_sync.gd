class_name PlayerNetworkSync
extends Node

## Multiplayer bridge for a Player. The local player sends its position and
## velocity to the Colyseus room at SEND_RATE; remote players interpolate to
## the latest server state and pick an animation from the reported velocity.

const SEND_RATE := 15.0
const REMOTE_LERP_SPEED := 12.0

var _send_timer: float = 0.0
var _tick: int = 0
var _target_position: Vector2
var _has_remote_state: bool = false

@onready var player: Player = owner as Player


func _ready() -> void:
	await player.ready
	if player.is_local_player:
		set_process(false)
		player.state_machine.state_changed.connect(_on_local_state_changed)
	else:
		set_physics_process(false)
		MultiplayerManager.player_state_changed.connect(_on_player_state_changed)


func _physics_process(delta: float) -> void:
	_tick += 1
	_send_timer += delta
	if _send_timer >= 1.0 / SEND_RATE:
		_send_timer = 0.0
		send_state()


func _process(delta: float) -> void:
	if not _has_remote_state:
		return
	player.global_position = player.global_position.lerp(_target_position, clampf(REMOTE_LERP_SPEED * delta, 0.0, 1.0))
	_animate_remote(player.remote_velocity)


## Sends the current position immediately (also used after respawn).
func send_state() -> void:
	MultiplayerManager.send_message("move", {
		"x": player.global_position.x,
		"y": player.global_position.y,
		"vx": player.velocity.x,
		"vy": player.velocity.y,
		"tick": _tick,
	})


func _on_local_state_changed(_previous_state: StringName, new_state: StringName) -> void:
	if new_state == &"Idle" and _previous_state == &"Dead":
		send_state()


func _on_player_state_changed(state_session_id: String, state: Dictionary) -> void:
	if state_session_id != player.session_id:
		return
	if state.has("x") and state.has("y"):
		_target_position = Vector2(state["x"], state["y"])
		if not _has_remote_state:
			player.global_position = _target_position
			_has_remote_state = true
	if state.has("vx") and state.has("vy"):
		player.remote_velocity = Vector2(state["vx"], state["vy"])


func _animate_remote(remote_velocity: Vector2) -> void:
	if not is_zero_approx(remote_velocity.x):
		player.set_facing(remote_velocity.x)
	if remote_velocity.y < -1.0:
		player.play_animation(&"jump")
	elif remote_velocity.y > 1.0:
		player.play_animation(&"fall")
	elif absf(remote_velocity.x) > 1.0:
		player.play_animation(&"run")
	else:
		player.play_animation(&"idle")
