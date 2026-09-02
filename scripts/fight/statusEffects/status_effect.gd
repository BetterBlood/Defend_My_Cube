extends Node

class_name StatusEffect

var effect_id: int
static var DEFAULT_COOLDOWN: float = 0.5 # all status Effect tick clock !
var cooldown: float = DEFAULT_COOLDOWN
var cooldown_timer: Timer

var target: Creature
var total_duration: float
var effect_area_range_transmission: float

var real_target: HealthComponent

var value: float = 1.0 # burn:damage/sec, slow:slow_penalty, shock:shock_duration

var same_effect: PackedScene
var total_duration_fixe: float

# TODO
var real_source: HealthComponent


func _ready() -> void:
	cooldown_timer = Timer.new()
	#print("burn effect: ready")
	cooldown_timer.wait_time = cooldown
	cooldown_timer.timeout.connect(_on_cooldown_timeout)
	add_child(cooldown_timer)
	cooldown_timer.start()
	
	if target != null && target.get_health_component() != null:
		real_target = target.get_health_component()
		if real_target != null:
			_apply_effect()
			_apply_visual_effect()


func _on_cooldown_timeout() -> void:
	total_duration -= cooldown
	#print("Trying to apply effect tick on target: ", target)
	if target != null && real_target != null:
		_apply_effect()
		_try_propagate_effect()
		if total_duration > 0.0:
			cooldown_timer.start()
		else:
			_clean_effect()
			queue_free()
	else:
		queue_free()


func _apply_effect() -> void:
	push_error("_apply_effect not implemented in ", self)
	assert(false, "Override of `_apply_effect()` needed in " + str(self))

func _apply_visual_effect() -> void:
	push_warning("_apply_visual_effect not implemented in ", self, ", to dissmiss this warning: override _apply_visual_effect with empty body (pass)")

func _clean_effect() -> void:
	push_warning("_clean_effect not implemented in ", self)

func _try_propagate_effect() -> void:
	#print("_try_propagate_effect:start")
	if same_effect == null:
		#print("_try_propagate_effect::aborted same_effect is null")
		return
	
	var propagateArea = Area3D.new()
	var collision_shape = CollisionShape3D.new()
	propagateArea.add_child(collision_shape)
	collision_shape.shape = SphereShape3D.new()
	collision_shape.shape.radius = 0.01
	propagateArea.collision_layer = 0 # to avoid collision with projectile (default is 1, and player raycast attack collide with -> projectiles were send to narnia)
	propagateArea.collision_mask = target.get_layer()
	#print(target.get_layer())
	propagateArea.area_entered.connect(
		func (area):
			var target_tmp = area.get_parent()
			#print("_try_propagate_effect::area_entered: ", target_tmp, ", target: ", target)
			#print("_try_propagate_effect::effect_id: ", effect_id, ", target_tmp.get_status_ids(): ", target_tmp.get_status_ids())
			
			if target_tmp == target: # || effect_id in target_tmp.get_status_ids():
				#print("_try_propagate_effect::area_entered:return")
				return
			
			if target_tmp.has_method("can_host_status_effect"):
				if target_tmp.can_host_status_effect(effect_id):
					target_tmp.add_effect_id(effect_id)
					#print("_try_propagate_effect::area_entered:propagate")
					var effect = same_effect.instantiate()
					effect.same_effect = same_effect
					effect.effect_id = effect_id
					effect.target = target_tmp
					effect.value = value
					effect.total_duration_fixe = total_duration_fixe
					effect.total_duration = total_duration_fixe # no duration reduction
					# reduction of effect duration after transmission :
					#effect.total_duration = total_duration
					effect.effect_area_range_transmission = effect_area_range_transmission
					target_tmp.add_child(effect)
	)
	add_child(propagateArea)
	propagateArea.global_position = target.global_position
	
	#print("layer:", target.collision_layer)
	#print("layer:", target.collision_mask)
	#print("layer:", target.get_layer())
	
	var tween_propagation: Tween = get_tree().create_tween()
	tween_propagation.tween_property(collision_shape.shape, "radius", effect_area_range_transmission, min(cooldown/2.0, total_duration))
	tween_propagation.tween_callback(propagateArea.queue_free)
	
	#print("_try_propagate_effect:end")
