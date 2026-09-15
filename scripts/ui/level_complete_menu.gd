class_name LevelCompleteMenu
extends OverlayMenu

## Results screen when the local player reaches the goal. In multiplayer it
## doesn't pause (other players keep playing) and only offers leaving.

var _next_level: LevelInfo

@onready var _title: Label = %Title
@onready var _time_value: Label = %TimeValue
@onready var _best_badge: Label = %BestBadge
@onready var _fruits_value: Label = %FruitsValue
@onready var _deaths_value: Label = %DeathsValue
@onready var _next_button: Button = %NextButton
@onready var _replay_button: Button = %ReplayButton
@onready var _levels_button: Button = %LevelsButton


func _ready() -> void:
	super()
	_next_button.pressed.connect(_on_next_pressed)
	_replay_button.pressed.connect(SceneRouter.reload_current)
	_levels_button.pressed.connect(_leave_to.bind(SceneRouter.LEVEL_SELECT_SCENE))


func show_result(result: LevelResult, is_new_best: bool) -> void:
	var single_player := MultiplayerManager.is_single_player
	_next_level = LevelCatalog.load_default().next_level(result.level_id)
	_title.text = "LEVEL COMPLETE" if single_player else "FINISHED!"
	_time_value.text = TimeText.format(result.time_seconds)
	_best_badge.visible = is_new_best and single_player
	_fruits_value.text = "%d/%d" % [result.fruits, result.total_fruits]
	_deaths_value.text = str(result.deaths)
	_next_button.visible = single_player and _next_level != null
	_replay_button.visible = single_player
	_levels_button.text = "LEVELS" if single_player else "LEAVE ROOM"
	open(single_player)


func _on_next_pressed() -> void:
	MultiplayerManager.start_single_player(_next_level.id)
	SceneRouter.go_to_level(_next_level)
