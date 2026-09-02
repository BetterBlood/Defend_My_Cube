extends Control

@onready var label: Label = $VBoxContainer/Label
@onready var label_2: Label = $VBoxContainer/Label2

@onready var upgrade_proposition: Control = $VBoxContainer/HBoxContainer/UpgradeProposition
@onready var upgrade_proposition_2: Control = $VBoxContainer/HBoxContainer/UpgradeProposition2
@onready var upgrade_proposition_3: Control = $VBoxContainer/HBoxContainer/UpgradeProposition3
@onready var close: Button = $VBoxContainer/HBoxContainer2/Close

@onready var active_rune: Button = $VBoxContainer/HBoxContainer2/ActiveRune
@onready var second_rune: Button = $VBoxContainer/HBoxContainer2/SecondRune

var function_to_call_on_selection: Callable
var is_active_selected: bool = true
var allow_second_rune: bool = false
var call_to_potentially_free_orbe: Signal

signal open_upgrade()
signal close_upgrade()

var is_vr_active: bool = false

func _ready() -> void:
	hide()
	
	var xr_interface: XRInterface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		is_vr_active = true
		if get_parent() is CanvasLayer:
			process_mode = Node.PROCESS_MODE_DISABLED
			hide()

func set_up_propositions(prop_1, prop_2, prop_3, dont_forget_to_call: Callable, call_on_finish: Signal) -> void:
	function_to_call_on_selection = dont_forget_to_call
	call_to_potentially_free_orbe = call_on_finish
	if prop_1:
		upgrade_proposition.set_up_proposition(prop_1)
		upgrade_proposition.show()
	else:
		upgrade_proposition.hide()
	
	if prop_2:
		upgrade_proposition_2.set_up_proposition(prop_2)
		upgrade_proposition_2.show()
	else:
		upgrade_proposition_2.hide()
	
	if prop_3:
		upgrade_proposition_3.set_up_proposition(prop_3)
		upgrade_proposition_3.show()
	else:
		upgrade_proposition_3.hide()

func set_title(txt: String) -> void:
	label.text = txt

func set_adding_new_rune() -> void:
	allow_second_rune = true

func _init_focus() -> void:
	close.grab_focus()

func _on_upgrade_proposition_select_pressed() -> void:
	function_to_call_on_selection.call(0, is_active_selected, call_to_potentially_free_orbe)
	close_menu()

func _on_upgrade_proposition_2_select_pressed() -> void:
	function_to_call_on_selection.call(1, is_active_selected, call_to_potentially_free_orbe)
	close_menu()


func _on_upgrade_proposition_3_select_pressed() -> void:
	function_to_call_on_selection.call(2, is_active_selected, call_to_potentially_free_orbe)
	close_menu()


func _on_close_pressed() -> void:
	close_menu()

func open_menu() -> void:
	show()
	_init_focus()
	
	if is_vr_active:
		open_upgrade.emit()
		
		if not get_tree().paused:
			for i in range(3):
				await get_tree().physics_frame
	
	get_tree().paused = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_menu() -> void:
	get_tree().paused = false
	$".".hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if is_vr_active:
		close_upgrade.emit()

func _on_active_rune_pressed() -> void:
	is_active_selected = true
	
	active_rune.disabled = true
	second_rune.disabled = false
	label_2.text = "active rune selected"


func _on_second_rune_pressed() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if allow_second_rune or (player and player.second_rune):
		is_active_selected = false
		
		second_rune.disabled = true
		active_rune.disabled = false
		label_2.text = "second rune selected"
