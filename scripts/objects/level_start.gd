class_name LevelStart
extends Node2D

## Start marker. Its position (the marker's base) is where players spawn;
## multiple players are spread horizontally by `spawn_spacing`.

@export var spawn_spacing: float = 20.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	sprite.play(&"moving")


func spawn_position(player_index: int) -> Vector2:
	# Alternate players left and right of the marker: 0, +1, -1, +2, -2 ...
	var slot := ceili(player_index / 2.0) * (1 if player_index % 2 == 1 else -1)
	return global_position + Vector2(slot * spawn_spacing, 0.0)
