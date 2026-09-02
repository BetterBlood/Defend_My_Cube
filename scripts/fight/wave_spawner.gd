extends Spawner

class_name WaveSpawner

signal damage_castle(value: float)

var end_portal_ref: Node3D
var sec_between_mob_spawn: float = 1.0

# wave manage
var total_mobs_per_wave: Array[int] = []
var mobs_processed: int = 0
var current_wave: int = 0
signal wave_updated(nbr_enemis: int, max_enemis: int, wave_number: int)
@warning_ignore("unused_signal")
signal wave_finished()

func _ready() -> void:
	possible_mobs = [
		preload("res://scenes/tower_def/zombie_td.tscn"),
	]

func setup_end_portal(portal: Node3D) -> void:
	end_portal_ref = portal
	
	var portal_area = end_portal_ref.get_node_or_null("Area3D")
	if portal_area:
		portal_area.set_collision_mask_value(2, false)
		portal_area.set_collision_mask_value(3, true)
		if not portal_area.area_entered.is_connected(_on_end_portal_area_entered):
			portal_area.area_entered.connect(_on_end_portal_area_entered)

func start_wave(mob_count: int, aggro_player: bool = false, wave_nbr: int = 1, wave_max: int = 5) -> void:
	total_mobs_per_wave.append(mob_count)
	current_wave += 1
	#mobs_processed = 0
	
	for i in range(mob_count):
		var new_id = Enemy.get_next_id()
		var human_seed = "wave_lvl_" + str(wave_nbr) + "_mob_" + str(new_id)
		rng.seed = hash(human_seed)
		
		var mob_type: int = rng.randi_range(0, len(possible_mobs) - 1)
		var new_mob = possible_mobs[mob_type].instantiate()
		
		new_mob.id = new_id
		# A4: connect
		current_mobs.append(new_mob)
		
		new_mob.set_mob_data(human_seed, (wave_nbr/(wave_max as float))*5 - 3, i/(mob_count as float))
		new_mob.lvl = wave_nbr
		add_child(new_mob)
		
		#new_mob.position = Vector3(randf_range(-1, 1) * 2.0, 0, randf_range(-1, 1) * 2.0)
		
		if end_portal_ref and "base_position" in new_mob:
			new_mob.base_position = end_portal_ref.global_position
		
		if not aggro_player:
			_disable_player_detection(new_mob)
		
		var total_mobs = 0
		for mob_per_wave in total_mobs_per_wave:
			total_mobs += mob_per_wave
		wave_updated.emit(mobs_processed, total_mobs, current_wave)
		
		await get_tree().create_timer(sec_between_mob_spawn).timeout

func _check_wave_end() -> void:
	var total_mobs = 0
	for mob_per_wave in total_mobs_per_wave:
		total_mobs += mob_per_wave
	if mobs_processed >= total_mobs:
		pass # A4: signal ?
	# A4: signals ?

func _disable_player_detection(mob: Enemy) -> void:
	for child in mob.get_children():
		if child is Area3D:
			child.set_collision_mask_value(2, false)

func _on_end_portal_area_entered(area: Area3D) -> void:
	var mob = area.get_parent()
	
	if mob is Enemy:
		damage_castle.emit(float(mob.lvl)) # TODO: consider using mob.damage
		
		if mob.id not in mob_dead:
			mob_dead.append(mob.id)
		
		mob.queue_free()
		mobs_processed += 1
		_check_wave_end()
		# TODO: damage animation ?
















func _on_mob_death(mob_id: int) -> void:
	# override parent one, DO NOT REMOVE !
	if mob_id in mob_dead:
		return
		
	#print("_on_mob_death::_mob_id: ", mob_id)
	mob_dead.append(mob_id)
	# A4: process
	# A4: check wave

func _process(_delta: float) -> void:
	# override parent one, DO NOT REMOVE !
	pass

func _on_area_3d_area_entered(_area: Area3D) -> void:
	# override parent one, DO NOT REMOVE !
	pass

func _on_area_3d_area_exited(_area: Area3D) -> void:
	# override parent one, DO NOT REMOVE !
	pass
