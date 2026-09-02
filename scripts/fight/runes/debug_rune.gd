extends Rune

class_name DebugRune

const DEBUG_PROJECTILE_MAT = preload("res://materials/projectiles/debug_projectile.tres")

func _init(parent: Node3D) -> void:
	super._init(parent)
	
	active_mat = DEBUG_PROJECTILE_MAT
	
	#print("_init de DebugRune: ", self)
	
	projectile_scene = preload("res://scenes/fight/projectiles/debug_projectile.tscn")
	
	_set_rune()

static func get_default_rune_data() -> Dictionary:
	#print("DebugRune::set_default_rune_data::test")
	# don't load from file for rune with id -1 or name DebugRune cause it's debug man you know )> (o.O) <{ or do }
	var rune_data = {
		"name": "Debug",
		"type": Enums.DamageType.FIRE,
		"cost_value": -1,
		
		"cooldown": 2.0,
	
		"cooldown_reduction": 0.0,
		"p_perforation_count": 1,
		"p_bounce_count": 1,
		"p_penetration": 1.0,
		"p_damage": 5.0,
		"p_speed": 14.0,
		"p_status_effect_chance": 1.0,
		"p_radius": 0.25,
		"p_effect_duration": 2.0,
		"p_effect_area_range_transmission": 30.0,
	}
	return rune_data

func get_rune_id() -> int:
	return -1


func get_damage_type() -> Enums.DamageType:
	return Enums.DamageType.FIRE
