extends Tower

class_name TowerFire

const BURN_EFFECT = preload("res://scenes/fight/statusEffects/burn_effect.tscn")
#var cone_angle: float = deg_to_rad(30.0)
var burn_chances: Array[float] = [0.6, 0.7, 0.8, 0.9, 1.0]

@onready var cone_area: Area3D = $AttackArea
@onready var gpu_particles_3d: GPUParticles3D = $AttackArea/CollisionShape3D/GPUParticles3D

func _custom_ready() -> void:
	$AttackArea.set_collision_mask_value(1, false)
	$AttackArea.set_collision_mask_value(3, true)
	
	base_damage = 0.1
	attack_cooldown = 0.5
	effect_value = 0.2
	effect_duration = 0.5
	effect_area_range_transmission = 2.0
	damage_type = Enums.DamageType.FIRE
	
	effect = BURN_EFFECT
	
	# TODO: update cone_area z coord to fit the tower attack range (better)
	

func _perform_attack(_target: Node3D, current_damage: float) -> void:
	var closest_enemy: Node3D = null
	var min_distance: float = INF
	
	for enemy in current_targets:
		if is_instance_valid(enemy):
			var dist = attack_source.global_position.distance_squared_to(enemy.global_position)
			if dist < min_distance:
				min_distance = dist
				closest_enemy = enemy
	
	if not is_instance_valid(closest_enemy):
		return
	
	cone_area.look_at(closest_enemy.global_position, Vector3.UP) # TODO: A3: Fire
	cone_area.force_update_transform() # TODO : check perf, maybe remove if not really usefull
	
	var enemies_in_cone = cone_area.get_overlapping_areas()
	
	for target in enemies_in_cone:
		#print("in_cone")
		var enemy = target.get_parent()
		if enemy is Enemy:
			#print("enemy")
			enemy = enemy as Enemy # normaly useless
			#print("_perform_attack: ", enemy)
			if is_instance_valid(enemy) and enemy.has_method("take_damage"):
				#print("take_damage")
				enemy.take_damage(current_damage, damage_type, 0.0)
				_apply_burn(enemy)
	
	if not gpu_particles_3d.emitting:
		gpu_particles_3d.emitting = true
		gpu_particles_3d.restart()


func _apply_burn(target: Node3D) -> void:
	if BURN_EFFECT == null:
		return
	
	#print(target.has_method("can_host_status_effect"))
	if target.has_method("can_host_status_effect"):
		var chance = burn_chances[clamp(level - 1, 0, 4)]
		if randf() < chance:
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
