extends Node3D

signal fake_portal_entered()

func _on_area_3d_area_entered(_area: Area3D) -> void:
	fake_portal_entered.emit()
