extends Creature

class_name WaveButton

signal start_wave_triggered

@onready var label: Label3D = $HitArea/Label3D
@onready var player_catcher: Node3D = $HitArea/PlayerCatcher

var current_tween: Tween

func _ready() -> void:
	health_bar = $HealthBar
	
	super._ready()
	
	health_component._max_health = 12
	health_component.health = 12
	_update_life_display()
	set_active_visuals(true)


func _death_sequence() -> void:
	start_wave_triggered.emit()
	
	health_component.health = health_component._max_health
	_update_life_display()
	set_active_visuals(false)

func set_active_visuals(active: bool) -> void:
	var max_size: float = 70.0 if active else 10.0
	var pulse_color: Color = Color(1.0, 0.0, 0.0, 0.3) if active else Color(1.0, 0.5, 0.0, 0.3)
	
	if player_catcher:
		var mat = player_catcher.material_override
		if not mat:
			mat = StandardMaterial3D.new()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			player_catcher.material_override = mat
		mat.albedo_color = pulse_color
		mat.emission_enabled = true
		mat.emission = pulse_color
	
	if current_tween:
		current_tween.kill()
	
	_start_pulse_animation(max_size)

func _start_pulse_animation(max_size: float) -> void:
	current_tween = create_tween().set_loops()
	
	current_tween.tween_property(player_catcher, "scale", Vector3(0.001, 0.001, 0.001), 1.5).from(Vector3.ONE * max_size)

func _update_life_display() -> void:
	var health_ratio: float = health_component.health / health_component.get_max_health()
	call_deferred("_update_life_display_custom", health_ratio)
