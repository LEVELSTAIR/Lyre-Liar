extends SceneTree

## Builds data/ui/lyre_liar_theme.tres, the single Theme used by every screen.
## Colors and fonts follow docs/design-system/colors_and_type.css:
##   godot --headless --path . -s res://tools/ui/build_theme.gd

const OUTPUT_PATH := "res://data/ui/lyre_liar_theme.tres"

const SHELL_VOID := Color("080f08")
const SHELL_PANEL := Color(0.05, 0.09, 0.06, 0.92)
const BRASS_RULE := Color("c78d2e")
const BRASS_DEEP := Color("522e0f")
const BRASS_GLOW := Color("d9b366")
const PARCHMENT := Color("f2e5d9")
const PARCHMENT_DIM := Color(0.95, 0.9, 0.85, 0.45)

const FONT_UI := preload("res://asset/Fonts/Jersey25-Regular.ttf")
const FONT_MONO := preload("res://asset/Fonts/VT323-Regular.ttf")
const FONT_DISPLAY := preload("res://asset/Fonts/Cinzel-VariableFont_wght.ttf")


func _init() -> void:
	var theme := Theme.new()
	theme.default_font = FONT_UI
	theme.default_font_size = 18

	_label(theme)
	_buttons(theme)
	_panels(theme)
	_inputs(theme)
	_title_variations(theme)

	var error := ResourceSaver.save(theme, OUTPUT_PATH)
	if error != OK:
		push_error("build_theme: failed to save %s (%d)" % [OUTPUT_PATH, error])
	quit()


func _label(theme: Theme) -> void:
	theme.set_color("font_color", "Label", PARCHMENT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.7))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)


func _buttons(theme: Theme) -> void:
	theme.set_stylebox("normal", "Button", _box(SHELL_PANEL, BRASS_RULE, 2))
	theme.set_stylebox("hover", "Button", _box(Color(0.12, 0.18, 0.1, 0.95), BRASS_GLOW, 2))
	theme.set_stylebox("pressed", "Button", _box(BRASS_DEEP, BRASS_GLOW, 2))
	theme.set_stylebox("disabled", "Button", _box(Color(0.05, 0.07, 0.05, 0.7), Color(0.4, 0.35, 0.3), 2))
	theme.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), PARCHMENT, 2, 4))
	for state in ["font_color", "font_focus_color"]:
		theme.set_color(state, "Button", PARCHMENT)
	theme.set_color("font_hover_color", "Button", BRASS_GLOW)
	theme.set_color("font_pressed_color", "Button", PARCHMENT)
	theme.set_color("font_disabled_color", "Button", PARCHMENT_DIM)
	theme.set_font_size("font_size", "Button", 18)

	# Flat icon buttons (Pixel Adventure menu icons) keep their own art.
	theme.set_type_variation("IconButton", "Button")
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled"]:
		theme.set_stylebox(state, "IconButton", empty)
	theme.set_stylebox("focus", "IconButton", _box(Color(0, 0, 0, 0), PARCHMENT, 1, 2))
	theme.set_color("icon_hover_color", "IconButton", BRASS_GLOW)
	theme.set_color("icon_pressed_color", "IconButton", BRASS_RULE)

	# Selectable cards (levels, characters). Toggle cards use "pressed" for
	# the selected look.
	theme.set_type_variation("CardButton", "Button")
	theme.set_stylebox("normal", "CardButton", _box(Color(0.04, 0.07, 0.05, 0.85), Color(0.45, 0.33, 0.15), 2))
	theme.set_stylebox("hover", "CardButton", _box(Color(0.1, 0.15, 0.09, 0.92), BRASS_GLOW, 2))
	theme.set_stylebox("pressed", "CardButton", _box(Color(0.2, 0.13, 0.05, 0.95), BRASS_GLOW, 3))
	theme.set_stylebox("hover_pressed", "CardButton", _box(Color(0.22, 0.15, 0.06, 0.95), PARCHMENT, 3))
	theme.set_stylebox("disabled", "CardButton", _box(Color(0.02, 0.03, 0.02, 0.8), Color(0.25, 0.22, 0.2), 2))
	theme.set_stylebox("focus", "CardButton", _box(Color(0, 0, 0, 0), PARCHMENT, 2, 3))

	theme.set_stylebox("normal", "CheckButton", StyleBoxEmpty.new())
	theme.set_stylebox("hover", "CheckButton", StyleBoxEmpty.new())
	theme.set_stylebox("pressed", "CheckButton", StyleBoxEmpty.new())
	theme.set_stylebox("focus", "CheckButton", _box(Color(0, 0, 0, 0), PARCHMENT, 1, 2))
	theme.set_color("font_color", "CheckButton", PARCHMENT)
	theme.set_color("font_hover_color", "CheckButton", BRASS_GLOW)


func _panels(theme: Theme) -> void:
	var panel := _box(SHELL_PANEL, BRASS_RULE, 2)
	panel.content_margin_left = 16
	panel.content_margin_right = 16
	panel.content_margin_top = 12
	panel.content_margin_bottom = 12
	theme.set_stylebox("panel", "PanelContainer", panel)

	# Selectable card (levels, characters) and its highlighted look.
	theme.set_type_variation("CardPanel", "PanelContainer")
	var card := _box(Color(0.04, 0.07, 0.05, 0.85), Color(0.45, 0.33, 0.15), 2)
	card.set_content_margin_all(8)
	theme.set_stylebox("panel", "CardPanel", card)

	theme.set_type_variation("HudPanel", "PanelContainer")
	var hud := _box(Color(0, 0, 0, 0.45), Color(0, 0, 0, 0), 0, 0, 4)
	hud.content_margin_left = 8
	hud.content_margin_right = 8
	hud.content_margin_top = 2
	hud.content_margin_bottom = 2
	theme.set_stylebox("panel", "HudPanel", hud)


func _inputs(theme: Theme) -> void:
	var field := _box(Color(0, 0, 0, 0.6), BRASS_RULE, 2)
	field.content_margin_left = 8
	field.content_margin_right = 8
	theme.set_stylebox("normal", "LineEdit", field)
	theme.set_stylebox("focus", "LineEdit", _box(Color(0, 0, 0, 0), PARCHMENT, 2))
	theme.set_font("font", "LineEdit", FONT_MONO)
	theme.set_font_size("font_size", "LineEdit", 22)
	theme.set_color("font_color", "LineEdit", PARCHMENT)
	theme.set_color("font_placeholder_color", "LineEdit", PARCHMENT_DIM)
	theme.set_color("caret_color", "LineEdit", BRASS_GLOW)

	theme.set_stylebox("normal", "OptionButton", _box(SHELL_PANEL, BRASS_RULE, 2))
	theme.set_stylebox("hover", "OptionButton", _box(Color(0.12, 0.18, 0.1, 0.95), BRASS_GLOW, 2))
	theme.set_stylebox("pressed", "OptionButton", _box(BRASS_DEEP, BRASS_GLOW, 2))
	theme.set_stylebox("focus", "OptionButton", _box(Color(0, 0, 0, 0), PARCHMENT, 2, 4))
	theme.set_color("font_color", "OptionButton", PARCHMENT)


func _title_variations(theme: Theme) -> void:
	# Game title: Cinzel caps with the brass-deep drop shadow.
	theme.set_type_variation("TitleLabel", "Label")
	theme.set_font("font", "TitleLabel", FONT_DISPLAY)
	theme.set_font_size("font_size", "TitleLabel", 44)
	theme.set_color("font_color", "TitleLabel", PARCHMENT)
	theme.set_color("font_shadow_color", "TitleLabel", Color(BRASS_DEEP, 0.9))
	theme.set_constant("shadow_offset_x", "TitleLabel", 0)
	theme.set_constant("shadow_offset_y", "TitleLabel", 3)

	theme.set_type_variation("HeaderLabel", "Label")
	theme.set_font_size("font_size", "HeaderLabel", 30)
	theme.set_color("font_color", "HeaderLabel", PARCHMENT)
	theme.set_color("font_shadow_color", "HeaderLabel", Color(BRASS_DEEP, 0.9))
	theme.set_constant("shadow_offset_y", "HeaderLabel", 2)

	theme.set_type_variation("SubtitleLabel", "Label")
	theme.set_font_size("font_size", "SubtitleLabel", 16)
	theme.set_color("font_color", "SubtitleLabel", BRASS_GLOW)

	theme.set_type_variation("MonoLabel", "Label")
	theme.set_font("font", "MonoLabel", FONT_MONO)
	theme.set_font_size("font_size", "MonoLabel", 22)
	theme.set_color("font_color", "MonoLabel", PARCHMENT)

	theme.set_type_variation("SmallLabel", "Label")
	theme.set_font_size("font_size", "SmallLabel", 14)
	theme.set_color("font_color", "SmallLabel", Color(PARCHMENT, 0.75))


func _box(background: Color, border: Color, border_width: int, expand: int = 0, radius: int = 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(6)
	box.expand_margin_left = expand
	box.expand_margin_right = expand
	box.expand_margin_top = expand
	box.expand_margin_bottom = expand
	box.anti_aliasing = false
	return box
