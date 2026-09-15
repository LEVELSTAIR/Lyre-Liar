class_name Level
extends Node2D

## Base for every playable level (scenes/levels/level_base.tscn). Level
## scenes inherit the base scene and only add layout: terrain tiles and
## instances under Objects, Pickups, Enemies, and Checkpoints.
##
## Responsibilities: spawn local and remote players at LevelStart, keep the
## camera inside the terrain, count fruits, handle death and respawn, and
## report the result when the goal is reached.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/pause_menu.tscn")
const DEATH_MENU_SCENE := preload("res://scenes/death_menu.tscn")
const COMPLETE_MENU_SCENE := preload("res://scenes/level_complete_menu.tscn")
const HEALTH_HUD_SCENE := preload("res://scenes/health_hud.tscn")

## Seconds before a player respawns automatically in multiplayer.
const MULTIPLAYER_RESPAWN_DELAY := 1.5
## Extra camera room around the terrain, in pixels.
const CAMERA_MARGIN := Vector2i(0, 160)

## Must match an id in data/levels/level_catalog.tres.
@export var level_id: StringName
@export var camera_zoom: Vector2 = Vector2(2, 2)

var run_time: float = 0.0
var deaths: int = 0
var fruits_collected: int = 0
var fruits_total: int = 0

var _local_player: Player
var _spawned_count: int = 0
var _completed: bool = false
var _death_menu: CanvasLayer
var _complete_menu: CanvasLayer
var _health_hud: CanvasLayer

@onready var terrain: TileMapLayer = $Terrain
@onready var players: Node2D = $Players
@onready var level_start: LevelStart = $LevelStart
@onready var level_goal: LevelGoal = $LevelGoal


func _ready() -> void:
	_add_overlays()
	_connect_fruits()
	level_goal.reached.connect(_on_goal_reached)

	MultiplayerManager.player_connected.connect(_spawn_player)
	MultiplayerManager.player_disconnected.connect(_remove_player)
	MultiplayerManager.connection_failed.connect(_on_connection_failed)
	for session_id in MultiplayerManager.active_players:
		_spawn_player(session_id)
	_show_room_code()
	Events.level_started.emit(level_id)


func _process(delta: float) -> void:
	if not _completed:
		run_time += delta


## World-space rectangle covered by terrain tiles.
func terrain_rect() -> Rect2i:
	var used := terrain.get_used_rect()
	var tile_size := terrain.tile_set.tile_size
	return Rect2i(used.position * tile_size, used.size * tile_size)


# ─── Players ──────────────────────────────────────────────────────────────────

func _spawn_player(session_id: String) -> void:
	if players.has_node(session_id):
		return
	var player: Player = PLAYER_SCENE.instantiate()
	player.name = session_id
	player.session_id = session_id
	player.camera_zoom = camera_zoom
	player.position = level_start.spawn_position(_spawned_count)
	_spawned_count += 1
	players.add_child(player)
	if not player.is_local_player:
		return
	_local_player = player
	var limits := terrain_rect().grow_individual(CAMERA_MARGIN.x, CAMERA_MARGIN.y, CAMERA_MARGIN.x, 0)
	player.camera.apply_limits(limits)
	player.died.connect(_on_local_player_died)
	player.hp_changed.connect(_health_hud.set_hp)
	_health_hud.set_hp(player.current_hp, Player.MAX_HP)


func _remove_player(session_id: String) -> void:
	var player := players.get_node_or_null(session_id)
	if player != null:
		player.queue_free()


func _on_local_player_died() -> void:
	deaths += 1
	if MultiplayerManager.is_single_player:
		_death_menu.show_death(_local_player)
		return
	# In multiplayer the tree can't pause for one player; respawn after a beat.
	await get_tree().create_timer(MULTIPLAYER_RESPAWN_DELAY).timeout
	if is_instance_valid(_local_player):
		_local_player.respawn()


# ─── Fruits and goal ──────────────────────────────────────────────────────────

func _connect_fruits() -> void:
	var fruits := get_tree().get_nodes_in_group(&"fruits").filter(func(node: Node) -> bool: return is_ancestor_of(node))
	fruits_total = fruits.size()
	for fruit: Fruit in fruits:
		fruit.collected.connect(_on_fruit_collected)
	Events.fruit_collected.emit(fruits_collected, fruits_total)


func _on_fruit_collected(_pickup: Pickup) -> void:
	fruits_collected += 1
	Events.fruit_collected.emit(fruits_collected, fruits_total)


func _on_goal_reached(_player: Player) -> void:
	if _completed:
		return
	_completed = true
	var result := LevelResult.new(level_id, run_time, fruits_collected, fruits_total, deaths)
	if MultiplayerManager.is_single_player:
		GameProgress.record_result(result)
	Events.level_completed.emit(result)
	_complete_menu.show_result(result)


# ─── Overlays and networking ──────────────────────────────────────────────────

func _add_overlays() -> void:
	add_child(PAUSE_MENU_SCENE.instantiate())
	_death_menu = DEATH_MENU_SCENE.instantiate()
	add_child(_death_menu)
	_complete_menu = COMPLETE_MENU_SCENE.instantiate()
	add_child(_complete_menu)
	_health_hud = HEALTH_HUD_SCENE.instantiate()
	add_child(_health_hud)


func _show_room_code() -> void:
	var code := MultiplayerManager.room_code
	if code.is_empty():
		code = MultiplayerManager.join_intent_code
	if code.is_empty():
		MultiplayerManager.room_code_ready.connect(_on_room_code_ready, CONNECT_ONE_SHOT)
		return
	_on_room_code_ready(code)


func _on_room_code_ready(code: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	var label := Label.new()
	label.name = "RoomCodeLabel"
	label.text = "Room: " + code
	label.position = Vector2(12, 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	layer.add_child(label)
	add_child(layer)


func _on_connection_failed(_reason: String) -> void:
	if MultiplayerManager.is_single_player:
		return
	MultiplayerManager.leave()
	SceneRouter.go_to_main_menu()
