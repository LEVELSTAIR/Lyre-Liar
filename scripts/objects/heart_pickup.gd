@tool
class_name HeartPickup
extends Pickup

## Restores HP. Left in place when the player is already at full health.

@export_range(1, 3) var heal_amount: int = 1


func _apply(player: Player) -> bool:
	return player.heal(heal_amount)
