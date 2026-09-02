extends Node3D

@onready var sizes: Array[Marker3D] = [
	$Size3, $Size4, $Size5, $Size6, $Size7, $Size8, $Size9, $Size10
]

@onready var indicator: MeshInstance3D = $Size6/Indicator
@onready var label_3d: Label3D = $Size6/Label3D

var _max_size: int = 10
var current_size: int = 6
var _min_size: int = 3

signal size_changed(new_size: int)


func _on_more_area_entered(area: Area3D) -> void:
	area.get_parent().queue_free()
	
	if current_size >= _max_size:
		return
	
	_set_size(min(_max_size, current_size + 1))
	sizes[current_size - _min_size].visible = true


func _on_less_area_entered(area: Area3D) -> void:
	area.get_parent().queue_free()
	
	if current_size <= _min_size:
		return
	
	_set_size(max(_min_size, current_size - 1))
	sizes[current_size - _min_size + 1].visible = false

func _set_size(size: int) -> void:
	current_size = size
	label_3d.text = str(current_size)
	label_3d.reparent(sizes[current_size - _min_size])
	label_3d.position = Vector3(0.5, 0, 0)
	size_changed.emit(current_size)
