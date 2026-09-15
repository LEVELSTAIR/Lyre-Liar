class_name CharacterData
extends Resource

## A selectable player skin. `sprite_frames` must contain the animations
## listed in REQUIRED_ANIMATIONS.

const REQUIRED_ANIMATIONS: Array[StringName] = [
	&"idle", &"run", &"jump", &"double_jump", &"fall", &"wall_slide", &"hit",
]

## Stable identifier stored in MultiplayerManager.selected_character.
@export var id: StringName
@export var display_name: String = ""
@export var sprite_frames: SpriteFrames
