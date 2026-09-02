extends RuneUpgrade

class_name RuneUpgradeCooldownReduction


func _init(rune: Rune, lvl: RuneUpgrade.UpgradeLevel = RuneUpgrade.UpgradeLevel.ONE) -> void:
	super._init(rune)
	upgrade_lvl = lvl
	rune_resource.cooldown_reduction = UPGRADE_VALUES[RuneUpgradeType.COOLDOWN_REDUCTION][lvl]


func _to_string() -> String:
	return str(RuneUpgrade.RuneUpgradeType.keys()[1])
