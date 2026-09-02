extends Node3D

const LOOT_ORBE_RUNE = preload("res://scenes/decorations/loot_orbe_rune.tscn")
const LOOT_ORBE_ICE_GRAPPLE = preload("res://scenes/decorations/loot_orbe_ice_grapple.tscn")

var xr_interface: XRInterface

func _ready() -> void:
	# VR-XR stuff:
	xr_interface = XRServer.find_interface("OpenXR")
	
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR succesfully initialized")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
	
	# TODO: menu for VR (interactions manager seems not working on VR too
	#var debug_rune = DebugRune.new($Player)
	#var loot_orbe_rune = LOOT_ORBE_RUNE.instantiate()
	#loot_orbe_rune.position = Vector3(0, 1, 0)
	#loot_orbe_rune.rotation = rotation
	#loot_orbe_rune.init_with_rune(debug_rune.get_save_infos())
	#add_child(loot_orbe_rune)
	
	var loot_orbe_ice_grapple = LOOT_ORBE_ICE_GRAPPLE.instantiate()
	loot_orbe_ice_grapple.position = Vector3(13, 18, -6)
	add_child(loot_orbe_ice_grapple)
