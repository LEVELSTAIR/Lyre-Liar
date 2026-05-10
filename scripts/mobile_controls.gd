extends Control

const BASE_JOYSTICK: float = 100.0
const BASE_HANDLE: float = 50.0
const BASE_BUTTON: float = 100.0
const BASE_PADDING: float = 20.0
const BASE_FONT: int = 24

@onready var joystick_base = $JoystickBase
@onready var joystick_handle = $JoystickBase/JoystickHandle
@onready var jump_button = $JumpButton

var _joystick_touch_id: int = -1
var _jump_touch_id: int = -1
var _joystick_center: Vector2
var _joystick_max_distance: float
var _mouse_pressed := false


func _ready() -> void:
	# Hide if not on mobile and not in editor
	if OS.get_name() in ["macOS", "Windows", "Linux"] and not OS.has_feature("editor"):
		visible = false
		set_process_input(false)
		return

	ResponsiveUI.scale_changed.connect(_apply_layout)
	resized.connect(func(): _apply_layout(ResponsiveUI.scale_factor))
	_apply_layout(ResponsiveUI.scale_factor)


func _apply_layout(sf: float) -> void:
	var jp := BASE_JOYSTICK * sf
	var hp := BASE_HANDLE * sf
	var bp := BASE_BUTTON * sf
	var pp := BASE_PADDING * sf
	var vp := get_viewport_rect().size

	# Size and position joystick base (bottom-right)
	joystick_base.size = Vector2(jp, jp)
	joystick_base.custom_minimum_size = Vector2(jp, jp)
	joystick_base.position = Vector2(vp.x - jp - pp, vp.y - jp - pp)

	# Size and position joystick handle (centered inside base)
	joystick_handle.size = Vector2(hp, hp)
	joystick_handle.custom_minimum_size = Vector2(hp, hp)
	joystick_handle.position = Vector2((jp - hp) / 2.0, (jp - hp) / 2.0)

	# Size and position jump button (bottom-left)
	jump_button.size = Vector2(bp, bp)
	jump_button.custom_minimum_size = Vector2(bp, bp)
	jump_button.position = Vector2(pp, vp.y - bp - pp)
	jump_button.add_theme_font_size_override("font_size", int(BASE_FONT * sf))

	# Update joystick interaction state
	_joystick_center = joystick_base.global_position + joystick_base.size / 2.0
	_joystick_max_distance = jp / 2.0

	# Update corner radii on style boxes
	_apply_corner_radius(joystick_base, "panel", int(jp / 2.0))
	_apply_corner_radius(joystick_handle, "panel", int(hp / 2.0))
	_apply_corner_radius(jump_button, "normal", int(bp / 2.0))


func _apply_corner_radius(node: Control, slot: StringName, r: int) -> void:
	var sb = node.get_theme_stylebox(slot)
	if not sb:
		return
	sb = sb.duplicate()
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
	node.add_theme_stylebox_override(slot, sb)


func _input(event: InputEvent) -> void:
	# Handle touch input
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_touch_pressed(event.position, event.get_index())
		else:
			_on_touch_released(event.get_index())
	elif event is InputEventScreenDrag:
		_on_touch_dragged(event)

	# Handle mouse input (for Godot editor play simulation)
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_touch_pressed(event.position, 0)
			_mouse_pressed = true
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_touch_released(0)
			_mouse_pressed = false
	elif event is InputEventMouseMotion and _mouse_pressed:
		_on_touch_dragged(event)


func _on_touch_pressed(position: Vector2, touch_id: int) -> void:
	var joystick_rect = joystick_base.get_global_rect()
	var jump_rect = jump_button.get_global_rect()

	# Check if touch is on joystick
	if joystick_rect.has_point(position):
		_joystick_touch_id = touch_id
		_update_joystick(position)
	# Check if touch is on jump button
	elif jump_rect.has_point(position):
		_jump_touch_id = touch_id
		jump_button.modulate = Color.GRAY
		Input.action_press("ui_accept")


func _on_touch_released(touch_id: int) -> void:
	# Reset joystick
	if _joystick_touch_id == touch_id:
		_joystick_touch_id = -1
		# Center the handle
		joystick_handle.position = Vector2(
			(joystick_base.size.x - joystick_handle.size.x) / 2.0,
			(joystick_base.size.y - joystick_handle.size.y) / 2.0
		)
		Input.action_release("ui_left")
		Input.action_release("ui_right")

	# Reset jump button
	if _jump_touch_id == touch_id:
		_jump_touch_id = -1
		jump_button.modulate = Color.WHITE
		Input.action_release("ui_accept")


func _on_touch_dragged(event: InputEvent) -> void:
	var pos = event.position if event is InputEventScreenDrag else (event as InputEventMouseMotion).position

	if _joystick_touch_id == (event.get_index() if event is InputEventScreenDrag else 0):
		_update_joystick(pos)


func _update_joystick(touch_position: Vector2) -> void:
	var joystick_rect = joystick_base.get_global_rect()
	var joystick_center = joystick_rect.get_center()

	# Calculate vector from center to touch
	var touch_offset = touch_position - joystick_center
	var distance = touch_offset.length()

	# Clamp to max distance
	if distance > _joystick_max_distance:
		touch_offset = touch_offset.normalized() * _joystick_max_distance

	# Convert offset to position within handle
	var base_size = joystick_base.size
	var handle_size = joystick_handle.size
	var offset_percent = touch_offset / (base_size / 2.0)
	offset_percent = offset_percent.clamp(Vector2(-1, -1), Vector2(1, 1))

	# Update handle position as offset from center
	var offset_pixels = offset_percent * ((base_size.x - handle_size.x) / 2.0)
	joystick_handle.position = Vector2(
		(base_size.x - handle_size.x) / 2.0 + offset_pixels.x,
		(base_size.y - handle_size.y) / 2.0 + offset_pixels.y
	)

	# Determine input based on direction
	_update_movement_input(touch_offset)


func _update_movement_input(offset: Vector2) -> void:
	# Use a deadzone to avoid drift
	var deadzone = 10.0

	if offset.x < -deadzone:
		Input.action_press("ui_left")
		Input.action_release("ui_right")
	elif offset.x > deadzone:
		Input.action_press("ui_right")
		Input.action_release("ui_left")
	else:
		Input.action_release("ui_left")
		Input.action_release("ui_right")
