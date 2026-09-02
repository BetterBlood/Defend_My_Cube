extends Node3D

@onready var mazo: Marker3D = $Mazo
@onready var hard: Marker3D = $Hard
@onready var norm: Marker3D = $Norm
@onready var easy: Marker3D = $Easy
@onready var kido: Marker3D = $Kido

const KIDO = preload("res://materials/difficulties/kido.tres")
const EASY = preload("res://materials/difficulties/easy.tres")
const NORM = preload("res://materials/difficulties/norm.tres")
const HARD = preload("res://materials/difficulties/hard.tres")
const MAZO = preload("res://materials/difficulties/mazo.tres")

@onready var indicator: MeshInstance3D = $Norm/Indicator

var current_difficulty: int = 0

signal difficulty_changed(new_difficulty: int)

func _ready() -> void:
	indicator.reparent(norm)
	indicator.mesh.material = NORM

func _on_more_area_entered(area: Area3D) -> void:
	area.get_parent().queue_free()
	_set_difficulty(min(2, current_difficulty + 1))
	#print("GRAND !")


func _on_less_area_entered(area: Area3D) -> void:
	area.get_parent().queue_free()
	_set_difficulty(max(-2, current_difficulty - 1))
	#print("Less (ly)")


func _set_difficulty(difficulty: int) -> void:
	current_difficulty = difficulty
	
	match current_difficulty:
		-2:
			indicator.reparent(kido)
			indicator.mesh.material = KIDO
		-1:
			indicator.reparent(easy)
			indicator.mesh.material = EASY
		0:
			indicator.reparent(norm)
			indicator.mesh.material = NORM
		1:
			indicator.reparent(hard)
			indicator.mesh.material = HARD
		2:
			indicator.reparent(mazo)
			indicator.mesh.material = MAZO
		
	indicator.position = Vector3()
	
	difficulty_changed.emit(current_difficulty)
