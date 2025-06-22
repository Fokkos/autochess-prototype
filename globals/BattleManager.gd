extends Node

var units: Array = []

func register_unit(unit):
	units.append(unit)
	
func unregister_unit(unit):
	units.erase(unit)

func get_enemy_units(for_team: int):
	return units.filter(func(unit): return unit.team != for_team)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
