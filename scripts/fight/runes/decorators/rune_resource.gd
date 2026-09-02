extends Resource

class_name RuneResource

# used by rune and by decorator; need to be 0 by default !
var cooldown_reduction: float = 0.0
var projectile_perforation_count: int = 0
var projectile_bounce_count: int = 0
var projectile_penetration: float = 0.0
var projectile_damage: float = 0.0
var projectile_speed: float = 0.0
var projectile_status_effect_chance: float = 0.0
var projectile_radius: float = 0.0
var projectile_effect_duration: float = 0.0
var projectile_effect_area_range_transmission: float = 0.0


static func add(
		upgraded_rune_resource: RuneResource = RuneResource.new(), 
		rune_resource: RuneResource = RuneResource.new()) -> RuneResource:
	var resource_new: RuneResource = RuneResource.new()
	
	resource_new.cooldown_reduction = upgraded_rune_resource.cooldown_reduction + rune_resource.cooldown_reduction
	resource_new.projectile_perforation_count = upgraded_rune_resource.projectile_perforation_count + rune_resource.projectile_perforation_count
	resource_new.projectile_bounce_count = upgraded_rune_resource.projectile_bounce_count + rune_resource.projectile_bounce_count
	resource_new.projectile_penetration = upgraded_rune_resource.projectile_penetration + rune_resource.projectile_penetration
	resource_new.projectile_damage = upgraded_rune_resource.projectile_damage + rune_resource.projectile_damage
	resource_new.projectile_speed = upgraded_rune_resource.projectile_speed + rune_resource.projectile_speed
	resource_new.projectile_status_effect_chance = upgraded_rune_resource.projectile_status_effect_chance + rune_resource.projectile_status_effect_chance
	resource_new.projectile_radius = upgraded_rune_resource.projectile_radius + rune_resource.projectile_radius
	resource_new.projectile_effect_duration = upgraded_rune_resource.projectile_effect_duration + rune_resource.projectile_effect_duration
	resource_new.projectile_effect_area_range_transmission = upgraded_rune_resource.projectile_effect_area_range_transmission + rune_resource.projectile_effect_area_range_transmission
	
	return resource_new
