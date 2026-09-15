extends MenuScreen

## Pick a character, then start the chosen level (single-player) or continue
## to the host/join screen (multiplayer).

const CHARACTER_CARD_SCENE := preload("res://scenes/ui/components/character_card.tscn")

var _selected: CharacterData

@onready var _cards: HBoxContainer = %Cards
@onready var _back_button: Button = %BackButton
@onready var _continue_button: Button = %ContinueButton
@onready var _subtitle: Label = %Subtitle


func _ready() -> void:
	var is_multiplayer := MenuFlow.mode == MenuFlow.Mode.MULTIPLAYER
	back_scene = SceneRouter.TITLE_SCENE if is_multiplayer else SceneRouter.LEVEL_SELECT_SCENE
	_back_button.pressed.connect(go_back)
	_continue_button.pressed.connect(_on_continue_pressed)
	_continue_button.text = "CONTINUE" if is_multiplayer else "START"
	var level := LevelCatalog.load_default().get_level(MenuFlow.level_id)
	_subtitle.text = "Multiplayer" if is_multiplayer or level == null else level.title

	var group := ButtonGroup.new()
	var selected_card: CharacterCard
	for character in CharacterCatalog.load_default().characters:
		var card: CharacterCard = CHARACTER_CARD_SCENE.instantiate()
		card.button_group = group
		_cards.add_child(card)
		card.setup(character)
		card.toggled.connect(func(is_selected: bool) -> void:
			if is_selected:
				_selected = character)
		if character.id == GameProgress.last_character or selected_card == null:
			selected_card = card
	selected_card.button_pressed = true
	initial_focus = selected_card
	super()


func _on_continue_pressed() -> void:
	GameProgress.remember_character(_selected.id)
	MultiplayerManager.selected_character = _selected.id
	if MenuFlow.mode == MenuFlow.Mode.MULTIPLAYER:
		SceneRouter.go_to(SceneRouter.MULTIPLAYER_SCENE)
		return
	var level := LevelCatalog.load_default().get_level(MenuFlow.level_id)
	if level == null:
		level = LevelCatalog.load_default().first_level()
	MultiplayerManager.start_single_player(level.id)
	SceneRouter.go_to_level(level)
