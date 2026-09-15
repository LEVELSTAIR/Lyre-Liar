extends RefCounted

## Player controller checks run inside the smoke runner (autoloads active).
## Builds a small arena (floor + wall), spawns the local player, and drives it
## with simulated input actions.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const FLOOR_Y := 0.0

var failures: Array[String] = []
var _tree: SceneTree
var _arena: Node2D
## Whether the double jump was consumed right after it was performed.
var _double_jump_consumed: bool = false


func run(tree: SceneTree) -> void:
	_tree = tree
	MultiplayerManager.start_single_player(&"day")
	await _check_run_and_jump()
	await _check_double_jump()
	await _check_wall_slide_and_wall_jump()
	await _check_damage_death_and_respawn()
	await _check_enemy_stomp()


func _check_run_and_jump() -> void:
	var player := await _spawn(Vector2(0, FLOOR_Y))
	_press(&"move_right")
	await _physics_frames(30)
	_release(&"move_right")
	_expect(player.global_position.x > 20.0, "run: player moved right (x=%.1f)" % player.global_position.x)
	_expect(player.state_machine.is_in(&"Run") or player.state_machine.is_in(&"Idle"), "run: grounded state after running")

	await _physics_frames(20)
	var ground_y := player.global_position.y
	var peak := await _jump_and_measure_peak(player, false)
	_expect(ground_y - peak > 35.0, "jump: rises at least ~2 tiles (rose %.1f px)" % (ground_y - peak))
	await _physics_frames(60)
	_expect(player.is_on_floor(), "jump: lands back on the floor")
	await _free_arena()


func _check_double_jump() -> void:
	var player := await _spawn(Vector2(0, FLOOR_Y))
	await _physics_frames(10)
	var ground_y := player.global_position.y
	var single_peak := ground_y - await _jump_and_measure_peak(player, false)
	await _physics_frames(90)
	var double_peak := ground_y - await _jump_and_measure_peak(player, true)
	_expect(double_peak > single_peak + 20.0, "double jump: goes higher than a single jump (%.1f vs %.1f)" % [double_peak, single_peak])
	_expect(_double_jump_consumed, "double jump: consumed until landing")
	await _physics_frames(120)
	_expect(player.can_double_jump, "double jump: restored after landing")
	await _free_arena()


func _check_wall_slide_and_wall_jump() -> void:
	# Wall at x = 60; start in the air next to it.
	var player := await _spawn(Vector2(40, -120))
	_press(&"move_right")
	await _physics_frames(40)
	_expect(player.state_machine.is_in(&"WallSlide"), "wall slide: entered when falling into a wall (state=%s)" % player.state_machine.current_state.name)
	_expect(player.velocity.y <= player.wall_slide_speed + 0.5, "wall slide: fall speed capped (vy=%.1f)" % player.velocity.y)
	_tap(&"jump")
	await _physics_frames(2)
	_release(&"jump")
	_expect(player.velocity.x < -50.0 and player.velocity.y < 0.0, "wall jump: kicks up and away from the wall (v=%s)" % player.velocity)
	_release(&"move_right")
	await _physics_frames(90)
	await _free_arena()


func _check_damage_death_and_respawn() -> void:
	var player := await _spawn(Vector2(0, FLOOR_Y))
	await _physics_frames(10)
	var hp_events: Array[int] = []
	player.hp_changed.connect(func(current: int, _maximum: int) -> void: hp_events.append(current))
	player.take_damage(1, player.global_position + Vector2(10, 0))
	await _physics_frames(2)
	_expect(player.current_hp == Player.MAX_HP - 1, "damage: HP decreased")
	_expect(player.state_machine.is_in(&"Hit"), "damage: Hit state entered")
	player.take_damage(1)
	_expect(player.current_hp == Player.MAX_HP - 1, "damage: invincibility frames block immediate re-hit")

	var died := [false]
	player.died.connect(func() -> void: died[0] = true)
	for i in Player.MAX_HP:
		player.health._invincibility_left = 0.0
		player.take_damage(1)
	await _physics_frames(2)
	_expect(died[0] and player.state_machine.is_in(&"Dead"), "death: died emitted and Dead state entered")

	player.respawn()
	await _physics_frames(2)
	_expect(player.current_hp == Player.MAX_HP and player.state_machine.is_in(&"Idle"), "respawn: full HP and Idle")
	_expect(hp_events.size() >= 3, "damage: hp_changed emitted for each change")
	await _free_arena()


func _check_enemy_stomp() -> void:
	var player := await _spawn(Vector2(0, -60))
	var enemy := StompableDummy.new()
	enemy.add_to_group(&"enemies")
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	(shape.shape as RectangleShape2D).size = Vector2(40, 16)
	enemy.add_child(shape)
	enemy.position = Vector2(0, -8)
	_arena.add_child(enemy)
	await _physics_frames(40)
	_expect(enemy.stomped, "stomp: landing on an enemy calls stomp()")
	_expect(player.current_hp == Player.MAX_HP, "stomp: no damage when landing on top")
	await _free_arena()


# ─── Helpers ──────────────────────────────────────────────────────────────────

func _spawn(at: Vector2) -> Player:
	_arena = Node2D.new()
	_tree.root.add_child(_arena)
	_add_static_box(Rect2(-400, FLOOR_Y, 800, 32))
	_add_static_box(Rect2(60, -400, 32, 400))
	var player: Player = PLAYER_SCENE.instantiate()
	player.session_id = MultiplayerManager.session_id
	player.name = "TestPlayer"
	player.position = at
	_arena.add_child(player)
	await _physics_frames(2)
	return player


func _add_static_box(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	_arena.add_child(body)


func _jump_and_measure_peak(player: Player, double: bool) -> float:
	_tap(&"jump")
	await _physics_frames(1)
	_release(&"jump")
	var peak := player.global_position.y
	for i in 90:
		if double and i == 12:
			_tap(&"jump")
			# The press is seen on the next physics step; sample after it.
			await _physics_frames(2)
			_release(&"jump")
			_double_jump_consumed = not player.can_double_jump
		await _physics_frames(1)
		peak = minf(peak, player.global_position.y)
	return peak


func _free_arena() -> void:
	for action in [&"move_left", &"move_right", &"jump"]:
		Input.action_release(action)
	_arena.queue_free()
	await _physics_frames(1)


func _press(action: StringName) -> void:
	Input.action_press(action)


func _release(action: StringName) -> void:
	Input.action_release(action)


func _tap(action: StringName) -> void:
	Input.action_press(action)


func _physics_frames(count: int) -> void:
	for i in count:
		await _tree.physics_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


class StompableDummy extends StaticBody2D:
	var stomped := false

	func stomp() -> void:
		stomped = true
