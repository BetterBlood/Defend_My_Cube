extends Node3D

class_name Grapple

var ray_cast_3d: RayCast3D

var is_shooting: bool = false
var is_dragging: bool = false
var is_returning: bool = false
var cooldown_returning: float
var tmp_destination: Vector3 = Vector3()


var _distance: float = 30.0
static var _distance_default_upgrade: float = 10.0

var _speed_boost: float = 1.2
static var _speed_boost_default_upgrade: float = 0.3

var _enemy_mask: int = 4 # 4 means enemy, enemy need to defined it as 2 to catch the player
var _defaul_mask: int = 16 

var upgrades: Array[int] = [0, 0, 0, 0] # [0:range, 1:boost, 2:enemy, 3:ice_wall]
static var NBR_UPGRADES: int = 2
static var upgrade_names: Array[String] = [
	"range",
	"speed boost",
	"enemy grab",
	"ice wall"
]
static var upgrade_default_values: Array[float] = [
	_distance_default_upgrade,
	_speed_boost_default_upgrade,
	1.0,
	1.0
]


var grapple_owner: Creature

const SPHERE = preload("res://addons/polyrinthe/sphere.tscn") # DEBUG
const IMPACT = preload("res://scenes/decorations/impact.tscn")
var grappling_hook: Node
var tween: Tween
var _grapple_speed: float = 40.0
var _grapple_return_modifier: float = 1.0

const SPEED_EFFECT: PackedScene = preload("res://scenes/fight/statusEffects/speed_effect.tscn")

func _ready() -> void:
	grappling_hook = SPHERE.instantiate() # TODO: GRAPHICS: real grappling hook
	grappling_hook.scale = Vector3(0.05, 0.05, 0.05)
	add_child(grappling_hook)
	grappling_hook.add_child(IMPACT.instantiate())


func _physics_process(delta: float) -> void:
	if is_dragging: # apply movement on the owner
		#print("is_dragging")
		
		# compute direction
		var direction: Vector3 = grappling_hook.global_position - grapple_owner.global_position
		# compute & apply velocity
		grapple_owner.velocity = direction.normalized() * delta * 1500
		
		# TODO: GRAPHICS : redraw grapple line based on owner position
	elif is_returning: # grapplpe is ununasble during this time
		var dist = abs((grappling_hook.global_position - global_position).length())
		# TODO: set the return speed proportionnaly of the owner speed cause the hook is too slow to return to user having hight speed
		if dist > 1:
			tween.stop()
			tween = get_tree().create_tween()
			cooldown_returning = dist / _grapple_speed * _grapple_return_modifier
			tween.tween_property(grappling_hook, "position", global_position, cooldown_returning)
			tween.finished.connect(_grapple_returned)


func set_up_with_data(data) -> void:
	for upgrade in data:
		if int(upgrade["type"]) > len(upgrades):
			push_warning("Grapple upgrade " + upgrade["type"] + " not recognized... skiped")
			continue
		upgrades[int(upgrade["type"])] += int(upgrade["value"])


func get_data():
	var data = []
	for i in range(len(upgrades)):
		data.append({"type": i, "value": upgrades[i]})
	return data


func get_distance() -> float:
	return _distance + upgrades[0] * _distance_default_upgrade


func get_boost() -> float:
	return _speed_boost + upgrades[1] * _speed_boost_default_upgrade
	


func get_collision_mask() -> int:
	return 	_defaul_mask + \
			_enemy_mask * (1 if upgrades[2] != 0 else 0) + \
			_defaul_mask * 2 * (1 if upgrades[3] != 0 else 0)


func set_creature_owner(new_owner: Creature) -> void:
	grapple_owner = new_owner


func _upgrade_at(index: int) -> int:
	upgrades[index] += 1
	return upgrades[index]


func upgrade_range() -> int:
	return _upgrade_at(0)


func upgrade_boost() -> int:
	return _upgrade_at(1)


func upgrade_enemy() -> int:
	return _upgrade_at(2)


func upgrade_wall() -> int:
	upgrade_ice_grapple_color()
	return _upgrade_at(3)

func upgrade_ice_grapple_color() -> void:
	# TODO: when the grappeling hook is no longer a sphere update him the proper way !
	grappling_hook.get_child(0).mesh.material.albedo_color = Color(0, 0.8, 0.8, 1)

#	TODO: may be interesting: for being usable on moving target, need to pass the entity hited to reparent 
#	hook on the target (the raycast should provide this information) 
func shoot(destination: Vector3, hit: bool, hit2: bool = false) -> void:
	if !_is_abble_to_shoot():
		return
	
	if hit:
		_grapple_return_modifier = 0.7
	else:
		_grapple_return_modifier = 1
	
	grappling_hook.reparent(get_parent().get_parent().get_parent())
	
	#print("shoot")
	#print(destination)
	tmp_destination = destination
	
	#var sphere = SPHERE.instantiate()
	#get_parent().get_parent().get_parent().add_child(sphere)
	#sphere.position = destination
	#sphere.scale = Vector3(0.2, 0.2, 0.2)
	
	_begin_shoot(hit, hit2)


func _is_abble_to_shoot() -> bool:
	#print("is_dragging, is_returning, is_shooting: ", is_dragging, is_returning, is_shooting)
	return !(is_dragging or is_returning or is_shooting)


func _begin_shoot(hit: bool, hit2: bool = false) -> void:
	#print("_begin_shoot hit: ", hit)
	is_shooting = true
	
	#(Should be useless, but prevent shooting bug in case of incoherent positions)
	grappling_hook.position = global_position
	
	tween = get_tree().create_tween()
	tween.tween_property(
		grappling_hook, "position", tmp_destination, 
		abs((tmp_destination - global_position).length()) / _grapple_speed)
	tween.finished.connect(_begin_traction.bind(hit, hit2))


func _begin_traction(hit: bool, hit2: bool = false) -> void:
	#print("_begin_traction")
	is_shooting = false
	
	if !hit or is_returning:
		if !is_returning:
			# TODO: animation ricochet
			if hit2:
				grappling_hook.get_child(1).emitting = true
			_begin_returning()
		#print("_begin_traction::aborted")
		return
	
	is_dragging = true
	grapple_owner.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING


func cancel_grab() -> void:
	#print("cancel_grab")
	if _is_abble_to_shoot() or is_returning:
		return
	
	grapple_owner.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED 
	if is_dragging and SPEED_EFFECT != null:
		#print("was dragging -> applying boost")
		# apply boost
		var vertical_force = 1
		var dist = (grappling_hook.position - grapple_owner.global_position).length()
		var y_diff = grappling_hook.position.y - grapple_owner.global_position.y
		if y_diff > -0.5:
			if dist >= 1:
				if dist < get_distance()/10:
					vertical_force *= 15
				else:
					vertical_force *= ((get_distance()/10)/dist) * 15
			elif dist >= 0.1:
				vertical_force *= dist * 15
		grapple_owner.velocity.y = vertical_force
		
		#print(area.get_parent().has_method("can_host_status_effect"))
		if 		grapple_owner.has_method("can_host_status_effect"):
			var new_id = StatusEffectId.get_next_id() 
			if grapple_owner.can_host_status_effect(new_id):
				grapple_owner.add_effect_id(new_id)
				
				var effect_instance = SPEED_EFFECT.instantiate()
				effect_instance.effect_id = new_id
				effect_instance.same_effect = null
				effect_instance.cooldown = 3.0
				effect_instance.value = get_boost()
				effect_instance.target = grapple_owner
				effect_instance.total_duration = 3.0
				effect_instance.total_duration_fixe = 3.0
				effect_instance.effect_area_range_transmission = 0
				grapple_owner.add_child(effect_instance)
	
	elif is_shooting:
		tween.stop()
	
	is_dragging = false
	is_shooting = false
	_begin_returning()


func _begin_returning() -> void:
	#print("_begin_returning")
	is_returning = true


func _grapple_returned() -> void:
	#print("_grapple_returned")
	is_returning = false
	tmp_destination = Vector3()
	grappling_hook.reparent(self)
	grappling_hook.position = Vector3()
