class_name DandelionCatapult
extends "res://scripts/towers/TowerBase.gd"

## DandelionCatapult: Pusteblumen-Artillerie.
## Verschießt flauschige Samen-Kugeln in hohem Bogen, die beim Aufprall
## Flächenschaden (22 DMG) anrichten und Schädlinge verlangsamen.

const DandelionSeedProjectileScene = preload("res://scenes/projectiles/DandelionSeedProjectile.tscn")
const DandelionGroundTargetScene = preload("res://scenes/effects/DandelionGroundTarget.tscn")

@export var seed_speed: float = 12.0
@export var splash_radius: float = 2.4
@export var slow_factor: float = 0.6
@export var slow_duration: float = 2.0

var ground_target_instance: Node3D = null
var salvo_count: int = 3
var is_aiming_symbiosis: bool = false
var current_aim_pos: Vector3 = Vector3.ZERO

func _init() -> void:
	plant_name = "Pusteblume"
	cost_level_1 = 70
	cost_level_2 = 90
	cost_level_3 = 160
	cost_symbiosis = 100
	attack_range = 8.5
	attack_damage = 22.0
	attack_cooldown = 1.5

func _ready() -> void:
	super._ready()
	
	# Ground-Target-Marker vorbereiten
	if DandelionGroundTargetScene:
		ground_target_instance = DandelionGroundTargetScene.instantiate()
		ground_target_instance.visible = false
		var root: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
		root.call_deferred("add_child", ground_target_instance)

func _exit_tree() -> void:
	if ground_target_instance and is_instance_valid(ground_target_instance):
		ground_target_instance.queue_free()

func _process(delta: float) -> void:
	super._process(delta)
	
	if is_active_in_symbiosis and ground_target_instance:
		_update_symbiosis_ground_target()

func _update_symbiosis_ground_target() -> void:
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
	
	var vp_size := get_viewport().get_visible_rect().size
	var ray_origin := cam.project_ray_origin(vp_size * 0.5)
	var ray_dir := cam.project_ray_normal(vp_size * 0.5)
	
	# Schnittpunkt mit dem Boden (Y = 0)
	if absf(ray_dir.y) > 0.001:
		var t := -ray_origin.y / ray_dir.y
		if t > 0.0:
			current_aim_pos = ray_origin + ray_dir * t
			ground_target_instance.global_position = current_aim_pos
			ground_target_instance.visible = true
			return
			
	ground_target_instance.visible = false

func fire_at_target(target: Node3D) -> void:
	if not target or not is_instance_valid(target):
		return
	_trigger_shoot_recoil()
	_spawn_seed_arc(first_person_mount.global_position, target.global_position)

func fire_manual_target(p_target_pos: Vector3) -> void:
	_trigger_shoot_recoil()
	# Salve von 3-4 Samen im 1st-Person Modus auf die Zielmarkierung regnen lassen
	var spawn_pos: Vector3 = first_person_mount.global_position
	var aim_spot: Vector3 = current_aim_pos if (ground_target_instance and ground_target_instance.visible) else p_target_pos
	aim_spot.y = 0.0
	for i in range(salvo_count):
		var delay := float(i) * 0.12
		var offset := Vector3(randf_range(-0.6, 0.6), 0.0, randf_range(-0.6, 0.6))
		var target := aim_spot + offset
		if delay > 0.0:
			get_tree().create_timer(delay).timeout.connect(func():
				if is_instance_valid(self):
					_spawn_seed_arc(spawn_pos, target)
			)
		else:
			_spawn_seed_arc(spawn_pos, target)

func fire_manual(aim_ray: RayCast3D) -> void:
	if ground_target_instance and ground_target_instance.visible:
		fire_manual_target(current_aim_pos)
	else:
		var target: Vector3 = global_position - first_person_mount.global_transform.basis.z * attack_range
		target.y = 0.0
		fire_manual_target(target)

func _spawn_seed_arc(from_pos: Vector3, to_pos: Vector3) -> void:
	if not DandelionSeedProjectileScene:
		return
	var proj := DandelionSeedProjectileScene.instantiate() as Node3D
	var parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	parent.add_child(proj)
	if proj.has_method("setup_arc"):
		proj.call("setup_arc", from_pos, to_pos, self, attack_damage)

func _trigger_shoot_recoil() -> void:
	var cutout = get_node_or_null("PaperCutout")
	if cutout and cutout.has_method("trigger_hit_recoil"):
		cutout.call("trigger_hit_recoil")

func trigger_special_ability() -> void:
	# Pusteblumen-Spezialität: Windstoß / Samensturm regnet auf alle Pfadbereiche im Umkreis
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node3D and global_position.distance_to(e.global_position) <= attack_range * 1.3:
			_spawn_seed_arc(first_person_mount.global_position, e.global_position)

func _on_symbiosis_entered(tower: Node3D) -> void:
	super._on_symbiosis_entered(tower)
	if tower == self and ground_target_instance:
		ground_target_instance.visible = true

func _on_symbiosis_exited() -> void:
	super._on_symbiosis_exited()
	if ground_target_instance:
		ground_target_instance.visible = false
