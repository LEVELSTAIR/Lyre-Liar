extends Control

const BASE_JOYSTICK: float = 130.0
const BASE_HANDLE: float = 65.0
const BASE_BUTTON: float = 130.0
const BASE_PADDING: float = 24.0
const BASE_FONT: int = 30

# On real mobile devices we add an extra scale boost based on the physical
# screen size — small phones (e.g., 720 px wide / ~5") get a noticeably bigger
# touch target than tablets (1200+ wide / ~10"). Desktop/editor stays at 1.0.
const MOBILE_BOOST_MIN: float = 1.0
const MOBILE_BOOST_MAX: float = 1.4
# Reference physical screen width in pixels at which the boost = 1.0.
# Below this width, we scale up toward MOBILE_BOOST_MAX. Above, we taper to 1.0.
const MOBILE_REF_WIDTH: float = 1200.0
const MOBILE_MIN_WIDTH: float = 600.0

# Brand colors mirrored from docs/design-system/colors_and_type.css. Used to
# build high-contrast styleboxes so the mobile controls stay visible against
# the dark cave / night backgrounds.
const BRASS_RULE := Color(0.78, 0.55, 0.18, 1)
const BRASS_GLOW := Color(0.85, 0.7, 0.4, 1)
const PARCHMENT := Color(0.95, 0.9, 0.85, 1)
const BRASS_DEEP := Color(0.32, 0.18, 0.06, 1)

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

	_apply_visible_styleboxes()

	ResponsiveUI.scale_changed.connect(_apply_layout)
	resized.connect(func(): _apply_layout(ResponsiveUI.scale_factor))
	_apply_layout(ResponsiveUI.scale_factor)


# Brand-coloured styleboxes for the touch controls. Default Godot styleboxes
# disappear against the cave/night backgrounds — these add a brass border and
# a translucent parchment fill so the controls read on any background.
func _apply_visible_styleboxes() -> void:
	# Joystick base — outer ring.
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(PARCHMENT.r, PARCHMENT.g, PARCHMENT.b, 0.30)
	base_style.border_color = BRASS_RULE
	base_style.border_width_left = 3
	base_style.border_width_top = 3
	base_style.border_width_right = 3
	base_style.border_width_bottom = 3
	joystick_base.add_theme_stylebox_override("panel", base_style)

	# Joystick handle — solid brass-glow nub.
	var handle_style := StyleBoxFlat.new()
	handle_style.bg_color = Color(BRASS_GLOW.r, BRASS_GLOW.g, BRASS_GLOW.b, 0.85)
	handle_style.border_color = Color(0, 0, 0, 0.4)
	handle_style.border_width_left = 2
	handle_style.border_width_top = 2
	handle_style.border_width_right = 2
	handle_style.border_width_bottom = 2
	joystick_handle.add_theme_stylebox_override("panel", handle_style)

	# Jump button normal — parchment fill, brass border.
	var jump_normal := StyleBoxFlat.new()
	jump_normal.bg_color = Color(PARCHMENT.r, PARCHMENT.g, PARCHMENT.b, 0.40)
	jump_normal.border_color = BRASS_RULE
	jump_normal.border_width_left = 3
	jump_normal.border_width_top = 3
	jump_normal.border_width_right = 3
	jump_normal.border_width_bottom = 3
	jump_button.add_theme_stylebox_override("normal", jump_normal)

	var jump_hover := jump_normal.duplicate() as StyleBoxFlat
	jump_hover.bg_color.a = 0.55
	jump_button.add_theme_stylebox_override("hover", jump_hover)

	# Jump button pressed — inverted: brass fill, parchment border.
	var jump_pressed := StyleBoxFlat.new()
	jump_pressed.bg_color = Color(BRASS_RULE.r, BRASS_RULE.g, BRASS_RULE.b, 0.85)
	jump_pressed.border_color = PARCHMENT
	jump_pressed.border_width_left = 3
	jump_pressed.border_width_top = 3
	jump_pressed.border_width_right = 3
	jump_pressed.border_width_bottom = 3
	jump_button.add_theme_stylebox_override("pressed", jump_pressed)

	# Label colors that read on both states.
	jump_button.add_theme_color_override("font_color", BRASS_DEEP)
	jump_button.add_theme_color_override("font_hover_color", BRASS_DEEP)
	jump_button.add_theme_color_override("font_pressed_color", PARCHMENT)


func _apply_layout(sf: float) -> void:
	# Combine the design-time responsive factor with a mobile-only boost so
	# small phones get a chunkier touch target than tablets.
	var boost: float = _mobile_size_boost()
	var jp := BASE_JOYSTICK * sf * boost
	var hp := BASE_HANDLE * sf * boost
	var bp := BASE_BUTTON * sf * boost
	var pp := BASE_PADDING * sf * boost
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
	jump_button.add_theme_font_size_override("font_size", int(BASE_FONT * sf * boost))

	# Update joystick interaction state
	_joystick_center = joystick_base.global_position + joystick_base.size / 2.0
	_joystick_max_distance = jp / 2.0

	# Update corner radii on style boxes
	_apply_corner_radius(joystick_base, "panel", int(jp / 2.0))
	_apply_corner_radius(joystick_handle, "panel", int(hp / 2.0))
	_apply_corner_radius(jump_button, "normal", int(bp / 2.0))


# Returns 1.0 on desktop / editor / large devices. Linearly ramps up to
# MOBILE_BOOST_MAX as the physical screen narrows from MOBILE_REF_WIDTH down
# to MOBILE_MIN_WIDTH. Below MOBILE_MIN_WIDTH it clamps at the max.
func _mobile_size_boost() -> float:
	if not OS.has_feature("mobile"):
		return 1.0
	var screen_w: float = float(DisplayServer.screen_get_size().x)
	if screen_w <= 0.0:
		return MOBILE_BOOST_MIN
	if screen_w <= MOBILE_MIN_WIDTH:
		return MOBILE_BOOST_MAX
	if screen_w >= MOBILE_REF_WIDTH:
		return MOBILE_BOOST_MIN
	var t: float = (MOBILE_REF_WIDTH - screen_w) / (MOBILE_REF_WIDTH - MOBILE_MIN_WIDTH)
	return lerp(MOBILE_BOOST_MIN, MOBILE_BOOST_MAX, t)


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


func _on_touch_pressed(touch_position: Vector2, touch_id: int) -> void:
	var joystick_rect = joystick_base.get_global_rect()
	var jump_rect = jump_button.get_global_rect()

	# Check if touch is on joystick
	if joystick_rect.has_point(touch_position):
		_joystick_touch_id = touch_id
		_update_joystick(touch_position)
	# Check if touch is on jump button
	elif jump_rect.has_point(touch_position):

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
