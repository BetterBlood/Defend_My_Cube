extends Node

class_name Enums

enum DamageType {
	NORMAL,
	FIRE,
	PLANT,
	ELEC
}

enum UpgradeLevel { # TODO: !!! check uniformisation with all upgrades !!!!
	ONE = 0,
	TWO = 1,
	THREE = 2,
	FOUR = 3,
	FIVE = 4,
}

static var damage_type_loaded: bool = false

static var damage_type_grid:Dictionary = {}

static func get_grid_modifier(att_type: Enums.DamageType, def_type: Enums.DamageType) -> float:
	#print("att_type: ", Enums.DamageType.keys()[att_type], ", def_type: ", Enums.DamageType.keys()[def_type])
	return damage_type_grid[str(Enums.DamageType.keys()[att_type])][def_type]

static func save_grid_damage_type() -> void:
	var config = ConfigFile.new()
	config.set_value("NORMAL", "grid", [1, 0.5, 0.5, 0.5])
	config.set_value("FIRE", "grid", [1.5, 1, 2, 0.5])
	config.set_value("PLANT", "grid", [1.5, 0.5, 1, 2])
	config.set_value("ELEC", "grid", [1.5, 2, 0.5, 1])
	config.save("user://damageGrid.cfg")
	
	for damage_type in config.get_sections():
		print(damage_type)
		if (	!damage_type_grid.has(damage_type)) and \
				len(config.get_value(damage_type, "grid")) == len(config.get_sections()):
			damage_type_grid[damage_type] = config.get_value(damage_type, "grid")
		#else:
			#print("Enums::save_grid_damage_type: ", damage_type, " not load, probably already loaded")
	
	damage_type_loaded = true

static func load_grid_damage_type(config: ConfigFile, erase: bool = false) -> void:
	for damage_type in config.get_sections():
		if (	!damage_type_grid.has(damage_type)) and \
				len(config.get_value(damage_type, "grid")) == len(config.get_sections()):
			damage_type_grid[damage_type] = config.get_value(damage_type, "grid")
			#print("Enums::load_grid_damage_type: ", damage_type, " loaded correctly")
		else:
			push_error("Error while reading 'damageGrid.cfg'. damage_type_grid may not correctly be initialised. Please verify file content !")
			config.clear()
			if erase:
				save_grid_damage_type()
			else:
				print("#TODO : close the application without erasing the file")
				#get_tree().quit(0)
			return
	damage_type_loaded = true
