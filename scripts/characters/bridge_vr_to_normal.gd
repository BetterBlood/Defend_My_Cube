extends XRController3D

class_name XRBridgeController3D

var action_states: Dictionary = {}

func _process(_delta):
	_bridge_action("attack", "attack")
	_bridge_action("jump", "jump")
	_bridge_action("grapple", "grapple")
	_bridge_action("interact", "interact")
	_bridge_action("god_mod", "godMod")
	_bridge_action("up", "up")
	_bridge_action("down", "down")
	_bridge_action("pause", "pause")
	_bridge_action("swap_rune", "swap_rune")
	_bridge_action("tower_right", "tower_right")
	_bridge_action("tower_left", "tower_left")
	_bridge_action("lvl_up", "lvl_up")
	_bridge_action("lvl_down", "lvl_down")
	_bridge_action("demolition_toggle", "demolition_toggle")
	# A3: 


func _bridge_action(xr_action_name: String, input_map_name: String):
	if not action_states.has(xr_action_name):
		action_states[xr_action_name] = false
	
	var is_pressed_now = is_button_pressed(xr_action_name)
	var was_pressed_before = action_states[xr_action_name]
	
	if is_pressed_now and not was_pressed_before:
		Input.action_press(input_map_name)
		action_states[xr_action_name] = true
	elif not is_pressed_now and was_pressed_before:
		Input.action_release(input_map_name)
		action_states[xr_action_name] = false
