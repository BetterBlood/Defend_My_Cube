@icon("res://images/icons/heart_3d.svg")
extends Node3D

class_name HealthComponent

@export var _max_health: float = 10.0
var health: float = _max_health
static var _health_default_upgrade: float = 1.0

@export var _health_regen_per_sec: float = 0.0
var health_regen_timer_reset: float = 0.25
static var _health_regen_default_upgrade: float = 0.1

@export var _armor: float = 0.0
static var _armor_default_upgrade: float = 0.25
@export var _penetration_resistance: float = 0.0 # [0; 1] 
static var _pen_res_default_upgrade: float = 0.01
@export var _max_speed: float = 5
var speed: float = _max_speed
static var _speed_default_upgrade: float = 0.5

# TODO : balance !
static var default_upgrades_values: Array[float] = [
	_health_default_upgrade,
	_health_regen_default_upgrade,
	_armor_default_upgrade,
	_pen_res_default_upgrade,
	_speed_default_upgrade,
]
static var upgrades_names: Array[String] = [
	"max health",
	"health regen / s",
	"armor",
	"penetration res",
	"max speed",
]

# [0:_max_health, 1:_health_regen_per_sec, 2:_armor, 3:_penetration_resistance, 4:_max_speed]
var perm_upgrades: Array[float] = [0, 0, 0, 0, 0]
var temp_upgrades: Array[float] = [0, 0, 0, 0, 0]
static var NBR_UPGRADES: int = 5

signal damage_taken()
signal heal_taken()
var health_regen_timer: Timer = Timer.new()

var speed_effects = {}

signal burn_effect()

func _ready() -> void:
	health_regen_timer.wait_time = health_regen_timer_reset
	health_regen_timer.autostart = true
	health_regen_timer.timeout.connect(_passive_heal)
	add_child(health_regen_timer)

func set_up_perm_with_data(data) -> void:
	for upgrade in data:
		if int(upgrade["type"]) > len(perm_upgrades):
			push_warning("Health component upgrade " + upgrade["type"] + " not recognized... skiped")
			continue
		perm_upgrades[int(upgrade["type"])] += float(upgrade["value"])

func add_perm_upgrade(type: int, level: float) -> void:
	for i in range(level + 1): # TODO check if level or level + 1
		perm_upgrades[type] += default_upgrades_values[type]
	#perm_upgrades[type] += value

func get_perm_data():
	var data = []
	for i in range(len(perm_upgrades)):
		data.append({"type": i, "value": perm_upgrades[i]})
	return data

func set_up_temp_with_data(data) -> void:
	for upgrade in data:
		if int(upgrade["type"]) > len(temp_upgrades):
			push_warning("Health component upgrade " + upgrade["type"] + " not recognized... skiped")
			continue
		temp_upgrades[int(upgrade["type"])] += float(upgrade["value"])

func add_temp_upgrade(type: int, level: float) -> void:
	for i in range(level + 1): # TODO check if level or level + 1
		temp_upgrades[type] += default_upgrades_values[type]
	#temp_upgrades[type] += value

func get_temp_data():
	var data = []
	for i in range(len(temp_upgrades)):
		data.append({"type": i, "value": temp_upgrades[i]})
	return data

func _get_upgrade_perm_and_temp_with_id(id: int) -> float:
	return perm_upgrades[id] + temp_upgrades[id]

func get_max_health() -> float:
	return _max_health + _get_upgrade_perm_and_temp_with_id(0)

func get_health_regen_per_sec() -> float:
	return _health_regen_per_sec + _get_upgrade_perm_and_temp_with_id(1)

func get_armor() -> float:
	return _armor + _get_upgrade_perm_and_temp_with_id(2)

func get_penetration_resistance() -> float:
	return _penetration_resistance + _get_upgrade_perm_and_temp_with_id(3)

func get_max_speed() -> float:
	return _max_speed + _get_upgrade_perm_and_temp_with_id(4)

func _passive_heal() -> void:
	if get_health_regen_per_sec() > 0.0 and health < get_max_health():
		health = min(health + get_health_regen_per_sec() * health_regen_timer_reset, get_max_health())
		#print(self, "::_passive_heal::health: ", health)
		heal_taken.emit()
	health_regen_timer.start(health_regen_timer_reset)


func take_burn_effect(value: float) -> float:
	var damage: float = value * _get_grid_modifier(Enums.DamageType.FIRE, get_parent().get_type())
	#print(get_parent(), "::HealthComponent: I'm literally on fire.... taking (", value, ") -> ", damage, " damages.")
	burn_effect.emit()
	health = max(health - damage, 0.0)
	damage_taken.emit()
	
	return damage


func take_speed_effect(id: int, value: float) -> float:
	#print(get_parent(), "::HealthComponent: Speed modifier -> taking (", id, " ", value, ") , max: ", get_max_speed())
	if !speed_effects.has(id):
		speed_effects[id] = value
		speed = get_max_speed() * _compute_speed_mult()
		#print(get_parent(), "::HealthComponent: Speed modifier max: ", get_max_speed(), " -> ", speed, " speed.")
	return speed


func remove_speed_effect(id: int) -> void:
	speed_effects.erase(id)
	speed = get_max_speed() * _compute_speed_mult()


func _compute_speed_mult() -> float:
	var mult: float = 1.0
	for val in speed_effects.values():
		mult *= val
	return mult

func get_icons_path() -> String:
	return "icon.svg"

func take_damage(	value: float, 
					att_type: Enums.DamageType, 
					def_type: Enums.DamageType, 
					armor_pen: float
				) -> float:
	var damage: float = value * _get_grid_modifier(att_type, def_type)
	#print("HealthComponent::take_damage (with grid modifier): ", damage)
	damage -= max(get_armor() - max((1.0 - get_penetration_resistance()), 0.0) * armor_pen, 0.0)
	#print("HealthComponent::take_damage ", value, " ", att_type, " ", def_type, " ", armor_pen, " ", damage)
	
	if damage <= 0:
		damage = 0.1 # <( not impossible to make damage, but really hard ) 
	
	#print("HealthComponent:: health: ", health, ", armor: ", _armor)
	health = max(health - damage, 0.0)
	damage_taken.emit()
	#print("HealthComponent:: health: ", health)
	return damage

func _get_grid_modifier(
						att_type: Enums.DamageType,
						def_type: Enums.DamageType
						) -> float:
	return Enums.get_grid_modifier(att_type, def_type)
