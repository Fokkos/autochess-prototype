extends Node2D

enum UnitState { IDLE, MOVE_TO_TARGET, ATTACK, DEAD }

@export var hp: int = 100
@export var attack: int = 10
@export var attack_speed: int = 10
@export var movement_speed: int = 10
@export var range: float = 10.0
@export var team: int = 0 # 0 = player, 1 = enemy

var unit_size: int = 64 # Units are 64*64px
var unit_type: String
var state: UnitState = UnitState.IDLE
var current_target: Node2D = null
var attack_timer: float = 0.0

@onready var hp_bar = $HPBar
@onready var sprite = $Sprite2D
@onready var control_panel = $UI

func _ready():
	# Register unit to the battle manager
	BattleManager.register_unit(self)
	hp_bar.max_value = hp
	hp_bar.value = hp
	
# Cleanup function for when a unit is removed from the node tree
func _exit_tree():
	BattleManager.unregister_unit(self)

func init(_unit_type: String, place_enemies: bool):
	unit_type = _unit_type
	
	match unit_type:
		"Sword":
			sprite.texture = load("res://sprites/sword.png")
			attack = 4
			attack_speed = 8
			movement_speed = 5
			range = 1
		"Axe":
			sprite.texture = load("res://sprites/axe.png")
			attack = 8
			attack_speed = 3
			movement_speed = 3
			range = 0.75
		"Bow":
			sprite.texture = load("res://sprites/bow.png")
			attack = 6
			attack_speed = 1
			movement_speed = 3
			range = 3
		
	if place_enemies: # Tint enemy units red
		team = 1
		sprite.modulate = Color.RED

	print("Unit created with type:", unit_type)
	
func _process(delta):
	if GameState.game_ready:
		match state:
			UnitState.IDLE:
				# If idle, get a list of all enemies, then look for target.
				var enemies = BattleManager.get_enemy_units(team)
				if enemies.is_empty():
					rotate(5*delta)
					return
				# Find the closest enemy, and set current target to that enemy unit
				var closest_enemy = enemies[0]
				var min_dist = position.distance_to(closest_enemy.position)
				
				for enemy in enemies:
					var dist = position.distance_to(enemy.position)
					if dist < min_dist:
						closest_enemy = enemy
						min_dist = dist
				
				# Once all enemies are checked, set the current target to the closest enemy
				current_target = closest_enemy
				# And set the state to MOVE_TO_TARGET
				state = UnitState.MOVE_TO_TARGET
			UnitState.MOVE_TO_TARGET:
				var direction = (current_target.position - position).normalized()
				if position.distance_to(current_target.position) > range * unit_size:
					position += direction * movement_speed * delta * 5
				else:
					state = UnitState.ATTACK
			UnitState.ATTACK:
				print("attack!")
				# Every `attack_speed` ticks, do `attack` damage to the targeted unit
				if not is_instance_valid(current_target):
					state = UnitState.IDLE
					current_target = null
					return
				
				if position.distance_to(current_target.position) > range * unit_size:
					state = UnitState.MOVE_TO_TARGET
					return
					
				attack_timer -= delta
				if attack_timer <= 0:
					current_target.hp -= attack
					current_target.hp_bar.value = current_target.hp
					attack_timer = 1.0 / float(attack_speed)
					
					print(current_target.hp)
					
					if current_target.hp <= 0:
						current_target.state = UnitState.DEAD
						state = UnitState.IDLE
						
			UnitState.DEAD:
				visible = false
				BattleManager.unregister_unit(self)
				current_target = null
				
				
			
		
