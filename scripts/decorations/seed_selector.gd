extends Node3D

@onready var curr_seed: Label3D = $Seed

signal seed_changed(new_seed: String)

func _ready() -> void:
	curr_seed.text = Polyrinthe.static_generate_seed()
	seed_changed.emit(curr_seed.text)

func _on_randomize_area_entered(area: Area3D) -> void:
	area.get_parent().queue_free()
	curr_seed.text = Polyrinthe.static_generate_seed()
	seed_changed.emit(curr_seed.text)
