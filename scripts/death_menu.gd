extends CanvasLayer

## Death overlay shown when the local player hits a KillZone. Pauses the tree
## while open so the player isn't still falling underneath the menu.

var _player: Node = null

@onready var _overlay: ColorRect = $Overlay
@onready var _restart_btn: Button = $Overlay/Panel/RestartButton
@onready var _quit_btn: Button = $Overlay/Panel/QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.visible = false
	_restart_btn.pressed.connect(_restart)
	_quit_btn.pressed.connect(_quit)


func show_death(player: Node) -> void:
	if _overlay.visible:
		return
	_player = player
	_overlay.visible = true
	get_tree().paused = true


func _restart() -> void:
	_overlay.visible = false
	get_tree().paused = false
	if _player and _player.has_method("respawn"):
		_player.respawn()


func _quit() -> void:
	get_tree().paused = false
	MultiplayerManager.leave()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
