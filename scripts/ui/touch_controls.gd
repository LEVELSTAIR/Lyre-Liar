extends CanvasLayer

## On-screen buttons for touch devices: move left/right on the bottom left,
## jump on the bottom right. They press the same input actions as the
## keyboard, so the player code doesn't know the difference.

const EDGE_MARGIN := Vector2(20, 20)
const BUTTON_GAP := 16.0

@onready var _left: TouchScreenButton = $Left
@onready var _right: TouchScreenButton = $Right
@onready var _jump: TouchScreenButton = $Jump


func _ready() -> void:
	GameProgress.settings_changed.connect(_apply_visibility)
	get_viewport().size_changed.connect(_layout)
	_apply_visibility()
	_layout()


func _apply_visibility() -> void:
	visible = GameProgress.wants_touch_controls()


func _layout() -> void:
	var screen := get_viewport().get_visible_rect().size
	var button_size := _button_size(_left)
	_left.position = Vector2(EDGE_MARGIN.x, screen.y - EDGE_MARGIN.y - button_size.y)
	_right.position = _left.position + Vector2(button_size.x + BUTTON_GAP, 0)
	var jump_size := _button_size(_jump)
	_jump.position = Vector2(screen.x - EDGE_MARGIN.x - jump_size.x, screen.y - EDGE_MARGIN.y - jump_size.y)


func _button_size(button: TouchScreenButton) -> Vector2:
	return button.texture_normal.get_size() * button.scale
