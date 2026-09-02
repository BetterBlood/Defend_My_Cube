extends RuneUpgrade

class_name RuneUpgradePerforation


func _init(rune: Rune, lvl: RuneUpgrade.UpgradeLevel = RuneUpgrade.UpgradeLevel.ONE) -> void:
	super._init(rune)
	upgrade_lvl = lvl
	rune_resource.projectile_perforation_count = UPGRADE_VALUES[RuneUpgradeType.PERFORATION][lvl]


func _to_string() -> String:
	return str(RuneUpgrade.RuneUpgradeType.keys()[6])
