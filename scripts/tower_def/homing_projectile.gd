extends NormalProjectile

class_name HomingProjectile

var target: Creature
var speed: float = 18.0
var turn_speed: float = 18.0 

var _target_lost: bool = false

func _ready() -> void:
	super._ready()
	
	#gravity_scale = 0.0
	
	# TODO: check if usefull :
	if not $InteractionArea.area_entered.is_connected(_on_interaction_area_entered):
		$InteractionArea.area_entered.connect(_on_interaction_area_entered)
	
	var upward_force = randf_range(10.0, 15.0)
	linear_velocity = Vector3(0, upward_force, 0)


func _physics_process(delta: float) -> void:
	if _target_lost:
		return
	
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		_target_lost = true
		# TODO: check if a new target is a better choice instead of deleting projectile
		#queue_free()
		return
	
	var target_pos = target.global_position + Vector3(0, 0.8, 0)
	var direction = (target_pos - global_position).normalized()
	
	var desired_velocity = direction * speed
	
	linear_velocity = linear_velocity.move_toward(desired_velocity, turn_speed * delta)

func _on_interaction_area_entered(area: Area3D) -> void:
	var hit_creature = area.get_parent()
	#print("HomingProjectile::_on_interaction_area_entered:hit_creature: ", hit_creature)
	
	if hit_creature == target:
		if hit_creature.has_method("take_damage"):
			hit_creature.take_damage(damage, get_type(), armor_penetration)
		
		queue_free()
