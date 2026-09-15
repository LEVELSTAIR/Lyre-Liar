class_name HealthComponent
extends Node

## Hit points with post-hit invincibility. Reusable by any entity that can be
## damaged; the owner reacts through the signals.

signal health_changed(current: int, maximum: int)
signal damaged(amount: int)
signal died

@export_range(1, 99) var max_health: int = 3
## Seconds of damage immunity after taking a hit.
@export_range(0.0, 5.0, 0.05) var invincibility_seconds: float = 1.0

var current_health: int
var _invincibility_left: float = 0.0


func _ready() -> void:
	current_health = max_health


func _process(delta: float) -> void:
	if _invincibility_left > 0.0:
		_invincibility_left = maxf(0.0, _invincibility_left - delta)


func is_alive() -> bool:
	return current_health > 0


func is_invincible() -> bool:
	return _invincibility_left > 0.0


## Applies damage unless dead or invincible. Returns true if it was applied.
func take_damage(amount: int = 1) -> bool:
	if amount <= 0 or not is_alive() or is_invincible():
		return false
	current_health = maxi(0, current_health - amount)
	_invincibility_left = invincibility_seconds
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()
	return true


## Restores health up to the maximum. Returns true only if health changed.
func heal(amount: int = 1) -> bool:
	if amount <= 0 or not is_alive() or current_health == max_health:
		return false
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
	return true


## Drops health to zero regardless of invincibility (pits, kill zones).
func kill() -> void:
	if not is_alive():
		return
	current_health = 0
	health_changed.emit(current_health, max_health)
	died.emit()


func reset() -> void:
	current_health = max_health
	_invincibility_left = 0.0
	health_changed.emit(current_health, max_health)
