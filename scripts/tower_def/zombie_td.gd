extends Zombie

class_name Zombie_TD

func _death_sequence() -> void:
	var essence_orbe = ESSENCE_ORBE.instantiate()
	essence_orbe.set_amount(1)
	essence_orbe.position = global_position + Vector3(-0.2, 0, -0.3)
	get_parent().get_parent().add_child(essence_orbe)
	essence_orbe.set_type(get_type())
	
	is_dead.emit(id) # notify the death (for the spawner or else, towers in this case)
	
	queue_free()
