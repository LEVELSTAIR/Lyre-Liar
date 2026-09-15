class_name Hud
extends CanvasLayer

## In-level heads-up display: hearts, fruit counter, run timer, pause button,
## and (in multiplayer) the room code. Gameplay values arrive through the
## Events bus; the Level pushes the timer and room code.

const HEART_EMPTY_TINT := Color(0.15, 0.1, 0.12, 0.8)

@export var heart_texture: Texture2D

@onready var _hearts: HBoxContainer = %Hearts
@onready var _fruit_label: Label = %FruitLabel
@onready var _timer_label: Label = %TimerLabel
@onready var _pause_button: Button = %PauseButton
@onready var _room_panel: PanelContainer = %RoomPanel
@onready var _room_label: Label = %RoomLabel


func _ready() -> void:
	Events.player_hp_changed.connect(set_hp)
	Events.fruit_collected.connect(set_fruits)
	_pause_button.pressed.connect(Events.pause_requested.emit)
	_room_panel.visible = false
	set_hp(Player.MAX_HP, Player.MAX_HP)
	set_time(0.0)


func set_hp(current: int, maximum: int) -> void:
	while _hearts.get_child_count() < maximum:
		var heart := TextureRect.new()
		heart.texture = heart_texture
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart.custom_minimum_size = Vector2(18, 14) * 1.5
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_hearts.add_child(heart)
	for i in _hearts.get_child_count():
		var heart := _hearts.get_child(i) as TextureRect
		heart.visible = i < maximum
		heart.modulate = Color.WHITE if i < current else HEART_EMPTY_TINT


func set_fruits(collected: int, total: int) -> void:
	_fruit_label.text = "%d/%d" % [collected, total]


func set_time(seconds: float) -> void:
	_timer_label.text = TimeText.format(seconds)


func show_room_code(code: String, address: String) -> void:
	_room_panel.visible = true
	_room_label.text = "ROOM %s" % code if address.is_empty() else "ROOM %s  ·  %s" % [code, address]
