@tool
extends XRToolsViewport2DIn3D


signal continue_game(player_name: String)
signal return_to_main_menu()
signal erase_player(player_name: String)

@onready var player_name: LineEdit# = $MainPanel/VBoxContainer/HBoxContainer/PlayerName
#@onready var continue_button: Button = $MainPanel/VBoxContainer/Continue
#@onready var known_player: VBoxContainer = $MainPanel/KnownPlayer

func _ready() -> void:
	super._ready() 
	
	var menu_instance = get_scene_instance()
	if menu_instance:
		menu_instance.continue_game.connect(_on_continue_pressed)
		menu_instance.return_to_main_menu.connect(_on_return_pressed)
		#menu_instance.erase_player.connect(??)
		#print(menu_instance.get_children()[0].get_children()[2].get_children()[0].get_children()[1])
		player_name = menu_instance.get_children()[0].get_children()[2].get_children()[0].get_children()[1]
	

func _process(_delta: float) -> void:
	if InputMap.has_action("return") and Input.is_action_just_pressed("return"):
		if visible == true:
			return_to_main_menu.emit()


func _init_focus() -> void:
	#continue_button.grab_focus()
	
	#while known_player.get_child_count() > 0:
		#known_player.remove_child(known_player.get_child(0))
	var label: Label = Label.new()
	label.text = "players list: "
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	#known_player.add_child(label)
	
	var player_names: Array[String] = get_players_names()
	for player_n in player_names:
		var player_line: HBoxContainer = HBoxContainer.new()
		
		var line_edit: LineEdit = LineEdit.new()
		line_edit.text = player_n
		line_edit.editable = false
		line_edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		player_line.add_child(line_edit)
		
		var del_button: Button = Button.new()
		del_button.text = "DEL"
		player_line.add_child(del_button)
		
		#known_player.add_child(player_line)
	
	#if len(player_names) > 1:
		#player_name.focus_neighbor_right = known_player.get_child(1).get_path()
		#continue_button.focus_neighbor_right = known_player.get_child(1).get_path()
		#$MainPanel/VBoxContainer/Return.focus_neighbor_right = known_player.get_child(1).get_path()
		#for child_id in range(1, len(known_player.get_children())): # 1, 
			#known_player.get_child(child_id).get_child(0).focus_entered.connect(
				#func (): player_name.text = known_player.get_child(child_id).get_child(0).text
			#)
			#(known_player.get_child(child_id).get_child(1) as Button).pressed.connect(
				#func (): erase_player.emit(known_player.get_child(child_id).get_child(0).text)
			#)


func _on_continue_pressed(player_name_txt) -> void:
	#continue_game.emit(player_name.text)
	continue_game.emit(player_name_txt)


func _on_return_pressed() -> void:
	return_to_main_menu.emit()


func _on_player_name_text_submitted(_new_text: String) -> void:
	_init_focus()


func get_players_names() -> Array[String]:
	var players_config = ConfigFile.new()
	var err = players_config.load("user://players.cfg")
	
	if err != OK:
		return []
	
	var result: Array[String] = []
	for player: String in players_config.get_sections():
		result.append(player)
	
	return result
