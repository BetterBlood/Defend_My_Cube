extends Control

signal select_pressed()


func set_up_proposition(prop) -> void:
	if prop:
		$Panel/VBoxContainer/Title.text = prop[0]
		$Panel/VBoxContainer/Illustration.texture = load(prop[1])
		$Panel/VBoxContainer/Description.text = prop[2]


func _on_select_pressed() -> void:
	select_pressed.emit()
