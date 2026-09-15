extends RefCounted

## Gameplay object checks run inside the smoke runner (autoloads active).
## Each check builds a flat arena, spawns the local player and one object,
## and verifies the object's effect.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const OBJECTS := "res://scenes/objects/%s.tscn"

var failures: Array[String] = []
var _tree: SceneTree
var _arena: Node2D


func run(tree: SceneTree) -> void:
	_tree = tree
	MultiplayerManager.start_single_player(&"day")
	await _check_spikes()
	await _check_kill_zone()
	await _check_fruit()
	await _check_heart_pickup()
	await _check_checkpoint()
	await _check_level_goal()
	await _check_trampoline()
	await _check_saw_and_spiked_ball()
	await _check_fire_trap()
	await _check_moving_platform()
	await _check_falling_platform()
	await _check_fan()
	await _check_pig()


func _check_spikes() -> void:
	var player := await _setup(Vector2(-60, 0))
	_add_object("spikes", Vector2(0, 0))
	player.global_position = Vector2(0, 0)
	await _frames(5)
	_expect(player.current_hp < Player.MAX_HP, "spikes: standing on spikes hurts the player")
	await _teardown()


func _check_kill_zone() -> void:
	var player := await _setup(Vector2(-60, 0))
	var died := [false]
	player.died.connect(func() -> void: died[0] = true)
	_add_object("kill_zone", Vector2(0, 200))
	player.global_position = Vector2(500, -40)  # past the floor's edge, so it falls
	await _frames(90)
	_expect(died[0], "kill_zone: falling into it kills the player")
	await _teardown()


func _check_fruit() -> void:
	var player := await _setup(Vector2(-60, 0))
	var fruit: Fruit = _add_object("fruit", Vector2(0, -10))
	fruit.kind = Fruit.Kind.MELON
	var collected := [false]
	fruit.collected.connect(func(_pickup: Pickup) -> void: collected[0] = true)
	player.global_position = Vector2(0, 0)
	await _frames(40)
	_expect(collected[0], "fruit: touching it emits collected")
	_expect(not is_instance_valid(fruit), "fruit: frees itself after the collected animation")
	await _teardown()


func _check_heart_pickup() -> void:
	var player := await _setup(Vector2(-60, 0))
	var heart: HeartPickup = _add_object("heart_pickup", Vector2(0, -10))
	player.global_position = Vector2(0, 0)
	await _frames(5)
	_expect(not heart.is_collected, "heart: not consumed at full health")
	player.global_position = Vector2(-60, 0)
	await _frames(5)
	player.take_damage(1)
	await _frames(30)
	player.global_position = Vector2(0, 0)
	await _frames(5)
	_expect(heart.is_collected and player.current_hp == Player.MAX_HP, "heart: heals when damaged")
	await _teardown()


func _check_checkpoint() -> void:
	var player := await _setup(Vector2(-60, 0))
	var checkpoint: Checkpoint = _add_object("checkpoint", Vector2(40, 0))
	var reached := [false]
	Events.checkpoint_reached.connect(func(_position: Vector2) -> void: reached[0] = true, CONNECT_ONE_SHOT)
	player.global_position = Vector2(40, 0)
	await _frames(5)
	_expect(checkpoint.is_active and reached[0], "checkpoint: activates and emits checkpoint_reached")
	_expect(player.spawn_point.is_equal_approx(checkpoint.global_position), "checkpoint: moves the respawn point")
	await _teardown()


func _check_level_goal() -> void:
	var player := await _setup(Vector2(-60, 0))
	var goal: LevelGoal = _add_object("level_goal", Vector2(40, 0))
	var reached := [false]
	goal.reached.connect(func(_player: Player) -> void: reached[0] = true)
	player.global_position = Vector2(40, 0)
	await _frames(5)
	_expect(reached[0], "level_goal: emits reached when touched")
	await _teardown()


func _check_trampoline() -> void:
	var player := await _setup(Vector2(0, -80))
	_add_object("trampoline", Vector2(0, 0))
	var min_velocity := 0.0
	for i in 60:
		await _frames(1)
		min_velocity = minf(min_velocity, player.velocity.y)
	_expect(min_velocity < -380.0, "trampoline: launches the player (min vy %.0f)" % min_velocity)
	await _teardown()


func _check_saw_and_spiked_ball() -> void:
	await _setup(Vector2(-200, 0))
	var saw: Saw = _add_object("saw", Vector2(0, -60))
	var ball: SpikedBall = _add_object("spiked_ball", Vector2(100, -120))
	var blade := saw.get_node("Blade") as Node2D
	var ball_node := ball.get_node("Ball") as Node2D
	var blade_start := blade.position
	var ball_start := ball_node.position
	await _frames(30)
	_expect(not blade.position.is_equal_approx(blade_start), "saw: blade moves along its path")
	_expect(not ball_node.position.is_equal_approx(ball_start), "spiked_ball: ball swings")
	await _teardown()


func _check_fire_trap() -> void:
	await _setup(Vector2(-200, 0))
	var trap: FireTrap = _add_object("fire_trap", Vector2(0, 0))
	var flame := trap.get_node("Flame") as Area2D
	await _frames(2)
	var was_off := not flame.monitoring
	var became_on := false
	# Default cycle: off_seconds, then the ignite animation, then on.
	for i in int((trap.off_seconds + 0.6) * Engine.physics_ticks_per_second):
		await _frames(1)
		became_on = became_on or flame.monitoring
	_expect(was_off and became_on, "fire_trap: flame starts off and turns on during the cycle")
	await _teardown()


func _check_moving_platform() -> void:
	var player := await _setup(Vector2(-200, 0))
	var platform: MovingPlatform = _add_object("moving_platform", Vector2(0, -40))
	player.global_position = Vector2(0, -60)
	await _frames(20)
	var player_start_x := player.global_position.x
	await _frames(60)
	_expect(platform.position.x > 5.0, "moving_platform: moves along travel")
	_expect(player.global_position.x > player_start_x + 5.0, "moving_platform: carries a standing player")
	await _teardown()


func _check_falling_platform() -> void:
	var player := await _setup(Vector2(-200, 0))
	var platform: FallingPlatform = _add_object("falling_platform", Vector2(0, -60))
	platform.respawn_seconds = 0.3
	var start_y := platform.position.y
	player.global_position = Vector2(0, -80)
	var fell := false
	for i in 120:
		await _frames(1)
		fell = fell or platform.position.y > start_y + 10.0
	_expect(fell, "falling_platform: falls after the player lands on it")
	await _frames(60)
	_expect(is_equal_approx(platform.position.y, start_y), "falling_platform: returns to its start position")
	await _teardown()


func _check_fan() -> void:
	var player := await _setup(Vector2(-200, 0))
	_add_object("fan", Vector2(0, 0))
	player.global_position = Vector2(0, -12)
	var start_y := player.global_position.y
	await _frames(20)
	_expect(player.global_position.y < start_y - 10.0, "fan: lifts the player (dy %.1f)" % (player.global_position.y - start_y))
	await _teardown()


func _check_pig() -> void:
	# Pig on a short ledge must turn around instead of walking off it.
	var player := await _setup(Vector2(-300, 0))
	_add_box(Rect2(100, -40, 64, 16))
	var pig: Pig = _add_object("pig", Vector2(130, -40))
	await _frames(240)
	_expect(pig.global_position.y < -30.0, "pig: stays on its ledge (y=%.1f)" % pig.global_position.y)

	var ground_pig: Pig = _add_object("pig", Vector2(-240, 0))
	ground_pig.walk_speed = 0.0
	await _frames(10)
	player.global_position = Vector2(-270, 0)
	player.velocity = Vector2.ZERO
	Input.action_press(&"move_right")
	await _frames(20)
	Input.action_release(&"move_right")
	_expect(player.current_hp < Player.MAX_HP, "pig: side contact hurts the player")

	var defeated := [false]
	pig.defeated.connect(func(_pig: Pig) -> void: defeated[0] = true)
	player.health.reset()
	player.global_position = pig.global_position + Vector2(0, -40)
	player.velocity = Vector2.ZERO
	await _frames(40)
	_expect(defeated[0], "pig: landing on it defeats it")
	_expect(player.current_hp == Player.MAX_HP, "pig: stomping does not hurt the player")
	await _teardown()


# ─── Helpers ──────────────────────────────────────────────────────────────────

func _setup(player_position: Vector2) -> Player:
	_arena = Node2D.new()
	_tree.root.add_child(_arena)
	_add_box(Rect2(-400, 0, 800, 32))
	var player: Player = PLAYER_SCENE.instantiate()
	player.session_id = MultiplayerManager.session_id
	player.position = player_position
	_arena.add_child(player)
	await _frames(2)
	return player


func _add_object(scene_name: String, at: Vector2) -> Node2D:
	var node: Node2D = load(OBJECTS % scene_name).instantiate()
	node.position = at
	_arena.add_child(node)
	return node


func _add_box(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	_arena.add_child(body)


func _teardown() -> void:
	for action in [&"move_left", &"move_right", &"jump"]:
		Input.action_release(action)
	_arena.queue_free()
	await _frames(2)


func _frames(count: int) -> void:
	for i in count:
		await _tree.physics_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
