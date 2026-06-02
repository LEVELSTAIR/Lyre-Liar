extends Area2D

## Restores 1 HP to the player on contact, then despawns. Works in
## single-player (the only player in the scene is the local one) and is
## intentionally minimal — multiplayer-sync of pickup state is a follow-up.

const HEAL_AMOUNT: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if "is_local_player" in body and body.is_local_player and body.has_method("heal"):
		body.heal(HEAL_AMOUNT)
		queue_free()
