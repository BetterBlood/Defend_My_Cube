extends RuneUpgrade

class_name RuneUpgradePenetration


func _init(rune: Rune, lvl: RuneUpgrade.UpgradeLevel = RuneUpgrade.UpgradeLevel.ONE) -> void:
	super._init(rune)
	upgrade_lvl = lvl
	rune_resource.projectile_penetration = UPGRADE_VALUES[RuneUpgradeType.PENETRATION][lvl]


func _to_string() -> String:
	return str(RuneUpgrade.RuneUpgradeType.keys()[5])
