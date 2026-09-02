extends Projectile

class_name PlantProjectile

func _ready() -> void:
	super._ready()
	effect = preload("res://scenes/fight/statusEffects/speed_effect.tscn")
	effect_value = 0.8


func get_type() -> Enums.DamageType:
	return Enums.DamageType.PLANT
