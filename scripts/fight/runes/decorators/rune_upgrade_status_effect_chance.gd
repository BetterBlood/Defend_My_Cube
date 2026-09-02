extends RuneUpgrade

class_name RuneUpgradeStatusEffectChance


func _init(rune: Rune, lvl: RuneUpgrade.UpgradeLevel = RuneUpgrade.UpgradeLevel.ONE) -> void:
	super._init(rune)
	upgrade_lvl = lvl
	rune_resource.projectile_status_effect_chance = UPGRADE_VALUES[RuneUpgradeType.STATUS_EFFECT_CHANCE][lvl]


func _to_string() -> String:
	return str(RuneUpgrade.RuneUpgradeType.keys()[9])
