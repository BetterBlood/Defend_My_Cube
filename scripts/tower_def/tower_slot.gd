extends Node3D

class_name TowerSlot

var current_tower: Node3D = null


func is_free() -> bool:
	return current_tower == null


func build_tower(tower_instance: Node3D) -> void:
	if is_free():
		current_tower = tower_instance
		add_child(tower_instance)
		tower_instance.position = Vector3(0, 7.15, 0) # TODO: do a marker3D for tower spawning position
