class_name TowerBase
extends Node3D

## TowerBase: Basisklasse für alle Verteidigungspflanzen (Blüten & Kräuter).

const SymbiosisIndicatorTex = preload("res://assets/sprites/props/symbiosis_flower_indicator.png")

signal level_upgraded(new_level: int)
signal symbiosis_unlocked()
signal energy_changed(current: float, max_val: float)

@export var plant_name: String = "Basis-Pflanze"
@export var level: int = 1
@export var max_level: int = 3
@export var cost_level_1: int = 50
@export var cost_level_2: int = 75
@export var cost_level_3: int = 140
@export var cost_symbiosis: int = 100

@export var attack_range: float = 6.0
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 0.8

# Symbiose-Werte
@export var has_symbiosis_upgrade: bool = false
@export var max_energy: float = 18.0
var current_energy: float = 18.0
var is_active_in_symbiosis: bool = false

var fire_timer: float = 0.0
var current_target: Node3D = null

@onready var first_person_mount: Marker3D = $FirstPersonMount
@onready var range_area: Area3D = $RangeArea

var _initial_sprite_scale: Vector3 = Vector3.ONE
var _plant_sprite: Sprite3D = null
var _symbiosis_indicator: Sprite3D = null

func _ready() -> void:
	current_energy = max_energy
	if range_area:
		range_area.area_entered.connect(_on_range_area_entered)
		range_area.area_exited.connect(_on_range_area_exited)
	GameManager.symbiosis_entered.connect(_on_symbiosis_entered)
	GameManager.symbiosis_exited.connect(_on_symbiosis_exited)

	_setup_sprite_and_indicator()

func _setup_sprite_and_indicator() -> void:
	_plant_sprite = find_child("PaperCutout", true, false) as Sprite3D
	if not _plant_sprite:
		_plant_sprite = find_child("Sprite3D", true, false) as Sprite3D
	if _plant_sprite:
		_initial_sprite_scale = _plant_sprite.scale

	# Symbiose-Indikator Blüte erstellen
	if SymbiosisIndicatorTex:
		_symbiosis_indicator = Sprite3D.new()
		_symbiosis_indicator.name = "SymbiosisIndicator"
		_symbiosis_indicator.texture = SymbiosisIndicatorTex
		_symbiosis_indicator.pixel_size = 0.0034
		_symbiosis_indicator.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_symbiosis_indicator.no_depth_test = true
		_symbiosis_indicator.render_priority = 5
		_symbiosis_indicator.position = Vector3(0.0, 2.7, 0.0)
		_symbiosis_indicator.visible = (level >= 3 or has_symbiosis_upgrade)

		# Klickbereich für bequemen Direkteinstieg
		var area := Area3D.new()
		area.name = "ClickArea"
		area.input_ray_pickable = true
		var col := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 0.65
		col.shape = sphere
		area.add_child(col)
		area.input_event.connect(_on_symbiosis_indicator_input)
		_symbiosis_indicator.add_child(area)

		add_child(_symbiosis_indicator)

func _process(delta: float) -> void:
	if _symbiosis_indicator and _symbiosis_indicator.visible:
		var t := Time.get_ticks_msec() * 0.001
		_symbiosis_indicator.position.y = 2.7 + sin(t * 3.2) * 0.08
		var pulse := 1.0 + sin(t * 4.2) * 0.08
		_symbiosis_indicator.scale = Vector3(pulse, pulse, pulse)
		_symbiosis_indicator.rotation.z = sin(t * 2.0) * 0.08

	if is_active_in_symbiosis:
		_process_symbiosis(delta)
	else:
		_process_tactical_autofire(delta)
		_process_tactical_autofire(delta)

func _process_tactical_autofire(delta: float) -> void:
	fire_timer -= delta
	if not current_target or not is_instance_valid(current_target):
		current_target = _find_next_target()
	if fire_timer <= 0.0 and current_target and is_instance_valid(current_target):
		fire_at_target(current_target)
		fire_timer = attack_cooldown

func _find_next_target() -> Node3D:
	if not range_area:
		return null
	for area in range_area.get_overlapping_areas():
		if area.owner and area.owner.is_in_group("enemies") and is_instance_valid(area.owner):
			return area.owner as Node3D
	return null

func _process_symbiosis(delta: float) -> void:
	current_energy = maxf(current_energy - delta, 0.0)
	energy_changed.emit(current_energy, max_energy)
	if current_energy <= 0.0:
		GameManager.exit_symbiosis()

func fire_at_target(target: Node3D) -> void:
	# Wird von abgeleiteten Pflanzen überschrieben (z.B. Dornen-Rose, Löwenzahn)
	pass

func fire_manual(aim_ray: RayCast3D) -> void:
	# Manuelles Schießen im 1st-Person Symbiose Modus
	pass

func trigger_special_ability() -> void:
	# Individuelle Fähigkeit (Rechte Bildschirmhälfte)
	pass

func upgrade_level() -> bool:
	if level >= max_level:
		return false
	var next_cost := get_upgrade_cost()
	if GameManager.spend_dewdrops(next_cost):
		level += 1
		attack_damage *= 1.35
		attack_range *= 1.15
		attack_cooldown *= 0.9

		_play_watering_growth_effect(level)

		# Bei Stufe 3 Symbiose aktivieren & Indikator zeigen
		if level >= 3:
			has_symbiosis_upgrade = true
			symbiosis_unlocked.emit()
		_update_symbiosis_indicator()

		level_upgraded.emit(level)
		return true
	return false

func _update_symbiosis_indicator() -> void:
	if _symbiosis_indicator:
		_symbiosis_indicator.visible = (level >= 3 or has_symbiosis_upgrade)

func _play_watering_growth_effect(new_level: int) -> void:
	# 1. Squash & Stretch Hüpf-Animation (+15% pro Stufe)
	var sprite := _plant_sprite
	if not sprite:
		sprite = find_child("PaperCutout", true, false) as Sprite3D
	if not sprite:
		sprite = find_child("Sprite3D", true, false) as Sprite3D

	var target_mult := 1.0 + float(new_level - 1) * 0.15
	var target_scale := _initial_sprite_scale * target_mult

	if sprite:
		var tw := create_tween()
		var squash := Vector3(target_scale.x * 1.25, target_scale.y * 0.78, target_scale.z * 1.25)
		var stretch := Vector3(target_scale.x * 0.85, target_scale.y * 1.32, target_scale.z * 0.85)

		tw.tween_property(sprite, "scale", squash, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(sprite, "scale", stretch, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(sprite, "scale", target_scale, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# 2. Wassertröpfchen-Spritzer Partikel
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.88
	p.amount = 20
	p.lifetime = 0.55
	p.direction = Vector3(0.0, 1.0, 0.0)
	p.spread = 65.0
	p.initial_velocity_min = 2.6
	p.initial_velocity_max = 4.8
	p.gravity = Vector3(0.0, -11.0, 0.0)

	var mesh := SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.10
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.48, 0.85, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.75, 1.0, 1.0)
	mat.emission_energy_multiplier = 0.8
	mat.roughness = 0.15
	mesh.material = mat
	p.mesh = mesh

	add_child(p)
	p.position = Vector3(0.0, 0.6, 0.0)
	p.emitting = true
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)

func _on_symbiosis_indicator_input(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		GameManager.enter_symbiosis(self)

func unlock_symbiosis() -> bool:
	if has_symbiosis_upgrade or level < 2:
		return false
	if GameManager.spend_dewdrops(cost_symbiosis):
		has_symbiosis_upgrade = true
		_update_symbiosis_indicator()
		symbiosis_unlocked.emit()
		return true
	return false

func get_upgrade_cost() -> int:
	if level == 1:
		return cost_level_2
	elif level == 2:
		return cost_level_3
	return 0

func _on_range_area_entered(area: Area3D) -> void:
	if not current_target and area.owner and area.owner.is_in_group("enemies"):
		current_target = area.owner

func _on_range_area_exited(area: Area3D) -> void:
	if current_target and area.owner == current_target:
		current_target = null

func _on_symbiosis_entered(tower: Node3D) -> void:
	if tower == self:
		is_active_in_symbiosis = true
		current_energy = max_energy

func _on_symbiosis_exited() -> void:
	if is_active_in_symbiosis:
		is_active_in_symbiosis = false
