extends SmallLoot

class_name GoldOrbe

const GOLD = preload("res://materials/gold.tres")

func _ready() -> void:
	super._ready()
	mesh_instance_3d.mesh.material = GOLD


func _on_area_3d_area_entered(_area: Area3D) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.gain_gold(int(value))
		queue_free()
	else:
		push_error("player not found !")
