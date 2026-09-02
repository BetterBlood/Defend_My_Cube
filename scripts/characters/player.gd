extends Creature

class_name Player

const SPEED = 7.0 # TODO: link to VR set
const JUMP_VELOCITY = 9 # TODO: link to VR set
@onready var head := $Head
@onready var camera := $Head/Camera3D
@onready var elbow: Marker3D = $Elbow
@onready var rune_spot: Marker3D = $RuneSpot
@onready var rune_spot_two: Marker3D = $RuneSpotTwo
@onready var ray_cast_3d: RayCast3D = $Head/RayCast3D

const SENSITIVITY = 0.07
var right_stick_sensitivity_h = 4
var right_stick_sensitivity_v = 4
var directionnalInputs = Vector3(0,0,0)

var JOY_DEADZONE:= 0.1

@export var godMode : bool
@export var godModeSpeedMultiplier = 5
@onready var collisionShape := $CollisionShape3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var joystick_v_event: InputEventJoypadMotion
var joystick_h_event: InputEventJoypadMotion

const SPHERE = preload("res://addons/polyrinthe/sphere.tscn") # DEBUG
const burn_effect = preload("res://scenes/fight/statusEffects/burn_effect.tscn")

var active_rune: Rune
var second_rune: Rune

var grapple: Grapple

var current_player_name: String = "Peter"
var gold: int = 0
#var xp_to_lvl_up:float = 10.0 # computed in function of lvl
var xp_left: float = 0.0 # used during lvl up
var xp_left_2: float = 0.0 # used while not enought xp is earn
var lvl_points: int = 0

const LOOT_ORBE_RUNE = preload("res://scenes/decorations/loot_orbe_rune.tscn")

 # used during upgrades
var tmp_new_runes: Array[int] = []
var tmp_new_rune
var tmp_upgrades: Array = []
const GOLD_UPGRADE_VALUE: int = 20

var essences: Array[int] = [0, 0, 0, 0]

signal try_lvl_up(maze_seed: String)
signal leveling_phase_ended()

var attack_timer: float = 0.0
var hold_attack: bool = false
var is_able_to_attack: bool = true
var last_delta_position: Vector3 = Vector3()

var difficulty: int = 0

var icons_path: String = "res://images/icons/lvl"
var icons_name: String = "_icon.svg"


var xr_interface: XRInterface
var ui: Node

@onready var active_upgrade_menu = $CanvasLayer/UpgradeMenu # Default upgrade menu

func _ready():
	health_bar = $Head/HealthBar
	super._ready()
	#print("player::_ready current_player_name: " + current_player_name)
	godMode = false
	collisionShape.disabled = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	active_rune = NormalRune1.new(self)
	#active_rune = DebugRune.new(self) # DEBUG > (x.o)
	_init_active_rune_visual_spot()
	
	layer = 2
	
	grapple = Grapple.new()
	grapple.set_creature_owner(self)
	$GrapplinPosition.add_child(grapple)
	
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		$MeshInstance3D.queue_free() # TODO: need to check the cohabitation of vr stuff and none vr stuff
		ui = $XROrigin3D/LeftController/Viewport2Din3D_UI.get_scene_instance()
		
		var vr_menu_node = $XROrigin3D/Viewport2Din3D_Upgrade
		if vr_menu_node:
			active_upgrade_menu = vr_menu_node.get_scene_instance()
		
		var vr_pause_node = $XROrigin3D/Viewport2Din3D_Pause
		if vr_pause_node and vr_menu_node:
			var pause_menu_instance = vr_pause_node.get_scene_instance()
			if pause_menu_instance:
				var original_layer = vr_menu_node.collision_layer
				pause_menu_instance.open_pause.connect(func():
					vr_menu_node.collision_layer = 0
				)
				pause_menu_instance.close_pause.connect(func():
					vr_menu_node.collision_layer = original_layer
				)
	else:
		$XROrigin3D.queue_free()
		ui = $CanvasLayer/UI

func initialize_player(meta_data, game_data) -> void:
	if meta_data == null:
		push_error("No meta data for player initialisation")
		return 
	current_player_name = meta_data["current_player_name"]
	
	# meta data:
	active_rune = Rune.create_rune_with_id(meta_data["equiped_rune_lobby"], self)
	active_rune.set_layet_to_hit(5)
	_init_active_rune_visual_spot()
	
	health_component.set_up_perm_with_data(meta_data["health_component_upgrades"])
	
	var essences_owned: Array[int] = []
	for essence in meta_data["essences"]:
		essences_owned.append(int(essence))
	ui.update_essences(essences_owned)
	gold = meta_data["gold"]
	ui.update_gold(gold)
	
	#progression data
	if game_data == null:
		print("while initialize_player: no game data")
		return
	
	#if current_maze == null:
		#push_error("while initialize_player: current_maze null, progression load failed")
		#return
	
	if meta_data["current_player_name"] != game_data["current_player_name"]:
		push_warning("Player game progression initialisation may failed: player names are inconsistant")
	
	#position = current_maze.get_position_for_player_save_point(int(game_data["save_spot_id"]))
	gold = game_data["gold"]
	essences.clear()
	for essence in game_data["essences"]:
		essences.append(int(essence))
	health_component.health = game_data["hp"]
	lvl = game_data["lvl"]
	xp = game_data["xp"]
	ui.update_lvl(lvl + lvl_points, lvl_points)
	ui.update_essences(essences)
	ui.update_gold(gold)
	#xp_to_lvl_up = get_xp_for_leveling_up(lvl)
	
	#print(game_data["runes"])
	var rune1_data = game_data["runes"][0]
	var rune2_data = game_data["runes"][1] if len(game_data["runes"]) > 1 else null
	#print(rune1_data)
	#print(rune2_data)
	
	active_rune = Rune.create_rune(rune1_data, self) # this override meta_data active_rune )> (~.O)
	_init_active_rune_visual_spot()
	second_rune = Rune.create_rune(rune2_data, self)
	if second_rune:
		_init_second_rune_visual_spot()
	
	health_component.set_up_temp_with_data(game_data["health_component_upgrades"])
	grapple.set_up_with_data(game_data["grappin_upgrades"])


func set_difficulty(new_difficulty: int) -> void:
	difficulty = min(2, max(-2, new_difficulty))


func save_progression(save_point_id: int = 0) -> void:
	var save_file = FileAccess.open("user://" + current_player_name + "/progression.save", FileAccess.WRITE)
	
	var save_dict = {
		"current_player_name" : current_player_name,
		"save_spot_id" : save_point_id,
		"gold" : gold,
		"essences" : essences,
		"hp" : health_component.health,
		"lvl" : lvl,
		"xp" : xp,
		"runes" : 
			[
				active_rune.get_save_infos(),
				second_rune.get_save_infos() if second_rune else {}
			],
		"health_component_upgrades" : health_component.get_temp_data(),
		"grappin_upgrades" : # [0:range, 1:boost, 2:enemy, 3:ice_wall]
			grapple.get_data()
	}
	
	var json_string = JSON.stringify(save_dict)
	
	save_file.store_line(json_string)


func _input(event):
	# Checking right analog stick input for "mouse look"
	if event is InputEventJoypadMotion:
		if event.get_axis() == 3:
			joystick_v_event = event
		if event.get_axis() == 2:
			joystick_h_event = event


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		#print("mouse_motion_detect: ", event)
		rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY))
		head.rotate_x(deg_to_rad(-event.relative.y * SENSITIVITY))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func _physics_process(delta):
	instant_speed = (position - last_delta_position).length() / delta
	
	# adjust health bar, rune position and grapple position for vr
	if xr_interface and xr_interface.is_initialized():
		var vr_cam = $XROrigin3D/XRCamera3D
		
		$Head/HealthBar.global_transform = vr_cam.global_transform * Transform3D().translated(Vector3(0, -0.4, -1))
		$GrapplinPosition.global_transform = $XROrigin3D/RightController.global_transform * Transform3D().translated(Vector3(-0.1, 0, 0))
		$RuneSpot.global_transform = $XROrigin3D/LeftController.global_transform * Transform3D().translated(Vector3(0, -0.1, -0.2))
		$RuneSpotTwo.global_transform = $XROrigin3D/LeftController.global_transform * Transform3D().translated(Vector3(0.1, 0, 0.1)) # TODO adjust with helmet
	
	if hold_attack:
		attack_timer += delta
		# TODO: animation at 0.25 holding time, shader on the visual rune indicator something shinning idk
		# TODO: animation at 2.0 holding time, shader on the visual rune indicator something (more) shinning idk
		#if attack_timer >= 2.0: # mmmmm don't know what I prefer: release on 2 sec holding or give information to player and let him release by himself ?
			#_attack()
	
	if InputMap.has_action("auto_ignite") and Input.is_action_just_pressed("auto_ignite"): # DEBUG
		var target = self
		var tmp_id = 17427
		target.add_effect_id(tmp_id)
		var effect_instance = burn_effect.instantiate()
		effect_instance.same_effect = burn_effect
		effect_instance.value = 1
		effect_instance.effect_id = tmp_id
		effect_instance.target = target
		effect_instance.total_duration = 1.0
		effect_instance.total_duration_fixe = 1.0
		effect_instance.effect_area_range_transmission = 1.0
		target.add_child(effect_instance)
	
	if InputMap.has_action("swap_rune") and Input.is_action_just_pressed("swap_rune"):
		_swap_runes() # TODO: animations !!
	
	if InputMap.has_action("attack") and Input.is_action_just_pressed("attack") and is_able_to_attack:
		#print("Input.is_action_just_pressed")
		attack_timer = 0.0
		hold_attack = true
	
	if InputMap.has_action("attack") and Input.is_action_just_released("attack") and is_able_to_attack and hold_attack:
		#print("Input.is_action_just_released")
		_attack()
	
	if InputMap.has_action("grapple") and Input.is_action_just_pressed("grapple"):
		#print("grapple ?")
		
		if xr_interface and xr_interface.is_initialized():
			ray_cast_3d.global_transform = $XROrigin3D/RightController.global_transform.rotated_local(Vector3.RIGHT, deg_to_rad(-45))
		else:
			ray_cast_3d.transform = Transform3D()
		
		ray_cast_3d.collision_mask = grapple.get_collision_mask()
		ray_cast_3d.target_position = Vector3(0, 0, -grapple.get_distance())
		ray_cast_3d.force_raycast_update()
		var destination = Vector3()
		var hit: bool
		var hit2: bool = false
		
		if ray_cast_3d.is_colliding():
			destination = ray_cast_3d.get_collision_point()
			hit = true
		else:
			$Head/RayCast3D/Marker3D.position = ray_cast_3d.target_position
			destination = $Head/RayCast3D/Marker3D.global_position
			hit = false
		
		if xr_interface and xr_interface.is_initialized():
			ray_cast_3d.global_transform = $XROrigin3D/RightController.global_transform.rotated_local(Vector3.RIGHT, deg_to_rad(-45))
		else:
			ray_cast_3d.transform = Transform3D()
		
		ray_cast_3d.collision_mask = 32768 - 1 - 8 # -8 to avoid collision with projectiles
		ray_cast_3d.target_position = Vector3(0, 0, -grapple.get_distance() - 1)
		ray_cast_3d.force_raycast_update()
		
		var dist_to_first_surface = Vector3()
		if ray_cast_3d.is_colliding():
			dist_to_first_surface = ray_cast_3d.get_collision_point() - position
			if dist_to_first_surface.length() + 0.0001 < (destination - position).length():
				destination = ray_cast_3d.get_collision_point()
				hit2 = true
				hit = false
		grapple.shoot(destination, hit, hit2)
	
	if InputMap.has_action("grapple") and Input.is_action_just_released("grapple"):
		#print("grapple released")
		grapple.cancel_grab()
	
	if InputMap.has_action("godMod") and Input.is_action_just_pressed("godMod"):
		godMode = !godMode
		if godMode:
			collisionShape.disabled = true
		else :
			collisionShape.disabled = false
	
	if joystick_h_event:
		if abs(joystick_h_event.get_axis_value()) > JOY_DEADZONE:
			rotate_y(deg_to_rad(-joystick_h_event.get_axis_value() * right_stick_sensitivity_h))
	if joystick_v_event:
		if abs(joystick_v_event.get_axis_value()) > JOY_DEADZONE:
			head.rotate_x(deg_to_rad(-joystick_v_event.get_axis_value() * right_stick_sensitivity_v))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	if xr_interface and xr_interface.is_initialized():
		var xr_rotate = $XROrigin3D/RightController.get_vector2("rotate")
		if abs(xr_rotate.x) > JOY_DEADZONE:
			rotate_y(deg_to_rad(-xr_rotate.x * right_stick_sensitivity_h))
		
		# check if usefull, but got nausea with (X~X)
		#if abs(xr_rotate.y) > 0.4:
			#$XROrigin3D.rotate_x(deg_to_rad(xr_rotate.y * right_stick_sensitivity_v))
			#$XROrigin3D.rotation.x = clamp($XROrigin3D.rotation.x, deg_to_rad(-44), deg_to_rad(44))
	
	
	# Add the gravity.
	if not is_on_floor() && !godMode:
		velocity.y -= gravity * delta * 2
	
	directionnalInputs = Vector3(0,0,0)
	
	# Handle Jump.
	if InputMap.has_action("jump") and Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	directionnalInputs.x = input_dir.x
	directionnalInputs.z = input_dir.y
	
	var vertical = Input.get_axis("down", "up")
	directionnalInputs.y = vertical
	
	var direction: Vector3 = Vector3()
	
	if xr_interface and xr_interface.is_initialized():
		var xr_move = $XROrigin3D/LeftController.get_vector2("move")
		directionnalInputs.x = xr_move.x
		directionnalInputs.z = -xr_move.y
		
		var cam_basis = $XROrigin3D/XRCamera3D.global_transform.basis
		direction = (cam_basis * directionnalInputs)
		direction.y = 0
		direction = direction.normalized()
	else:
		direction = (get_global_transform().basis * directionnalInputs).normalized()
	
	if direction.x:
		if grapple.is_dragging:
			velocity.x += direction.x * (health_component.speed/2) * (godModeSpeedMultiplier if godMode else 1)
		else:
			velocity.x = direction.x * health_component.speed * (godModeSpeedMultiplier if godMode else 1)
	else:
		velocity.x = move_toward(velocity.x, 0, health_component.speed)
		
	if direction.z:
		if grapple.is_dragging:
			velocity.z += direction.z * (health_component.speed/2) * (godModeSpeedMultiplier if godMode else 1)
		else:
			velocity.z = direction.z * health_component.speed * (godModeSpeedMultiplier if godMode else 1)
	else:
		velocity.z = move_toward(velocity.z, 0, health_component.speed)
	
	if godMode:
		if direction.y:
			velocity.y = direction.y * health_component.speed * godModeSpeedMultiplier
		else:
			velocity.y = move_toward(velocity.y, 0, health_component.speed)
	
	last_delta_position = position
	
	move_and_slide()


func _attack() -> void:
	#print("Input.u_just_released")
	hold_attack = false
	#print("orphan:")
	#print_orphan_nodes() # DEBUG
	#print("---")
	
	if xr_interface and xr_interface.is_initialized():
		ray_cast_3d.global_transform = $XROrigin3D/LeftController.global_transform.rotated_local(Vector3.RIGHT, deg_to_rad(-45))
	else:
		ray_cast_3d.transform = Transform3D()
	
	ray_cast_3d.collision_mask = 7
	ray_cast_3d.target_position = Vector3(0, 0, -100)
	ray_cast_3d.force_raycast_update()
	var destination = Vector3()
	
	if ray_cast_3d.is_colliding():
		destination = ray_cast_3d.get_collision_point()
	else:
		$Head/RayCast3D/Marker3D.position = ray_cast_3d.target_position
		destination = $Head/RayCast3D/Marker3D.global_position
	
	var rune_resource: RuneResource = active_rune.get_data_to_performe_attaque()
	#print(rune_resource.projectile_damage)
	if attack_timer/2.0 < 0.25:
		active_rune.light_attack(destination, rune_resource)
	else:
		active_rune.heavy_attack(destination, rune_resource, attack_timer/2.0) # 2 second or more = biggest strongest attack
	is_able_to_attack = false
	var cd: float = active_rune.get_initial_cooldown() * (1.0 - min(rune_resource.cooldown_reduction, 0.5)) if not is_in_lobby else 0.1;
	#print("cds: ", active_rune.get_initial_cooldown(), " ", rune_resource.cooldown_reduction, " ", cd)
	var timer: SceneTreeTimer = get_tree().create_timer(cd)
	timer.timeout.connect(
		func ():
			#print("cd ended time: ", cd)
			is_able_to_attack = true
	)
	#print("active_rune save infos: ", active_rune.get_save_infos())
	#active_rune = RuneUpgradeDamage.new(active_rune)
	#active_rune = RuneUpgradeSpeed.new(active_rune)
	
	#var sphere = SPHERE.instantiate()
	#get_parent().add_child(sphere)
	#sphere.position = destination
	#sphere.scale = Vector3(0.2, 0.2, 0.2)


func _on_damage_taken():
	super._on_damage_taken()
	ui.damage_tick()

func _update_life_display():
	var health_ratio: float = health_component.health / health_component.get_max_health()
	#print(self, " _update_life_display, health_ratio: ", health_ratio)
	#$Head/HealthBar.set_instance_shader_parameter("health", health_ratio)
	# TODO : a better visual health indication $Head/HealthBar
	call_deferred("_update_life_display_custom", health_ratio)

func _on_player_area_3d_body_entered(body: Node3D) -> void:
	# TODO: unused for the moment, could be used when the player need to react to something physical hitting him
	print("_on_player_area_3d_body_entered: ", body)


func get_type() -> Enums.DamageType:
	return active_rune.get_damage_type()


func _swap_runes() -> void:
	#print("player::_swap_runes second_rune: ", second_rune)
	if second_rune:
		var tmp_rune = active_rune
		active_rune = second_rune
		second_rune = tmp_rune
		_init_second_rune_visual_spot()
	
	_init_active_rune_visual_spot()


func _init_active_rune_visual_spot() -> void:
	active_rune.activate()
	active_rune.set_layet_to_hit(5)
	# TODO: animation ?

func _init_second_rune_visual_spot() -> void:
	if second_rune:
		second_rune.activate_two()
		second_rune.set_layet_to_hit(5)
		# TODO: animation ?

# upgrades: [[runeType, lvl], [healthType, lvl], [grapleType, lvl]]
func propose_upgrades(upgrades: Array, call_after: Signal) -> void:
	#print(upgrades)
	tmp_upgrades = upgrades
	
	#get_tree().paused = true
	# TODO: maybe show the levels but not the upgrade here
	var prop_1 = ["Rune upgrade", "res://images/icons/icon.svg", "Description:\nSelect 1 of 3 upgrades for selected rune"]
	var prop_2 = ["Player upgrade", "res://images/icons/icon.svg", "Description:\nSelect 1 of 3 upgrades for the health component"]
	var prop_3 = ["Grapple upgrade", "res://images/icons/icon.svg", "Description:\nSelect 1 of 3 upgrades for the grapple"]
	active_upgrade_menu.set_up_propositions(prop_1, prop_2, prop_3, select_upgrade_proposition_type, call_after)
	active_upgrade_menu.set_title("Select an upgrade (rune, health, grapple)")
	active_upgrade_menu.open_menu()
	active_upgrade_menu._init_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func propose_new_runes(new_runes: Array, call_on_finish: Signal) -> void:
	#print(new_runes)
	tmp_new_runes = new_runes
	#get_tree().paused = true
	#print(str(Rune.all_runes[new_runes[0]]))
	var runes: Array = []
	for i in range(3):
		var rune_data: Dictionary = Rune.get_rune_info(int(new_runes[i]))
		runes.append([rune_data["name"], "res://images/icons/icon.svg", 
			"Cooldown: " + str(rune_data["cooldown"]) +
			"\nDamage: " + str(rune_data["p_damage"]) +
			"\nPerforation: " + str(rune_data["p_perforation_count"]) +
			"\nBounce: " + str(rune_data["p_bounce_count"]) +
			"\nPenetration: " + str(rune_data["p_penetration"]) +
			"\nSpeed: " + str(rune_data["p_speed"])
		])
	active_upgrade_menu.set_up_propositions(runes[0], runes[1], runes[2], set_new_rune_at_placement, call_on_finish)
	active_upgrade_menu.set_title("Select a new Rune")
	active_upgrade_menu.set_adding_new_rune()
	active_upgrade_menu.open_menu()
	active_upgrade_menu._init_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func propose_new_rune(new_rune_data: Dictionary, call_on_finish: Signal) -> void:
	#print(new_rune_data)
	tmp_new_rune = new_rune_data
	#get_tree().paused = true
	#print(new_rune_data)
	var rune_data: Dictionary = Rune.get_rune_info(int(new_rune_data["rune_id"]))
	
	var cd_reduction: float = _get_total_for_rune_upgrade("COOLDOWN_REDUCTION")
	var cooldown: float = rune_data["cooldown"] - cd_reduction
	var damage_upgrades: float = _get_total_for_rune_upgrade("DAMAGE")
	var damage: float = rune_data["p_damage"] + damage_upgrades
	var perforation_upgrades: int = int(_get_total_for_rune_upgrade("PERFORATION"))
	var perforation: int = rune_data["p_perforation_count"] + perforation_upgrades
	var bounce_upgrades: int = int(_get_total_for_rune_upgrade("BOUNCE"))
	var bounce: int = rune_data["p_bounce_count"] + bounce_upgrades
	var penetration_upgrades: float = _get_total_for_rune_upgrade("PENETRATION")
	var penetration: float = rune_data["p_penetration"] + penetration_upgrades
	var speed_upgrades: float = _get_total_for_rune_upgrade("SPEED")
	var speed: float = rune_data["p_speed"] + speed_upgrades
	
	var rune_2 = [
		rune_data["name"], 
		"res://images/icons/icon.svg", 
		"Cooldown: " + str(cooldown) + "(" + str(cd_reduction) + ")" +
			"\nDamage: " + str(damage) + "(" + str(damage_upgrades) + ")" +
			"\nPerforation: " + str(perforation) + "(" + str(perforation_upgrades) + ")" +
			"\nBounce: " + str(bounce) + "(" + str(bounce_upgrades) + ")" +
			"\nPenetration: " + str(penetration) + "(" + str(penetration_upgrades) + ")" +
			"\nSpeed: " + str(speed) + "(" + str(speed_upgrades) + ")"
	]
	#var rune_2 = ["rune id:" + str(new_rune_data["rune_id"]), "res://images/icons/icon.svg", "Description:\ndata: " + str(new_rune_data["rune_upgrades"])]
	active_upgrade_menu.set_up_propositions(null, rune_2, null, set_old_rune_at_placement, call_on_finish)
	active_upgrade_menu.set_title("Swap rune with selected slot")
	active_upgrade_menu.set_adding_new_rune()
	active_upgrade_menu.open_menu()
	active_upgrade_menu._init_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _get_total_for_rune_upgrade(upgrade_type:String) -> float:
	var total: float = 0.0
	for upgrade in tmp_new_rune["rune_upgrades"]:
		if upgrade["type"] == upgrade_type:
			total += RuneUpgrade.UPGRADE_VALUES[RuneUpgrade.enum_str_to_int[upgrade["type"]]][upgrade["level"]]
	return total

# TODO: update name for set_new_rune_id_at_placement
func set_new_rune_at_placement(rune_index: int, active_placement: bool, call_on_finish: Signal) -> void:
	var loot_orbe_rune = LOOT_ORBE_RUNE.instantiate()
	loot_orbe_rune.position = position
	loot_orbe_rune.rotation = rotation
	if active_placement: # for the moment copy whole rune with upgrades, maybe swap upgrades on the new rune
		loot_orbe_rune.init_with_rune(active_rune.get_save_infos())
		get_parent().add_child(loot_orbe_rune)
		active_rune = Rune.create_rune_with_id(tmp_new_runes[rune_index], self)
		_init_active_rune_visual_spot()
	else:
		if second_rune:
			loot_orbe_rune.init_with_rune(second_rune.get_save_infos())
			get_parent().add_child(loot_orbe_rune)
		second_rune = Rune.create_rune_with_id(tmp_new_runes[rune_index], self)
		_init_second_rune_visual_spot()
	call_on_finish.emit(true)
	#_set_new_rune_at_placement(tmp_new_runes[rune_index], active_placement, call_on_finish)

#TODO: update name for set_new_rune_at_placement (after updating set_new_rune_id_at_placement bellow) 
func set_old_rune_at_placement(_not_used: int, active_placement: bool, call_on_finish: Signal) -> void:
	var loot_orbe_rune = LOOT_ORBE_RUNE.instantiate()
	loot_orbe_rune.position = position
	loot_orbe_rune.rotation = rotation
	if active_placement: # for the moment copy whole rune with upgrades, maybe swap upgrades on the new rune
		loot_orbe_rune.init_with_rune(active_rune.get_save_infos())
		get_parent().add_child(loot_orbe_rune)
		active_rune = Rune.create_rune(tmp_new_rune, self)
		_init_active_rune_visual_spot()
	else:
		if second_rune:
			loot_orbe_rune.init_with_rune(second_rune.get_save_infos())
			get_parent().add_child(loot_orbe_rune)
		second_rune = Rune.create_rune(tmp_new_rune, self)
		_init_second_rune_visual_spot()
	call_on_finish.emit(true)
	#_set_new_rune_at_placement(tmp_new_rune, active_placement, call_on_finish)


#func _set_new_rune_at_placement(new_rune, active_placement: bool, call_on_finish: Signal) -> void:
	#var loot_orbe_rune = LOOT_ORBE_RUNE.instantiate()
	#loot_orbe_rune.position = position
	#loot_orbe_rune.rotation = rotation
	#if active_placement: # for the moment copy whole rune with upgrades, maybe swap upgrades on the new rune
		#loot_orbe_rune.init_with_rune(active_rune.get_save_infos())
		#get_parent().add_child(loot_orbe_rune)
		#active_rune = Rune.create_rune(new_rune, self)
		#_init_active_rune_visual_spot()
	#else:
		#if second_rune:
			#loot_orbe_rune.init_with_rune(second_rune.get_save_infos())
			#get_parent().add_child(loot_orbe_rune)
		#second_rune = Rune.create_rune(new_rune, self)
		#_init_second_rune_visual_spot()
	#call_on_finish.emit(true)


func select_upgrade_proposition_type(proposition_type_index: int, _no_active_placement: bool, call_on_finished: Signal) -> void:
	await get_tree().create_timer(0.01).timeout
	
	#get_tree().paused = true
	var props: Array = []
	if proposition_type_index == 0:
		active_upgrade_menu.set_title("Select a rune upgrade (1 of 3)")
		for i in range(3):
			props.append([
				str(RuneUpgrade.RuneUpgradeType.keys()[tmp_upgrades[0][i][0]]), 
				icons_path + str(tmp_upgrades[0][i][1] + 1) + icons_name, 
				"Description:\nlvl: " + str(tmp_upgrades[0][i][1] + 1) + "\nvalue: " + 
					str(RuneUpgrade.UPGRADE_VALUES[tmp_upgrades[0][i][0]][tmp_upgrades[0][i][1]])
			])
	elif proposition_type_index == 1:
		active_upgrade_menu.set_title("Select a health upgrade (1 of 3)")
		for i in range(3):
			props.append([
				HealthComponent.upgrades_names[tmp_upgrades[proposition_type_index][i][0]], 
				icons_path + str(tmp_upgrades[proposition_type_index][i][1] + 1) + icons_name, 
				"Description:\nlvl: " + str(tmp_upgrades[proposition_type_index][i][1] + 1) +
					"\nvalue: " + str(HealthComponent.default_upgrades_values[tmp_upgrades[
						proposition_type_index][i][0]] * (tmp_upgrades[proposition_type_index][i][1] + 1))
			])
	else:
		active_upgrade_menu.set_title("Select a grapple upgrade (1 of 2) or gold")
		var gold_proposal = ["golds", "res://images/icons/lvl3_icon.svg", "Description:\nquantité: " + str(GOLD_UPGRADE_VALUE)]
		for i in range(2):
			props.append([
				Grapple.upgrade_names[tmp_upgrades[proposition_type_index][i][0]], 
				icons_path + str(tmp_upgrades[proposition_type_index][i][1] + 1) + icons_name, 
				"Description:\nlvl: " + str(tmp_upgrades[proposition_type_index][i][1] + 1) +
					"\nvalue: " + str(Grapple.upgrade_default_values[tmp_upgrades[
						proposition_type_index][i][0]] * (tmp_upgrades[proposition_type_index][i][1] + 1))
			])
		props.append(gold_proposal)
	#print(props)
	var func_to_call = [select_rune_upgrade, select_health_upgrade, select_grapple_upgrade]
	active_upgrade_menu.set_up_propositions(props[0], props[1], props[2], func_to_call[proposition_type_index], call_on_finished)
	#active_upgrade_menu.set_title("Select an upgrade (1 of 3)")
	active_upgrade_menu.open_menu()
	active_upgrade_menu._init_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func select_rune_upgrade(rune_upgrade_index: int, active_placement: bool, call_on_finished: Signal):
	#print("Player::select_rune_upgrade, active_placement: ", active_placement, ", should be: ", str(RuneUpgrade.RuneUpgradeType.keys()[tmp_upgrades[0][rune_upgrade_index][0]]), ", lvl: ", tmp_upgrades[0][rune_upgrade_index][1])
	if active_placement:
		active_rune = Rune.upgrade_rune(active_rune, str(RuneUpgrade.RuneUpgradeType.keys()[tmp_upgrades[0][rune_upgrade_index][0]]), tmp_upgrades[0][rune_upgrade_index][1])
		_init_active_rune_visual_spot()
	elif second_rune:
		second_rune =  Rune.upgrade_rune(second_rune, str(RuneUpgrade.RuneUpgradeType.keys()[tmp_upgrades[0][rune_upgrade_index][0]]), tmp_upgrades[0][rune_upgrade_index][1])
		_init_second_rune_visual_spot()
	
	call_on_finished.emit(true)


func select_health_upgrade(health_upgrade_index: int, _active_placement: bool, call_on_finished: Signal):
	health_component.add_temp_upgrade(tmp_upgrades[1][health_upgrade_index][0], tmp_upgrades[1][health_upgrade_index][1])
	call_on_finished.emit(true)


func select_grapple_upgrade(grapple_upgrade_index: int, _active_placement: bool, call_on_finished: Signal):
	match grapple_upgrade_index: 
		0: 
			for i in range(tmp_upgrades[2][grapple_upgrade_index][1]):
				grapple.upgrade_range()
		1: 
			for i in range(tmp_upgrades[2][grapple_upgrade_index][1]):
				grapple.upgrade_boost()
		2: gold += GOLD_UPGRADE_VALUE
		_: push_warning("Player::select_grapple_upgrade: grapple_upgrade_index: ", grapple_upgrade_index, " is unknown, tmp_upgrades: ", tmp_upgrades)
	
	call_on_finished.emit(true)


func gain_xp(value: float) -> void:
	#xp_left += value
	#xp_left_2 += value
	#print("Player gain xp amount: ", value, ", total: ", xp_left)
	xp += value
	
	while xp >= get_xp_for_leveling_up(lvl + lvl_points):
		#xp += xp_left_2
		xp -= get_xp_for_leveling_up(lvl + lvl_points)
		#xp_left_2 = 0
		lvl_points += 1
		ui.update_lvl(lvl + lvl_points, lvl_points)


func leveling_phase(maze_seed: String) -> void:
	#print("Player::leveling_phase")
	#if xp_left > 0:
		#xp += xp_left
		##xp_to_lvl_up -= xp_left
		#xp_left = 0
	
	if lvl_points > 0:
		propose_upgrades(LootUtilities.get_loot(true, maze_seed + "lvl" + str(lvl)), try_lvl_up)
		#xp = xp_left_2
		lvl += 1
		lvl_points -= 1
		#xp_to_lvl_up = get_xp_for_leveling_up(lvl)
		await try_lvl_up
		ui.update_lvl(lvl + lvl_points, lvl_points)
		await get_tree().create_timer(0.001).timeout
		leveling_phase(maze_seed)
	else:
		await get_tree().create_timer(0.001).timeout
		#print("Player::leveling_phase:: lvl up end")
		leveling_phase_ended.emit()
	
	#if xp >= xp_to_lvl_up:
		##print("Player::leveling_phase:: lvl up !!")
		#propose_upgrades(LootUtilities.get_loot(true, maze_seed + "lvl" + str(lvl)), try_lvl_up)
		#xp -= xp_to_lvl_up
		#lvl += 1
		#xp_to_lvl_up = get_xp_for_leveling_up(lvl)
		#await try_lvl_up
		#await get_tree().create_timer(0.001).timeout
		#leveling_phase(maze_seed)
	#else:
		#await get_tree().create_timer(0.001).timeout
		##print("Player::leveling_phase:: lvl up end")
		#leveling_phase_ended.emit()


func get_xp_for_leveling_up(current_lvl: int) -> float:
	# TODO: find a great formula to set xp for next lvl
	return 5.0 + 5.0 * current_lvl * current_lvl


func gain_gold(value: int) -> void:
	gold += value
	ui.update_gold(gold)
	#print("Player gain gold amount: ", value, ", new total: ", gold)


func gain_essence(essence_type: Enums.DamageType, value: int) -> void:
	essences[essence_type] += value
	ui.update_essences(essences)
	#print("Player gain essence_type: '", essence_type, "',  amount: ", value, ", total: ", essences)


func gain_ice_wall_grab_upgrade() -> void:
	grapple.upgrade_wall()


func get_fire_projectile_spot() -> Marker3D:
	return rune_spot

func get_waiting_rune_spot() -> Marker3D:
	return rune_spot_two


func get_player_name() -> String:
	return current_player_name


func get_interaction_label() -> Label:
	return ui.get_children()[1]


func set_ressource_on_boss_win() -> void:
	_update_resources(1.0)


func set_ressource_on_death() -> void:
	_update_resources(0.3)


func _update_resources(mult_factor: float) -> void:
	var diff_mult: float = mult_factor + difficulty / 10.0
	gold = int(diff_mult * gold)
	for i in range(len(essences)):
		essences[i] = int(essences[i] * diff_mult)


func _death_sequence() -> void:
	is_dead.emit(-1) # id not used for player


func set_rune_at_placement(rune_id: int, active_placement: bool = true) -> void:
	if active_placement:
		active_rune = Rune.create_rune_with_id(rune_id, self)
		_init_active_rune_visual_spot()
	else:
		second_rune = Rune.create_rune_with_id(rune_id, self)
		_init_second_rune_visual_spot()

# TODO: be carefull when removing an effect pls be certain to correctly clean effect
func remove_all_status_effect() -> void:
	for node in get_children():
		if node is StatusEffect:
			print("Player::remove_all_status_effect node: ", node)
			if node is SpeedEffect:
				health_component.remove_speed_effect(node.effect_id)
			node.queue_free()
	
