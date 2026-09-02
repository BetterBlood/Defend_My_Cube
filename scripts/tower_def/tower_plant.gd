extends Tower

class_name TowerPlant

var durations: Array[float] = [7.5, 10., 12.5, 15., 20.]
var cooldowns: Array[float] = [7, 6.5, 6., 5.5, 5.]
var sizes: Array[float] = [2.5, 2.7, 2.9, 3.2, 3.7]
var slow_values: Array[float] = [0.8, 0.7, 0.6, 0.5, 0.3]

const PUDDLE_SCENE = preload("res://scenes/tower_def/puddle.tscn")

func _custom_ready() -> void:
	base_damage = 0.0
	damage_type = Enums.DamageType.PLANT

func _process(_delta: float) -> void:
	attack_cooldown = cooldowns[clamp(level - 1, 0, 4)] # TODO: use cooldowns[clamp(level - 1, 0, 4)] in Tower instead of this !!! and initialise is in custom_ready or in ready with a call to super._ready !!!
	super._process(_delta)

func _perform_attack(_target: Node3D, _current_damage: float) -> void:
	var best_target = null
	for enemy in current_targets:
		if is_instance_valid(enemy):
			best_target = enemy
			break
	
	if not best_target:
		return
	
	var target_pos = best_target.global_position - Vector3(0, 0.8, 0)
	#target_pos.y = 0.0
	
	_throw_dummy_projectile(attack_source.global_position, target_pos)

func _throw_dummy_projectile(start_pos: Vector3, end_pos: Vector3) -> void:
	var dummy = MeshInstance3D.new()
	dummy.mesh = SphereMesh.new()
	dummy.mesh.radius = 0.2
	dummy.mesh.height = 0.4
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.GREEN
	dummy.material_override = mat
	
	get_tree().root.add_child(dummy)
	dummy.global_position = start_pos
	
	var tween = get_tree().create_tween()
	tween.tween_property(dummy, "global_position", end_pos, 0.3)
	
	tween.tween_callback(func():
		dummy.queue_free()
		_spawn_puddle(end_pos)
	)

func _spawn_puddle(pos: Vector3) -> void:
	var puddle = PUDDLE_SCENE.instantiate()
	get_tree().root.add_child(puddle)
	puddle.global_position = pos
	
	if puddle.has_method("setup"):
		puddle.setup(
			durations[level-1],
			sizes[level-1],
			slow_values[level-1],
			base_damage # TODO use _current_damage instead of base_damage
		)
