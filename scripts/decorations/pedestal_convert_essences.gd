extends Pedestral

class_name PedestalConvertEssences

var cost_type: Enums.DamageType = Enums.DamageType.NORMAL
var cost_value: int = 10
var give_type: Enums.DamageType = Enums.DamageType.FIRE
var give_value: int = 1 
var lobby: Lobby

var materials: Array[Material] = [ # TODO: update on other type or runes added
	preload("res://materials/projectiles/normal_projectile.tres"),
	preload("res://materials/projectiles/fire_projectile.tres"),
	preload("res://materials/projectiles/plant_projectile.tres"),
	preload("res://materials/projectiles/electric_projectile.tres"),
]

func _ready() -> void:
	super._ready()
	_set_display() #default display
	SceneFade.costs_changed.connect(_set_display)


func set_cost_value(value: int) -> void:
	cost_value = value
	_set_display()


func set_cost_type(type: Enums.DamageType) -> void:
	cost_type = type
	_set_display()
	#set_color(materials[type % len(materials)].albedo_color)


func set_give_value(value: int) -> void:
	give_value = value
	_set_display()


func set_give_type(type: Enums.DamageType) -> void:
	give_type = type
	_set_display()
	set_color(materials[type % len(materials)].albedo_color)


func _set_display() -> void:
	var c_name: String =  Enums.DamageType.keys()[cost_type]
	var c_val: String = str(cost_value)
	var c_ess: String = str(lobby.essences[cost_type])
	
	var g_name: String =  Enums.DamageType.keys()[give_type]
	var g_val: String = str(give_value)
	var g_ess: String = str(lobby.essences[give_type])
	
	interactionToDisplay = "E or X\n\nConvert " + c_val + " " + c_name + \
	" (owned: " + c_ess + ") for " + g_val  + " " + g_name + " (owned: " + g_ess + ")."
	interactionDetector.actionName = interactionToDisplay


func use() -> void:
	if lobby.convert_essences(cost_value, cost_type, give_value, give_type):
		SceneFade.emit_signal("costs_changed")
		_set_display()


func _on_animation_area_body_entered(_body: Node3D) -> void:
	animation_tree.set("parameters/Transition/transition_request", "Nearing")


func _on_animation_area_body_exited(_body: Node3D) -> void:
	animation_tree.set("parameters/Transition/transition_request", "Leaving")
