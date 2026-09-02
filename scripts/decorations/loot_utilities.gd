extends Node

class_name LootUtilities

static func get_loot(is_upgrade: bool, special_seed: String):
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(special_seed)
	
	if !is_upgrade:
		var loot_options: Array[int] = []
		
		var all_runes = []
		for rune_data in Rune.get_runes_infos():
			if rune_data["rune_id"] != -1: # (not -1) cause is debug rune
				all_runes.append(rune_data["rune_id"])
		
		for i in range(3):
			var index = rng.randi_range(0, len(all_runes) - 1)
			loot_options.append(all_runes[index])
			all_runes.remove_at(index) # prevent presenting 2 same rune to user
		
		#print("LootOrbe::set_loot:new_runes: ", new_runes)
		return loot_options
	else:
		var upgrade_lvls: Array[int] = [0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 3, 3, 4]
		
		var loot_options: Array = []
		loot_options.append([])
		for i in range(3):
			loot_options[0].append(
				[rng.randi_range(0, Rune.NBR_UPGRADES - 1),
				upgrade_lvls[rng.randi_range(0, len(upgrade_lvls) - 1)]
				])
		
		loot_options.append([])
		for i in range(3):
			loot_options[1].append(
				[rng.randi_range(0, HealthComponent.NBR_UPGRADES - 1),
				upgrade_lvls[rng.randi_range(0, len(upgrade_lvls) - 1)]
				])
		
		loot_options.append([])
		for i in range(2):
			loot_options[2].append([
				rng.randi_range(0, Grapple.NBR_UPGRADES - 1),
				upgrade_lvls[rng.randi_range(0, len(upgrade_lvls) - 1)]
				])
		return loot_options
