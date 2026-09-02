extends Node3D

class_name Pedestral

@onready var readable_part: MeshInstance3D = $Shelf/ReadablePart/MeshInstance3D
@onready var holder: MeshInstance3D = $Shelf/holder/MeshInstance3D
@onready var column: MeshInstance3D = $Column/StaticBody3D/MeshInstance3D
@onready var base: MeshInstance3D = $Base/StaticBody3D/MeshInstance3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree
var maze: Maze
var id: int = 0

var is_save_pedestral: bool
var is_used: bool = false
var is_rune: bool = false

const SAVE_COLOR = preload("res://materials/save_color.tres")
const CHEST_COLOR = preload("res://materials/chest_color.tres")

const LOOT_ORBE = preload("res://scenes/decorations/loot_orbe.tscn")

@onready var interactionDetector:= $InteractionsDetector
@export var interactionToDisplay: String = ""


func _ready() -> void:
	var material: StandardMaterial3D
	
	if is_save_pedestral:
		material = SAVE_COLOR
		interactionToDisplay = "Save"
		SceneFade.save_id_changed.connect(try_being_save_point_selected)
	else:
		material = CHEST_COLOR
		interactionToDisplay = "Open"
	
	readable_part.material_override = material
	holder.material_override = material
	column.material_override = material
	base.material_override = material
	
	interactionDetector.interact = Callable(self, "use")
	if !interactionToDisplay.is_empty():
		interactionDetector.actionName += interactionToDisplay
	


func set_color(color: Color) -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	
	readable_part.material_override = material
	holder.material_override = material
	column.material_override = material
	base.material_override = material
	#readable_part.material_override.normal_enabled = true
	#readable_part.material_override.normal_enabled.normal_texture = NoiseTexture2D.new()
	#readable_part.material_override.normal_enabled.normal_texture.noise = FastNoiseLite.new()


func _on_area_3d_body_entered(_body: Node3D) -> void:
	if !is_used or is_save_pedestral:
		animation_tree.set("parameters/Transition/transition_request", "Nearing")


func _on_area_3d_body_exited(_body: Node3D) -> void:
	if !is_used:
		animation_tree.set("parameters/Transition/transition_request", "Leaving")
	elif is_save_pedestral:
		animation_tree.set("parameters/Transition/transition_request", "Active")


func use() -> void:
	is_used = true
	if is_save_pedestral:
		var player = get_tree().get_first_node_in_group("Player")
		player.leveling_phase(maze.polyrinthe.get_seed())
		await player.leveling_phase_ended
		maze._save_point_activated(id)
		SceneFade.emit_signal("save_id_changed", id)
	else:
		maze.updated_chests.append(id)
		
		var loot_orbe = LOOT_ORBE.instantiate()
		loot_orbe.position = position
		loot_orbe.set_loot(!is_rune, maze.polyrinthe.get_seed() + interactionToDisplay + str(id))
		get_parent().add_child(loot_orbe)
		
		$AnimationArea.queue_free()
		interactionDetector.queue_free()
		
		animation_tree.set("parameters/Transition/transition_request", "Destroing")


func try_being_save_point_selected(value: int) -> void:
	if is_save_pedestral:
		if value == id:
			is_used = true
			animation_tree.set("parameters/Transition/transition_request", "Active")
		else:
			is_used = false
			animation_tree.set("parameters/Transition/transition_request", "Idle")
