@tool
extends XRToolsViewport2DIn3D

func _ready() -> void:
	super._ready()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var sub_viewport = get_node_or_null("Viewport")
	if sub_viewport:
		sub_viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var menu_instance = get_scene_instance()
	if menu_instance:
		menu_instance.open_pause.connect(_on_pause_menu_open_pause)
		menu_instance.close_pause.connect(_on_pause_menu_close_pause)

func _on_pause_menu_open_pause() -> void:
	visible = true

func _on_pause_menu_close_pause() -> void:
	visible = false
