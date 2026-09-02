extends StaticBody3D

@onready var fire: GPUParticles3D = $handle/top/Fire
@onready var light: OmniLight3D = $Light

@export var begin_lit: bool = false

func _ready() -> void:
	#fire.emitting = begin_lit
	light.visible = begin_lit

func _on_area_3d_area_entered(area: Area3D) -> void:
	#print("I'm a torch and the following projectile hit me, is it a fire one ? ", area.get_parent())
	if area.get_parent().has_method("get_type") && area.get_parent().get_type() == Enums.DamageType.FIRE:
		fire.emitting = true
		light.visible = true
		#print("Hooooo a fire one -> ignition !!!!")
	#else:
		#print("nop, it's not")


func _on_fire_finished() -> void:
	push_warning("nothing done then torch fire emission finished ?")


func _on_generation(_size: int) -> void:
	fire.emitting = false
	light.visible = false
