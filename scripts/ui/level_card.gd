class_name LevelCard
extends Button

## Level-select card: number badge, name, description, and best run.

const BADGE_PATH := "res://asset/Pixel Adventure/Menu/Levels/%02d.png"

var level: LevelInfo

@onready var _badge: TextureRect = %Badge
@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _best_time: Label = %BestTime
@onready var _fruits: Label = %Fruits


func setup(level_info: LevelInfo, number: int) -> void:
	level = level_info
	var unlocked := GameProgress.is_unlocked(level.id)
	disabled = not unlocked
	_badge.texture = load(BADGE_PATH % number)
	_title.text = level.title if unlocked else "LOCKED"
	_title.add_theme_color_override("font_color", level.accent_color if unlocked else Color(0.6, 0.6, 0.6))
	_subtitle.text = level.subtitle if unlocked else "Finish the previous level"
	var best := GameProgress.best_time(level.id)
	_best_time.text = "BEST %s" % TimeText.format(best) if best >= 0.0 else "BEST --:--"
	var total := GameProgress.total_fruits(level.id)
	_fruits.text = "Fruits %d/%d" % [GameProgress.best_fruits(level.id), total] if total > 0 else "Fruits -"
	modulate = Color.WHITE if unlocked else Color(1, 1, 1, 0.6)
