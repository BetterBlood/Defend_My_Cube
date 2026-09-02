extends Projectile

class_name ElectricProjectile

func _ready() -> void:
	super._ready()
	effect = preload("res://scenes/fight/statusEffects/speed_effect.tscn")
	effect_value = 0.0


func get_type() -> Enums.DamageType:
	return Enums.DamageType.ELEC
