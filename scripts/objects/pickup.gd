@tool
class_name Pickup
extends Area2D

## Base for collectibles. Subclasses decide whether the player may take it in
## `_apply(player)`; on success the pickup plays its "collected" animation,
## emits `collected`, and frees itself.

signal collected(pickup: Pickup)

var is_collected: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = PhysicsLayers.PICKUPS
	collision_mask = PhysicsLayers.PLAYER
	body_entered.connect(_on_body_entered)
	sprite.play(&"idle")


## Returns true if the pickup was consumed by `player`.
func _apply(_player: Player) -> bool:
	return true


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if is_collected or player == null or not player.is_local_player or not player.is_alive():
		return
	if not _apply(player):
		return
	is_collected = true
	set_deferred(&"monitoring", false)
	collected.emit(self)
	sprite.play(&"collected")
	await sprite.animation_finished
	queue_free()
