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

var active_enemies: int = 0

func _ready() -> void:
	GameManager.reset_level_state()
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.symbiosis_entered.connect(_on_symbiosis_entered)
	GameManager.symbiosis_exited.connect(_on_symbiosis_exited)

	# Pflanzplätze verbinden
	for child in get_tree().get_nodes_in_group("tower_spots"):
		if child.has_signal("spot_clicked"):
			child.connect("spot_clicked", _on_tower_spot_clicked)

func _on_wave_started(wave_idx: int, _total: int) -> void:
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
