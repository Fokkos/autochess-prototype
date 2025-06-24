# Grid.gd (for Godot 4.x)
extends Control

const GRID_SIZE := 10
const TILE_SCENE := preload("res://scenes/common/TileButton.tscn")

@onready var control_panel = $UI
@onready var unit_scene = preload("res://scenes/units/Unit.tscn")

var units := {}  # Dictionary to map (x, y) to units

# Hover effect
var hover_sprite          : Sprite2D  = null
var hover_highlights      : Array[ColorRect] = []
var hover_allowed         : bool = false      # are we over a legal tile?
const HIGHLIGHT_COLOR := Color(0, 1, 0, 0.25) # translucent green
var tile_size: int = 64


func _ready():
	var grid = $GridContainer
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile = TILE_SCENE.instantiate()
			tile.name = "Tile_%d_%d" % [x, y]
			tile.text = ""
			tile.pressed.connect(_on_tile_pressed.bind(x, y))
			tile.mouse_entered.connect(_on_tile_hover_entered.bind(x, y))
			tile.mouse_exited .connect(_on_tile_hover_exited)
			grid.add_child(tile)

func _on_tile_pressed(x: int, y: int) -> void:
	_clear_hover_visuals()
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


func _on_tile_hover_entered(x:int, y:int) -> void:
	# 1) make sure the tile is in an allowed row
	var place_enemies = control_panel.change_sides_enabled
	var allowed_rows := [0,1,2] if place_enemies  else [7,8,9]
	hover_allowed = (y in allowed_rows) and not units.has(Vector2i(x,y))
	if not hover_allowed:
		return

	# 2) spawn the ghost sprite
	var unit_type = control_panel.selected_unit_type
	hover_sprite   = Sprite2D.new()
	hover_sprite.texture = _get_unit_texture(unit_type)
	hover_sprite.modulate.a = 0.5 # 50 % opacity
	if place_enemies:
		hover_sprite.modulate = Color.RED
	hover_sprite.z_index = 50 # draw on top
	# I have no idea why this spawns 8 tiles to the right and 1 above mouse
	var tile_button = $GridContainer.get_node("Tile_%d_%d" % [x, y])
	# For now, this is manually fixed... TODO look into a proper fix lol
	hover_sprite.global_position = tile_button.global_position - + Vector2(32, 32) - Vector2(64 * 8, -64)
	add_child(hover_sprite)

	# 3) draw the range squares
	var unit_range := _get_unit_range(unit_type)
	_spawn_range_highlights(x, y, unit_range)


# Always clear the visuals when either selecting a unit or moving mouse away
func _on_tile_hover_exited() -> void:
	_clear_hover_visuals()

# Ideally, this would be done by accessing the class itself, or have the class data stored
# In another structure like a db or json
func _get_unit_texture(unit_type:String) -> Texture2D:
	match unit_type:
		"Sword": return preload("res://scenes/units/assets/sword.png")
		"Axe":   return preload("res://scenes/units/assets/axe.png")
		"Bow":   return preload("res://scenes/units/assets/bow.png")
		_:       return null

# As above, find better, more global friendly way of doing this
func _get_unit_range(unit_type:String) -> int:
	match unit_type:
		"Sword": return 1
		"Axe":   return 1
		"Bow":   return 4
		_:       return 1


func _spawn_range_highlights(cx:int, cy:int, rng:int) -> void:
	var grid = $GridContainer
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var dist = abs(x - cx) + abs(y - cy) # Manhattan Distance
			if dist == 0 or dist > rng: # skip center & out-of-range
				continue
			var rect := ColorRect.new()
			rect.color = HIGHLIGHT_COLOR
			rect.size  = Vector2(tile_size, tile_size)
			var tile_button = $GridContainer.get_node("Tile_%d_%d" % [x, y])
			# As before, for some reason the preview is rendered 9 tiles to the right
			# ... this is manually fixed TODO for now
			rect.global_position = tile_button.global_position - Vector2(64 * 9, 0)
			rect.z_index = 40
			add_child(rect)
			hover_highlights.append(rect)


func _clear_hover_visuals() -> void:
	if hover_sprite and is_instance_valid(hover_sprite):
		hover_sprite.queue_free()
	hover_sprite = null
	for rect in hover_highlights:
		if is_instance_valid(rect):
			rect.queue_free()
	hover_highlights.clear()


func unit_exists(x, y):
	var key = Vector2i(x, y)
	return units.has(key)
	
	
	
	
