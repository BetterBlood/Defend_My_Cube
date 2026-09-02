extends RuneUpgrade

class_name RuneUpgradeSpeed


func _init(rune: Rune, lvl: RuneUpgrade.UpgradeLevel = RuneUpgrade.UpgradeLevel.ONE) -> void:
	super._init(rune)
	upgrade_lvl = lvl
	rune_resource.projectile_speed = UPGRADE_VALUES[RuneUpgradeType.SPEED][lvl]


func _to_string() -> String:
	return str(RuneUpgrade.RuneUpgradeType.keys()[8])
