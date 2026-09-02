extends Enemy

class_name Tentacle

var can_rotate: bool = true
var is_attacking: bool = false
var on_knockback_area: bool = false
var player: Player

var shader_mat: Material
var shader_mat_2: Material
var shader_mat_3: Material

@onready var default_material: MeshInstance3D = $"Sketchfab_Scene/Sketchfab_model/Collada visual scene group/Cube/defaultMaterial"
@onready var default_material_2: MeshInstance3D = $"Sketchfab_Scene/Sketchfab_model/Collada visual scene group/Cube/defaultMaterial2"
@onready var default_material_3: MeshInstance3D = $"Sketchfab_Scene/Sketchfab_model/Collada visual scene group/Cube/defaultMaterial3"
const BOSS_ON_FIRE_1 = preload("res://materials/shaders/boss_on_fire_1.tres")
const BOSS_ON_FIRE_2 = preload("res://materials/shaders/boss_on_fire_2.tres")
const BOSS_ON_FIRE_3 = preload("res://materials/shaders/boss_on_fire_3.tres")

var bird: PackedScene = preload("res://scenes/characters/bird.tscn")

func _ready() -> void:
	health_bar = $HealthBar
	super._ready()
	
	player = get_tree().get_first_node_in_group("Player")
	
	 # TODO: balance :
	health_component._max_health = 350
	health_component.health = health_component._max_health
	health_component._armor = 2.0
	health_component._penetration_resistance = 0.5
	health_component._max_speed = 50 # rotation speed
	health_component.speed = health_component._max_speed
	damage = 15
	damage_type = Enums.DamageType.NORMAL # TODO: when water type is added: change this to water damage type
	$AnimationPlayer.play("idle")
	
	attack_cd = 2.0
	id = -1
	damage_area = $"Sketchfab_Scene/Sketchfab_model/Collada visual scene group/Cube/defaultMaterial2"
	
	health_bar_max_ratio = 10.0


func _on_burn_effect(): # TODO: better fire animation
	pass
	##print("burn_effect")
	#default_material.set_surface_override_material(0, BOSS_ON_FIRE_1)
	#shader_mat = default_material.get_surface_override_material(0)
	#
	#default_material_2.set_surface_override_material(0, BOSS_ON_FIRE_2)
	#shader_mat_2 = default_material_2.get_surface_override_material(0)
	#
	#default_material_3.set_surface_override_material(0, BOSS_ON_FIRE_3)
	#shader_mat_3 = default_material_3.get_surface_override_material(0)
	#
	#shader_mat.set_shader_parameter("shader_parameter/dissolveSlider", 0.0)
	#shader_mat_2.set_shader_parameter("shader_parameter/dissolveSlider", 0.0)
	#shader_mat_3.set_shader_parameter("shader_parameter/dissolveSlider", 0.0)
	#
	##shader_parameter/dissolveSlider
	#var cd: float = StatusEffect.DEFAULT_COOLDOWN / 2
	#var tween = get_tree().create_tween()
	#tween.tween_property(shader_mat, "shader_parameter/dissolveSlider", 0.5, cd)
	#tween.tween_property(shader_mat_2, "shader_parameter/dissolveSlider", 0.5, cd)
	#tween.tween_property(shader_mat_3, "shader_parameter/dissolveSlider", 0.5, cd)
	#
	#var timer = get_tree().create_timer(cd)
	#await timer.timeout
	#
	#default_material.set_surface_override_material(0, null)
	#default_material_2.set_surface_override_material(0, null)
	#default_material_3.set_surface_override_material(0, null)
	#
	

func apply_visual_burn_effect(duration: float) -> void:
	burn_applied += 1
	default_material.set_surface_override_material(0, BOSS_ON_FIRE_1)
	shader_mat = default_material.get_surface_override_material(0)
	
	default_material_2.set_surface_override_material(0, BOSS_ON_FIRE_2)
	shader_mat_2 = default_material_2.get_surface_override_material(0)
	
	default_material_3.set_surface_override_material(0, BOSS_ON_FIRE_3)
	shader_mat_3 = default_material_3.get_surface_override_material(0)
	
	shader_mat.set_shader_parameter("dissolveSlider", 1.0)
	shader_mat_2.set_shader_parameter("dissolveSlider", 1.0)
	shader_mat_3.set_shader_parameter("dissolveSlider", 1.0)
	
	var timer = get_tree().create_timer(duration)
	await timer.timeout
	burn_applied -= 1
	if burn_applied <= 0:
		default_material.set_surface_override_material(0, null)
		default_material_2.set_surface_override_material(0, null)
		default_material_3.set_surface_override_material(0, null)
	

func _physics_process(delta: float) -> void:
	if can_rotate:
		current_cd += delta
		if is_attacking:
			current_cd = 0.0
		
		if current_cd >= attack_cd:
			is_attacking = true
			current_cd = 0.0
			attack_cd = randf_range(0.5, 3.0)
			$AnimationPlayer.play("attack")
			if randf() < 0.2:
				_spawn_boid()
		
		var to_player = player.global_transform.origin - global_transform.origin
		to_player.y = 0
		to_player = to_player.normalized()
		
		var current_y = rotation.y
		var desired_y = atan2(to_player.x, to_player.z)
		var new_y = lerp_angle(current_y, desired_y, 0.1)
		
		rotation.y = new_y


func _spawn_boid() -> void:
	var max_spawn_radius = 10
	
	for i in range(5):
		var new_bird = bird.instantiate()
		new_bird.id = i
		new_bird.summoned = true
		new_bird.set_mob_data("boss_bird" + str(i), 0, 1)
		get_parent().add_child(new_bird)
		new_bird.position = Vector3(randf_range(-1, 1) * max_spawn_radius, randf_range(1, max_spawn_radius), randf_range(-1, 1) * max_spawn_radius)
		new_bird.set_boids(range(5))
		new_bird.set_color(Color.CRIMSON)
		new_bird.set_target(player)

func _attack_end() -> void:
	can_rotate = true
	is_attacking = false
	$AnimationPlayer.play("idle")

func _attack_callibrate() -> void:
	can_rotate = false


func _on_player_listener_area_entered(area: Area3D) -> void:
	#print("player hit: ", area.get_parent())
	if area.get_parent().is_in_group("Player"):
		var creature = (area.get_parent() as Creature)
		if 	creature and creature.has_method("get_health_component") and \
			creature.has_method("take_damage"):
				creature.take_damage(damage, get_type(), armor_pen)


func _attack_touch_ground() -> void:
	var direction: Vector3 = player.position - position
	direction.y = 0
	#print(direction)
	if on_knockback_area:
		#print("too close -> apply velocity")
		player.velocity += direction.normalized() * 120


func _on_knock_back_area_area_entered(_area: Area3D) -> void:
	on_knockback_area = true


func _on_knock_back_area_area_exited(_area: Area3D) -> void:
	on_knockback_area = false


func _death_sequence() -> void:
	# TODO: death animations
	
	is_dead.emit(id) # notify the death (need an id to emit, but isn't used for bosses)
	
	queue_free()
