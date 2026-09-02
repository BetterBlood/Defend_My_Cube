extends Pedestral

class_name PedestalRuneUnlocker

var rune_name: String = ""
var cost_type: Enums.DamageType = Enums.DamageType.NORMAL
var cost_value: int = 1 
var lobby: Lobby

const materials: Array[Material] = [ # TODO: update on other type or runes added
	preload("res://materials/projectiles/normal_projectile.tres"),
	preload("res://materials/projectiles/fire_projectile.tres"),
	preload("res://materials/projectiles/plant_projectile.tres"),
	preload("res://materials/projectiles/electric_projectile.tres"),
]
var debug_color = preload("res://materials/projectiles/debug_projectile.tres")

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
	set_color(materials[type % len(materials)].albedo_color)

func set_debug() -> void:
	set_color(debug_color.albedo_color)

func _set_display() -> void:
	interactionToDisplay = "E or X\n\nUnlock cost for " + rune_name + " is " + str(cost_value) + " " + Enums.DamageType.keys()[cost_type] + ". You have " + str(lobby.essences[cost_type]) + "."
	interactionDetector.actionName = interactionToDisplay


func set_used(used: bool) -> void:
	is_used = used
	if is_used:
		animation_tree.set("parameters/Transition/transition_request", "Active")
		interactionToDisplay = "E or X\n\nto select " + rune_name + " as active rune"
		interactionDetector.actionName = interactionToDisplay
	

func use() -> void:
	if not is_used:
		# update lobby (and save) with the new unlocked rune
		if lobby.unlock_rune(id, cost_value, cost_type):
			is_used = true
			animation_tree.set("parameters/Transition/transition_request", "Active")
			SceneFade.emit_signal("costs_changed")
	else:
		var player = get_tree().get_first_node_in_group("Player")
		player.set_rune_at_placement(id, true)
		lobby.save_meta()



func _on_animation_area_body_entered(_body: Node3D) -> void:
	if !is_used:
		animation_tree.set("parameters/Transition/transition_request", "Nearing")


func _on_animation_area_body_exited(_body: Node3D) -> void:
	if !is_used:
		animation_tree.set("parameters/Transition/transition_request", "Leaving")
