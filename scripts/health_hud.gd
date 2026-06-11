extends CanvasLayer

## Heart-row HUD shown in single-player. Listens to player.hp_changed (wired
## by the level) and recolors the heart polygons. Each heart is a Polygon2D
## (no texture needed) so it renders crisp at any zoom and stays on-brand.

const HEART_SPACING: float = 32.0       # px between heart centers
const HEART_DROP_SHADOW: Vector2 = Vector2(2, 2)

# state-died = #FF3333 for full hearts; muted gray for empty.
const COLOR_FULL := Color(1.0, 0.2, 0.2, 1.0)
const COLOR_EMPTY := Color(0.25, 0.25, 0.25, 0.6)
const COLOR_SHADOW := Color(0.0, 0.0, 0.0, 0.55)

# Stylised heart silhouette centered on (0, 0). Two upper lobes + V at bottom.
# Has to be a `var`, not a `const`, because GDScript can't const-init a
# PackedVector2Array literal.
var _heart_polygon: PackedVector2Array = PackedVector2Array([
	Vector2(0, -4), Vector2(4, -8), Vector2(8, -8), Vector2(12, -4),
	Vector2(12, 2), Vector2(0, 12), Vector2(-12, 2), Vector2(-12, -4),
	Vector2(-8, -8), Vector2(-4, -8), Vector2(0, -4),
])

@onready var _root: Control = $Root

# Holds the fill polygon for each heart slot; shadow polygons live underneath
# them in the tree but don't need to be tracked since they never change.
var _hearts: Array[Polygon2D] = []


func _ready() -> void:
	build(3)


## Rebuild the heart row for `max_hp` hearts. Idempotent — safe to call
## multiple times (e.g. if MAX_HP ever becomes dynamic).
func build(max_hp: int) -> void:
	for c in _root.get_children():
		c.queue_free()
	_hearts.clear()
	for i in max_hp:
		var center := Vector2(12 + i * HEART_SPACING, 12)
		var shadow := Polygon2D.new()
		shadow.polygon = _heart_polygon
		shadow.position = center + HEART_DROP_SHADOW
		shadow.color = COLOR_SHADOW
		_root.add_child(shadow)

		var heart := Polygon2D.new()
		heart.polygon = _heart_polygon
		heart.position = center
		heart.color = COLOR_FULL
		_root.add_child(heart)
		_hearts.append(heart)


## Repaint the row for the given hp values.
func set_hp(current: int, max_hp: int) -> void:
	if _hearts.size() != max_hp:
		build(max_hp)
	for i in _hearts.size():
		_hearts[i].color = COLOR_FULL if i < current else COLOR_EMPTY
