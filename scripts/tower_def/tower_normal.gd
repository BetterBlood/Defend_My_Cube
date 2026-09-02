extends Tower

class_name TowerNormal

const HOMING_PROJECTILE = preload("res://scenes/tower_def/homing_projectile.tscn")
# dégats par défaut : 3.5
# cooldown par défaut: 2.0

func _custom_ready() -> void:
	pass # A3: 

func _perform_attack(target: Node3D, current_damage: float) -> void:
	var proj = HOMING_PROJECTILE.instantiate()
	
	get_tree().current_scene.add_child(proj)
	
	proj.global_position = attack_source.global_position
	proj.target = target
	proj.damage = current_damage
