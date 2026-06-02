extends CanvasLayer

## Win-screen overlay shown when the local player touches the level's Goal
## Area2D. Pauses the tree while open. Single-player only — self-removes in
## multiplayer (mirrors timer_hud's pattern).

var _won: bool = false

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

	# On the final map next_mode() wraps back to the first level, so hide
	# "Next Level" rather than sending the player back to the start.
	if MultiplayerManager.selected_mode == MultiplayerManager.MAP_REGISTRY[-1]["mode"]:
		_next_btn.visible = false


func show_win(_player: Node, time_seconds: float = -1.0, deaths: int = -1) -> void:
	if _won:
		return
	_won = true
	if time_seconds >= 0.0 and deaths >= 0:
		var minutes: int = int(time_seconds) / 60
		var secs: int = int(time_seconds) % 60
		_stats_label.text = "Time: %02d:%02d   Deaths: %d" % [minutes, secs, deaths]
	else:
		_stats_label.text = ""
	_overlay.visible = true
	_overlay.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	get_tree().paused = true


func _replay() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _next_level() -> void:
	get_tree().paused = false
	var next: String = MultiplayerManager.next_mode(MultiplayerManager.selected_mode)
	MultiplayerManager.selected_mode = next
	get_tree().change_scene_to_file(MultiplayerManager.get_map(next)["scene"])


func _to_main_menu() -> void:
	get_tree().paused = false
	MultiplayerManager.leave()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
