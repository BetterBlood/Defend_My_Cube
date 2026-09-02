extends Projectile

class_name NormalProjectile

func _ready() -> void:
	super._ready()


func get_type() -> Enums.DamageType:
	return Enums.DamageType.NORMAL
