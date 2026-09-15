class_name CharacterCatalog
extends Resource

## Every selectable character, in menu order.

const DEFAULT_PATH := "res://data/characters/character_catalog.tres"

@export var characters: Array[CharacterData] = []


static func load_default() -> CharacterCatalog:
	return load(DEFAULT_PATH) as CharacterCatalog


## Returns the character with `id`, falling back to the first entry.
func get_character(id: StringName) -> CharacterData:
	for character in characters:
		if character.id == id:
			return character
	return characters[0] if not characters.is_empty() else null
