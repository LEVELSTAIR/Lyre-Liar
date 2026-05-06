extends Node

const BASE_W: float = 360.0
const BASE_H: float = 640.0
const MIN_SCALE: float = 0.7
const MAX_SCALE: float = 2.5

signal scale_changed(new_scale: float)

var scale_factor: float = 1.0

func _ready() -> void:
	get_tree().root.size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()

func _on_viewport_resized() -> void:
	var vp: Vector2 = get_tree().root.get_visible_rect().size
	scale_factor = clamp(min(vp.x / BASE_W, vp.y / BASE_H), MIN_SCALE, MAX_SCALE)
	scale_changed.emit(scale_factor)

func scale(base_value: float) -> float:
	return base_value * scale_factor

func scale_i(base_value: int) -> int:
	return int(base_value * scale_factor)
