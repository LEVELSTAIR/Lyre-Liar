@tool
class_name ScrollingBackground
extends CanvasLayer

## Full-screen tiled background (Pixel Adventure 64x64 tiles) that drifts
## slowly, drawn behind the level independently of the camera.

@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			_tiles.texture = value
## Screen pixels per background pixel; match the level camera zoom.
@export var pixel_scale: float = 2.0
## Drift speed in background pixels per second.
@export var scroll_velocity: Vector2 = Vector2(0, 12)

var _offset: Vector2 = Vector2.ZERO

@onready var _tiles: TextureRect = $Tiles


func _ready() -> void:
	layer = -10
	_tiles.texture = texture
	get_viewport().size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()


func _process(delta: float) -> void:
	if texture == null:
		return
	var tile := texture.get_size() * pixel_scale
	_offset = (_offset + scroll_velocity * pixel_scale * delta).posmodv(tile)
	_tiles.position = _offset - tile


func _fit_to_viewport() -> void:
	if texture == null:
		return
	var tile := texture.get_size() * pixel_scale
	_tiles.scale = Vector2.ONE * pixel_scale
	# One extra tile on every side so the drift never shows an edge.
	_tiles.size = (get_viewport().get_visible_rect().size + tile * 2.0) / pixel_scale
