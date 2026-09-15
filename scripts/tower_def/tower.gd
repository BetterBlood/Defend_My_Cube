extends Node3D

class_name Tower

@export var damage_type: Enums.DamageType = Enums.DamageType.NORMAL
@export var base_damage: float = 3.5 # normal zombies killed with 3 shoots
@export var attack_cooldown: float = 2.0
@export var attack_range: float = 20.0

var level: int = 1
@export var base_cost: int = 1
static var max_level: int = 5
var current_targets: Array[Creature] = []
var can_attack: bool = true
var _attack_timer: float = 0.0

@onready var detection_area: Area3D = $DetectionArea
@onready var collision_shape: CollisionShape3D = $DetectionArea/CollisionShape3D
@onready var attack_source: Node3D = $AttackSource
@onready var level_indicators: Array[Node] = [
	$LevelIndicators/Level_1, 
	$LevelIndicators/Level_2, 
	$LevelIndicators/Level_3, 
	$LevelIndicators/Level_4, 
	$LevelIndicators/Level_5
]

var effect: PackedScene = null
var effect_value: float = 0
var effect_duration: float = 1.0
var effect_area_range_transmission: float = 3.0

func _ready() -> void:
	
	detection_area.set_collision_mask_value(1, false)
	detection_area.set_collision_mask_value(3, true)
	
	if collision_shape.shape is CylinderShape3D:
		collision_shape.shape.radius = attack_range
		collision_shape.shape.height = 10.0 # TODO : update based on maze room sizedand maze scale
		#collision_shape.position.y = 0.0 # TODO : useless I think (coz now enemies are higher)
		
		detection_area.area_entered.connect(_on_detection_area_area_entered)
		detection_area.area_exited.connect(_on_detection_area_area_exited)
		
		#call_deferred("_check_initial_targets") #TODO : remove when sub classes ok
		_custom_ready()
		update_level_visuals()

func _custom_ready() -> void:
	pass

func _perform_attack(_target: Node3D, _current_damage: float) -> void:
	push_error("Tower: _perform_attack() should be implemented in child classes !")

func _check_initial_targets() -> void:
	var overlapping = detection_area.get_overlapping_areas()
	for area in overlapping:
		_on_detection_area_area_entered(area)

func _on_detection_area_area_entered(area: Area3D) -> void:
	var enemy = area.get_parent()
	if enemy.has_method("take_damage") and not current_targets.has(enemy):
		current_targets.append(enemy)
		
		if not enemy.is_dead.is_connected(_on_enemy_dead):
			enemy.is_dead.connect(_on_enemy_dead.bind(enemy))

func _on_detection_area_area_exited(area: Area3D) -> void:
	var enemy = area.get_parent()
	if current_targets.has(enemy):
		current_targets.erase(enemy)
		if enemy.is_dead.is_connected(_on_enemy_dead):
			enemy.is_dead.disconnect(_on_enemy_dead)

func _on_enemy_dead(_enemy_id: int, enemy_node: Creature) -> void:
	if current_targets.has(enemy_node):
		current_targets.erase(enemy_node)

func _process(delta: float) -> void:
	_clean_enemy_list()
	
	_attack_timer += delta
	
	
	if _attack_timer >= attack_cooldown and not current_targets.is_empty():
		var current_damage = base_damage * pow(1.75, level - 1)
		var target = _get_best_target()
		if target:
			_perform_attack(target, current_damage)
			_attack_timer = 0.0

func _clean_enemy_list() -> void:
	current_targets = current_targets.filter(func(t): return is_instance_valid(t) and not t.is_queued_for_deletion())

func _get_best_target() -> Node3D:
	if current_targets.size() > 0:
		return current_targets[0]
	return null

func upgrade_tower() -> void:
	if level < max_level:
		level += 1
		update_level_visuals()

func update_level_visuals() -> void:
	for i in range(level_indicators.size()):
		level_indicators[i].visible = (i + 1 <= level)





#
#func _shoot_homing_projectile(target: Creature, dmg: float) -> void:
	#var proj = HOMING_PROJECTILE.instantiate()
	#
	#get_tree().current_scene.add_child(proj)
	#
	#proj.global_position = attack_source.global_position
	#proj.target = target
	#proj.damage = dmg
#
#func _shoot_fire_cone(dmg: float) -> void:
	#pass
#
#func _shoot_lightning(target: Creature, dmg: float) -> void:
	#pass 
#
#func _spawn_plant_puddle(target: Creature, dmg: float) -> void:
	#pass
