extends CanvasLayer

signal new_game(player_name: String)
signal return_to_main_menu()

@onready var player_name: LineEdit = $MainPanel/VBoxContainer/HBoxContainer/PlayerName
@onready var new_game_button: Button = $MainPanel/VBoxContainer/NewGame

func _ready() -> void:
	_init_focus()


func _init_focus() -> void:
	new_game_button.grab_focus()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("return"):
		if visible == true:
			return_to_main_menu.emit()


func _on_new_game_pressed() -> void:
	new_game.emit(player_name.text)


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
	player_name.text = n
