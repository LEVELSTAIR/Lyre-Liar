extends Node

## Global signal bus for communication between nodes that don't share a
## parent (gameplay → HUD, gameplay → progress, etc.). Parent/child
## communication should keep using direct signals and method calls.

signal player_hp_changed(current: int, maximum: int)
signal player_died
signal player_respawned

signal fruit_collected(collected: int, total: int)
signal checkpoint_reached(respawn_position: Vector2)

signal level_started(level_id: StringName)
signal level_completed(result: LevelResult)
signal pause_toggled(is_paused: bool)
