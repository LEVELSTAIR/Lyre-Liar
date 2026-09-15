extends CanvasLayer

## Win-screen overlay shown by Level when the local player reaches the goal.
## Pauses the tree while open. Single-player only; self-removes in
## multiplayer.

var _won: bool = false
var _catalog: LevelCatalog = LevelCatalog.load_default()

@onready var _overlay: ColorRect = $Overlay
@onready var _stats_label: Label = $Overlay/Panel/StatsLabel
@onready var _replay_btn: Button = $Overlay/Panel/ReplayButton
@onready var _next_btn: Button = $Overlay/Panel/NextLevelButton
@onready var _menu_btn: Button = $Overlay/Panel/MainMenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not MultiplayerManager.is_single_player:
		queue_free()
		return
	_overlay.visible = false
	_replay_btn.pressed.connect(_replay)
	_next_btn.pressed.connect(_next_level)
	_menu_btn.pressed.connect(_to_main_menu)

	# The last level has nothing to advance to.
	_next_btn.visible = _catalog.next_level(MultiplayerManager.selected_mode) != null


func show_result(result: LevelResult) -> void:
	if _won:
		return
	_won = true
	var minutes: int = int(result.time_seconds) / 60
	var secs: int = int(result.time_seconds) % 60
	_stats_label.text = "Time: %02d:%02d   Fruits: %d/%d   Deaths: %d" % [minutes, secs, result.fruits, result.total_fruits, result.deaths]
	_overlay.visible = true
	_overlay.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	get_tree().paused = true


func _replay() -> void:
	SceneRouter.reload_current()


func _next_level() -> void:
	var next := _catalog.next_level(MultiplayerManager.selected_mode)
	if next == null:
		return
	MultiplayerManager.selected_mode = next.id
	SceneRouter.go_to_level(next)


func _to_main_menu() -> void:
	MultiplayerManager.leave()
	SceneRouter.go_to_main_menu()
