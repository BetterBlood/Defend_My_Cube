extends Area3D

class_name InteractionsDetector

@export var actionName: String = "X or E\n\n"

var interact: Callable = func():
	pass

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)
	

func _on_body_entered(_body: Node3D) -> void:
	#print("_on_body_entered::InteractionDetector")
	InteractionsManager.registerArea(self)


func _on_body_exited(_body: Node3D) -> void:
	InteractionsManager.unregisterArea(self)
