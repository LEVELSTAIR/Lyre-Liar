class_name LevelGoal
extends Area2D

## End trophy. Emits `reached` once when the local player touches it.

signal reached(player: Player)

var is_reached: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	collision_layer = PhysicsLayers.TRIGGERS
	collision_mask = PhysicsLayers.PLAYER
	body_entered.connect(_on_body_entered)
	sprite.play(&"idle")


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if is_reached or player == null or not player.is_local_player or not player.is_alive():
		return
	is_reached = true
	sprite.play(&"pressed")
	reached.emit(player)
