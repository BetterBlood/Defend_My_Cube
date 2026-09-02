extends Node3D

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var label: Label# = player.get_interaction_label()#$Label

const beginText: String = "" #"[F] "

var activeAreas: Array[InteractionsDetector] = []
var canInteract: bool = true
var previous_size: int = 0

func registerArea(area: InteractionsDetector):
	#print("registerArea: ", area)
	activeAreas.push_back(area)

func unregisterArea(area: InteractionsDetector):
	var index = activeAreas.find(area)
	if index != -1:
		activeAreas.remove_at(index)

func _process(_delta: float) -> void:
	if activeAreas.size() != previous_size:
		previous_size = activeAreas.size()
		if canInteract:
			#print("canInteract::_process")
			if activeAreas.size() == 0 :
				label.hide()
			else :
				if activeAreas.size() > 1 :
					activeAreas.sort_custom(_sortByDistToPlayer)
				var currArea: InteractionsDetector = activeAreas[0]
				_setActiveLabel(currArea)
				label.show()
		else:
			label.hide()
	
	if canInteract and activeAreas.size() > 0:
		var is_interacting = false
		
		if Input.is_action_just_pressed("interact"):
			is_interacting = true
		if not is_interacting and player and player.get_node_or_null("XROrigin3D/RightController"):
			var right_controller = player.get_node("XROrigin3D/RightController")
			if right_controller.get_float("interact") > 0.5:
				is_interacting = true
		if is_interacting:
			#print("Interaction validée !")
			_trigger_interaction()

func _trigger_interaction() -> void:
	canInteract = false
	label.hide()
	await activeAreas[0].interact.call()
	canInteract = true

#func _input(event: InputEvent) -> void:
	#print("event ??? event: ", event, " canInteract: ", canInteract)
	#if event.has_action("intercat") and event.is_action_pressed("interact") && canInteract:
		#print("interact ?")
		#if activeAreas.size() > 0:
			#canInteract = false
			#label.hide()
			#
			#await activeAreas[0].interact.call()
			#
			#canInteract = true

func _setActiveLabel(currArea: InteractionsDetector):
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		label = player.get_interaction_label()
	if not label:
		label = Label.new()
	label.text = beginText + currArea.actionName

func _sortByDistToPlayer(a1: InteractionsDetector, a2: InteractionsDetector):
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		label = player.get_interaction_label()
	return player.global_position.distance_to(a1.global_position) < player.global_position.distance_to(a2.global_position)
