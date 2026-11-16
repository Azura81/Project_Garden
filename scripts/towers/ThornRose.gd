class_name ThornRose
extends "res://scripts/towers/TowerBase.gd"

## ThornRose: Schnellfeuer-Schütze (Dornen) mit Dornensturm im Symbiose-Modus und Duftwolken-Fähigkeit.

const ThornProjectileScene = preload("res://scenes/projectiles/ThornProjectile.tscn")
const SfxShoot = preload("res://assets/audio/thorn_shoot.wav")

@export var thorn_speed: float = 26.0
var combo_hits: int = 0
var special_cooldown: float = 8.0
var special_timer: float = 0.0

@onready var audio_shoot: AudioStreamPlayer3D = $AudioShoot

func _init() -> void:
	plant_name = "Dornen-Rose"
	cost_level_1 = 50
	cost_level_2 = 75
	cost_level_3 = 140
	cost_symbiosis = 100
	attack_range = 7.0
	attack_damage = 15.0
	attack_cooldown = 0.65

func _process(delta: float) -> void:
	super._process(delta)
	if special_timer > 0.0:
		special_timer -= delta

func fire_at_target(target: Node3D) -> void:
	if not target or not is_instance_valid(target):
		return
	_play_shoot_sound()
	_spawn_thorn_at_target(target)

func fire_manual(aim_ray: RayCast3D) -> void:
	_play_shoot_sound()
	var spawn_pos: Vector3 = first_person_mount.global_position
	var target_pos: Vector3
	if aim_ray and aim_ray.is_colliding():
		target_pos = aim_ray.get_collision_point()
	else:
		target_pos = spawn_pos - first_person_mount.global_transform.basis.z * attack_range
	_spawn_thorn_direction(spawn_pos, target_pos)

func _play_shoot_sound() -> void:
	if audio_shoot:
		audio_shoot.pitch_scale = randf_range(0.95, 1.1)
		audio_shoot.play()

func _spawn_thorn_at_target(target: Node3D) -> void:
	if not ThornProjectileScene:
		return
	var proj := ThornProjectileScene.instantiate() as Node3D
	get_tree().current_scene.add_child(proj)
	proj.global_position = first_person_mount.global_position
	if proj.has_method("setup"):
		proj.call("setup", target, self, attack_damage)

func _spawn_thorn_direction(from_pos: Vector3, to_pos: Vector3) -> void:
	if not ThornProjectileScene:
		return
	var proj := ThornProjectileScene.instantiate() as Node3D
	get_tree().current_scene.add_child(proj)
	proj.global_position = from_pos
	if proj.has_method("setup_direction"):
		proj.call("setup_direction", to_pos, self, attack_damage * 1.25)

func trigger_special_ability() -> void:
	if special_timer > 0.0:
		return
	special_timer = special_cooldown
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node3D and global_position.distance_to(e.global_position) <= attack_range:
			if e.has_method("apply_slow"):
				e.call("apply_slow", 0.3, 3.5)
