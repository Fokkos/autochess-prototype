extends Node2D

@export var hp: int = 10
@export var atk: int = 5
var unit_type: String

@onready var hp_bar = $HPBar
@onready var sprite = $Sprite2D

func _ready():
	hp_bar.max_value = hp
	hp_bar.value = hp

func init(_unit_type: String, place_enemies: bool):
	unit_type = _unit_type
	
	match unit_type:
		"Sword":
			sprite.texture = load("res://sprites/sword.png")
		"Axe":
			sprite.texture = load("res://sprites/axe.png")
		"Lance":
			sprite.texture = load("res://sprites/lance.png")
	if place_enemies: # Tint enemy units red
		sprite.modulate = Color.RED

	print("Unit created with type:", unit_type)
