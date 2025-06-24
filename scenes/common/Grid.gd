# Grid.gd (for Godot 4.x)
extends Control

const GRID_SIZE := 10
const TILE_SCENE := preload("res://scenes/common/TileButton.tscn")

@onready var control_panel = $UI
@onready var unit_scene = preload("res://scenes/units/Unit.tscn")

var units := {}  # Dictionary to map (x, y) to units

func _ready():
	var grid = $GridContainer
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile = TILE_SCENE.instantiate()
			tile.name = "Tile_%d_%d" % [x, y]
			tile.text = ""
			tile.pressed.connect(_on_tile_pressed.bind(x, y))
			grid.add_child(tile)

func _on_tile_pressed(x: int, y: int) -> void:
	var place_enemies = control_panel.change_sides_enabled
	var allowed_rows = [0, 1, 2] if place_enemies else [7, 8, 9]

	if y in allowed_rows:
		var key = Vector2i(x, y)
		
		
		if units.has(key):
			print("Unit already exists at (%d, %d)" % [x, y])
			return
		
		var unit = unit_scene.instantiate()
		add_child(unit)
		unit.init(control_panel.selected_unit_type, place_enemies)
		
		# Assign the unit type
		unit.unit_type = control_panel.selected_unit_type

		# Position the unit based on the button's position
		var tile_button = $GridContainer.get_node("Tile_%d_%d" % [x, y])
		unit.global_position = tile_button.global_position + Vector2(32, 32)  # offset by half of cell size

		units[key] = unit
		print("Spawned unit at (%d, %d)" % [x, y])
	else:
		print("Click in allowed row only")
	
	
