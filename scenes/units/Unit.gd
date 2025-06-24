extends Node2D

enum UnitState { IDLE, MOVE_TO_TARGET, ATTACK, DEAD }

@export var hp: int = 100
@export var attack: int = 10
@export var attack_speed: int = 10
@export var range: float = 1 # How many squares can this unit attack from?
@export var team: int = 0 # 0 = player, 1 = enemy

var unit_size: int = 64 # Units are 64*64px
var unit_type: String
var state: UnitState = UnitState.IDLE
var current_target: Node2D = null
var attack_timer: float = 0.0

var tile_size = 64
var current_tile: Vector2i
var destination_tile: Vector2i
var destination_reached := true
var move_timer := 0.0
const STEP_INTERVAL := 0.5  # seconds

@onready var hp_bar = $HPBar
@onready var sprite = $Sprite2D
@onready var control_panel = $UI
var grid: Control

func _ready():
	# Register unit to the battle manager
	BattleManager.register_unit(self)
	hp_bar.max_value = hp
	
# Cleanup function for when a unit is removed from the node tree
func _exit_tree():
	BattleManager.unregister_unit(self)

func init(_unit_type: String, place_enemies: bool):
	unit_type = _unit_type
	
	match unit_type:
		"Sword":
			sprite.texture = load("res://scenes/units/assets/sword.png")
			attack = 4
			attack_speed = 8
			range = 1
		"Axe":
			sprite.texture = load("res://scenes/units/assets/axe.png")
			attack = 8
			attack_speed = 4
			range = 1
		"Bow":
			sprite.texture = load("res://scenes/units/assets/bow.png")
			attack = 6
			attack_speed = 4
			range = 4
		
	if place_enemies: # Tint enemy units red
		team = 1
		sprite.modulate = Color.RED

	print("Unit created with type:", unit_type)


func _process(delta):
	if not GameState.game_ready:
		return

	current_tile = Vector2i(global_position.x / tile_size, global_position.y / tile_size)

	match state:
		UnitState.IDLE:
			# Look for the closest enemy
			var enemies = BattleManager.get_enemy_units(team)
			if enemies.is_empty():
				rotate(5 * delta)
				return

			var closest_enemy = enemies[0]
			var min_dist = current_tile.distance_to(Vector2i(closest_enemy.global_position / tile_size))

			for enemy in enemies:
				var dist = current_tile.distance_to(Vector2i(enemy.global_position / tile_size))
				if dist < min_dist:
					closest_enemy = enemy
					min_dist = dist

			current_target = closest_enemy

			# If already in range, switch to attack
			if min_dist <= range:
				state = UnitState.ATTACK
			else:
				destination_reached = true
				state = UnitState.MOVE_TO_TARGET

		UnitState.MOVE_TO_TARGET:
			if not is_instance_valid(current_target):
				state = UnitState.IDLE
				return

			var target_tile = Vector2i(current_target.global_position / tile_size)
			var distance = current_tile.distance_to(target_tile)

			if distance <= range:
				state = UnitState.ATTACK
				return

			move_timer += delta
			if move_timer >= STEP_INTERVAL:
				move_timer = 0.0  # Reset the timer

				# Determine Manhattan step toward target
				var step = Vector2i.ZERO
				if current_tile.x < target_tile.x:
					step.x = 1
				elif current_tile.x > target_tile.x:
					step.x = -1
				elif current_tile.y < target_tile.y:
					step.y = 1
				elif current_tile.y > target_tile.y:
					step.y = -1

				translate(Vector2(step.x * 64, step.y * 64))

		UnitState.ATTACK:
			if not is_instance_valid(current_target):
				state = UnitState.IDLE
				current_target = null
				return

			var target_tile = Vector2i(current_target.global_position / tile_size)
			var dist = current_tile.distance_to(target_tile)

			if dist > range:
				state = UnitState.MOVE_TO_TARGET
				return

			attack_timer -= delta
			if attack_timer <= 0:
				current_target.hp -= attack
				current_target.hp_bar.value = current_target.hp
				attack_timer = 1.0 / float(attack_speed)

				if current_target.hp <= 0:
					current_target.state = UnitState.DEAD
					state = UnitState.IDLE

		UnitState.DEAD:
			visible = false
			BattleManager.unregister_unit(self)
			current_target = null
