extends RuneUpgrade

class_name RuneUpgradeEffectDuration


func _init(rune: Rune, lvl: RuneUpgrade.UpgradeLevel = RuneUpgrade.UpgradeLevel.ONE) -> void:
	super._init(rune)
	upgrade_lvl = lvl
	rune_resource.projectile_effect_duration = UPGRADE_VALUES[RuneUpgradeType.EFFECT_DURATION][lvl]


func _to_string() -> String:
	return str(RuneUpgrade.RuneUpgradeType.keys()[3])
