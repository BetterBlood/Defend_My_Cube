extends LootOrbe

class_name LootOrbeRune

var new_rune_data

func _spawning_animation() -> void:
	scale = Vector3(0.001, 0.001, 0.001)
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property($".", "scale", Vector3(1.0, 1.0, 1.0), 2.0)
	tween.tween_property($".", "position", position + Vector3(-sin(rotation.y), 0, -cos(rotation.y)) * 3, 2.0)


func _interact() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.propose_new_rune(new_rune_data, action_after_interation)
	else:
		push_error("player not found !")


func set_loot(_is_upgrade: bool, _special_seed: String) -> void:
	push_warning("Be carefull, this function is not designed for 'LootOrbeRune', please consider using 'init_with_rune'")


func init_with_rune(rune_data) -> void:
	new_rune_data = rune_data
