extends CanvasLayer

signal new_game()
signal continue_game()

@onready var new_game_button: Button = $MainPanel/VBoxContainer/NewGame

func _ready() -> void:
	new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	new_game.emit()


func _on_continue_pressed() -> void:
	continue_game.emit()


func _init_focus() -> void:
	new_game_button.grab_focus()


func _on_options_pressed() -> void:
	# TODO: add options (volume, fullscreen), reglage, controls etc...
	print("option pressed from main menu")


func _on_exit_pressed() -> void:
	get_tree().quit(0)
