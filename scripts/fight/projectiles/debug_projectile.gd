extends Projectile

class_name DebugProjectile

func _ready() -> void:
	super._ready()
	
	match get_type():
		Enums.DamageType.FIRE: # burn effect
			effect = preload("res://scenes/fight/statusEffects/burn_effect.tscn")
			effect_value = 1.0
			
		Enums.DamageType.PLANT: # slow effect
			effect = preload("res://scenes/fight/statusEffects/speed_effect.tscn")
			effect_value = 0.8
			
		Enums.DamageType.ELEC: # stun effect
			effect = preload("res://scenes/fight/statusEffects/speed_effect.tscn")
			effect_value = 0.0


func get_type() -> Enums.DamageType:
	return Enums.DamageType.FIRE
