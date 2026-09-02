extends Rune

class_name RuneUpgrade

var rune_upgraded: Rune

enum RuneUpgradeType {
	BOUNCE,
	COOLDOWN_REDUCTION,
	DAMAGE,
	EFFECT_DURATION,
	EFFECT_RANGE,
	PENETRATION,
	PERFORATION,
	RADIUS,
	SPEED,
	STATUS_EFFECT_CHANCE
}

static var enum_str_to_int: Dictionary = {
	"BOUNCE": 0,
	"COOLDOWN_REDUCTION": 1,
	"DAMAGE": 2,
	"EFFECT_DURATION": 3,
	"EFFECT_RANGE": 4,
	"PENETRATION": 5,
	"PERFORATION": 6,
	"RADIUS": 7,
	"SPEED": 8,
	"STATUS_EFFECT_CHANCE": 9
}

enum UpgradeLevel {
	ONE = 0,
	TWO = 1,
	THREE = 2,
	FOUR = 3,
	FIVE = 4,
}
# TODO: balance values
const UPGRADE_VALUES: Array = [
	[1, 2, 3, 4, 5], # BOUNCE
	[0.01, 0.02, 0.04, 0.06, 0.1], # COOLDOWN_REDUCTION
	[1, 3, 6, 10, 15], # DAMAGE
	[1, 2, 3, 4, 5], # EFFECT_DURATION
	[1, 2, 3, 4, 5], # EFFECT_RANGE
	[1, 2, 3, 4, 5], # PENETRATION
	[1, 2, 3, 4, 5], # PERFORATION
	[0.1, 0.2, 0.3, 0.4, 0.5], # RADIUS
	[1, 2, 3, 4, 5], # SPEED
	[0.01, 0.02, 0.04, 0.06, 0.1] # STATUS_EFFECT_CHANCE
]


var upgrade_lvl: UpgradeLevel = UpgradeLevel.ONE

func _init(previous_rune: Rune) -> void:
	#print("_init de RuneUpgrade: ", self)
	rune_upgraded = previous_rune


func light_attack(destination: Vector3, rune_resource_for_projectile: RuneResource) -> void:
	rune_upgraded.light_attack(destination, rune_resource_for_projectile)


func heavy_attack(destination: Vector3, rune_resource_for_projectile: RuneResource, ratio: float) -> void:
	rune_upgraded.heavy_attack(destination, rune_resource_for_projectile, ratio)


func get_data_to_performe_attaque() -> RuneResource:
	#print("get_data_to_performe_attaque()::RuneUpgrade")
	return RuneResource.add(rune_upgraded.get_data_to_performe_attaque(), rune_resource)


func get_rune_id() -> int:
	return rune_upgraded.get_rune_id()

func get_save_infos() -> Dictionary:
	var dico = rune_upgraded.get_save_infos()
	dico["rune_upgrades"].append({"type" : _to_string(), "level": upgrade_lvl})
	return dico

func get_rune_spot() -> Marker3D:
	return rune_upgraded.get_rune_spot()

func get_rune_spot_two() -> Marker3D:
	return rune_upgraded.get_rune_spot_two()

func get_active_mat() -> StandardMaterial3D:
	return rune_upgraded.get_active_mat()
	
func get_projectile_source() -> Creature:
	return rune_upgraded.get_projectile_source()

func get_layet_to_hit() -> int:
	return rune_upgraded.get_layet_to_hit()

func get_initial_cooldown() -> float:
	return rune_upgraded.get_initial_cooldown()

func set_layet_to_hit(value: int) -> void:
	rune_upgraded.set_layet_to_hit(value)

func get_damage_type() -> Enums.DamageType:
	return rune_upgraded.get_damage_type()
