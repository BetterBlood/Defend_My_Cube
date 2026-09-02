extends Area3D

class_name Puddle

const SLOW_EFFECT = preload("res://scenes/fight/statusEffects/speed_effect.tscn")

var damage: float = 0.0
var slow_value: float = 1.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var life_timer: Timer = $LifeTimer
@onready var tick_timer: Timer = $TickTimer

func _ready() -> void:
	set_collision_mask_value(1, false)
	set_collision_mask_value(3, true)
	
	life_timer.timeout.connect(_on_life_timer_timeout)
	tick_timer.timeout.connect(_on_tick_timer_timeout)

func setup(p_duration: float, p_radius: float, p_slow_value: float, p_damage: float) -> void:
	damage = p_damage
	slow_value = p_slow_value
	
	#scale = Vector3(p_radius, 1.0, p_radius)
	
	scale = Vector3(0.001, 0.001, 0.001)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector3(p_radius, 1.0, p_radius), 0.2).set_trans(Tween.TRANS_BOUNCE)
	life_timer.wait_time = p_duration
	life_timer.start()
	
	tick_timer.wait_time = 0.5
	tick_timer.start()
	
	_tick_effect()

func _on_life_timer_timeout() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector3(0.001, 0.001, 0.001), 0.2)
	tween.tween_callback(queue_free)

func _on_tick_timer_timeout() -> void:
	_tick_effect()


func _tick_effect() -> void:
	var enemies_in_puddle = get_overlapping_areas()
	
	for area in enemies_in_puddle:
		var target = area.get_parent()
		
		if is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(damage * tick_timer.wait_time, Enums.DamageType.PLANT, 0.0)
			_apply_slow(target)

func _apply_slow(target: Node3D) -> void:
	if SLOW_EFFECT == null:
		return
	
	if target.has_method("can_host_status_effect"):
		var new_id = StatusEffectId.get_next_id()
		if target.can_host_status_effect(new_id):
			target.add_effect_id(new_id)
			
			var effect_instance = SLOW_EFFECT.instantiate()
			effect_instance.same_effect = SLOW_EFFECT
			effect_instance.value = slow_value
			effect_instance.effect_id = new_id
			effect_instance.target = target
			
			var duration_in_puddle = tick_timer.wait_time
			effect_instance.total_duration = duration_in_puddle
			effect_instance.total_duration_fixe = duration_in_puddle
			effect_instance.effect_area_range_transmission = 0.0
			
			target.add_child(effect_instance)
