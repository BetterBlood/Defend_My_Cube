extends CenterContainer

@export var radius: float = 1.0
@export var color: Color = Color.WHITE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(), radius, color)
