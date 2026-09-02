extends RuneUpgrade

class_name RuneUpgradeDamage


func _init(rune: Rune, lvl: RuneUpgrade.UpgradeLevel = RuneUpgrade.UpgradeLevel.ONE) -> void:
	super._init(rune)
	upgrade_lvl = lvl
	rune_resource.projectile_damage = UPGRADE_VALUES[RuneUpgradeType.DAMAGE][lvl]


func _to_string() -> String:
	return str(RuneUpgrade.RuneUpgradeType.keys()[2])
