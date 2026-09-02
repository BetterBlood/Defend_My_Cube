extends Rune

class_name ElectricRune1

const ELECTRIC_PROJECTILE_MAT = preload("res://materials/projectiles/electric_projectile.tres")

func _init(parent: Node3D) -> void:
	super._init(parent)
	
	active_mat = ELECTRIC_PROJECTILE_MAT
	
	#print("_init de ElectricRune1: ", self)
	
	projectile_scene = preload("res://scenes/fight/projectiles/electric_projectile.tscn")
	
	_set_rune()
	
	#cooldown = 1.5
	#
	#rune_resource.cooldown_reduction = 0.0
	#rune_resource.projectile_perforation_count = 1
	#rune_resource.projectile_bounce_count = 0
	#rune_resource.projectile_penetration = 1.0
	#rune_resource.projectile_damage = 3.0
	#rune_resource.projectile_speed = 16.0
	#rune_resource.projectile_status_effect_chance = 0.05 # 0.05 default
	#rune_resource.projectile_radius = 0.2
	#rune_resource.projectile_effect_duration = 0.6
	#rune_resource.projectile_effect_area_range_transmission = 10

static func get_default_rune_data() -> Dictionary:
	#print("ElectricRune1::set_default_rune_data::test")
	var rune_data = {
		"name": "Elec_1",
		"type": Enums.DamageType.ELEC,
		"cost_value": 50,
		
		"cooldown": 1.5,
	
		"cooldown_reduction": 0.0,
		"p_perforation_count": 1,
		"p_bounce_count": 0,
		"p_penetration": 1.0,
		"p_damage": 3.0,
		"p_speed": 16.0,
		"p_status_effect_chance": 0.05, # 0.05 default
		"p_radius": 0.2,
		"p_effect_duration": 0.6,
		"p_effect_area_range_transmission": 10.0,
	}
	return rune_data

func get_rune_id() -> int:
	return 3


func get_damage_type() -> Enums.DamageType:
	return Enums.DamageType.ELEC
