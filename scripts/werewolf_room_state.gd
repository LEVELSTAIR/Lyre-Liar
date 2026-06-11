## Mirrors WerewolfRoomState in colyseus_server/index.js. Field order MUST match.
class_name WerewolfRoomState
extends Schema

var players: MapSchema
var roomCode: String = ""
var mode: String = "day"
var hostSessionId: String = ""

func _init() -> void:
	super()
	players = MapSchema.new("WerewolfPlayerState")
	_define_field(0, "players", "map:ref:WerewolfPlayerState")
	_define_field(1, "roomCode", "string")
	_define_field(2, "mode", "string")
	_define_field(3, "hostSessionId", "string")
	register_schema_type("WerewolfPlayerState", func(): return WerewolfPlayerState.new())
