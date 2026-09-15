class_name DeathMenu
extends OverlayMenu

## Shown in single-player when the local player dies. Multiplayer players
## respawn automatically (see Level).

var _player: Player

@onready var _respawn_button: Button = %RespawnButton
@onready var _restart_button: Button = %RestartButton
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	super()
	_respawn_button.pressed.connect(_on_respawn_pressed)
	_restart_button.pressed.connect(SceneRouter.reload_current)
	_menu_button.pressed.connect(_leave_to.bind(SceneRouter.LEVEL_SELECT_SCENE))


func show_death(player: Player) -> void:
	_player = player
	open(true)


func _on_respawn_pressed() -> void:
	close()
	if is_instance_valid(_player):
		_player.respawn()
