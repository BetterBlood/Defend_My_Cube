extends StatusEffect 

class_name BurnEffect

func _apply_effect() -> void:
	real_target.take_burn_effect(value/(1.0/cooldown)) # or value * cd

func _apply_visual_effect() -> void:
	target.apply_visual_burn_effect(total_duration)

func _clean_effect() -> void:
	pass
