extends RefCounted

## Menu and overlay checks run inside the smoke runner. Drives the real
## screens by pressing their buttons, the way a player would.

const STEP_TIMEOUT_FRAMES := 600

var failures: Array[String] = []
## Number of expectations evaluated, printed by the runner as a sanity check.
var checks_run: int = 0
var _tree: SceneTree


func run(tree: SceneTree) -> void:
	_tree = tree
	GameProgress.reset_progress()
	await _check_title_to_level()
	await _check_pause_menu()
	await _check_death_menu()
	await _check_level_complete_and_next()
	await _check_settings_screen()
	await _check_multiplayer_screen()


func _check_title_to_level() -> void:
	if not await _open(SceneRouter.TITLE_SCENE):
		return
	var title := _tree.current_scene
	_press(title, "PlayButton")
	if not await _wait_for_scene(SceneRouter.LEVEL_SELECT_SCENE, "title: PLAY opens level select"):
		return

	var cards := _descendants_of(_tree.current_scene, LevelCard)
	var catalog := LevelCatalog.load_default()
	_expect(cards.size() == catalog.levels.size(), "level select: one card per level (%d)" % cards.size())
	if cards.size() < 2:
		return
	_expect(not (cards[0] as LevelCard).disabled, "level select: first level unlocked")
	_expect((cards[1] as LevelCard).disabled, "level select: second level locked on fresh progress")
	(cards[0] as LevelCard).pressed.emit()
	if not await _wait_for_scene(SceneRouter.CHARACTER_SELECT_SCENE, "level select: card opens character select"):
		return

	var character_cards := _descendants_of(_tree.current_scene, CharacterCard)
	_expect(character_cards.size() == CharacterCatalog.load_default().characters.size(), "character select: one card per character")
	var selected := character_cards.filter(func(card: CharacterCard) -> bool: return card.button_pressed)
	_expect(selected.size() == 1, "character select: exactly one character selected")
	(character_cards[-1] as CharacterCard).pressed.emit()
	(character_cards[-1] as CharacterCard).button_pressed = true
	_press(_tree.current_scene, "ContinueButton")
	if not await _wait_for_scene(catalog.first_level().scene_path, "character select: START loads the level"):
		return
	_expect(MultiplayerManager.selected_character == CharacterCatalog.load_default().characters[-1].id, "character select: chosen character is used")
	_expect(_descendants_of(_tree.current_scene, Hud).size() == 1, "level: HUD is shown")


func _check_pause_menu() -> void:
	var pause_menu := _overlay("PauseMenu") as PauseMenu
	if pause_menu == null:
		failures.append("pause: pause menu missing from level")
		return
	Events.pause_requested.emit()
	await _frames(2)
	_expect(pause_menu.is_open and _tree.paused, "pause: HUD pause request opens the menu and pauses")
	_press(pause_menu, "ResumeButton")
	await _frames(2)
	_expect(not pause_menu.is_open and not _tree.paused, "pause: RESUME closes the menu and unpauses")


func _check_death_menu() -> void:
	var level := _tree.current_scene as Level
	var player := level.get_node("Players/local") as Player
	var death_menu := _overlay("DeathMenu") as DeathMenu
	player.kill()
	await _frames(2)
	_expect(death_menu.is_open and _tree.paused, "death: dying opens the death menu and pauses")
	_press(death_menu, "RespawnButton")
	await _frames(4)
	_expect(not death_menu.is_open and player.is_alive() and not _tree.paused, "death: RESPAWN revives the player")
	_expect(level.deaths == 1, "death: death counted for the results screen")


func _check_level_complete_and_next() -> void:
	var level := _tree.current_scene as Level
	var player := level.get_node("Players/local") as Player
	var complete_menu := _overlay("LevelCompleteMenu") as LevelCompleteMenu
	player.global_position = level.level_goal.global_position
	if not await _wait_until(func() -> bool: return complete_menu.is_open):
		failures.append("complete: reaching the goal did not open the results screen")
		return
	_expect(_tree.paused, "complete: results screen pauses single-player")
	var next_button := complete_menu.find_child("NextButton") as Button
	_expect(next_button.visible, "complete: NEXT LEVEL offered after the first level")
	next_button.pressed.emit()
	var next_level := LevelCatalog.load_default().next_level(level.level_id)
	await _wait_for_scene(next_level.scene_path, "complete: NEXT LEVEL loads %s" % next_level.id)


func _check_settings_screen() -> void:
	if not await _open(SceneRouter.SETTINGS_SCENE):
		return
	var screen := _tree.current_scene
	var touch := screen.find_child("TouchControls") as OptionButton
	var previous := GameProgress.touch_controls
	touch.select(touch.get_item_index(GameProgress.TouchControls.NEVER))
	touch.item_selected.emit(touch.selected)
	_expect(GameProgress.touch_controls == GameProgress.TouchControls.NEVER, "settings: touch controls choice is saved")
	GameProgress.update_settings(previous, GameProgress.fullscreen)


func _check_multiplayer_screen() -> void:
	MenuFlow.mode = MenuFlow.Mode.MULTIPLAYER
	if not await _open(SceneRouter.MULTIPLAYER_SCENE):
		return
	var picker := _tree.current_scene.find_child("LevelPicker") as OptionButton
	_expect(picker.item_count == LevelCatalog.load_default().levels.size(), "multiplayer: host can pick any level")
	var code := _tree.current_scene.find_child("CodeInput") as LineEdit
	code.text = "AB"
	_press(_tree.current_scene, "JoinButton")
	await _frames(2)
	var status := _tree.current_scene.find_child("Status") as Label
	_expect(status.text.contains("4 characters"), "multiplayer: short room code is rejected before connecting")
	MenuFlow.mode = MenuFlow.Mode.SINGLE_PLAYER


# ─── Helpers ──────────────────────────────────────────────────────────────────

func _open(scene_path: String) -> bool:
	SceneRouter.go_to(scene_path)
	return await _wait_for_scene(scene_path, "%s did not open" % scene_path)


func _wait_for_scene(scene_path: String, description: String) -> bool:
	var loaded := await _wait_until(func() -> bool:
		var scene := _tree.current_scene
		return scene != null and scene.scene_file_path == scene_path and not SceneRouter.is_transitioning)
	if not loaded:
		failures.append(description)
	return loaded


## All descendants that are instances of `type` (a script class).
func _descendants_of(root: Node, type: Variant) -> Array:
	return root.find_children("*", "", true, false).filter(func(node: Node) -> bool: return is_instance_of(node, type))


func _overlay(node_name: String) -> Node:
	return _tree.current_scene.get_node_or_null(node_name)


func _press(root: Node, button_name: String) -> void:
	var button := root.find_child(button_name, true, false) as BaseButton
	if button == null:
		failures.append("button %s not found in %s" % [button_name, root.name])
		return
	button.pressed.emit()


func _wait_until(condition: Callable) -> bool:
	for i in STEP_TIMEOUT_FRAMES:
		if condition.call():
			return true
		await _tree.process_frame
	return false


func _frames(count: int) -> void:
	for i in count:
		await _tree.process_frame


func _expect(condition: bool, message: String) -> void:
	checks_run += 1
	if not condition:
		failures.append(message)
