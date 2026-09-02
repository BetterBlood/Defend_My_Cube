@tool
extends EditorPlugin

class_name PolyrinthePlugin

## Callback called when the plugin is activated in the editor. Registers the
## custom "Polyrinthe" type with its associated script and icon.
func _enter_tree():
	# Initialization of the plugin goes here.
	add_custom_type("Polyrinthe", "Node3D", 
		preload("res://addons/polyrinthe/polyrintheGenerator.gd"), 
		preload("res://addons/polyrinthe/polyrinthe_logo.png")
	)

## Callback called when the plugin is deactivated in the editor.
## Removes the previously registered "Polyrinthe" custom type.
func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_custom_type("Polyrinthe")
