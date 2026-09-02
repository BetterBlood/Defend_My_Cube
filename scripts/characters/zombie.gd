extends Enemy

class_name Zombie

const SPEED:float = 3.0
@onready var navigation_agent_3d: NavigationAgent3D = $Navigation/NavigationAgent3D
var target: Creature
var base_position: Vector3
var is_attacking: bool = false
var player_at_range: bool = false
@onready var burn_effect: MeshInstance3D = $Effect
var burn_shader_mat: ShaderMaterial

func _ready() -> void:
	health_bar = $HealthBar
	super._ready()
	
	if is_in_lobby:
		health_component._health_regen_per_sec = 1.0
	
	health_component._armor = 0.0
	health_component._penetration_resistance = 0.0
	health_component._max_speed = SPEED
	health_component.speed = SPEED 
	
	burn_shader_mat = burn_effect.mesh.material
	
	$Navigation/UpdateNavigation.timeout.connect(compute_path)
	
	damage_area = $MeshInstance3D


func _physics_process(delta: float) -> void:
	if not base_position and not $Navigation/UpdateNavigation.is_stopped():
		$Navigation/UpdateNavigation.stop() # while not base position, stop the computation
	elif $Navigation/UpdateNavigation.is_stopped():
		$Navigation/UpdateNavigation.start()
	
	var prev_gravity = velocity.y
	
	var direction = Vector3()
	if target or not navigation_agent_3d.is_navigation_finished():
		direction = (navigation_agent_3d.get_next_path_position() - global_position).normalized()
	velocity = velocity.lerp(direction * health_component.speed, delta * 10)
	
	if player_at_range:
		velocity = Vector3()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * 4
		#base_position = null
		velocity.y += prev_gravity  * delta * 4
	
	move_and_slide()

func _on_burn_effect():
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

func set_mob_data(human_seed: String, difficulty: int, depth_ratio: float) -> void:
	super.set_mob_data(human_seed, difficulty, depth_ratio)
	#print("Zombie::set_mob_data damage_type: ", damage_type)
	
	$TypeVisualIndicator.mesh.material = mat[get_type()]

func compute_path() -> void:
	#print("compute_path: ", base_position, ", target: ", target)
	if target:
		#print(target)
		navigation_agent_3d.target_position = target.global_position
	elif base_position:
		navigation_agent_3d.target_position = base_position
	
	var look_direction = Vector3(navigation_agent_3d.target_position.x, global_position.y, navigation_agent_3d.target_position.z)
	if (look_direction - global_position).length() > 0.2: # avoid errors on look_at himself
		look_at(look_direction, Vector3.UP, true)

func _on_enemy_area_3d_body_entered(_body: Node3D) -> void:
	#print("enemy collide with: ", _body, ", groups: ", _body.get_groups())
	if not base_position and not _body.is_in_group("Player"):
		base_position = global_position
		#print(self, " set base_position to: ", base_position)
	elif _body.is_in_group("Player"):
		var creature = (_body as Creature)
		if 	creature and creature.has_method("get_health_component") and \
			creature.has_method("take_damage"):
				creature.take_damage(damage, get_type(), armor_pen)
				_apply_effect(creature)


#func _update_life_display() -> void:
	#var health_ratio: float = health_component.health / health_component.get_max_health()
	##print(self, " _update_life_display, health_ratio: ", health_ratio)
	#$HealthBar.set_instance_shader_parameter("health", health_ratio)


func _on_chase_area_area_entered(area: Area3D) -> void:
	#print("_on_chase_area_area_entered")
	target = area.get_parent()


func _on_release_chase_area_area_exited(area: Area3D) -> void:
	#print("_on_release_chase_area_area_exited")
	if target == area.get_parent():
		target = null


func _on_attack_area_area_entered(_area: Area3D) -> void:
	player_at_range = true
	try_attack()


func _on_attack_area_area_exited(_area: Area3D) -> void:
	player_at_range = false


func try_attack() -> void:
	if player_at_range and !is_attacking:
		is_attacking = true
		$AnimationPlayer.play("attack")

func recover_after_attack() -> void:
	$AnimationPlayer.play("recover")

func end_attack() -> void:
	is_attacking = false
	await get_tree().create_timer(0.3).timeout
	try_attack()
