extends RuneUpgrade

class_name RuneUpgradeBounce


func _init(rune: Rune, lvl: RuneUpgrade.UpgradeLevel = RuneUpgrade.UpgradeLevel.ONE) -> void:
	super._init(rune)
	upgrade_lvl = lvl
	rune_resource.projectile_bounce_count = UPGRADE_VALUES[RuneUpgradeType.BOUNCE][lvl]


func _to_string() -> String:
	return str(RuneUpgrade.RuneUpgradeType.keys()[0])
