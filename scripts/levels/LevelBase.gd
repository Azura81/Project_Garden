class_name LevelBase
extends Node3D

## LevelBase: Verwaltet Beet, Pfad (Path3D), Pflanzplätze, Wellen und Spawning.

@export var level_number: int = 1
@export var enemy_snail_scene: PackedScene
@export var rose_tower_scene: PackedScene

@onready var path3d: Path3D = $Path3D
@onready var radial_menu: Control = $UI/RadialMenu
@onready var hud_tactical: Control = $UI/HUD_Tactical
@onready var hud_first_person: Control = $UI/HUD_FirstPerson
@onready var start_arrow: Node3D = get_node_or_null("PathStartArrow")
@onready var range_indicator: RangeIndicator = get_node_or_null("RangeIndicator")

var active_enemies: int = 0

func _ready() -> void:
	GameManager.reset_level_state()
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.symbiosis_entered.connect(_on_symbiosis_entered)
	GameManager.symbiosis_exited.connect(_on_symbiosis_exited)
	GameManager.spot_selected.connect(_on_spot_selected_range)
	GameManager.spot_deselected.connect(_on_spot_deselected_range)

	# Pflanzplätze verbinden
	for child in get_tree().get_nodes_in_group("tower_spots"):
		if child.has_signal("spot_clicked"):
			child.connect("spot_clicked", _on_tower_spot_clicked)

func _on_spot_selected_range(spot: Area3D) -> void:
	if not range_indicator or not spot:
		return
	var r: float = 7.0
	if spot.get("current_plant") != null:
		var p: Node3D = spot.get("current_plant")
		if p and p.get("attack_range") != null:
			r = float(p.get("attack_range"))
	range_indicator.show_range(spot.global_position, r)

func _on_spot_deselected_range() -> void:
	if range_indicator:
		range_indicator.hide_range()

func _on_wave_started(wave_idx: int, _total: int) -> void:
	_trigger_entrance_warning()
	# Richtungspfeil verschwindet bei Start der ersten Runde
	if start_arrow and is_instance_valid(start_arrow):
		var tw := create_tween()
		tw.tween_property(start_arrow, "scale", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(start_arrow.queue_free)

	var count := 4 + wave_idx * 3
	active_enemies = count
	for i in range(count):
		await get_tree().create_timer(1.2).timeout
		_spawn_enemy()

func _trigger_entrance_warning() -> void:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 14
	p.lifetime = 0.7
	p.direction = Vector3(1.0, 1.2, 0.0)
	p.spread = 45.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 5.0
	p.gravity = Vector3(0.0, -8.0, 0.0)
	var mesh := SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.48, 0.65, 0.25, 0.9)
	mesh.material = mat
	p.mesh = mesh
	add_child(p)
	p.global_position = Vector3(-16.8, 0.4, -4.5)
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)

func _spawn_enemy() -> void:
	if not path3d or not enemy_snail_scene:
		return
	var snail := enemy_snail_scene.instantiate() as PathFollow3D
	if snail.has_signal("defeated"):
		snail.connect("defeated", func(_r): _on_enemy_removed())
	if snail.has_signal("reached_core"):
		snail.connect("reached_core", func(_d): _on_enemy_removed())
	path3d.add_child(snail)

func _on_enemy_removed() -> void:
	active_enemies = max(active_enemies - 1, 0)
	if active_enemies == 0 and GameManager.is_wave_active:
		GameManager.complete_wave()

func _on_tower_spot_clicked(spot: Area3D) -> void:
	if GameManager.active_symbiosis_tower:
		return
	if radial_menu and radial_menu.has_method("open_for_spot"):
		radial_menu.open_for_spot(spot)

func _on_symbiosis_entered(_tower: Node3D) -> void:
	if hud_tactical:
		hud_tactical.visible = false
	if hud_first_person:
		hud_first_person.visible = true
	if radial_menu:
		radial_menu.visible = false

func _on_symbiosis_exited() -> void:
	if hud_tactical:
		hud_tactical.visible = true
	if hud_first_person:
		hud_first_person.visible = false
