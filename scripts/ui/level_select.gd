extends MenuScreen

## Grid of level cards. Unlocked levels open the character screen.

const LEVEL_CARD_SCENE := preload("res://scenes/ui/components/level_card.tscn")

@onready var _cards: HBoxContainer = %Cards
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(go_back)
	var levels := LevelCatalog.load_default().levels
	var focus_card: LevelCard
	for i in levels.size():
		var card: LevelCard = LEVEL_CARD_SCENE.instantiate()
		_cards.add_child(card)
		card.setup(levels[i], i + 1)
		card.pressed.connect(_on_level_chosen.bind(levels[i]))
		# Focus the furthest level the player can play.
		if not card.disabled:
			focus_card = card
	initial_focus = focus_card
	super()


func _on_level_chosen(level: LevelInfo) -> void:
	MenuFlow.level_id = level.id
	SceneRouter.go_to(SceneRouter.CHARACTER_SELECT_SCENE)
