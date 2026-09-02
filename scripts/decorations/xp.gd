extends SmallLoot

class_name XP

const DEBUG_PROJECTILE = preload("res://materials/projectiles/debug_projectile.tres")

func _ready() -> void:
	super._ready()
	mesh_instance_3d.mesh.material = DEBUG_PROJECTILE


func _on_area_3d_area_entered(area: Area3D) -> void:
	var player = area.get_parent()
	if player:
		player.gain_xp(value)
		queue_free()
	else:
		push_error("player not found !")
