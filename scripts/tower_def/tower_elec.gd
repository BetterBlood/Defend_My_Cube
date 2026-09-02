extends Tower

class_name TowerElec

const STUN_EFFECT = preload("res://scenes/fight/statusEffects/speed_effect.tscn")
var stun_chances: Array[float] = [0.10, 0.20, 0.30, 0.50, 0.75]

func _ready() -> void:
	attack_range = 40
	super._ready()

func _custom_ready() -> void:
	base_damage = 5.0
	attack_cooldown = 7.0
	effect_value = 0.0
	
	effect_area_range_transmission = 0.0 # TODO: for the moment, mayby upgrad with lvls
	
	effect = STUN_EFFECT

func _perform_attack(_target: Node3D, current_damage: float) -> void:
	var best_target: Node3D = null
	var highest_hp_ratio: float = -1.0
	
	for enemy in current_targets:
		if is_instance_valid(enemy) and enemy.has_method("get_health_component"):
			var health_comp = enemy.get_health_component()
			var hp_ratio = float(health_comp.health) / float(health_comp.get_max_health())
			if hp_ratio > highest_hp_ratio:
				highest_hp_ratio = hp_ratio
				best_target = enemy
	
	if not is_instance_valid(best_target):
		return
	
	best_target.take_damage(current_damage, Enums.DamageType.ELEC, 0.0)
	
	if randf() <= stun_chances[clamp(level - 1, 0, 4)]:
		_apply_stun(best_target)
	
	_draw_lightning(attack_source.global_position, best_target.global_position)


func _apply_stun(target: Node3D) -> void:
	if STUN_EFFECT == null:
		return
	
	#print(target.has_method("can_host_status_effect"))
	if target.has_method("can_host_status_effect"):
		var chance = stun_chances[clamp(level - 1, 0, 4)]
		if randf() > chance:
			return
		
		var new_id = StatusEffectId.get_next_id() # TODO : be carefull that the id dosen't grow too quickly, maybe release if not used 
		if target.can_host_status_effect(new_id): # TODO: check if really usefull
			target.add_effect_id(new_id)
			var effect_instance = effect.instantiate()
			effect_instance.same_effect = effect
			effect_instance.value = effect_value
			effect_instance.effect_id = new_id
			effect_instance.target = target
			effect_instance.total_duration = effect_duration
			effect_instance.total_duration_fixe = effect_duration
			effect_instance.effect_area_range_transmission = effect_area_range_transmission
			target.add_child(effect_instance)


func _draw_lightning(start_pos: Vector3, end_pos: Vector3) -> void:
	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	var distance = start_pos.distance_to(end_pos)
	var direction = start_pos.direction_to(end_pos)
	
	cylinder.top_radius = 0.05
	cylinder.bottom_radius = 0.05
	cylinder.height = distance
	mesh_instance.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.9, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.6, 1.0)
	mat.emission_energy_multiplier = 3.0
	
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	
	get_tree().current_scene.add_child(mesh_instance)
	
	mesh_instance.global_position = start_pos.lerp(end_pos, 0.5)
	
	var up_vector = Vector3.UP
	
	if direction.is_equal_approx(up_vector):
		pass
	elif direction.is_equal_approx(-up_vector):
		mesh_instance.basis = Basis(Vector3.RIGHT, PI)
	else:
		var axis = up_vector.cross(direction).normalized()
		var angle = up_vector.angle_to(direction)
		mesh_instance.basis = Basis(axis, angle)
	
	var tween = get_tree().create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.2)
	tween.tween_callback(mesh_instance.queue_free)
	
	
	
	
	
