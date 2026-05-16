## Mirrors PlayerState in colyseus_server/index.js. Field order MUST match.
class_name WerewolfPlayerState
extends Schema

var x: float = 0.0
var y: float = 0.0
var vx: float = 0.0
var vy: float = 0.0
var tick: float = 0.0

func _init() -> void:
	super()
	_define_field(0, "x", "number")
	_define_field(1, "y", "number")
	_define_field(2, "vx", "number")
	_define_field(3, "vy", "number")
	_define_field(4, "tick", "number")
