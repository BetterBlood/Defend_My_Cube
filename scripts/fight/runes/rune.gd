extends Node

class_name Rune

var cooldown: float 
# decorators attribute
var rune_resource: RuneResource = RuneResource.new()


var projectile_scene: Resource

var projectile_layer_to_hit: int = 1
var projectile_source: Creature
var rune_spot: Marker3D
var rune_spot_two: Marker3D

static var NBR_UPGRADES: int = 10

const RUNE_VISUAL_IDENTIFIER = preload("res://scenes/fight/runes/visualIndicators/rune_visual_identifier.tscn")
const SECOND_RUNE_VISUAL_IDENTIFIER = preload("res://scenes/fight/runes/visualIndicators/second_rune_visual_identifier.tscn")
var visual_rune: Node3D
var active_mat: StandardMaterial3D

static var all_runes: Array = []
static var all_default_rune_classes: Array = [
	DebugRune, NormalRune1, FireRune1, PlantRune1, ElectricRune1
]

func _init(parent: Node3D) -> void:
	#print("_init de Rune: ", self)
	projectile_source = parent
	rune_spot = projectile_source.get_fire_projectile_spot()
	rune_spot_two = projectile_source.get_waiting_rune_spot()
	if rune_spot == null:
		push_warning("Rune shooting position not set, set to (0, 0, 0)")
		rune_spot = Marker3D.new()
		rune_spot.position = Vector3()
		#get_parent().add_child(rune_spot)
	if rune_spot_two == null:
		push_warning("Rune waiting position position not set, set to (0, 0, 0)")
		rune_spot_two = Marker3D.new()
		rune_spot_two.position = Vector3()
		#get_parent().add_child(rune_spot_two)
		


func activate() -> void:
	for child in get_rune_spot().get_children():
		child.queue_free()
	visual_rune = RUNE_VISUAL_IDENTIFIER.instantiate()
	visual_rune.scale = Vector3(0.2, 0.2, 0.2)
	get_rune_spot().add_child(visual_rune)
	visual_rune.get_child(0).mesh.material = get_active_mat()

func activate_two() -> void:
	for child in get_rune_spot_two().get_children():
		child.queue_free()
	visual_rune = SECOND_RUNE_VISUAL_IDENTIFIER.instantiate()
	visual_rune.scale = Vector3(0.1, 0.1, 0.1)
	get_rune_spot_two().add_child(visual_rune)
	visual_rune.get_child(0).mesh.material = get_active_mat()

func get_rune_spot() -> Marker3D:
	return rune_spot

func get_rune_spot_two() -> Marker3D:
	return rune_spot_two

func get_active_mat() -> StandardMaterial3D:
	return active_mat

func _set_rune() -> void:
	#print("Rune::_set_rune all_rune: ", all_runes)
	if len(all_runes) <= 0:
		#print("Rune::_set_rune call 'get_runes_infos'")
		get_runes_infos(true)
	
	#print("Rune::_set_rune 'get_runes_infos' called")
	
	for rune_data in all_runes:
		if int(rune_data["rune_id"]) == get_rune_id():
			_set_rune_data(rune_data)

func _set_rune_data(rune_data: Dictionary) -> void:
	cooldown = float(rune_data["cooldown"])
	
	rune_resource.cooldown_reduction = float(rune_data["cooldown_reduction"])
	rune_resource.projectile_perforation_count = int(rune_data["p_perforation_count"])
	rune_resource.projectile_bounce_count = int(rune_data["p_bounce_count"])
	rune_resource.projectile_penetration = float(rune_data["p_penetration"])
	rune_resource.projectile_damage = float(rune_data["p_damage"])
	rune_resource.projectile_speed = float(rune_data["p_speed"])
	rune_resource.projectile_status_effect_chance = float(rune_data["p_status_effect_chance"])
	rune_resource.projectile_radius = float(rune_data["p_radius"])
	rune_resource.projectile_effect_duration = float(rune_data["p_effect_duration"])
	rune_resource.projectile_effect_area_range_transmission = float(rune_data["p_effect_area_range_transmission"])

static func get_default_rune_data() -> Dictionary:
	print("Rune::set_default_rune_data:: SHOULD NOT APPEAR !")
	push_warning("Pls be carefull, this methode is designed to be overriden in subclasses, or not being called")
	return {}

static func save_rune_infos() -> void: # TODO: on update, don't forget to update get_runes_infos
	var config = ConfigFile.new()
	for i in range(len(all_default_rune_classes)):
		var rune_data = all_default_rune_classes[i].get_default_rune_data()
		#print(rune_data)
		var rune_id_as_str = str(i - 1) # minus 1 cause of debug rune state at 0 but id -1
		
		config.set_value(rune_id_as_str, "name", rune_data["name"])
		config.set_value(rune_id_as_str, "type", int(rune_data["type"]))
		config.set_value(rune_id_as_str, "cost_value", int(rune_data["cost_value"]))
		
		config.set_value(rune_id_as_str, "cooldown", float(rune_data["cooldown"]))
		
		config.set_value(rune_id_as_str, "cooldown_reduction", float(rune_data["cooldown_reduction"]))
		config.set_value(rune_id_as_str, "p_perforation_count", int(rune_data["p_perforation_count"]))
		config.set_value(rune_id_as_str, "p_bounce_count", int(rune_data["p_bounce_count"]))
		config.set_value(rune_id_as_str, "p_penetration", float(rune_data["p_penetration"]))
		config.set_value(rune_id_as_str, "p_damage", float(rune_data["p_damage"]))
		config.set_value(rune_id_as_str, "p_speed", float(rune_data["p_speed"]))
		config.set_value(rune_id_as_str, "p_status_effect_chance", float(rune_data["p_status_effect_chance"]))
		config.set_value(rune_id_as_str, "p_radius", float(rune_data["p_radius"]))
		config.set_value(rune_id_as_str, "p_effect_duration", float(rune_data["p_effect_duration"]))
		config.set_value(rune_id_as_str, "p_effect_area_range_transmission", float(rune_data["p_effect_area_range_transmission"]))
	
	#config.set_value("0", "name", "Normal_1")
	#config.set_value("0", "type", Enums.DamageType.NORMAL)
	#config.set_value("0", "cost_value", 50)
	#
	#config.set_value("1", "name", "Fire_1")
	#config.set_value("1", "type", Enums.DamageType.FIRE)
	#config.set_value("1", "cost_value", 50)
	#
	#config.set_value("2", "name", "Plant_1")
	#config.set_value("2", "type", Enums.DamageType.PLANT)
	#config.set_value("2", "cost_value", 50)
	#
	#config.set_value("3", "name", "Elec_1")
	#config.set_value("3", "type", Enums.DamageType.ELEC)
	#config.set_value("3", "cost_value", 50)
	
	
	config.save("user://all_runes.cfg")

static func get_rune_info(id: int) -> Dictionary:
	for rune in all_runes:
		if rune["rune_id"] == id:
			return rune
	return {}

 # TODO: on update, don't forget to update save_rune_infos
static func get_runes_infos(erase_current: bool = false) -> Array:
	#print("Rune::get_runes_infos")
	var config = ConfigFile.new()
	var err = config.load("user://all_runes.cfg")
	
	if err != OK:
		#print("Rune::get_runes_infos:: err: ", str(err))
		if erase_current:
			push_warning("Rune info unreadable, set to default")
			#print("Rune::_set_rune call 'save_rune_infos'")
			save_rune_infos()
		
		err = config.load("user://all_runes.cfg")
		if err != OK:
			push_error("Unable to load rune config files. Please check file: " + " 'all_runes.cfg'")
			return []
	
	if erase_current:
		all_runes.clear()
	elif len(config.get_sections()) == len(all_runes):
		return all_runes
	
	if len(config.get_sections()) == 0:
		save_rune_infos()
		push_warning("Rune info was empty, set to default")
		
		err = config.load("user://all_runes.cfg")
		if err != OK:
			push_error("Unable to load rune config files. Please check file: " + " 'all_runes.cfg'")
			return []
	
	for section in config.get_sections():
		all_runes.append(
			{
				"rune_id" : int(section), 
				"name" : config.get_value(section, "name"), 
				"type" : int(config.get_value(section, "type")),
				"cost_value" : int(config.get_value(section, "cost_value")),
				
				"cooldown" : float(config.get_value(section, "cooldown")),
				
				"cooldown_reduction" : float(config.get_value(section, "cooldown_reduction")),
				"p_perforation_count" : int(config.get_value(section, "p_perforation_count")),
				"p_bounce_count" : int(config.get_value(section, "p_bounce_count")),
				"p_penetration" : float(config.get_value(section, "p_penetration")),
				"p_damage" : float(config.get_value(section, "p_damage")),
				"p_speed" : float(config.get_value(section, "p_speed")),
				"p_status_effect_chance" : float(config.get_value(section, "p_status_effect_chance")),
				"p_radius" : float(config.get_value(section, "p_radius")),
				"p_effect_duration" : float(config.get_value(section, "p_effect_duration")),
				"p_effect_area_range_transmission" : float(config.get_value(section, "p_effect_area_range_transmission"))
			}
		)
	
	return all_runes


static func create_rune_with_id(id: int, parent: Node3D) -> Rune:
	match(id): # TODO: add case for all runes
		-1: return DebugRune.new(parent)
		0: return NormalRune1.new(parent)
		1: return FireRune1.new(parent)
		2: return PlantRune1.new(parent)
		3: return ElectricRune1.new(parent)
		_: push_warning("Rune id " + str(id) + " not recognized: FireRune1 used by default")
	
	return FireRune1.new(parent)


static func create_rune(rune_data, parent: Node3D) -> Rune:
	if !rune_data: return null
	 
	var rune: Rune = create_rune_with_id(int(rune_data["rune_id"]), parent)
	
	var upgrades = rune_data["rune_upgrades"]
	
	for upgrade in upgrades:
		rune = upgrade_rune(rune, upgrade["type"], upgrade["level"])
	
	return rune


static func upgrade_rune(rune: Rune, upgrade_name: String, level: int) -> Rune:
	#sprint("Rune::upgrade_rune, rune: ", rune.get_save_infos(), ", upgrade_name: ", upgrade_name, ", lvl: ", str(level))
	match(upgrade_name):
		"BOUNCE":
			return RuneUpgradeBounce.new(rune, level)
		"COOLDOWN_REDUCTION":
			return RuneUpgradeCooldownReduction.new(rune, level)
		"DAMAGE":
			return RuneUpgradeDamage.new(rune, level)
		"EFFECT_DURATION":
			return RuneUpgradeEffectDuration.new(rune, level)
		"EFFECT_RANGE":
			return RuneUpgradeEffectRangeTransmission.new(rune, level)
		"PENETRATION":
			return RuneUpgradePenetration.new(rune, level)
		"PERFORATION":
			return RuneUpgradePerforation.new(rune, level)
		"RADIUS":
			return RuneUpgradeRadius.new(rune, level)
		"SPEED":
			return RuneUpgradeSpeed.new(rune, level)
		"STATUS_EFFECT_CHANCE":
			return RuneUpgradeStatusEffectChance.new(rune, level)
		_: push_warning("Rune upgrade " + upgrade_name + " not recognized")
	return rune


func light_attack(destination: Vector3, rune_resource_for_projectile: RuneResource) -> void:
	#print(self, " ", rune_resource_for_projectile.projectile_damage)
	var projectile = projectile_scene.instantiate()
	
	get_projectile_source().get_parent().add_child(projectile)
	projectile.source = get_projectile_source()
	projectile.global_position = get_rune_spot().global_position
	projectile.set_layers_to_hit(get_layet_to_hit())
	projectile.set_data(rune_resource_for_projectile)
	
	projectile.apply_impulse(
		(destination - get_rune_spot().global_position).normalized() * 
		rune_resource_for_projectile.projectile_speed, Vector3())

func get_projectile_source() -> Creature:
	return projectile_source

func get_layet_to_hit() -> int:
	return projectile_layer_to_hit

func set_layet_to_hit(value: int) -> void:
	projectile_layer_to_hit = value

func heavy_attack(destination: Vector3, rune_resource_for_projectile: RuneResource, ratio: float) -> void:
	ratio = max(ratio, 0.0)
	ratio = min(ratio, 1.0)
	#print("Rune::heavy_attack ratio: ", ratio)
	var tmp: RuneResource = RuneResource.new()
	tmp.projectile_radius = rune_resource_for_projectile.projectile_radius * ratio
	tmp.projectile_damage = rune_resource_for_projectile.projectile_damage * ratio
	tmp.projectile_speed = (rune_resource_for_projectile.projectile_speed * ratio) / -4 # cause we add so we need a negative speed to slow down the projetile (bigger stronger but slower)
	light_attack(destination, RuneResource.add(rune_resource_for_projectile, tmp))


func get_rune_id() -> int:
	return -1


func get_damage_type() -> Enums.DamageType:
	push_error("get_damage_type not implemented in ", self)
	assert(false, "Override of `get_damage_type()` needed in " + str(self))
	return Enums.DamageType.NORMAL


func get_data_to_performe_attaque() -> RuneResource:
	#print("get_data_to_performe_attaque()::Rune")
	return rune_resource


func get_initial_cooldown() -> float:
	return cooldown


func get_save_infos() -> Dictionary:
	return {"rune_id": get_rune_id(), "rune_upgrades" : []}
