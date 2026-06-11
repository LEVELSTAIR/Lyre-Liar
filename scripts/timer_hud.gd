extends CanvasLayer

## Countdown HUD for single-player runs. When the timer reaches zero, shows
## a "TOO LATE" overlay with Restart / Quit. Pauses the tree while the
## overlay is up. Disables itself in multiplayer.

@export var duration: float = 60.0

var _time_left: float = 0.0
var _active: bool = false

@onready var _time_label: Label = $TimeLabel
@onready var _overlay: ColorRect = $Overlay
@onready var _restart_btn: Button = $Overlay/Panel/RestartButton
@onready var _quit_btn: Button = $Overlay/Panel/QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not MultiplayerManager.is_single_player:
		queue_free()
		return
	_overlay.visible = false
	_restart_btn.pressed.connect(_restart)
	_quit_btn.pressed.connect(_quit)
	_reset()


func _process(delta: float) -> void:
	if not _active:
		return
	# Freeze the countdown while the tree is paused (pause menu / death menu).
	if get_tree().paused:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_time_left = 0.0
		_active = false
		_show_timeout()
	_update_label()


func _update_label() -> void:
	var t := int(ceil(_time_left))
	_time_label.text = "%02d:%02d" % [t / 60, t % 60]


func _reset() -> void:
	_time_left = duration
	_active = true
	_overlay.visible = false
	_update_label()


## Freeze the countdown permanently (e.g. when the player wins). Won't
## trigger the TOO LATE overlay even if time has already reached zero.
func stop() -> void:
	_active = false


func _show_timeout() -> void:
	_update_label()
	_overlay.visible = true
	get_tree().paused = true


func _find_local_player() -> Node:
	var level := get_parent()
	if level == null:
		return null
	for child in level.get_children():
		if "is_local_player" in child and child.is_local_player:
			return child
	return null


func _restart() -> void:
	get_tree().paused = false
	var player := _find_local_player()
	if player and player.has_method("respawn"):
		player.respawn()
	_reset()


func _quit() -> void:
	get_tree().paused = false
	MultiplayerManager.leave()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
