extends Control

var main: PackedScene = preload("res://scenes/main.tscn")
var previous_pause_state: bool = false
var previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED
@onready var continue_button: Button = $VBoxContainer/Continue

signal open_pause()
signal close_pause()

var is_vr_active: bool = false

func _ready() -> void:
	hide()
	
	var xr_interface: XRInterface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		is_vr_active = true
		if get_parent() is CanvasLayer:
			process_mode = Node.PROCESS_MODE_DISABLED
			hide()

func _process(_delta: float) -> void:
	if InputMap.has_action("pause") and Input.is_action_just_pressed("pause"):
		if not visible:
			open_menu()
		else:
			_on_continue_pressed()

func open_menu() -> void:
	continue_button.grab_focus()
	previous_pause_state = get_tree().paused
	previous_mouse_mode = Input.mouse_mode
	show()
	
	if is_vr_active:
		open_pause.emit()
		
		get_tree().paused = false
		for i in range(3):
			await get_tree().physics_frame
	
	get_tree().paused = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_continue_pressed() -> void:
	get_tree().paused = previous_pause_state
	hide()
	Input.set_mouse_mode(previous_mouse_mode)
	
	if is_vr_active:
		close_pause.emit()


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	# TODO: warning for user on maze exploration or boss fight: all none saved progress will be lost
	SceneFade.change_scene_with_file("res://scenes/main.tscn", SceneFade.main_loaded)
