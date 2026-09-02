extends Node3D

var _max_algo: int = 9
var current_algo: int = 9
var _min_algo: int = 0

@onready var label_3d: Label3D = $Size10/Label3D
@onready var sizes: Array[Marker3D] = [
	$Size1, $Size2, $Size3, $Size4, $Size5, $Size6, $Size7, $Size8, $Size9, $Size10
]
signal algo_changed(new_algo: Polyrinthe.GENERATION_ALGORITHME)

	#DFS_3D,        0
	#DFS_3D_ALT_1,  1
	#DFS_3D_ALT_2,  2
	#DFS_LBL,       3
	#DFS_LBL_ALT_1, 4
	#DFS_LBL_ALT_2, 5
	#DFS_LBL_ALT_3, 6
	#DFS_LBL_ALT_4, 7
	#DFS_LBL_ALT_5, 8
	#DFS_LBL_ALT_6  9
	
func _on_more_area_entered(area: Area3D) -> void:
	area.get_parent().queue_free()
	
	if current_algo >= _max_algo:
		return
	sizes[current_algo].visible = false
	_set_algo(min(_max_algo, current_algo + 1))
	sizes[current_algo].visible = true


func _on_less_area_entered(area: Area3D) -> void:
	area.get_parent().queue_free()
	
	if current_algo <= _min_algo:
		return
	
	sizes[current_algo].visible = false
	_set_algo(max(_min_algo, current_algo - 1))
	sizes[current_algo].visible = true

func _set_algo(algo: int) -> void:
	current_algo = algo
	label_3d.text = str(Polyrinthe.GENERATION_ALGORITHME.keys()[current_algo])
	label_3d.reparent(sizes[current_algo])
	label_3d.position = Vector3(1.25, 0, 0)
	#print(Polyrinthe.GENERATION_ALGORITHME.keys()[current_algo])
	algo_changed.emit(Polyrinthe.GENERATION_ALGORITHME.values()[current_algo])
