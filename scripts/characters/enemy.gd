extends Creature

class_name Enemy

static var next_id = 0

var damage_type: Enums.DamageType = Enums.DamageType.NORMAL
var damage: float = 3
var armor_pen: float = 0
var attack_cd: float = 5.0
var current_cd: float = 0.0

const XP_ORBE = preload("res://scenes/decorations/xp.tscn")
const GOLD_ORBE = preload("res://scenes/decorations/gold.tscn")
const ESSENCE_ORBE = preload("res://scenes/decorations/essence.tscn")

var damage_area: Node3D = null
var material_damage_tick: StandardMaterial3D = preload("res://materials/creatures/mob_damage_tick.tres")
const mat = [
	preload("res://materials/projectiles/normal_projectile.tres"),
	preload("res://materials/projectiles/fire_projectile.tres"),
	preload("res://materials/projectiles/plant_projectile.tres"),
	preload("res://materials/projectiles/electric_projectile.tres")
]

var effect_type: int = -1
var effect_application_chance: float = 0.05 # 5%
const effects_data: Array = [
	[preload("res://scenes/fight/statusEffects/burn_effect.tscn"), 0.25, 1.0, 4.0],
	[preload("res://scenes/fight/statusEffects/speed_effect.tscn"), 0.8, 0.25, 7.0],
	[preload("res://scenes/fight/statusEffects/speed_effect.tscn"), 0.0, 0.25, 10.0]
]
static var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	super._ready()
	layer = 4

func _on_damage_taken():
	super._on_damage_taken()
	
	if damage_area and health_component.health > 0:
		damage_area.set_surface_override_material(0, material_damage_tick)
		await get_tree().create_timer(0.1).timeout
		damage_area.set_surface_override_material(0, null)

## depth_ratio: [0.0; 1.0] => determines enemy lvl
## difficulty: [-2; 2] => determines all stats accordingly with the lvl
func set_mob_data(human_seed: String, difficulty: int, depth_ratio: float) -> void:
	#print("TODO: set_mob_data override in subclasses !")
	#print("Enemy::set_mob_data::human_seed: ", human_seed, ", difficulty: ", difficulty, ", depth_ratio: ", depth_ratio)
	
	# [-0.125; 0.125]
	var new_diff = difficulty / (4.0 * 4.0) # ~normalisation (/4) attenuation (/4)
	
	if depth_ratio + new_diff >= 1/3.0: # typed mobs appears nearer to begin with high difficulty
		#var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = hash(human_seed)
		rng.state = hash(human_seed + "wtfstate !!!!!!")
		var val_tmp: int = rng.randi_range(0, len(Enums.damage_type_grid) - 1)
		damage_type = Enums.DamageType.values()[val_tmp]
		effect_type = damage_type - 1
		#print(self, " ", human_seed, " ", hash(human_seed), " ", val_tmp, " ", damage_type, " ", str(len(Enums.damage_type_grid) - 1))
	var lvl_max = (difficulty + 3) * 10 # [10; 50]
	lvl = max(1, int(lvl_max * depth_ratio)) # at least lvl 1, max [10, 20, 30, 40, 50]
	xp = lvl * (5 - difficulty) # lvl * [7; 3] => [7; 3] to [350; 150]
	damage += difficulty + int(lvl/5.0) # damage + [-2; 2] + [2; 10] 
	if lvl <= lvl_max / 5.0:
		armor_pen = 0
	else:
		armor_pen = lvl / 10.0 # [0.2; 1] ... [1.0; 5.0]


func _death_sequence() -> void:
	# TODO: animations
	
	var xp_orbe = XP_ORBE.instantiate()
	xp_orbe.set_amount(xp)
	xp_orbe.position = global_position
	get_parent().get_parent().add_child(xp_orbe)
	
	var gold_orbe = GOLD_ORBE.instantiate()
	gold_orbe.set_amount(lvl)
	gold_orbe.position = global_position + Vector3(0.2, 0, 0.2)
	get_parent().get_parent().add_child(gold_orbe)
	
	var essence_orbe = ESSENCE_ORBE.instantiate()
	essence_orbe.set_amount(1)
	essence_orbe.position = global_position + Vector3(-0.2, 0, -0.3)
	get_parent().get_parent().add_child(essence_orbe)
	essence_orbe.set_type(get_type())
	
	is_dead.emit(id) # notify the death (for the spawner or else)
	
	queue_free()


func _apply_effect(creature: Creature) -> void:
	if effect_type < 0:
		return
	
	#print(target.has_method("can_host_status_effect"))
	if 		creature.has_method("can_host_status_effect") && \
			effect_application_chance > randf_range(0,1):
		var new_id = StatusEffectId.get_next_id() # TODO : be carefull that the id dosen't grow too quickly, maybe release if not used 
		if creature.can_host_status_effect(new_id): # TODO: check if really usefull
			creature.add_effect_id(new_id)
			var effect_instance = effects_data[effect_type][0].instantiate()
			effect_instance.same_effect = effects_data[effect_type][0]
			effect_instance.value = effects_data[effect_type][1]
			effect_instance.effect_id = new_id
			effect_instance.target = creature
			effect_instance.total_duration = effects_data[effect_type][2]
			effect_instance.total_duration_fixe = effects_data[effect_type][2]
			effect_instance.effect_area_range_transmission = effects_data[effect_type][3]
			creature.add_child(effect_instance)


func _update_life_display() -> void:
	var health_ratio: float = health_component.health / health_component.get_max_health()
	#print(self, " _update_life_display, health_ratio: ", health_ratio)
	#$HealthBar.set_instance_shader_parameter("health", health_ratio)
	
	call_deferred("_update_life_display_custom", health_ratio)

func _death_sequence_summoned() -> void:
	# TODO: animations
	is_dead.emit(id)
	queue_free() # no emition of death signals

static func get_next_id() -> int:
	next_id += 1
	return next_id - 1

func get_id() -> int:
	return id

func get_type() -> Enums.DamageType:
	return damage_type
