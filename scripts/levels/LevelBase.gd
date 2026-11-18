class_name LevelBase
extends Node3D

## LevelBase: Verwaltet Beet, Pfad (Path3D), Pflanzplätze, Wellen und Spawning.

@export var level_number: int = 1
@export var enemy_snail_scene: PackedScene
@export var enemy_beetle_scene: PackedScene
@export var rose_tower_scene: PackedScene
@export var dandelion_tower_scene: PackedScene

@onready var path3d: Path3D = $Path3D
@onready var radial_menu: Control = $UI/RadialMenu
@onready var hud_tactical: Control = $UI/HUD_Tactical
@onready var hud_first_person: Control = $UI/HUD_FirstPerson
@onready var start_arrow: Node3D = get_node_or_null("PathStartArrow")
@onready var range_indicator: RangeIndicator = get_node_or_null("RangeIndicator")

var active_enemies: int = 0
var current_spawn_wave: int = 0

func _ready() -> void:
	GameManager.reset_level_state()
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_completed.connect(_on_wave_completed)
	GameManager.game_over.connect(_on_game_over)
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
	current_spawn_wave = wave_idx
	_trigger_entrance_warning()
	
	# Richtungspfeil verschwindet bei Start der ersten Runde
	if start_arrow and is_instance_valid(start_arrow):
		var tw := create_tween()
		tw.tween_property(start_arrow, "scale", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(start_arrow.queue_free)

	var spawn_queue: Array[String] = []
	match wave_idx:
		1:
			# Welle 1: 4x Gartenschnecke (ruhiger Einstieg)
			spawn_queue = ["snail", "snail", "snail", "snail"]
		2:
			# Welle 2: 4x Gartenschnecke + 2x Schmuckkäfer
			spawn_queue = ["snail", "snail", "beetle", "snail", "snail", "beetle"]
		3:
			# Welle 3: 5x Schmuckkäfer (schnelle Welle)
			spawn_queue = ["beetle", "beetle", "beetle", "beetle", "beetle"]
		4:
			# Welle 4: 6x Gartenschnecke + 4x Schmuckkäfer (Finale von Level 1)
			spawn_queue = ["snail", "snail", "beetle", "snail", "beetle", "snail", "snail", "beetle", "snail", "beetle"]
		_:
			for i in range(4 + wave_idx * 2):
				spawn_queue.append("snail" if randf() > 0.4 else "beetle")

	active_enemies = spawn_queue.size()
	for enemy_type in spawn_queue:
		await get_tree().create_timer(1.2).timeout
		if not is_instance_valid(self):
			return
		_spawn_enemy(enemy_type)

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

func _spawn_enemy(type: String) -> void:
	if not path3d:
		return
	
	var scene_to_spawn: PackedScene = enemy_snail_scene
	if type == "beetle" and enemy_beetle_scene:
		scene_to_spawn = enemy_beetle_scene
	elif not enemy_snail_scene:
		return

	var enemy := scene_to_spawn.instantiate() as PathFollow3D
	if enemy.has_signal("defeated"):
		enemy.connect("defeated", func(_r): _on_enemy_removed())
	if enemy.has_signal("reached_core"):
		enemy.connect("reached_core", func(_d): _on_enemy_removed())
	path3d.add_child(enemy)

func _on_enemy_removed() -> void:
	active_enemies = max(active_enemies - 1, 0)
	if active_enemies == 0 and GameManager.is_wave_active:
		GameManager.complete_wave()

func _on_wave_completed(wave_idx: int) -> void:
	if wave_idx >= 4:
		_trigger_golden_growth()

func _on_game_over(victory: bool) -> void:
	if victory:
		_trigger_golden_growth()

func _trigger_golden_growth() -> void:
	var sprout: Node = find_child("GoldenSprout", true, false)
	if sprout and sprout.has_method("celebrate_growth"):
		sprout.call("celebrate_growth")

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
