extends RigidBody3D

class_name Projectile

@onready var interaction_area: Area3D = $InteractionArea

var perforation_count: int = 0 # default 0 # number of ennemies that can be perfored by projectile
var bouncing_count: int = 0 # default 0 # number of walls that projectile can bounced on
var status_effect_chance: float = 0.0 # [0;1] # default 0
var effect_duration: float = 2.1 # default 2.1 (tick 0.5 -> 4 apply)
var effect_area_range_transmission: float = 0 
var armor_penetration: float = 0.0
var damage: float = 0.0

var source: Creature

var effect: PackedScene = null
var effect_value: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$TimeToLive.timeout.connect(_on_time_to_live_timeout)
	$TimeToLive.wait_time = 5
	$TimeToLive.start()
	
	interaction_area.area_entered.connect(_on_interaction_area_area_entered)
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)


func set_layers_to_hit(layers: int) -> int:
	interaction_area.collision_mask = layers
	return interaction_area.collision_mask


func _on_interaction_area_area_entered(area: Area3D) -> void:
	#print("In Projectile detect collision with: ", area)
	var target = area.get_parent()
	if target and target.has_method("get_health_component"):
		_impact_health_component_user(target)


func _impact_health_component_user(target: Node):
	if target.has_method("take_damage"):
		#print("On: ", target, " damage dealed: ", damage)
		#var damage_taken = \
		target.take_damage(damage, get_type(), armor_penetration)
		#print("On: ", target, " damage taken: ", damage_taken)
	
	_apply_effect(target)
	
	#print("Projectile: ", self, ": perforation_count: ", perforation_count)
	if perforation_count <= 0:
		#print("Projectile: ", self , ": perforating destroy reached")
		queue_free()
	perforation_count -= 1


func _apply_effect(target: Creature) -> void:
	if effect == null:
		return
	
	#print(target.has_method("can_host_status_effect"))
	if 		target.has_method("can_host_status_effect") && \
			status_effect_chance > randf_range(0,1):
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


func _on_interaction_area_body_entered(_body: Node3D) -> void:
	#print("Projectile: ", self , " hits ", _body, ", bouncing_count: ", bouncing_count)
	
	if bouncing_count <= 0:
		#print("Projectile: ", self , ": bouncing destroy reached")
		queue_free()
	
	bouncing_count -= 1


func _on_time_to_live_timeout() -> void:
	#print("Projectile living time reached: auto destroy")
	queue_free()


func get_type() -> Enums.DamageType:
	return Enums.DamageType.NORMAL


func set_data(rune_resource_for_projectile: RuneResource) -> void:
	damage = rune_resource_for_projectile.projectile_damage
	bouncing_count = rune_resource_for_projectile.projectile_bounce_count
	perforation_count = rune_resource_for_projectile.projectile_perforation_count
	armor_penetration = rune_resource_for_projectile.projectile_penetration
	status_effect_chance = rune_resource_for_projectile.projectile_status_effect_chance
	effect_duration = rune_resource_for_projectile.projectile_effect_duration
	effect_area_range_transmission = rune_resource_for_projectile.projectile_effect_area_range_transmission
	_set_radius(rune_resource_for_projectile.projectile_radius)
	
	var tween = get_tree().create_tween()
	$MeshInstance3D.scale = Vector3(0.01, 0.01, 0.01)
	tween.tween_property($MeshInstance3D, "scale", Vector3(1, 1, 1), 0.5)


func _set_radius(radius: float) -> void:
	$CollisionShape3D.shape.radius = radius
	$MeshInstance3D.mesh.radius = radius
	$MeshInstance3D.mesh.height = radius * 2
	interaction_area.get_child(0).shape.radius = radius
