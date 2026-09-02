extends Node3D

class_name Maze

# polyrinthe stuff
@export var size: int = 7 # Default
@export var polyrinthe: Polyrinthe = Polyrinthe.new()
@export var difficulty: int = 0 # Default [-2; 2]
var default_tags: Array[int] = [1, 0]
var updated_tags: Array = []
var updated_chests: Array[int] = []
var updated_spawners: Dictionary = {}

#const Logger = preload("res://scripts/CSharp/Logger.cs")
#var logger:Logger = Logger.new()

const ICE = preload("res://materials/ice.tres")
const ENV_VALUE = 1
const NORMAL_GRAPPLE = 16
const ICE_GRAPPLE = 32
const NORMAL_WALL_VALUE = NORMAL_GRAPPLE + ENV_VALUE
const ICE_WALL_VALUE = ICE_GRAPPLE + ENV_VALUE

@onready var player: Player = $Player
@onready var navigation_region_3d: NavigationRegion3D = $NavigationRegion3D

var chests_room_ids: Array[int] = []
var spawners_room_ids: Array[int] = []
var save_points_room_ids: Array[int] = []
var grapple_ice_upgrade_room_id: int

static var normal_wall_proportion: float = 2.0/3.0

const SPHERE = preload("res://addons/polyrinthe/sphere.tscn") # DEBUG
const PEDESTRAL = preload("res://scenes/decorations/pedestral.tscn")
const SPAWNER = preload("res://scenes/fight/spawner.tscn")
const GOLD = preload("res://scenes/decorations/gold.tscn")
const TORCH = preload("res://scenes/decorations/torch.tscn")

const LOOT_ORBE_ICE_GRAPPLE = preload("res://scenes/decorations/loot_orbe_ice_grapple.tscn")

var save_pedestral_position: Vector3 = Vector3(-5, 9.7, 5)
var chest_pedestral_position: Vector3 = Vector3(5, 9.7, 5)
var last_save_id: int = 0

const FAKE_PORTAL = preload("res://scenes/movement/fake_portal.tscn")
var boss_room: PackedScene = preload("res://scenes/boss_room.tscn")
var lobby_scene: PackedScene = preload("res://scenes/demo/lobby.tscn")


# VR-XR stuff:
var xr_interface: XRInterface



#func _init(new_player_name: String = "DEBUG") -> void:
	#player_name = new_player_name

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
	#add_child(logger)
	#logger.Info("An informational message: " + self.to_string());
	#logger.Debug("A Debug message: " + self.to_string());
	#
	#for line in logger.GetLines():
		#print(line)
	#print()
	
	if !Enums.damage_type_loaded:
		var config = ConfigFile.new()
		var err = config.load("user://damageGrid.cfg")
		if err != OK:
			Enums.save_grid_damage_type()
		else:
			Enums.load_grid_damage_type(config, true)
	
	navigation_region_3d.add_child(polyrinthe)
	
	_initialise_world()
	
	player.is_dead.connect(_on_player_death)
	
	SceneFade.emit_signal("maze_loaded")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("launch_generation"):
		print("pressed")
		#player.grapple.upgrade_wall()
		#player.active_rune = RuneUpgradeBounce.new(player.active_rune)
		player.gain_xp(1000.0)
		#_save_player_progress(size*size-1)
		#_initialise_player()
		#SceneFade._erase_player_progress(player.get_player_name())
		#print("player.health_component.get_max_life(): ", player.health_component.get_max_health())


func _initialise_world() -> void:
	
	_generate_maze()
	
	polyrinthe.generate(polyrinthe.size, polyrinthe.get_seed(), [-1, -1] + default_tags)
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
	
	navigation_region_3d.bake_navigation_mesh()


func _generate_maze() -> void:
	polyrinthe.clean()
	polyrinthe.room_scale = 2
	
	if not FileAccess.file_exists("user://" + player.get_player_name() + "/maze.save"):
		push_warning("file:'" + player.get_player_name() + "/maze.save' not found, new generation created with size: " + str(size))
		polyrinthe.algo = polyrinthe.GENERATION_ALGORITHME.DFS_LBL_ALT_6
		polyrinthe.begin_id = 0
		polyrinthe.generate(size, "", [-1, -1, 1])
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
		for val in maze_data["default_tags"]:
			default_tags.append(int(val))
		polyrinthe.size = int(maze_data["size"])
		polyrinthe.seed_human = maze_data["seed"]
		#polyrinthe.generate(int(maze_data["size"]), maze_data["seed"], [-1, -1] + default_tags)
		
		# used after polyrinthe.generate
		var i = 0
		for tab in maze_data["updated_tags"]:
			updated_tags.append([])
			for val in tab:
				updated_tags[i].append(int(val))
			i += 1
		
		for val in maze_data["updated_chests"]:
			updated_chests.append(int(val))
		
		for key in maze_data["updated_spawners"]: # {int, [int]}
			var array_int: Array[int]
			for val in maze_data["updated_spawners"][key]:
				array_int.append(int(val))
			updated_spawners[key] = array_int
	
	#_save_maze()


func _generate_maze_modifications(maze: Polyrinthe) -> void:
	#determine chests / spawners / save_points locations (room id) based on the seed and the polyrinthe maze given 
	var maze_size = maze.size
	var maze_nbr_rooms = maze_size * maze_size * maze_size
	
	var nbr_save_points = maze_size - difficulty * 2
	var nbr_chests = maze_size * 2 - difficulty * 2
	var nbr_spawner = max(5, ceil(maze_nbr_rooms / 4.0) + difficulty * 3)
	
	# init save_points room ids :
	_init_tabs(nbr_save_points, maze_nbr_rooms, save_points_room_ids, maze.get_seed() + "save_points")
	# init chest room ids :
	_init_tabs(nbr_chests, maze_nbr_rooms, chests_room_ids, maze.get_seed() + "chests")
	# init spawner room ids :
	_init_tabs(nbr_spawner, maze_nbr_rooms, spawners_room_ids, maze.get_seed() + "spawner")
	
	# apply updated chests
	for i in range(len(chests_room_ids) - 1, -1, -1):
		var id = chests_room_ids[i]
		if id in updated_chests:
			chests_room_ids.remove_at(i)
	
	#print("save_points_room_ids\t\t: ", save_points_room_ids)
	#print("updated_chests\t\t\t: ", updated_chests)
	#print("chests_room_ids\t\t\t: ", chests_room_ids)
	#print("spawners_room_ids\t\t: ", spawners_room_ids)
	
	grapple_ice_upgrade_room_id = _find_last_dead_end_before_ice(maze)
	#print("grapple upgrade room id: ", grapple_ice_upgrade_room_id)
	
	# apply tags spreads arround chests (yellow spheres for tresors/chests) 
	for chest_id in chests_room_ids:
		maze.tag_spreads_wide_way(chest_id, 3, 4, [100, 80, 60, 40, 20], true)


# init given array with room ids # TODO: add a param array with id to dodge ?
func _init_tabs(
		nbr_occurence: int, 
		nbr_room_total: int, 
		tab_to_populate: Array[int],
		new_seed: String) -> void:
	
	if nbr_occurence > nbr_room_total:
		push_error("bad_initialisation: maze initialized without any spawners, save pointsand other stuff added")
		return
	
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(new_seed)
	
	for i in range(nbr_occurence):
		var next_id = rng.randi_range(0, nbr_room_total - 1)
		while next_id in tab_to_populate:
			next_id = rng.randi_range(0, nbr_room_total - 1)
		tab_to_populate.append(next_id)


func _find_last_dead_end_before_ice(maze: Polyrinthe) -> int:
	var graphe = maze.cubeGraph
	
	var deepest_dead_end_id: int = maze.begin_id
	var deepest_dead_end_depth: int = graphe.getDepth(maze.begin_id)
	
	var backup_id: int = maze.begin_id
	var backup_depth: int = graphe.getDepth(maze.begin_id)
	
	var current_depth:int = deepest_dead_end_depth
	
	for id: int in range(graphe.getNbrRoom()):
		var connections = graphe.getNeighborsConnection(id)
		var nbr_connection: int = 0
		
		for jd: int in connections:
			nbr_connection += 1 if jd > -1 else 0
		
		current_depth = graphe.getDepth(id)
		
		if current_depth < graphe.get_deepest() * normal_wall_proportion:
			if backup_depth < current_depth:
				backup_id = id
				backup_depth = current_depth
			
			 # not a dead-end and not deeper
			if nbr_connection <= 1 and deepest_dead_end_depth < current_depth:
				deepest_dead_end_id = id
				deepest_dead_end_depth = current_depth
	
	#print(deepest_dead_end_id, maze.begin_id, backup_id)
	return deepest_dead_end_id if deepest_dead_end_id != maze.begin_id else backup_id


# called on save point: save maze and player progression with the current save point id
func _save_point_activated(save_point_id: int = 0) -> void:
	player.remove_all_status_effect()
	player.save_progression(save_point_id)
	_save_maze()


# save player progression with the current save point id
func _save_player_progress(save_point_id: int = 0) -> void: 
	player.save_progression(save_point_id)


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
	
	last_save_id = int(game_data["save_spot_id"])
	
	player.initialize_player(meta_data, game_data)
	player.set_difficulty(difficulty)
	player.position = get_position_for_player_save_point(int(game_data["save_spot_id"]))

# save maze data
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
		"updated_tags": updated_tags,
		"updated_chests": updated_chests,
		"updated_spawners": updated_spawners
	}
	
	var json_string = JSON.stringify(save_dict)
	
	save_file.store_line(json_string)


func _apply_maze_modifications(maze: Polyrinthe) -> void:
	for save_point_id: int in save_points_room_ids:
		var pedestral = PEDESTRAL.instantiate()
		pedestral.maze = self
		pedestral.is_save_pedestral = true
		pedestral.id = save_point_id
		#add_child(pedestral)
		navigation_region_3d.add_child(pedestral)
		#pedestral.set_color(Color(0, 1, 0, 1))
		pedestral.position = maze.maze[save_point_id].position - save_pedestral_position
	
	SceneFade.emit_signal("save_id_changed", last_save_id) # set_up save pedesatl animation for player's spwan point
	
	var max_rune_pedestal: int = 2
	for chests_id: int in chests_room_ids: # chests_room_ids is correct, already cleaned
		var pedestal = PEDESTRAL.instantiate()
		pedestal.maze = self
		pedestal.is_save_pedestral = false
		pedestal.id = chests_id
		#pedestral.set_color(Color(0, 0, 1, 1))
		#pedestral.is_rune = maze.maze[chests_id].position.y == 0
		if max_rune_pedestal > 0 and Polyrinthe.is_id_on_first_floor(maze.size, chests_id):
			pedestal.is_rune = true
			max_rune_pedestal -= 1
		else:
			pedestal.is_rune = false
		navigation_region_3d.add_child(pedestal)
		pedestal.position = maze.maze[chests_id].position - chest_pedestral_position
	
	#print("spawners_room_ids: ", spawners_room_ids)
	for spawner_id: int in spawners_room_ids:
		#var sphere = SPHERE.instantiate() # DEBUG
		#add_child(sphere) # DEBUG
		#sphere.position = maze.maze[spawner_id].position # DEBUG
		
		var mob_id_to_avoid: Array[int] = []
		if str(spawner_id) in updated_spawners.keys(): # cleaning process
			mob_id_to_avoid = updated_spawners[str(spawner_id)]
			#sphere.get_child(0).mesh.material.albedo_color = Color(1, 0, float(len(mob_id_to_avoid))/Spawner.NBR_MOB_BY_SPAWNER, 1) # DEBUG
			if len(mob_id_to_avoid) >= Spawner.NBR_MOB_BY_SPAWNER:
				print("spawner '", spawner_id, "' skipped, all mobs are dead") # DEBUG
				for i in range(Spawner.NBR_MOB_BY_SPAWNER):
					Enemy.get_next_id()
				continue # skip spawner creation
		#else:
			#sphere.get_child(0).mesh.material.albedo_color = Color(1, 0, 0, 1) # DEBUG
		
		var spawner = SPAWNER.instantiate()
		spawner.set_maze(self)
		add_child(spawner)
		spawner.id = spawner_id
		spawner.position = maze.maze[spawner_id].position
		spawner.initialise_mobs_list(maze.seed_human + "_spawner_" + str(spawner_id), mob_id_to_avoid)
		
	# check player grapple to know if it's needed to spawn this upgrade
	if player.grapple.upgrades[3] == 0:
		var loot_orbe_ice_grapple = LOOT_ORBE_ICE_GRAPPLE.instantiate()
		loot_orbe_ice_grapple.position = maze.maze[grapple_ice_upgrade_room_id].position
		add_child(loot_orbe_ice_grapple)
		
		# DEBUG: if the player alread have the grapple upgrade, uncomment bellow 
		# lines to add an ice-blue sphere on the room with the grapple ice wall upgrades
		#var sphere = SPHERE.instantiate()
		#add_child(sphere)
		#sphere.get_child(0).mesh.material.albedo_color = Color(0, 0.8, 0.8, 1)
		#sphere.position = maze.maze[grapple_ice_upgrade_room_id].position - Vector3(0, 5, 0)
	else: # the player has already loot the ice upgrade
		player.grapple.upgrade_ice_grapple_color()
	
	#var sphere_end = SPHERE.instantiate()
	#add_child(sphere_end)
	#sphere_end.get_child(0).mesh.material.albedo_color = Color(0, 0, 0, 1)
	#sphere_end.position = maze.maze[maze.deepest_id].position - Vector3(0, 0, 5)
	
	# portal in the last room to enter the boss fight
	var portal_end = FAKE_PORTAL.instantiate()
	add_child(portal_end)
	portal_end.position = maze.maze[maze.deepest_id].position - Vector3(0, 8.8, 5)
	portal_end.fake_portal_entered.connect(_on_last_room_portal_passed.bind(maze.deepest_id))
	
	# gold near chests :
	var gold_factor: Vector3 = Vector3(16, 16, 16)
	for key in maze.maze.keys():
		var chests_closure = maze.cubeGraph.get_tag(key, 3)
		if chests_closure > 0:
			var gold_scale = chests_closure / 1000.0
			var neighbors = maze.cubeGraph.getNeighborsConnection(key)
			var higher: bool = false
			for id in neighbors:
				if chests_closure < maze.cubeGraph.get_tag(id, 3):
					higher = true
					var direction = (maze.maze[id].position - maze.maze[key].position)/2.5
					
					var gold = GOLD.instantiate()
					gold.position = maze.maze[key].global_position - Vector3(0, 10, 0) + direction + Vector3(0, gold_scale, 0)/2
					add_child(gold)
					gold.get_child(0).scale = gold_factor * gold_scale
					gold.set_amount(int(chests_closure/20.0))
					
					#var sphere = SPHERE.instantiate()
					#add_child(sphere)
					#sphere.get_child(0).mesh.material.albedo_color = Color(1, 1, 0, 1)
					#sphere.position = maze.maze[key].global_position - Vector3(0, 10, 0) + direction - Vector3(0, rg_color, 0)/2
			
			if !higher:
				var gold = GOLD.instantiate()
				gold.position = maze.maze[key].global_position - Vector3(0, 10, 0) + Vector3(0, gold_scale, 0)/2
				add_child(gold)
				gold.get_child(0).scale = gold_factor * gold_scale
				gold.set_amount(int(chests_closure/20.0))

## polyrinthe need to be generated before calling this method
func get_position_for_player_save_point(save_point_id: int) -> Vector3:
	return polyrinthe.maze[save_point_id].position


static func _generate_array_for_ice_wall_tags(array_size: int, normal_value: int, ice_value: int) -> Array[int]:
	var array: Array[int] = []
	
	for i in range(array_size * normal_wall_proportion):
		array.append(normal_value)
	
	for i in range(array_size * normal_wall_proportion, array_size):
		array.append(ice_value)
	
	return array


static func set_tag_for_collision_layer(maze: Polyrinthe) -> void:
	var max_depth = maze.cubeGraph.get_deepest()
	maze.tag_spreads_wide_way(maze.begin_id, 2, max_depth, _generate_array_for_ice_wall_tags(max_depth + 1, NORMAL_WALL_VALUE, ICE_WALL_VALUE))


static func apply_collision_layer(maze: Polyrinthe, material: StandardMaterial3D = ICE) -> void:
	for key in maze.maze.keys():
		var col_layer = maze.cubeGraph.get_tag(key, 2)
		for wall: Node3D in maze.maze.get(key).get_children():
			wall.collision_layer = col_layer
			if col_layer == ICE_WALL_VALUE:
				wall.get_children()[0].material_override = material


static func add_torch_to(maze: Polyrinthe, begin_lit: bool = false, modulo: int = 2) -> void:
	for key in maze.maze.keys():
		if key%modulo == 0:
			var torch = TORCH.instantiate()
			torch.position = Vector3(0, -5, 0)
			torch.begin_lit = begin_lit
			maze.maze.get(key).add_child(torch)


func update_spawner(id_spawner: int, mob_ids: Array[int]) -> void:
	if updated_spawners.has(str(id_spawner)):
		pass # TODO: update list ?
	updated_spawners[str(id_spawner)] = mob_ids


func _on_last_room_portal_passed(room_id: int) -> void:
	#print("Maze::_on_last_room_portal_passed")
	player.leveling_phase(polyrinthe.get_seed())
	
	await player.leveling_phase_ended
	
	_save_point_activated(room_id)
	SceneFade.change_scene(boss_room, SceneFade.boss_room_loaded)


func _on_player_death(_id: int) -> void:
	player.set_ressource_on_death()
	
	SceneFade._erase_player_progress(player.get_player_name())
	SceneFade.change_scene_with_file("res://scenes/demo/lobby.tscn", SceneFade.lobby_loaded)
