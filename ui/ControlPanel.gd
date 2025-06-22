extends Panel

@export var change_sides_enabled: bool = false
@export var selected_unit_type := "Sword"

func _ready():
	$VBoxContainer/ChangeSidesButton.pressed.connect(_on_change_sides_pressed)
	$VBoxContainer/StartButton.pressed.connect(_on_start_game_pressed)
	
	var selector = $VBoxContainer/UnitTypeSelector
	selector.selected = 0  # Default to Sword
	selector.item_selected.connect(_on_unit_type_selected)

func _on_change_sides_pressed():
	change_sides_enabled = !change_sides_enabled
	var label = $VBoxContainer/ChangeSidesLabel
	label.text = "Enemy" if change_sides_enabled else "User"
	print("Change Sides toggled:", change_sides_enabled)

func _on_unit_type_selected(index: int):
	selected_unit_type = $VBoxContainer/UnitTypeSelector.get_item_text(index)
	print("Selected unit type:", selected_unit_type)

func _on_start_game_pressed():
	print("Start Game pressed! (placeholder)")
	GameState.game_ready = true
