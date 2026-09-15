extends Node3D

class_name Tower_Def

# polyrinthe stuff
var begin_id: int = 0
@export var size: int = 7 # Default # A2: max 10
@export var polyrinthe: Polyrinthe = Polyrinthe.new()

# mob strength
@export var difficulty: int = 0 # Default [-2; 2] # A2: min -2, max 2

const ICE = preload("res://materials/ice.tres")
const ENV_VALUE = 1
const NORMAL_GRAPPLE = 16
const ICE_GRAPPLE = 32
const NORMAL_WALL_VALUE = NORMAL_GRAPPLE + ENV_VALUE
const ICE_WALL_VALUE = ICE_GRAPPLE + ENV_VALUE

const TOWER_NORMAL = preload("res://scenes/tower_def/tower_normal.tscn")
const TOWER_FIRE = preload("res://scenes/tower_def/tower_fire.tscn")
const TOWER_ELEC = preload("res://scenes/tower_def/tower_elec.tscn")
const TOWER_PLANT = preload("res://scenes/tower_def/tower_plant.tscn")

const TOWER_BASE = preload("res://scenes/tower_def/tower_base.tscn")
@onready var player: Player = $Player
@onready var navigation_region_3d: NavigationRegion3D = $NavigationRegion3D

static var normal_wall_proportion: float = 0.2/3.0

const SPHERE = preload("res://addons/polyrinthe/sphere.tscn")
const SPAWNER = preload("res://scenes/fight/spawner.tscn")
const GOLD = preload("res://scenes/decorations/gold.tscn")
const TORCH = preload("res://scenes/decorations/torch.tscn")
const FAKE_PORTAL = preload("res://scenes/movement/fake_portal.tscn")

const LOOT_ORBE_ICE_GRAPPLE = preload("res://scenes/decorations/loot_orbe_ice_grapple.tscn")

var unlocked_runes: Array[int] = [0]
var gold: int = 0
var essences: Array[int] = [0, 0, 0, 0]


# VR-XR stuff:
var xr_interface: XRInterface



# Tower def stuffs
var spawn_point: Vector3 = Vector3(0, 30, 0)
 # A3: 

# wave things
const WAVE_SPAWNER = preload("res://scenes/fight/wave_spawner.tscn")
const WAVE_BUTTON = preload("res://scenes/tower_def/wave_button.tscn")
var wave_button: WaveButton
var current_wave: int = 0
var is_wave_running: bool = false
var time_between_waves: float = 20.0 # A2: 
var wave_timer: float = 0.0
var wave_configs: Array[Dictionary] = [ # A2: 
	{"count": 10, "lvl": 1},
	{"count": 15, "lvl": 2},
	{"count": 25, "lvl": 3},
	{"count": 35, "lvl": 4},
	{"count": 50, "lvl": 5}
]
var max_waves: int = len(wave_configs)

var wave_infos: Dictionary = {"nbr_enemis": 0, "max_enemis": 0, "wave_count": 0}

var dead_ends: Array[int] = []
var path_to_castle: Array[int] = []
var castle_position: Vector3 = Vector3()
var portal_position: Vector3 = Vector3()

var hologram_instance: Node3D = null
var current_hologram_scene: PackedScene = null
var mat_valid: StandardMaterial3D = StandardMaterial3D.new()
var mat_invalid: StandardMaterial3D = StandardMaterial3D.new()

var end_portal: Node3D
var wave_spawner: Node3D

var is_in_destruction_mode: bool = false

var player_life: int = 10

func _ready() -> void:
	# VR-XR stuff:
	xr_interface = XRServer.find_interface("OpenXR")
	
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR succesfully initialized")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
	else:
		print("OpenXR failed initialization, headset probably not connected.")
		player.remove_child(player.get_child(0))
	
	player.current_player_name = SceneFade.player_name
	player.health_component.health = player_life
	player.health_component._max_health = player_life
	
	if !Enums.damage_type_loaded:
		var config = ConfigFile.new()
		var err = config.load("user://damageGrid.cfg")
		if err != OK:
			Enums.save_grid_damage_type()
		else:
			Enums.load_grid_damage_type(config, true)
	
	navigation_region_3d.add_child(polyrinthe) # TODO add pdf
	
	_init_tower_holo_mat()
	
	_initialise_world()
	
	player.is_dead.connect(_on_player_death)
	player.gain_essence(Enums.DamageType.NORMAL, 2) # TODO: balance
	player.gain_essence(Enums.DamageType.FIRE, 1) # TODO: balance
	player.gain_essence(Enums.DamageType.PLANT, 1) # TODO: balance
	player.gain_essence(Enums.DamageType.ELEC, 1) # TODO: balance
	
	SceneFade.emit_signal("tower_def_loaded")
	
	# TODO : run waves ! (compute a timer for each wave based on the distance (depth of the maze)) and the wave lvl
	print("Waiting player to push button start !") # TODO : UI !
	wave_timer = 10.0
	is_wave_running = false
	update_wave_ui()
	#
	#if wave_button:
		#wave_button.start_wave_triggered.connect(_on_wave_button_triggered)
	
	await get_tree().create_timer(10.0).timeout
	if wave_spawner:
		wave_spawner.start_wave(10, false, 1, 5)
	
	player.is_in_lobby = true

func _init_tower_holo_mat() -> void:
	mat_valid.albedo_color = Color(0.0, 1.0, 0.0, 0.5)
	mat_valid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_valid.emission_enabled = true
	mat_valid.emission = Color(0.0, 0.8, 0.0)
	mat_valid.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	mat_invalid.albedo_color = Color(1.0, 0.0, 0.0, 0.5)
	mat_invalid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_invalid.emission_enabled = true
	mat_valid.emission = Color(0.8, 0.0, 0.0)
	mat_invalid.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _initialise_world() -> void:
	
	_generate_maze()
	
	polyrinthe.generate(size)
	
	polyrinthe.generate(polyrinthe.size, polyrinthe.get_seed(), [-1, -1])
	_save_maze()
	
	if not FileAccess.file_exists("user://" + player.get_player_name() + "/progression.save"):
		if not FileAccess.file_exists("user://" + player.get_player_name() + "/meta.save"):
			push_error("player: " + player.get_player_name() + " does not exist. Player meta load failed. Progression may fail")
		else:
			_save_player_progress(polyrinthe.begin_id) # init player with position (room id)
	
	# once polyrinthe generated:
	set_tag_for_collision_layer(polyrinthe) # ice Wall
	
	
	_generate_maze_modifications(polyrinthe)
	
	
	#once polyrinthe update ready for display
	polyrinthe.display()
	
	_initialise_player()
	
	#TODO: add light in something like 1 room of 3
	# post display modifications 
	apply_collision_layer(polyrinthe, ICE) # static updates for wall grapple collisions 
	
	_apply_maze_modifications(polyrinthe)
	# TODO: add to pdf
	navigation_region_3d.bake_navigation_mesh()

func _generate_maze() -> void:
	polyrinthe.clean()
	polyrinthe.room_scale = 1
	
	if not FileAccess.file_exists("user://" + player.get_player_name() + "/maze.save"):
		push_warning("file:'" + player.get_player_name() + "/maze.save' not found, new generation created with size: " + str(size))
		polyrinthe.algo = polyrinthe.GENERATION_ALGORITHME.DFS_FLAT # A2: change algo
		polyrinthe.begin_id = begin_id
		polyrinthe.generate(size, "", [-1, -1, 1])
		save_meta()
		_save_maze()
	
	# read file info to initialize polyrinthe
	var maze_file = FileAccess.open(
		"user://" + player.get_player_name() + "/maze.save", 
		FileAccess.READ)
	
	while maze_file.get_position() < maze_file.get_length():
		var json_string = maze_file.get_line()
		
		var json = JSON.new()
		
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			push_warning("JSON Parse Error: " + json.get_error_message() + " in " + json_string + " at line " + str(json.get_error_line()))
			continue
		
		var maze_data = json.data
		polyrinthe.begin_id = int(maze_data["begin_id"])
		polyrinthe.algo = polyrinthe.GENERATION_ALGORITHME.values()[maze_data["generation_used"]]
		if polyrinthe.algo < polyrinthe.GENERATION_ALGORITHME.DFS_LBL:
			polyrinthe.reduce_wall = false
		
		difficulty = int(maze_data["difficulty"])
		# ignore default tags
		#for val in maze_data["default_tags"]:
			#default_tags.append(int(val))
		polyrinthe.size = int(maze_data["size"])
		polyrinthe.seed_human = maze_data["seed"]
		#polyrinthe.generate(int(maze_data["size"]), maze_data["seed"], [-1, -1] + default_tags)
		
		# ignore updated tags
		## used after polyrinthe.generate
		#var i = 0
		#for tab in maze_data["updated_tags"]:
			#updated_tags.append([])
			#for val in tab:
				#updated_tags[i].append(int(val))
			#i += 1
		
		# ignore updated chests
		#for val in maze_data["updated_chests"]:
			#updated_chests.append(int(val))
		
		# ignore updated spawners
		#for key in maze_data["updated_spawners"]: # {int, [int]}
			#var array_int: Array[int]
			#for val in maze_data["updated_spawners"][key]:
				#array_int.append(int(val))
			#updated_spawners[key] = array_int
	
	#_save_maze()

func save_meta() -> void:
	var save_file = FileAccess.open("user://" + player.get_player_name() + "/meta.save", FileAccess.WRITE)
	if save_file == null:
		print("Meta Data: first save for user: " + player.get_player_name())
		
		# directory creation with user name
		DirAccess.make_dir_absolute("user://" + player.get_player_name())
		save_file = FileAccess.open("user://" + player.get_player_name() + "/meta.save", FileAccess.WRITE)
		if save_file == null:
			push_error("Cannot save meta data. FileAccess error: " + str(save_file.get_error()))
			return
	
	var save_dict = {
		"current_player_name" : player.get_player_name(),
		"unlocked_runes" : unlocked_runes,
		"equiped_rune_lobby" : player.active_rune.get_rune_id(),
		"gold" : gold,
		"essences" : essences,
		"health_component_upgrades" : player.health_component.get_perm_data(),
	}
	
	var json_string = JSON.stringify(save_dict)
	
	save_file.store_line(json_string)

func _save_maze() -> void:
	var save_file = FileAccess.open("user://" + player.get_player_name() + "/maze.save", FileAccess.WRITE)
	if save_file == null:
		push_error("Cannot save maze data. FileAccess error: " + str(save_file.get_error()))
		return
	
	# get real data from the current maze
	var save_dict = {
		"seed" : polyrinthe.get_seed(),
		"size" : polyrinthe.size,
		"begin_id" : polyrinthe.begin_id,
		"generation_used" : polyrinthe.algo,
		"difficulty" : difficulty,
		"default_tags": [ # TODO: other tags needed !!
			1, # wall default collision layers (automatically update for grapple use in initialisation)
			0, # coloration for near chest rooms
		],
		"updated_tags": [],
		"updated_chests": [],
		"updated_spawners": []
	}
	
	var json_string = JSON.stringify(save_dict)
	
	save_file.store_line(json_string)

func _save_player_progress(save_point_id: int = 0) -> void: 
	player.save_progression(save_point_id)

static func set_tag_for_collision_layer(maze: Polyrinthe) -> void:
	var max_depth = maze.cubeGraph.get_deepest()
	maze.tag_spreads_wide_way(maze.begin_id, 2, max_depth, _generate_array_for_ice_wall_tags(max_depth + 1, NORMAL_WALL_VALUE, ICE_WALL_VALUE))

static func _generate_array_for_ice_wall_tags(array_size: int, normal_value: int, ice_value: int) -> Array[int]:
	var array: Array[int] = []
	
	for i in range(array_size * normal_wall_proportion):
		array.append(normal_value)
	
	for i in range(array_size * normal_wall_proportion, array_size):
		array.append(ice_value)
	
	return array

func _generate_maze_modifications(maze: Polyrinthe) -> void:
	dead_ends = _get_dead_ends(maze)
	path_to_castle = _get_main_path(maze)

func _get_dead_ends(maze: Polyrinthe) -> Array[int]:
	var dead_ends_intern: Array[int] = []
	var total: int = maze.cubeGraph.getNbrRoom()
	for id in range(1, total):
		if not Polyrinthe.is_id_on_first_floor(total, id):
			continue
		var degree = 0
		for n in maze.cubeGraph.getNeighborsConnection(id):
			if n >= 0:
				degree += 1
		if degree == 1:
			dead_ends_intern.append(id)
	return dead_ends_intern

func _get_main_path(maze: Polyrinthe) -> Array[int]:
	var path: Array[int] = [begin_id]
	var visited: Array[int] = [begin_id]
	var curr_id: int = begin_id
	
	while curr_id != maze.deepest_id:
		var next_room_ids: Array[int] = maze.cubeGraph.getNextNeighbors(curr_id)
		var unvisited: Array[int] = next_room_ids.filter(func(id): return id not in visited)
		
		if unvisited.is_empty():
			if path.size() <= 1:
				push_warning("No path found to deepest_id")
				break
			path.pop_back()
			curr_id = path[-1]
			continue
		
		curr_id = unvisited[0]
		visited.append(curr_id)
		path.append(curr_id)
	
	return path # A3:

func _initialise_player():
	if not FileAccess.file_exists("user://" + player.get_player_name() + "/meta.save"):
		push_error("player: " + player.get_player_name() + " does not exist. Player meta load failed")
		return
		
	var meta_file = FileAccess.open(
		"user://" + player.get_player_name() + "/meta.save", 
		FileAccess.READ)
	
	var meta_data = null
	
	while meta_file.get_position() < meta_file.get_length():
		var json_string = meta_file.get_line()
		
		var json = JSON.new()
		
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			push_warning("JSON Parse Error: " + json.get_error_message() + " in " + json_string + " at line " + json.get_error_line())
			continue
		
		meta_data = json.data
	
	# progression data
	if not FileAccess.file_exists("user://" + player.get_player_name() + "/progression.save"):
		push_error("player: " + player.get_player_name() + " does not exist. Player initialisation for progression failed")
		return
	
	var progression_file = FileAccess.open(
		"user://" + player.get_player_name() + "/progression.save", 
		FileAccess.READ)
	
	var game_data = null
	
	while progression_file.get_position() < progression_file.get_length():
		var json_string = progression_file.get_line()
		
		var json = JSON.new()
		
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			push_warning("JSON Parse Error: " + json.get_error_message() + " in " + json_string + " at line " + str(json.get_error_line()))
			continue
		
		game_data = json.data
	
	# ignore player position
	#last_save_id = int(game_data["save_spot_id"])
	
	player.initialize_player(meta_data, game_data)
	player.set_difficulty(difficulty)
	player.position = spawn_point

static func apply_collision_layer(maze: Polyrinthe, material: StandardMaterial3D = ICE) -> void:
	for key in maze.maze.keys():
		var col_layer = maze.cubeGraph.get_tag(key, 2)
		for wall: Node3D in maze.maze.get(key).get_children():
			wall.collision_layer = col_layer
			if col_layer == ICE_WALL_VALUE:
				wall.get_children()[0].material_override = material

func _apply_maze_modifications(maze: Polyrinthe) -> void:
	# TODO: 
	#	- add a castle at the end
	
	_build_elevated_path(maze)
	
	var path_height = 0.8 * (maze.CubeCustom.distFromCenter) * 2 * maze.room_scale
	
	wave_spawner = WAVE_SPAWNER.instantiate()
	#wave_spawner.set_maze(self)
	add_child(wave_spawner)
	#wave_spawner.id = spawner_id
	wave_spawner.position = maze.maze[maze.begin_id].position + Vector3(-3, -(2.5 * maze.room_scale), 5 * maze.room_scale - 2) + Vector3(0, path_height, 0)
	#spawner.initialise_mobs_list(maze.seed_human + "_spawner_" + str(spawner_id), mob_id_to_avoid)
	# A4: connect signal wave end
	wave_spawner.wave_updated.connect(_on_wave_updated)
	
	portal_position = maze.maze[maze.begin_id].position + Vector3(-3, -(2.5 * maze.room_scale), 5 * maze.room_scale - 2)
	var spawn_portal = FAKE_PORTAL.instantiate()
	add_child(spawn_portal)
	spawn_portal.position = portal_position + Vector3(0, path_height + 1, 0)
	spawn_portal.rotate(Vector3.UP, -45)
	spawn_portal.scale = Vector3(maze.room_scale, maze.room_scale, maze.room_scale) * 2
	
	# A4: wave button
	
	castle_position = maze.maze[maze.deepest_id].position + Vector3(0, path_height, 0)
	
	#for dead_end_id in dead_ends:
		#var sphere_dead_end = SPHERE.instantiate()
		#add_child(sphere_dead_end)
		#sphere_dead_end.get_child(0).mesh.material.albedo_color = Color(0.8, 0.1, 0.9, 1)
		#sphere_dead_end.position = maze.maze[dead_end_id].global_position
	#
	#for path_id in path_to_castle:
		#print("path_id ", path_id)
		#var sphere_path = SPHERE.instantiate()
		#add_child(sphere_path)
		#sphere_path.get_child(0).mesh.material.albedo_color = Color(1, 0.8, 0.1, 1)
		#sphere_path.position = maze.maze[path_id].global_position + Vector3(0, 5, 0)
	#
	var available_slots: Array[TowerSlot] = [] # A3: 
	var rooms: int = maze.cubeGraph.getNbrRoom()
	
	for tmp_id in range (rooms):
		if Polyrinthe.is_id_on_first_floor(size,tmp_id) and tmp_id not in path_to_castle:
			
	# A3: 
			#var sphere_path_dead_end = SPHERE.instantiate()
			#add_child(sphere_path_dead_end)
			#sphere_path_dead_end.get_child(0).mesh.material.albedo_color = Color(0, 0.8, 0.5, 1)
			#sphere_path_dead_end.position = maze.maze[tmp_id].global_position + Vector3(0, 10, 0)
	## A3: 
			var tower_base = TOWER_BASE.instantiate()
			add_child(tower_base)
			tower_base.scale = Vector3(maze.room_scale, maze.room_scale, maze.room_scale)*1.05
			tower_base.position = maze.maze[tmp_id].global_position
			available_slots.append(tower_base)
	
	
	_place_random_towers(available_slots, 5) # TODO: remove in eleve
	
	# check player grapple to know if it's needed to spawn this upgrade
	if player.grapple.upgrades[3] == 0:
		var loot_orbe_ice_grapple = LOOT_ORBE_ICE_GRAPPLE.instantiate()
		# TODO: make the orbe spawn at a certain level
		#loot_orbe_ice_grapple.position = maze.maze[grapple_ice_upgrade_room_id].position
		#add_child(loot_orbe_ice_grapple)
		
	else: # the player has already loot the ice upgrade
		player.grapple.upgrade_ice_grapple_color()
	
	#var sphere_begin = SPHERE.instantiate()
	#add_child(sphere_begin)
	#sphere_begin.get_child(0).mesh.material.albedo_color = Color(1, 1, 1, 1)
	##sphere_begin.position = maze.maze[maze.deepest_id].position - Vector3(0, 0, 5)
	#sphere_begin.position = Vector3(0, 0, 0)
	
	#var sphere_end = SPHERE.instantiate()
	#add_child(sphere_end)
	#sphere_end.get_child(0).mesh.material.albedo_color = Color(0, 0, 0, 1)
	#sphere_end.position = maze.maze[maze.deepest_id].position - Vector3(0, 0, 5)
	
	
	end_portal = FAKE_PORTAL.instantiate()
	add_child(end_portal)
	end_portal.rotation = Vector3(0, PI/2, 0) # TODO: check orientation for last room and previous one (orientation of the last portal)
	end_portal.position = maze.maze[maze.deepest_id].position - Vector3(0, 2.5 * maze.room_scale, 0) + Vector3(0, path_height + 1, 0)
	end_portal.scale = Vector3(maze.room_scale, maze.room_scale, maze.room_scale) * 2
	
	wave_spawner.setup_end_portal(end_portal)
	
	#TODO : connect the mob damages to castle :
	wave_spawner.damage_castle.connect(_tmp_on_castle_taking_damage)

func _build_elevated_path(maze: Polyrinthe) -> void:
	var room_size = (maze.CubeCustom.distFromCenter) * 2 * maze.room_scale
	var floor_elevation = 0.8 * room_size
	var floor_thickness = 0.2 * maze.room_scale
	
	var path_material = StandardMaterial3D.new()
	path_material.albedo_color = Color(0.377, 0.231, 0.121, 1.0)
	
	for room_id in path_to_castle:
		var room_pos = maze.maze[room_id].position
		var floor_body = StaticBody3D.new()
		floor_body.set_collision_layer_value(5, true)
		
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(room_size, floor_thickness, room_size)
		collision_shape.shape = box_shape
		
		var mesh_instance = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = box_shape.size
		box_mesh.material = path_material
		mesh_instance.mesh = box_mesh
		
		floor_body.add_child(collision_shape)
		floor_body.add_child(mesh_instance)
		
		floor_body.position = room_pos + Vector3(0, (floor_elevation - (floor_thickness / 2.0)) / 2, 0)
		
		navigation_region_3d.add_child(floor_body)

func _place_random_towers(slots: Array[TowerSlot], amount: int) -> void:
	var shuffled_slots = slots.duplicate()
	shuffled_slots.shuffle()
	
	for i in range(min(amount, shuffled_slots.size())):
		var tower = TOWER_NORMAL.instantiate() as Tower
		shuffled_slots[i].build_tower(tower)

func _process(delta: float) -> void:
	#_handle_tower_placement()
	
	if not is_wave_running and current_wave < max_waves and current_wave > 0:
		wave_timer -= delta
		if wave_timer <= 0.0:
			_start_next_wave()
	
	update_wave_ui()

func _physics_process(_delta: float) -> void:
	
	_handle_tower_placement()
	
	if InputMap.has_action("demolition_toggle") and Input.is_action_just_pressed("demolition_toggle"):
		#print("demolition_toggle ?")
		is_in_destruction_mode = not is_in_destruction_mode
		
		# TODO : do it for VR too
		var ui_node = player.ui if player.ui else player.get_node_or_null("CanvasLayer/UI")
		
		if ui_node and ui_node.has_method("set_destruction_mode"):
			ui_node.set_destruction_mode(is_in_destruction_mode)
		else:
			print("ui_node not found or set_destruction_mode function unreachable")
		
		#if is_in_destruction_mode:
			#print("Mode Destruction : ACTIVE")
		#else:
			#print("Mode Destruction : DESACTIVE")
		
		hide_hologram()

func update_wave_ui() -> void:
	var ui_node = player.ui if player.ui else player.get_node_or_null("CanvasLayer/UI")
	if not is_instance_valid(ui_node):
		return
	
	var wave_info_label = ui_node.get_node("WaveInfoLabel")
	if not is_instance_valid(wave_info_label):
		return
	
	if not is_wave_running and current_wave < max_waves:
		if current_wave == 0:
			wave_info_label.text = "Hit the button to start !"
		else:
			var time_left = wave_timer 
			wave_info_label.text = "Wave " + str(current_wave) + " finished\nNext Wave in : " + str(snapped(time_left, 0.1)) + "s"
	else:
		wave_info_label.text = "Wave " + str(current_wave) + "\nEnemis : " + str(wave_infos["nbr_enemis"]) + " / " + str(wave_infos["max_enemis"])

func _on_wave_button_triggered() -> void:
	if current_wave < max_waves:
		force_start_next_wave()

func _start_next_wave() -> void:
	if current_wave >= max_waves:
		if is_instance_valid(wave_button):
			wave_button.queue_free()
		return
	 
	is_wave_running = true
	var config = wave_configs[current_wave]
	
	print("Launching wave ", current_wave + 1) # TODO : UI !
	
	if wave_spawner:
		wave_spawner.start_wave(config["count"], false, config["lvl"], max_waves)
	
	wave_button.set_active_visuals(false)
	player.is_in_lobby = false
	
	current_wave += 1
	update_wave_ui()

func _on_wave_updated(nbr_enemis: int, max_enemis: int, wave_count: int) -> void:
	wave_infos["nbr_enemis"] = nbr_enemis
	wave_infos["max_enemis"] = max_enemis
	wave_infos["wave_count"] = wave_count
	
	update_wave_ui()

func _on_wave_finished() -> void:
	is_wave_running = false
	if current_wave < max_waves:
		wave_timer = time_between_waves
		#print("Wave ended. Next wave in ", time_between_waves, " sec.")
		if is_instance_valid(wave_button):
			wave_button.set_active_visuals(true)
		player.is_in_lobby = true
	#else:
		##print("Victory !")
		#if is_instance_valid(wave_button):
			#wave_button.queue_free()
	
	update_wave_ui()

func force_start_next_wave() -> void:
	print("force_start_next_wave:current_wave: ", current_wave)
	if not is_wave_running:
		wave_timer = 0.0
		if current_wave != 0: # first wave launch !
			var time_saved = wave_timer
			var bonus_essence = int(time_saved * 1.5)
			player.gain_essence(Enums.DamageType.NORMAL, bonus_essence) # TODO: update with other essences too
			print("Wave launched earlier ! Bonus : ", bonus_essence) # TODO : UI !
		_start_next_wave()
	elif is_wave_running and current_wave < max_waves: # launch before the end of the previous wave
		var time_saved = time_between_waves
		var bonus_essence = int(time_saved * 2)
		player.gain_essence(Enums.DamageType.NORMAL, bonus_essence) # TODO: update with other essences too
		print("Wave launched way earlier ! Big bonus : ", bonus_essence) # TODO : UI !
		
		wave_timer = 0.0
		_start_next_wave()
	
	update_wave_ui()

func _handle_tower_placement() -> void:
	var ui_node = player.ui if player.ui else player.get_node_or_null("CanvasLayer/UI")
	if not ui_node or ui_node.current_towers_data.is_empty():
		hide_hologram()
		return
	
	var selected_tower_dict = ui_node.current_towers_data[ui_node.current_selected_index]
	var selected_tower_scene = selected_tower_dict["scene"]
	var selected_tower_level = ui_node.current_tower_level
	var base_cost = selected_tower_dict.get("cost", 3)
	var tower_cost = base_cost * int(pow(2, selected_tower_level - 1))
	var tower_type = selected_tower_dict.get("type", Enums.DamageType.NORMAL)
	
	if not selected_tower_scene is PackedScene or is_in_destruction_mode:
		hide_hologram()
		#return
	
	if xr_interface and xr_interface.is_initialized():
		var right_controller = player.get_node("XROrigin3D/RightController") #TODO: check VR, Sa me semble complètement faux ça
		player.ray_cast_3d.global_transform = right_controller.global_transform.rotated_local(Vector3.RIGHT, deg_to_rad(-45))
	else:
		player.ray_cast_3d.transform = Transform3D()
	
	player.ray_cast_3d.collision_mask = 1
	player.ray_cast_3d.target_position = Vector3(0, 0, -50.0)
	player.ray_cast_3d.force_raycast_update()
	
	if player.ray_cast_3d.is_colliding():
		var collider = player.ray_cast_3d.get_collider()
		var tower_base = collider.get_parent()
		
		if tower_base is TowerSlot:
			var is_empty = tower_base.is_free()
			
			if is_in_destruction_mode:
				if not is_empty:
					var target_tower = tower_base.current_tower
					var target_scene = load(target_tower.scene_file_path)
					
					tower_cost = base_cost * int(pow(2, selected_tower_level - 1))
					update_hologram(target_scene, tower_base.global_position, false)
					if InputMap.has_action("attack") and Input.is_action_just_pressed("attack"):
						var target_base_cost = target_tower.get("base_cost")
						var target_type = target_tower.get("damage_type")
						var target_level = target_tower.get("level")
						
						var target_cost = target_base_cost * int(pow(2, target_level - 1))
						
						_destroy_and_refund_tower(tower_base, target_cost, target_type)
				else:
					hide_hologram()
			elif selected_tower_scene is PackedScene:
				var can_build_new = false
				var can_upgrade = false
				
				if is_empty:
					if _check_player_essences(tower_type, tower_cost):
						can_build_new = true
				else:
					var current_tower = tower_base.current_tower
					if current_tower and current_tower.get("damage_type") == tower_type:
						var current_level = current_tower.get("level")
						if current_level < Tower.max_level and selected_tower_level == current_level:
							var upgrade_cost = tower_cost
							if _check_player_essences(tower_type, upgrade_cost):
								can_upgrade = true
				
				var is_valid = can_build_new or can_upgrade
				update_hologram(selected_tower_scene, tower_base.global_position, is_valid)
				
				if InputMap.has_action("attack") and Input.is_action_just_pressed("attack") and is_valid:
					if can_build_new:
						_place_tower(tower_base, selected_tower_scene, selected_tower_level, tower_type)
					elif can_upgrade:
						_upgrade_tower(tower_base, tower_type)
		else:
			hide_hologram()
	else:
		hide_hologram()

func _check_player_essences(type: int, amount: int) -> bool:
	if type >= 0 and type < player.essences.size():
		return player.essences[type] >= amount
	return false

func _consume_player_essence(type: int, amount: int) -> void:
	if type >= 0 and type < player.essences.size():
		player.gain_essence(type, -amount)

func _place_tower(base: TowerSlot, tower_scene: PackedScene, lvl: int, type: int) -> void:
	var new_tower = tower_scene.instantiate()
	
	new_tower.set("tower_type", type)
	new_tower.set("level", lvl)
	
	base.build_tower(new_tower)
	_consume_player_essence(type, new_tower.base_cost * int(pow(2, lvl - 1)))
	
	hide_hologram()
	
	if hologram_instance:
		hologram_instance.queue_free()
		hologram_instance = null
		current_hologram_scene = null

func _upgrade_tower(base: TowerSlot, type: Enums.DamageType) -> void:
	var current_tower = base.current_tower
	var current_level = current_tower.level
	
	_consume_player_essence(type, current_tower.base_cost * int(pow(2, current_level - 1)))
	current_tower.upgrade_tower()
	print("Tower upgraded to lvl ", current_tower.get("level"))
	
	if current_tower.has_method("upgrade_tower_visuals"):
		current_tower.upgrade_tower_visuals() # TODO when différent visuals 
	
	hide_hologram()

func _destroy_and_refund_tower(base: TowerSlot, refund_amount: int, type: Enums.DamageType) -> void:
	var current_tower = base.current_tower
	if current_tower:
		player.gain_essence(type, refund_amount)
		current_tower.queue_free()
		base.current_tower = null
		hide_hologram()

#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("demolition_toggle"):
		#print("demolition_toggle wtf ?")
		#is_in_destruction_mode = not is_in_destruction_mode
		#
		## TODO : do it for VR too
		#var ui_node = player.ui if player.ui else player.get_node_or_null("CanvasLayer/UI")
		#
		#if ui_node and ui_node.has_method("set_destruction_mode"):
			#ui_node.set_destruction_mode(is_in_destruction_mode)
		#else:
			#print("ui_node not found or set_destruction_mode function unreachable")
		#
		##if is_in_destruction_mode:
			##print("Mode Destruction : ACTIVE")
		##else:
			##print("Mode Destruction : DESACTIVE")
		#
		#hide_hologram()

func _tmp_on_castle_taking_damage(damage: float) -> void:
	# TODO: connect castle !
	print("castle takes damage: ", damage)
	player.take_damage(damage, Enums.DamageType.NORMAL, 0.0)
	print("player life: ", player.health_component.health, "/", player.health_component._max_health)

func _on_player_death(_id: int) -> void:
	player.set_ressource_on_death()
	# TODO: return to main menu may be better 
	SceneFade.change_scene_with_file("res://scenes/tower_def/tower_def.tscn", SceneFade.tower_def_loaded)


func update_hologram(tower_scene: PackedScene, target_position: Vector3, is_valid_placement: bool) -> void:
	if current_hologram_scene != tower_scene:
		if hologram_instance:
			hologram_instance.queue_free()
			hologram_instance = null
		current_hologram_scene = tower_scene
	
	if not hologram_instance:
		hologram_instance = tower_scene.instantiate()
		add_child(hologram_instance)
		_strip_for_hologram(hologram_instance)
		
		#current_hologram_scene = tower_scene
		#_disable_logic_and_physics(hologram_instance)
	
	hologram_instance.visible = true
	hologram_instance.global_position = target_position + Vector3(0, 7.5, 0)
	hologram_instance.scale = Vector3(2,2,2)
	
	var current_mat = mat_valid if is_valid_placement else mat_invalid
	_apply_material_override(hologram_instance, current_mat)

func hide_hologram() -> void:
	if hologram_instance and hologram_instance.visible:
		hologram_instance.visible = false

func _strip_for_hologram(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	
	if node is CollisionShape3D or node is CollisionPolygon3D:
		node.disabled = true
	
	for child in node.get_children():
		_strip_for_hologram(child)

func _disable_logic_and_physics(node: Node) -> void:
	if node is CollisionShape3D or node is CollisionPolygon3D:
		node.disabled = true
	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children():
		_disable_logic_and_physics(child)

func _apply_material_override(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_apply_material_override(child, mat)

# A2:
func _on_respawn_zone_area_entered(_area: Area3D) -> void:
	player.position = spawn_point
