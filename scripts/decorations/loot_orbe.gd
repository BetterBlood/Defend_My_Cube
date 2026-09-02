extends Node3D

class_name LootOrbe

@onready var interactionDetector:= $InteractionsDetector
@export var interactionToDisplay: String = "Loot"

var loot_is_upgrade: bool = false
var new_runes: Array[int] = []
var other_upgrades: Array = [] # upgrades: [[runeType, value], [healthType, value], [grapleType, value]]

signal action_after_interation(destroy: bool)

func _ready() -> void:
	interactionDetector.interact = Callable(self, "_interact")
	if !interactionToDisplay.is_empty():
		interactionDetector.actionName += interactionToDisplay
	
	action_after_interation.connect(_action_after_interaction)
	_spawning_animation()

func _spawning_animation() -> void:
	scale = Vector3(0.001, 0.001, 0.001)
	var tween = get_tree().create_tween()
	tween.tween_property($".", "scale", Vector3(1.0, 1.0, 1.0), 1.0)

func _interact() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		if loot_is_upgrade:
			#var nothing: Signal
			player.propose_upgrades(other_upgrades, action_after_interation)
			#queue_free()
		else:
			player.propose_new_runes(new_runes, action_after_interation)
	else:
		push_error("player not found !")

func _action_after_interaction(destroy: bool) -> void:
	if destroy:
		queue_free()


func set_loot(is_upgrade: bool, special_seed: String) -> void:
	loot_is_upgrade = is_upgrade
	#var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	#rng.seed = hash(special_seed)
	
	if !loot_is_upgrade:
		new_runes = LootUtilities.get_loot(is_upgrade, special_seed)
		
		#print("LootOrbe::set_loot:new_runes: ", new_runes)
	else:
		other_upgrades = LootUtilities.get_loot(is_upgrade, special_seed)
		#print("LootOrbe::set_loot:other_upgrades: ", other_upgrades)
