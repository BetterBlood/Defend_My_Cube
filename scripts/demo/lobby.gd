extends Node3D

class_name Lobby

#signal launch_game(player_name: String)

@export var maze_seed: String = ""
@export var difficulty: int = 0
@export var size: int = 6 # DEBUG
@export var algo: Polyrinthe.GENERATION_ALGORITHME = Polyrinthe.GENERATION_ALGORITHME.DFS_LBL_ALT_6
@export var begin_id: int = 0

var all_runes: Array = []
var unlocked_runes: Array[int] = [0]
var gold: int = 0
var essences: Array[int] = [0, 0, 0, 0]

#const Logger = preload("res://scripts/CSharp/Logger.cs")
#var logger:Logger = Logger.new()

var debug_size: int = 3 # DEBUG
var polyrinthe: Polyrinthe = Polyrinthe.new()
var hologram: Polyrinthe = Polyrinthe.new()
@onready var player: Player = $Player

var maze_scene: PackedScene = preload("res://scenes/maze.tscn")
const PEDESTRAL_RUNE_UNLOCKER = preload("res://scenes/decorations/pedestral_rune_unlock.tscn")
const PEDESTAL_CONVERT_ESSENCES = preload("res://scenes/decorations/pedestal_convert_essences.tscn")

# Practice room
var bird: PackedScene = preload("res://scenes/characters/bird.tscn")


# VR-XR stuff:
var xr_interface: XRInterface


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
	
	
	# auto closing room
	$MainFloor/Ceil.position = $MainFloor/Ceil.position - Vector3(0, 40, 0)
	$MainFloor/Walls/Wall5.position = $MainFloor/Walls/Wall5.position - Vector3(0, 0, 100)
	$MainFloor/Walls/Wall8.position = $MainFloor/Walls/Wall8.position - Vector3(100, 0, 0)
	
	$MazeSelectionFloor/Ceil.position = $MazeSelectionFloor/Ceil.position - Vector3(0, 70, 0)
	
	$RuneUnlockedRoom/Ceil.position = $RuneUnlockedRoom/Ceil.position - Vector3(0, 70, 0)
	$NormalRuneUnlock/Ceil.position = $NormalRuneUnlock/Ceil.position - Vector3(0, 70, 0)
	$FireRuneUnlock/Ceil.position = $FireRuneUnlock/Ceil.position - Vector3(0, 70, 0)
	$PlantRuneUnlock/Ceil.position = $PlantRuneUnlock/Ceil.position - Vector3(0, 70, 0)
	$ElectricRuneUnlock/Ceil.position = $ElectricRuneUnlock/Ceil.position - Vector3(0, 70, 0)
	$MoreRuneUnlock/Ceil.position = $MoreRuneUnlock/Ceil.position - Vector3(0, 70, 0)
	
	$HealthComponentUpgradeRoom/Ceil.position = $HealthComponentUpgradeRoom/Ceil.position - Vector3(0, 70, 0)
	
	player.current_player_name = SceneFade.player_name
	#add_child(logger)
	#logger.Info("An informational message: " + self.to_string());
	#logger.Debug("A Debug message: " + self.to_string());
	
	#for line in logger.GetLines():
		#print(line)
	print()
	
	add_child(polyrinthe)
	polyrinthe.position = Vector3(48.841, 5.24, 0)
	polyrinthe.rotation = Vector3(0, -PI/2, 0)
	polyrinthe.clean()
	polyrinthe.algo = polyrinthe.GENERATION_ALGORITHME.DFS_LBL_ALT_6
	polyrinthe.generate(debug_size, "DEBUG", [-1, -1, 1])
	Maze.set_tag_for_collision_layer(polyrinthe)
	polyrinthe.display()
	Maze.apply_collision_layer(polyrinthe)
	Maze.add_torch_to(polyrinthe, true)
	
	#_update_hologram()
	$MazeSelectionFloor/Hologram/Hologram.add_child(hologram)
	hologram.rotation_order = EULER_ORDER_ZXY
	hologram.rotation = Vector3(0, 0, PI/4)
	$MazeSelectionFloor/Hologram/Hologram.rotation = Vector3(PI/5, 0, 0)
	hologram.debug = true
	hologram.showWall = false
	hologram.outWallV = -1
	hologram.room_scale = 0.1
	hologram.clean()
	hologram.algo = hologram.GENERATION_ALGORITHME.DFS_LBL_ALT_6
	maze_seed = $MazeSelectionFloor/Seed/SeedSelector.curr_seed.text
	hologram.generate(size, "DEBUG" if SceneFade.player_name == "DEBUG" else maze_seed, [-1, -1, 1])
	hologram.display()
	
	if len(all_runes) == 0:
		all_runes = Rune.get_runes_infos()
	
	if !Enums.damage_type_loaded:
		var config = ConfigFile.new()
		var err = config.load("user://damageGrid.cfg")
		if err != OK:
			Enums.save_grid_damage_type()
		else:
			Enums.load_grid_damage_type(config, true)
	
	if not FileAccess.file_exists("user://" + player.get_player_name() + "/meta.save"):
		save_meta() # initialise the save on first time with this username
	
	load_meta()
	
	call_deferred("_init_practice_mobs")
	call_deferred("_update_hologram")
	call_deferred("rotate_hologram")
	
	SceneFade.emit_signal("lobby_loaded")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("launch_generation"):
		print("pressed")
		
		# DEBUG
		player.health_component.add_perm_upgrade(0, 2)
		save_meta()
		print("player.health_component.get_max_life(): ", player.health_component.get_max_health())
		# DEBUG
		
		#launch_game.emit(player.get_player_name())
		
		#initialise the file containing maze info
		#_initialize_new_maze_file_save()
		# player initialisation needed to keep the lobby rune
		#player.health_component.health = player.health_component.get_max_health()
		#player.save_progression(begin_id)
		#SceneFade.change_scene(maze_scene, SceneFade.maze_loaded)
		#get_tree().change_scene_to_packed(maze_scene)


func _init_practice_mobs() -> void:
	#print(maze_seed)
	
	# TODO: set-up zombies (and other mobs when they are created)
	
	var max_spawn_radius = 10
	
	# boid 1
	for i in range(4):
		var new_bird = bird.instantiate()
		new_bird.is_in_lobby = true
		new_bird.id = i
		new_bird.set_mob_data(maze_seed + "bird" + str(i), 0, 1)
		new_bird.position = Vector3(randf_range(-1, 1) * max_spawn_radius, randf_range(-9, -1), randf_range(-1, 1) * max_spawn_radius)
		add_child(new_bird)
		new_bird.set_boids(range(4))
	
	# boid 2
	for i in range(4, 8):
		var new_bird = bird.instantiate()
		new_bird.is_in_lobby = true
		new_bird.id = i
		new_bird.set_mob_data(maze_seed + "bird" + str(i), 0, 1)
		new_bird.position = Vector3(randf_range(-1, 1) * max_spawn_radius, randf_range(-9, -1), randf_range(-1, 1) * max_spawn_radius)
		add_child(new_bird)
		new_bird.set_boids(range(4, 8))


func _initialize_new_maze_file_save() -> void:
	var save_file = FileAccess.open("user://" + player.get_player_name() + "/maze.save", FileAccess.WRITE)
	if save_file == null:
		push_error("Cannot save maze data. FileAccess error: " + str(save_file.get_error()))
		return
	
	var save_dict = {
		"seed" : "DEBUG" if player.get_player_name() == "DEBUG" else maze_seed,
		"size" : size,
		"begin_id" : begin_id,
		"generation_used" : algo,
		"difficulty" : difficulty, # [-2; 2]
		"default_tags": [ # [int]
			1, # wall default collision layers 
			0, # color for room near chests
		],
		"updated_tags": [# [[int]]
			[]
		],
		"updated_chests": [], # [int]
		"updated_spawners": {} # {int, [int]}
	}
	
	var json_string = JSON.stringify(save_dict)
	
	save_file.store_line(json_string)

# use this to save meta data about player (on health_component upgrade bought and rune unlocked)
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


func load_meta() -> void:
	if not FileAccess.file_exists("user://" + player.get_player_name() + "/meta.save"):
		push_error("player: " + player.get_player_name() + " does not exist. Player meta load failed")
		return
	
	var save_file = FileAccess.open(
		"user://" + player.get_player_name() + "/meta.save", 
		FileAccess.READ)
	
	var meta_data = null
	
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()
		
		var json = JSON.new()
		
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			push_warning("JSON Parse Error: " + json.get_error_message() + " in " + json_string + " at line " + json.get_error_line())
			continue
		
		meta_data = json.data
	
	gold = meta_data["gold"]
	essences.clear()
	for essence in meta_data["essences"]:
		essences.append(int(essence))
	unlocked_runes.clear()
	for rune_id in meta_data["unlocked_runes"]:
		unlocked_runes.append(int(rune_id))
	
	_init_runes_unlocker()
	_init_runes_essences_converter()
	
	#player.call_deferred("initialize_player").bind(meta_data, null, null)
	player.initialize_player(meta_data, null)


func _init_runes_unlocker() -> void:
	var tmp_rune_number = 4 # need to stay hard codded for developpement
	if len(unlocked_runes) > tmp_rune_number and -1 not in unlocked_runes:
		push_warning("Possible errors of rune unlocker pedestal placement, pls check")
	if len(unlocked_runes) > tmp_rune_number + 1 and -1 in unlocked_runes: # DEBUG
		push_warning("Possible errors of rune unlocker pedestal placement, pls check") # DEBUG
	
	# TODO: check correct orientation and room if more than tmp_rune_number runes !!!
	var parents: Array = [$NormalRuneUnlock, $FireRuneUnlock, $PlantRuneUnlock, $ElectricRuneUnlock]
	var rotation_deg: Array = [180, 180, 0, 0]
	
	#print(unlocked_runes)
	
	for rune_data in all_runes:
		#print("rune_data: ", rune_data)
		if rune_data["rune_id"] == -1: # DEBUG RUNE
			if player.get_player_name() == "DEBUG":
				var debug_pedestal = PEDESTRAL_RUNE_UNLOCKER.instantiate()
				debug_pedestal.maze = null
				debug_pedestal.is_save_pedestral = false
				debug_pedestal.id = rune_data["rune_id"]
				debug_pedestal.rune_name = rune_data["name"]
				debug_pedestal.lobby = self
				$RuneUnlockedRoom.get_children()[0].add_child(debug_pedestal)
				debug_pedestal.set_cost_value(rune_data["cost_value"])
				debug_pedestal.set_cost_type(rune_data["type"])
				debug_pedestal.set_debug()
				debug_pedestal.set_used(true)
				debug_pedestal.position = Vector3(0, 30.75, 0)
				debug_pedestal.rotation_degrees = Vector3(0, 90, 0)
			continue
		
		var pedestal = PEDESTRAL_RUNE_UNLOCKER.instantiate()
		pedestal.maze = null
		pedestal.is_save_pedestral = false
		pedestal.id = rune_data["rune_id"]
		pedestal.rune_name = rune_data["name"]
		pedestal.lobby = self
		parents[rune_data["rune_id"] % len(parents)].get_children()[0].add_child(pedestal)
		pedestal.set_cost_value(rune_data["cost_value"])
		pedestal.set_cost_type(rune_data["type"])
		pedestal.set_used(rune_data["rune_id"] in unlocked_runes)
		pedestal.position = Vector3(0, 1.25, 0) # TODO: when more rune of type normal fire plant or elec: change position x and z
		pedestal.rotation_degrees = Vector3(0, rotation_deg[rune_data["rune_id"] % len(rotation_deg)], 0)


func _init_runes_essences_converter() -> void:
	
	# Normal to Fire, Normal to Plant & Normal to Electric
	var convert_to: Array = [Enums.DamageType.FIRE, Enums.DamageType.PLANT, Enums.DamageType.ELEC]
	var positions: Array[Vector3] = [Vector3(-8, 0.6, 20), Vector3(+8, 0.6, -20), Vector3(-8, 0.6, -20)]
	var rotations: Array[Vector3] = [Vector3(0, 180, 0), Vector3(0, 0, 0), Vector3(0, 0, 0)]
	
	for i in range(len(convert_to)):
		var pedestal = PEDESTAL_CONVERT_ESSENCES.instantiate()
		pedestal.maze = null
		pedestal.is_save_pedestral = false
		pedestal.id = -1
		pedestal.lobby = self
		$RuneUnlockedRoom.get_children()[0].add_child(pedestal)
		pedestal.set_cost_value(10)
		pedestal.set_cost_type(Enums.DamageType.NORMAL)
		pedestal.set_give_value(1)
		pedestal.set_give_type(convert_to[i])
		pedestal.position = positions[i]
		pedestal.rotation_degrees = rotations[i]


func _on_difficulty_selectionner_difficulty_changed(new_difficulty: int) -> void:
	#print("lobby::_on_difficulty_selectionner_difficulty_changed new_difficulty: ", new_difficulty)
	difficulty = new_difficulty


func _on_size_selector_size_changed(new_size: int) -> void:
	#print("lobby::_on_size_selector_size_changed new_size: ", new_size)
	size = new_size
	_update_hologram()


func _on_seed_selector_seed_changed(new_seed: String) -> void:
	#print("lobby::_on_seed_selector_seed_changed new_seed: ", new_seed)
	maze_seed = new_seed
	_update_hologram()


func _on_algo_selector_algo_changed(new_algo: Polyrinthe.GENERATION_ALGORITHME) -> void:
	#print("lobby::_on_algo_selector_algo_changed new_algo: ", new_algo)
	algo = new_algo
	_update_hologram()


func _update_hologram() -> void:
	hologram.clean()
	 
	hologram.algo = algo
	hologram.begin_id = begin_id
	hologram.size = size
	hologram.generate(size, "DEBUG" if SceneFade.player_name == "DEBUG" else maze_seed)
	hologram.display()


func _on_fake_portal_fake_portal_entered() -> void:
	#launch_game.emit(player.get_player_name())
	
	#initialise the file containing maze info
	_initialize_new_maze_file_save()
	# player initialisation needed to keep the lobby rune
	player.health_component.health = player.health_component.get_max_health() # regen before initialising progression save
	player.save_progression(begin_id)
	SceneFade.change_scene(maze_scene, SceneFade.maze_loaded)


func unlock_rune(id: int, cost_value: int, cost_type: Enums.DamageType) -> bool:
	if cost_value <= essences[cost_type]:
		essences[cost_type] -= cost_value
		unlocked_runes.append(id)
		save_meta()
		return true
	return false


func convert_essences(cost_value: int, cost_type: Enums.DamageType, give_value: int, give_type: Enums.DamageType) -> bool:
	if cost_value <= essences[cost_type]:
		essences[cost_type] -= cost_value
		essences[give_type] += give_value
		save_meta()
		return true
	return false


func rotate_hologram() -> void:
	$MazeSelectionFloor/Hologram.rotation = Vector3(0, 0, 0)
	
	var tween = get_tree().create_tween()
	tween.tween_property($MazeSelectionFloor/Hologram, "rotation", Vector3(0, -2*PI, 0), 30)
	
	await tween.finished
	rotate_hologram()
