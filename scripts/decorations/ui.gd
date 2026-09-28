extends Control

@onready var hotbar_container = $HotBar
const MAX_VISIBLE_SLOTS = 5
var current_offset = 0

const NORMAL_ELEM = preload("res://images/tower_def/normal_elem.png")
const FIRE_ELEM = preload("res://images/tower_def/element.png")
const PLANT_ELEM = preload("res://images/tower_def/plant_elem.png")
const ELEC_ELEM = preload("res://images/tower_def/elec_elem.png")

const TOWER_NORMAL: PackedScene = preload("res://scenes/tower_def/tower_normal.tscn")
const TOWER_FIRE: PackedScene = preload("res://scenes/tower_def/tower_fire.tscn")
const TOWER_ELEC: PackedScene = preload("res://scenes/tower_def/tower_elec.tscn")
const TOWER_PLANT: PackedScene = preload("res://scenes/tower_def/tower_plant.tscn")

var current_towers_data: Array = []
var current_selected_index: int = 0
var current_tower_level: int = 1

@onready var destruction_indicator = $DestructionIndicator

func _ready() -> void:
	$ColorRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$ColorRect.modulate.a = 0
	
	
	var dummy_data = [# TODO: find real cost
		{ "type": null, "icon": null, "cost": 0, "scene": null }, # avoid overstimulating holograms
		
		{ "type" : Enums.DamageType.NORMAL, "icon" : NORMAL_ELEM, "cost" : 1, "scene": TOWER_NORMAL},
		{ "type" : Enums.DamageType.FIRE, "icon" : FIRE_ELEM, "cost" : 1, "scene": TOWER_FIRE},
		{ "type" : Enums.DamageType.PLANT, "icon" : PLANT_ELEM, "cost" : 1, "scene": TOWER_PLANT},
		{ "type" : Enums.DamageType.ELEC, "icon" : ELEC_ELEM, "cost" : 1, "scene": TOWER_ELEC}
	]
	
	setup_towers(dummy_data)


func damage_tick() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property($ColorRect, "modulate:a", 1, 0.1)
	await tween.finished
	
	if self:
		var tree = get_tree()
		if tree:
			tween = tree.create_tween()
			tween.tween_property($ColorRect, "modulate:a", 0, 0.1)


func update_lvl(lvl: int, lvl_points: int) -> void:
	$VBoxContainer/LvlInfos.text = "lvl: " + str(lvl) + " (" + str(lvl_points) + ")"


func update_essences(essences: Array[int]) -> void:
	$VBoxContainer/EssencesInfos.text = "essences: "
	for i in range(len(essences)):
		$VBoxContainer/EssencesInfos.text += str(essences[i]) + " "


func update_gold(gold: int) -> void:
	$VBoxContainer/GoldInfo.text = "gold: " + str(gold)


func setup_towers(towers_data: Array) -> void:
	current_towers_data = towers_data
	_refresh_hotbar()

func change_selection(direction: int) -> void:
	var total_towers = current_towers_data.size()
	if total_towers == 0:
		return
	
	current_selected_index = (current_selected_index + direction) % total_towers
	if current_selected_index < 0:
		current_selected_index += total_towers
	
	if total_towers > MAX_VISIBLE_SLOTS:
		if current_selected_index == 0 and direction > 0:
			current_offset = 0
		elif current_selected_index == total_towers - 1 and direction < 0:
			current_offset = total_towers - MAX_VISIBLE_SLOTS
		else:
			var min_offset = current_selected_index - MAX_VISIBLE_SLOTS + 2
			var max_offset = current_selected_index - 1
			current_offset = clamp(current_offset, min_offset, max_offset)
			
		current_offset = clamp(current_offset, 0, total_towers - MAX_VISIBLE_SLOTS)
	else:
		current_offset = 0
	_refresh_hotbar()


func change_tower_level(new_level: int) -> void:
	current_tower_level = clamp(current_tower_level + new_level, 1, 5)
	
	_refresh_hotbar()


func _refresh_hotbar() -> void:
	for child in hotbar_container.get_children():
		child.queue_free()
	 
	if current_towers_data.is_empty():
		return
	
	var total_towers = current_towers_data.size()
	var end_index = min(current_offset + MAX_VISIBLE_SLOTS, total_towers)
	
	for i in range(current_offset, end_index):
		var is_selected = (i == current_selected_index)
		var slot = _create_slot_ui(current_towers_data[i], is_selected)
		hotbar_container.add_child(slot)


func _create_slot_ui(data: Dictionary, is_selected: bool) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(80, 80)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.8, 0.2, 0.5) if is_selected else Color(0.1, 0.1, 0.1, 0.5)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color.WHITE if is_selected else Color.GRAY
	panel.add_theme_stylebox_override("panel", style)
	
	if data.get("scene") == null:
		var empty_label = Label.new()
		empty_label.text = "Main\nLibre"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(empty_label)
		return panel
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var icon_container = Control.new()
	icon_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(icon_container)
	
	var icon = TextureRect.new()
	icon.texture = data.get("icon")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	#icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_container.add_child(icon)
	
	var total_cost = data.get("cost", 2) * pow(2, current_tower_level - 1)
	var essence_type = data.get("type", 0)
	var essence_colors = [Color.WHITE, Color.ORANGE_RED, Color.WEB_GREEN, Color.SKY_BLUE]
	
	var cost_label = Label.new()
	cost_label.text = str(total_cost) + " ess"
	cost_label.add_theme_color_override("font_color", essence_colors[essence_type % essence_colors.size()])
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cost_label)
	
	if is_selected:
		var lvl_label = Label.new()
		lvl_label.text = "Lvl " + str(current_tower_level)
		lvl_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		lvl_label.add_theme_font_size_override("font_size", 24)
		lvl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lvl_label.add_theme_color_override("font_color", Color.YELLOW)
		
		panel.add_child(lvl_label)
	
	return panel

func _physics_process(delta) -> void:
	if InputMap.has_action("tower_right") and Input.is_action_just_pressed("tower_right"):
		change_selection(1)
		get_viewport().set_input_as_handled()
	if InputMap.has_action("tower_left") and Input.is_action_just_pressed("tower_left"):
		change_selection(-1)
		get_viewport().set_input_as_handled()
	if InputMap.has_action("lvl_up") and Input.is_action_just_pressed("lvl_up"):
		change_tower_level(1)
		get_viewport().set_input_as_handled()
	if InputMap.has_action("lvl_down") and Input.is_action_just_pressed("lvl_down"):
		change_tower_level(-1)
		get_viewport().set_input_as_handled()
	
#func _unhandled_input(event: InputEvent) -> void:
	## TODO : map VR buttons (and controllers)
	#if event.is_action_pressed("tower_right"):
		#change_selection(1)
		#get_viewport().set_input_as_handled()
	#elif event.is_action_pressed("tower_left"):
		#change_selection(-1)
		#get_viewport().set_input_as_handled()
	#elif event.is_action_pressed("lvl_up"):
		#change_tower_level(1)
		#get_viewport().set_input_as_handled()
	#elif event.is_action_pressed("lvl_down"):
		#change_tower_level(-1)
		#get_viewport().set_input_as_handled()


func set_destruction_mode(is_active: bool) -> void:
	if destruction_indicator:
		destruction_indicator.visible = is_active
