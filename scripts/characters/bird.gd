extends Enemy

class_name Bird

@export var speed: float = 3

@export var boids_birds: Array[int] = []
@export var cohesion_birds: Array[Bird] = []
@export var avoidance_birds: Array[Bird] = []

@onready var ray_casts: Node3D = $RayCasts
var ray_cast: RayCast3D = RayCast3D.new()
@onready var burn_effect: MeshInstance3D = $Meshes/Effect
var burn_shader_mat: ShaderMaterial

var delta_last_tick: float = 0.0
var tick_ray_cast: float = 0.1
@onready var front: Marker3D = $Front
@onready var right: Marker3D = $Right

var base_position: Vector3


const SPHERE = preload("res://addons/polyrinthe/sphere.tscn") # DEBUG
var debug_id: int = -1

#behavior
@onready var body: MeshInstance3D = $Meshes/Body
var spawner: Spawner = null
var target: Creature = null
#var potential_target: Creature = null

var target_force: float = 10 # balanced

func _ready() -> void:
	health_bar = $HealthBar
	super._ready()
	
	if is_in_lobby:
		health_component._health_regen_per_sec = 0.5
	
	health_component._max_health = 5
	health_component.health = health_component._max_health
	health_component._max_speed = speed
	health_component.speed = health_component._max_speed
	health_component.damage_taken.connect(_damage_taken)
	
	burn_shader_mat = burn_effect.mesh.material
	
	ray_cast.collide_with_areas = false
	ray_cast.collision_mask = 1
	ray_cast.target_position = Vector3(0, 0, 10)
	ray_cast.enabled = true
	ray_cast.debug_shape_custom_color = Color(1, 0, 0, 1)
	ray_cast.debug_shape_thickness = 3
	ray_casts.add_child(ray_cast)
	
	base_position = global_position
	
	damage_area = $Meshes/Body
	
	health_bar_max_ratio = 0.5


func _physics_process(delta: float) -> void:
	# TODO if too far from center (something like maze.size * CubeCustom.size * maze.scale_factor) reset position to spawner
	
	#if id == 1:
		#return
	delta_last_tick += delta

	var _direction = Vector3()
	var creature_target_direction = Vector3()
	if target:
		creature_target_direction = (target.global_position + global_position)
	#var total_direction: Vector3 = Vector3()
	#var right_direction = right.global_position - global_position
	#var top_direction = right_direction.cross(front_direction)

	if delta_last_tick > tick_ray_cast:
		#if id == debug_id:
			#print()
		
		delta_last_tick = 0.0
		var max_i: int = 10
		var i: int = 0
		var new_target: Vector3 = Vector3(0, 0, 10)
		ray_cast.target_position = new_target
		#total_direction = to_global(new_target)
		ray_cast.force_raycast_update()
		#if id == debug_id:
			#print("i: ", i, ", new_target: ", new_target, " -> global: ", to_global(new_target))
		
		#var sphere2 = SPHERE.instantiate()
		#get_parent().add_child(sphere2)
		#if ray_cast.is_colliding():
			#sphere2.global_position = ray_cast.get_collision_point()
		#else:
			#sphere2.global_position = to_global(ray_cast.target_position)
		#sphere2.scale = Vector3(0.1, 0.1, 0.1)
		
		while i < max_i:
			if not ray_cast.is_colliding():
				if id == debug_id:
					var prev_target = SPHERE.instantiate()
					get_parent().add_child(prev_target)
					prev_target.position = to_global(ray_cast.target_position)
					prev_target.scale *= 0.05
					prev_target.get_children()[0].mesh.material.albedo_color = Color(1,0,0,0.5)
					prev_target.get_children()[0].mesh.material.transparency = true
					#print("\tray_cast.target_position: ", ray_cast.target_position)
				
				if cohesion_birds or avoidance_birds:
					var diff = _compute_boids_target_position()
					if id == debug_id:
						#print("\t_compute_boids_target: ", diff, ", to local: ", to_local(diff))
						var end_target = SPHERE.instantiate()
						get_parent().add_child(end_target)
						end_target.position = global_position + diff
						end_target.get_children()[0].mesh.material.albedo_color = Color(0,0,1,0.5)
						end_target.get_children()[0].mesh.material.transparency = true
						end_target.scale *= 0.2
					#total_direction = to_global(ray_cast.target_position) + (diff + position - to_global(ray_cast.target_position)) * tick_ray_cast
					#ray_cast.target_position = total_direction
					ray_cast.target_position += (to_local(diff + global_position) - ray_cast.target_position) * tick_ray_cast
				
				if target:
					#print("\t", i, " target. ", ray_cast.target_position)
					ray_cast.target_position += to_local(creature_target_direction - global_position) * tick_ray_cast * target_force
					#print("\t", i, " target: ", ray_cast.target_position)
					
				if id == debug_id:
					#print("\tray_cast.target_position: ", ray_cast.target_position)
					#print("\t", i, " not colliding -> should go forward")
					
					var real_target = SPHERE.instantiate()
					get_parent().add_child(real_target)
					real_target.position = to_global(ray_cast.target_position)
					real_target.scale *= 0.1
					real_target.get_children()[0].mesh.material.albedo_color = Color(0,1,0,0.5)
					real_target.get_children()[0].mesh.material.transparency = true
				
				if to_global(ray_cast.target_position).normalized().abs() != Vector3.UP: # avoid 1/1000000 error when the target is in the same direction
					look_at(to_global(ray_cast.target_position), Vector3.UP, true) # TODO: smooth rotation
				break
			#if id == debug_id:
				#print("\t", ray_cast.get_collider())
			i += 1
			new_target = _compute_new_target_position(i, max_i)
			#total_direction = new_target
			ray_cast.target_position = new_target
			ray_cast.force_raycast_update()
			#if id == debug_id:
				#print("i: ", i, ", new_target: ", new_target)
			
			#var sphere2 = SPHERE.instantiate()
			#get_parent().add_child(sphere2)
			#sphere2.position = ray_cast.get_collision_point()
			#sphere2.scale *= 0.1
			
			#if i == max_i:
				#position -= front_direction.normalized() * delta * health_component.speed
				#look_at(to_global(-ray_cast.target_position), Vector3.UP, true)
				#return

	_direction = to_global(ray_cast.target_position) - global_position

	position += _direction.normalized() * delta * (health_component.speed if not target else health_component.speed * 1.3)


func set_boids(boids: Array) -> void:
	for bird_id in boids:
		boids_birds.append(bird_id)
	boids_birds.erase(id)


func set_color(color: Color) -> void:
	body.mesh.material.albedo_color = color
	#print(color, " ", color.hex(color.to_rgba32()), " ", color.hex64(color.to_rgba64()))
	burn_shader_mat.set_shader_parameter("baseColor", color) # doesn't work don't know why

func set_spawner(manager: Spawner) -> void:
	spawner = manager

func _damage_taken() -> void:
	if spawner: spawner._bird_taking_damage(id)

func set_target(new_target: Creature) -> void:
	#print(id, " Bird::set_target: ", new_target, ", id: ", new_target.id)
	target = new_target
	$Meshes/Eye.set_surface_override_material(0, preload("res://materials/difficulties/mazo.tres"))
	$Meshes/Eye2.set_surface_override_material(0, preload("res://materials/difficulties/mazo.tres"))

func set_creature_to_listen(new_target: Creature) -> void:
	#if new_target is Player: 
		#print("Bird::set_creature_to_listen: ", new_target)
	new_target.health_component.damage_taken.connect(potential_target_take_damage.bind(new_target))
	new_target.is_dead.connect(potential_target_dead)

func potential_target_dead(dead_target_id: int) -> void:
	#print(id, " Bird::potential_target_dead target: ", dead_target_id)
	if target and dead_target_id == target.id:
		remove_creature_to_listen(target)
		target = null
	if not target:
		$Meshes/Eye.set_surface_override_material(0, null)
		$Meshes/Eye2.set_surface_override_material(0, null)

func potential_target_take_damage(curr_target: Creature) -> void:
	#print("Bird::potential_target_take_damage: curr_target: ", curr_target)
	if spawner and curr_target.health_component.health > 0: spawner.damage_taken_close_to_bird(curr_target, id)

func remove_creature_to_listen(old_target: Creature) -> void:
	#print(self, " ", id, " Bird::remove_creature_to_listen")
	if old_target.is_dead.is_connected(potential_target_dead):
		old_target.is_dead.disconnect(potential_target_dead)
	if old_target.health_component.damage_taken.is_connected(potential_target_take_damage):
		old_target.health_component.damage_taken.disconnect(potential_target_take_damage)


func _compute_new_target_position(i: int, max_i: int) -> Vector3:
	var angle: float = 3*PI / max_i
	return Vector3.BACK * (max_i - i) + Vector3.RIGHT * cos(i*angle) * i + Vector3.UP * sin(i*angle) * i


func _compute_boids_target_position() -> Vector3:
	var nbr_c: int = len(cohesion_birds)
	var avg_dir: Vector3 = Vector3()
	var avg_pos: Vector3 = Vector3()
	
	for bird in cohesion_birds:
		avg_dir += bird.front.global_position - bird.global_position
		avg_pos += bird.position
	
	if nbr_c > 0:
		avg_dir /= nbr_c
		avg_dir -= front.global_position - global_position # TODO: mmmm strange result but ok
		
		
		avg_pos /= nbr_c
		
		#var sphere2 = SPHERE.instantiate()
		#get_parent().add_child(sphere2)
		#sphere2.position = avg_pos
		#sphere2.scale *= 0.3
		
		avg_pos -= position
		
		#var sphere2 = SPHERE.instantiate()
		#get_parent().add_child(sphere2)
		#sphere2.position = position + avg_pos
		#sphere2.scale *= 0.3
	
	var nbr_a: int = len(avoidance_birds)
	var avg_avo: Vector3 = Vector3()
	for bird in avoidance_birds:
		var curr_dir = bird.global_position - global_position
		var max_dist = $AvoidanceVision/CollisionShape3D.shape.radius
		#(m - d.length) * d * -1 
		avg_avo += curr_dir * ((max_dist * 10) / curr_dir.length()) * -1  # TODO: mmmm maybe greater than 10
	
	if nbr_a > 0:
		avg_avo /= nbr_a
	#if id == debug_id and (avg_dir + avg_pos + avg_avo).length() >= 0.1:
		#print("\t_compute_boids_target: ", avg_dir + avg_pos + avg_avo)

	return avg_dir + avg_pos + avg_avo


func _on_burn_effect() -> void:
	#burn_effect.visible = true
	#var cd: float = StatusEffect.DEFAULT_COOLDOWN / 2
	#burn_shader_mat.set_shader_parameter("shader_parameter/dissolveSlider", 0.0)
	#var tween = get_tree().create_tween()
	#tween.tween_property(burn_shader_mat, "shader_parameter/dissolveSlider", 1.0, cd)
	#var timer = get_tree().create_timer(cd)
	#await timer.timeout
	#burn_effect.visible = false
	pass


func apply_visual_burn_effect(duration: float) -> void:
	burn_applied += 1
	burn_effect.visible = true
	burn_shader_mat.set_shader_parameter("dissolveSlider", 1.0)
	var timer = get_tree().create_timer(duration)
	await timer.timeout
	burn_applied -= 1
	if burn_applied <= 0:
		burn_effect.visible = false

#func _update_life_display() -> void:
	#var health_ratio: float = health_component.health / health_component.get_max_health()
	##print(self, " _update_life_display, health_ratio: ", health_ratio)
	#$HealthBar.set_instance_shader_parameter("health", health_ratio)



func set_mob_data(human_seed: String, difficulty: int, depth_ratio: float) -> void:
	super.set_mob_data(human_seed, difficulty, depth_ratio)
	#print("Zombie::set_mob_data damage_type: ", damage_type)
	$TypeVisualIndicator.mesh.material = mat[get_type()]


func _on_cohesion_vision_area_entered(area: Area3D) -> void:
	#print(self, " _on_cohesion_vision_area_entered with ", area.get_parent())
	var parent = area.get_parent()
	if self != parent and parent.has_method("get_id") and parent.get_id() in boids_birds:
		cohesion_birds.append(parent)


func _on_cohesion_vision_area_exited(area: Area3D) -> void:
	#print(self, " _on_cohesion_vision_area_exited with ", area.get_parent())
	var parent = area.get_parent()
	if self != parent and parent.has_method("get_id") and parent.get_id() in boids_birds and parent in cohesion_birds:
		cohesion_birds.erase(parent)


func _on_avoidance_vision_area_entered(area: Area3D) -> void:
	#print(self, " _on_avoidance_vision_area_entered with ", area.get_parent())
	var parent = area.get_parent()
	if self != parent and parent.has_method("get_id") and parent.get_id() in boids_birds:
		avoidance_birds.append(parent)


func _on_avoidance_vision_area_exited(area: Area3D) -> void:
	#print(self, " _on_avoidance_vision_area_exited with ", area.get_parent())
	var parent = area.get_parent()
	if self != parent and parent.has_method("get_id") and parent.get_id() in boids_birds and parent in avoidance_birds:
		avoidance_birds.erase(parent)


#func _on_body_body_entered(_body: Node3D) -> void:
	#pass
	#print(id, " bird collide with: ", _body, ", groups: ", _body.get_groups())
	#if _body.is_in_group("Player"):
	#var creature = (_body as Creature)
	#if not spawner or creature.id not in boids_birds:
		#if 	creature and creature.has_method("get_health_component") and \
			#creature.has_method("take_damage"):
				#creature.take_damage(damage, get_type(), armor_pen)


func _on_player_detection_area_entered(area: Area3D) -> void:
	if spawner: spawner.player_detected(area.get_parent(), id)


func _on_player_detection_area_exited(area: Area3D) -> void:
	if spawner: spawner.player_exited(area.get_parent(), id)


func _on_creature_detection_area_entered(area: Area3D) -> void:
	if spawner: spawner.creature_detected(area.get_parent(), id)


func _on_creature_detection_area_exited(area: Area3D) -> void:
	if spawner: spawner.creature_exited(area.get_parent(), id)

## collision with entity
func _on_body_area_entered(area: Area3D) -> void:
	#print(id, " bird _on_body_area_entered: ", (area.get_parent() as Creature).id, " ", area.get_parent())
	var creature = (area.get_parent() as Creature)
	if is_in_lobby or creature.id not in boids_birds:
		if 	creature and creature.has_method("get_health_component") and \
			creature.has_method("take_damage"):
				creature.take_damage(damage, get_type(), armor_pen)
				_apply_effect(creature)
