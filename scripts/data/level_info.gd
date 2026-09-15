class_name LevelInfo
extends Resource

## Static metadata for one playable level. Instances live in
## `res://data/levels/` and are listed, in play order, by the LevelCatalog.

## Stable identifier. Also sent to the Colyseus server as the room "mode",
## so it must match the server's allowed mode list.
@export var id: StringName

@export var title: String = ""
@export var subtitle: String = ""
@export_file("*.tscn") var scene_path: String = ""

## Accent color used by menus when showing this level.
@export var accent_color: Color = Color.WHITE
