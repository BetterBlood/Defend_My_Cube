extends Node3D

@onready var player: Player = $Player
@export var player_spawn_position: Vector3 = Vector3(0, 3, 15)

var fight_ended: bool = false

const FAKE_PORTAL = preload("res://scenes/movement/fake_portal.tscn")
var lobby_scene: PackedScene = preload("res://scenes/demo/lobby.tscn")

func _ready() -> void:
	$Ceil.position = $Ceil.position - Vector3(0, 100, 0)
	player.current_player_name = SceneFade.player_name
	_initialise_player()
	_init_difficulty()
	
	#TODO : init boss
	$Boss.is_dead.connect(_on_boss_defeated)
	$Boss.lvl = (player.difficulty + 3) * 10
	player.is_dead.connect(_on_player_death)
	
	SceneFade.emit_signal("boss_room_loaded")
	
	# animation for player entrance and boss entrance

# TODO: be carefull, duplicated code part, see maze _generate_maze methode
func _init_difficulty() -> void:
	if not FileAccess.file_exists("user://" + player.get_player_name() + "/maze.save"):
		push_error("file:'" + player.get_player_name() + "/maze.save' not found")
	
	# read file info to initialize difficulty
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
		player.set_difficulty(int(maze_data["difficulty"]))

# TODO: be carefull, duplicated code, see maze _initialise_player methode
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
	
	#last_save_id = int(game_data["save_spot_id"])
	
	player.initialize_player(meta_data, game_data)
	player.position = player_spawn_position

# TODO: be carefull, duplicated code (+ updated), see lobby save_meta methode
func save_meta() -> void:
	#var save_file = FileAccess.open("user://" + player.get_player_name() + "/meta.save", FileAccess.WRITE)
	#if save_file == null:
		#push_error("Cannot save meta data. FileAccess error: " + str(save_file.get_error()))
		#return
	
	var save_file = FileAccess.open(
		"user://" + player.get_player_name() + "/meta.save", 
		FileAccess.READ)
	
	var meta_data = null
	
	while save_file.get_position() < save_file.get_length():
		var json_string_meta = save_file.get_line()
		
		var json = JSON.new()
		
		var parse_result = json.parse(json_string_meta)
		if not parse_result == OK:
			push_warning("JSON Parse Error: " + json.get_error_message() + " in " + json_string_meta + " at line " + json.get_error_line())
			continue
		
		meta_data = json.data
	
	save_file = FileAccess.open("user://" + player.get_player_name() + "/meta.save", FileAccess.WRITE)
	var essenses: Array[int] = [0, 0, 0, 0]
	for i in range(len(player.essences)):
		essenses[i] = player.essences[i] + int(meta_data["essences"][i])
		
	var save_dict = {
		"current_player_name" : player.get_player_name(),
		"unlocked_runes" : meta_data["unlocked_runes"],
		"equiped_rune_lobby" : meta_data["equiped_rune_lobby"],
		"gold" : int(meta_data["gold"]) + player.gold,
		"essences" : essenses,
		"health_component_upgrades" : player.health_component.get_perm_data(),
	}
	
	var json_string = JSON.stringify(save_dict)
	
	save_file.store_line(json_string)


func _on_boss_defeated(_id: int) -> void:
	if fight_ended:
		return
	fight_ended = true
	player.gain_gold(50)
	player.gain_essence(Enums.DamageType.NORMAL, 3) #TODO: based on boss type !
	
	player.set_ressource_on_boss_win()
	
	# transfert values to the meta save
	save_meta()
	
	# delete progression save and maze save
	SceneFade._erase_player_progress(player.get_player_name())
	
	# spawn fake portal to go to lobby or open doors of the room containing the portal
	var portal_end = FAKE_PORTAL.instantiate()
	add_child(portal_end)
	portal_end.position = Vector3(0, 1.25, -20)
	portal_end.fake_portal_entered.connect(_go_to_lobby)


func _on_player_death(_id: int) -> void:
	if fight_ended:
		return
	fight_ended = true
	player.set_ressource_on_death()
	SceneFade._erase_player_progress(player.get_player_name())
	_go_to_lobby()


func _go_to_lobby() -> void:
	call_deferred("_go_to_lobby_deferred")


func _go_to_lobby_deferred() -> void:
	#print(lobby_scene)
	SceneFade.player_name = player.current_player_name
	#SceneFade.change_scene(lobby_scene, SceneFade.lobby_loaded) # TODO: wtf ??? this doesn't work, no idea why
	SceneFade.change_scene_with_file("res://scenes/demo/lobby.tscn", SceneFade.lobby_loaded)
	
	# this works, but no fade:
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#get_tree().change_scene_to_file("res://scenes/demo/lobby.tscn")
	
