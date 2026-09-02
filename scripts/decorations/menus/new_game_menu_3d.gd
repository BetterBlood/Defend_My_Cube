@tool
extends XRToolsViewport2DIn3D

signal new_game(player_name: String)
signal return_to_main_menu()

#@onready var player_name: LineEdit = $MainPanel/VBoxContainer/HBoxContainer/PlayerName

func _ready() -> void:
	super._ready() 
	
	var menu_instance = get_scene_instance()
	if menu_instance:
		menu_instance.new_game.connect(_on_new_game_pressed)
		menu_instance.return_to_main_menu.connect(_on_return_pressed)
		
		if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
			# TODO:check that child one is new label name !
			menu_instance.get_child(1).focus_entered.connect(_on_focus_entered)
			menu_instance.get_child(1).focus_exited.connect(_on_focus_exited)

func _init_focus() -> void:
	pass

func _on_focus_entered():
	DisplayServer.virtual_keyboard_show(self.text)

func _on_focus_exited():
	DisplayServer.virtual_keyboard_hide()

func _process(_delta: float) -> void:
	if InputMap.has_action("return") and Input.is_action_just_pressed("return"):
		if visible == true:
			return_to_main_menu.emit()


func _on_new_game_pressed(player_name_txt) -> void:
	#new_game.emit(player_name.text)
	new_game.emit(player_name_txt)


func _on_return_pressed() -> void:
	return_to_main_menu.emit()


func _on_player_name_text_submitted(_new_text: String) -> void:
	_init_focus()


func _on_randomize_pressed() -> void:
	var chars = "abcdefghijklmnopqrstuvwxyz"
	var n = ""
	var chars_len = len(chars)
	for i in range(7):
		n += chars[randi()% chars_len]
	#player_name.text = n
