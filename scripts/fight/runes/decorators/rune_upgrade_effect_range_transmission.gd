extends RuneUpgrade

class_name RuneUpgradeEffectRangeTransmission


func _init(rune: Rune, lvl: RuneUpgrade.UpgradeLevel = RuneUpgrade.UpgradeLevel.ONE) -> void:
	super._init(rune)
	upgrade_lvl = lvl
	rune_resource.projectile_effect_area_range_transmission = UPGRADE_VALUES[RuneUpgradeType.EFFECT_RANGE][lvl]


func _to_string() -> String:
	return str(RuneUpgrade.RuneUpgradeType.keys()[4])
