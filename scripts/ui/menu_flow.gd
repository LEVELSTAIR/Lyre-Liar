class_name MenuFlow
extends RefCounted

## Choices carried between menu screens during one session (not saved).

enum Mode { SINGLE_PLAYER, MULTIPLAYER }

static var mode: Mode = Mode.SINGLE_PLAYER
## Level picked on the level-select screen (single-player).
static var level_id: StringName = &""
