extends Node3D

class_name SmallLoot

var value: float = 0.0
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	_spawning_animation()

func set_amount(new_value: float) -> void:
	value = new_value

func _spawning_animation() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property($".", "position", position + Vector3(0, 2, 0), 0.5)
	tween.tween_property($".", "position", position + Vector3(0, 0, 0), 0.5)
