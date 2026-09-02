extends CharacterBody3D

class_name Creature

@export var id: int = -1
@export var is_in_lobby: bool = false
signal is_dead(id: int)

var health_component: HealthComponent
var lvl:int = 1
var xp:float = 0.0


var layer: int = 0
var effect_ids: Dictionary = {}

var instant_speed: float = 0.0

var summoned: bool = false

var burn_applied: int = 0

var health_bar_max_ratio: float = 1.0

var health_bar: MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print("Creature::_ready")
	if health_component == null:
		#push_warning("health component missing for: ", self, ", set to default")
		health_component = HealthComponent.new()
		add_child(health_component)
	
	health_component.damage_taken.connect(_on_damage_taken)
	health_component.burn_effect.connect(_on_burn_effect)
	health_component.heal_taken.connect(_on_heal_taken)
	_update_life_display()

func _on_damage_taken():
	if is_in_lobby:
		_lobby_damage_taken() 
	else:
		if health_component.health <= 0:
			if summoned:
				_death_sequence_summoned()
			else:
				_death_sequence()
	
	_update_life_display()


func _on_heal_taken() -> void:
	#TODO: heal animation ?
	_update_life_display()

func _update_life_display_custom(health_ratio: float) -> void:
	health_bar.mesh.size.x = health_bar_max_ratio * health_ratio


func _lobby_damage_taken():
	if health_component.health <= 0:
		print(self, " is dead ! Regeneration activated !!! health: ", health_component.health, " -> ", health_component.get_max_health())
		health_component.health = health_component.get_max_health()

func _death_sequence() -> void:
	# TODO: in herited classes: do something on creature's death !
	pass

func _death_sequence_summoned() -> void:
	# TODO: in herited classes: do something on summoned creature's death !
	is_dead.emit(-1)
	queue_free() # no emition of death signals

func _on_burn_effect():
	# TODO: in herited classes: do something on creature on fire !
	pass


func apply_visual_burn_effect(_duration: float) -> void:
	push_warning("apply_visual_burn_effect not implemented in ", self, ", to dissmiss this warning: override apply_visual_burn_effect with empty body (pass)")

func _update_life_display() -> void:
	push_warning("_update_life_display not implemented in ", self, ", to dissmiss this warning: override _update_life_display with empty body (pass)")

func can_host_status_effect(status_id: int = 0) -> bool:
	return !effect_ids.has(status_id)

func get_health_component() -> HealthComponent:
	return health_component

func take_damage(	value: float, 
					att_type: Enums.DamageType, 
					armor_pen: float) -> float:
	return health_component.take_damage(value, att_type, get_type(), armor_pen)


func get_type() -> Enums.DamageType:
	return Enums.DamageType.NORMAL


func get_fire_projectile_spot() -> Marker3D:
	return null


func get_layer() -> int:
	return layer


func add_effect_id(status_id: int = 0) -> void:
	effect_ids[status_id] = true

# TODO: remove
func get_status_ids() -> Array:
	return effect_ids.keys()

func get_instant_speed() -> float:
	return instant_speed
