class_name CharacterCard
extends Button

## Toggle card with an animated character preview. The selected card runs.

var character: CharacterData

@onready var _preview: CharacterPreview = %Preview
@onready var _name: Label = %Name


func _ready() -> void:
	toggled.connect(_on_toggled)


func setup(character_data: CharacterData) -> void:
	character = character_data
	_preview.character = character
	_name.text = character.display_name.to_upper()


func _on_toggled(is_selected: bool) -> void:
	_preview.animation = &"run" if is_selected else &"idle"
