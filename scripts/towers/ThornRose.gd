class_name ThornRose
extends "res://scripts/towers/TowerBase.gd"

## ThornRose: Schnellfeuer-Schütze mit natürlichen Farbverläufen & 5 zufälligen Blütenfarben.

const ThornProjectileScene = preload("res://scenes/projectiles/ThornProjectile.tscn")
const SfxShoot = preload("res://assets/audio/thorn_shoot.wav")

const COLOR_PALETTES = [
	# 1. Rot (Referenz Bild 1: Tiefes Weinrot bis zartes Rosé)
	{
		"name": "Rot",
		"base": Color(0.82, 0.16, 0.32, 1.0),
		"grad": Color(0.98, 0.44, 0.62, 1.0),
		"shadow": Color(0.45, 0.08, 0.18, 1.0),
		"rim": Color(1.0, 0.65, 0.78, 1.0),
		"outline": Color(0.26, 0.04, 0.1, 1.0)
	},
	# 2. Gelb (Warmes Goldgelb bis sonniges Zitronengelb)
	{
		"name": "Gelb",
		"base": Color(0.94, 0.72, 0.12, 1.0),
		"grad": Color(1.0, 0.92, 0.42, 1.0),
		"shadow": Color(0.62, 0.42, 0.06, 1.0),
		"rim": Color(1.0, 0.96, 0.68, 1.0),
		"outline": Color(0.32, 0.2, 0.03, 1.0)
	},
	# 3. Violett (Tiefes Purpur bis zartes Lavendel)
	{
		"name": "Violett",
		"base": Color(0.64, 0.2, 0.76, 1.0),
		"grad": Color(0.86, 0.5, 0.96, 1.0),
		"shadow": Color(0.36, 0.08, 0.44, 1.0),
		"rim": Color(0.94, 0.72, 1.0, 1.0),
		"outline": Color(0.2, 0.05, 0.26, 1.0)
	},
	# 4. Blau (Mystisches Saphirblau bis sanftes Kornblumenblau)
	{
		"name": "Blau",
		"base": Color(0.18, 0.44, 0.86, 1.0),
		"grad": Color(0.45, 0.74, 1.0, 1.0),
		"shadow": Color(0.08, 0.22, 0.52, 1.0),
		"rim": Color(0.68, 0.88, 1.0, 1.0),
		"outline": Color(0.05, 0.12, 0.3, 1.0)
	},
	# 5. Orange (Sonniges Korallenrot bis zarter Pfirsich)
	{
		"name": "Orange",
		"base": Color(0.92, 0.38, 0.12, 1.0),
		"grad": Color(1.0, 0.68, 0.34, 1.0),
		"shadow": Color(0.58, 0.2, 0.05, 1.0),
		"rim": Color(1.0, 0.82, 0.58, 1.0),
		"outline": Color(0.32, 0.1, 0.02, 1.0)
	}
]

@export var thorn_speed: float = 26.0
var combo_hits: int = 0
var special_cooldown: float = 8.0
var special_timer: float = 0.0
var color_name: String = "Rot"

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

func _ready() -> void:
	super._ready()
	_apply_random_color_theme()

func _apply_random_color_theme() -> void:
	var theme: Dictionary = COLOR_PALETTES.pick_random()
	color_name = theme["name"]
	
	var cutout = get_node_or_null("PaperCutout")
	if cutout:
		cutout.modulate = Color.WHITE
	
	var mesh_node: MeshInstance3D = get_node_or_null("FacetedRoseMesh")
	if not mesh_node:
		return
	
	# Petal Material (Surface 2)
	var mat_orig := mesh_node.get_surface_override_material(2)
	if mat_orig and mat_orig is ShaderMaterial:
		var mat_dup: ShaderMaterial = mat_orig.duplicate(true)
		mat_dup.set_shader_parameter("base_color", theme["base"])
		mat_dup.set_shader_parameter("gradient_color", theme["grad"])
		mat_dup.set_shader_parameter("shadow_color", theme["shadow"])
		mat_dup.set_shader_parameter("rim_color", theme["rim"])
		
		# Outline anpassen
		if mat_dup.next_pass and mat_dup.next_pass is ShaderMaterial:
			var outl_dup: ShaderMaterial = mat_dup.next_pass.duplicate(true)
			outl_dup.set_shader_parameter("outline_color", theme["outline"])
			mat_dup.next_pass = outl_dup
		
		mesh_node.set_surface_override_material(2, mat_dup)

func _process(delta: float) -> void:
	super._process(delta)
	if special_timer > 0.0:
		special_timer -= delta

func fire_at_target(target: Node3D) -> void:
	if not target or not is_instance_valid(target):
		return
	_play_shoot_sound()
	_spawn_thorn_at_target(target)

func fire_manual_target(p_target_pos: Vector3) -> void:
	_play_shoot_sound()
	var spawn_pos: Vector3 = first_person_mount.global_position
	_spawn_thorn_direction(spawn_pos, p_target_pos)

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
	_trigger_shoot_recoil()
	var proj := ThornProjectileScene.instantiate() as Node3D
	var target_parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	target_parent.add_child(proj)
	proj.global_position = first_person_mount.global_position
	if proj.has_method("setup"):
		proj.call("setup", target, self, attack_damage)

func _spawn_thorn_direction(from_pos: Vector3, to_pos: Vector3) -> void:
	if not ThornProjectileScene:
		return
	_trigger_shoot_recoil()
	var proj := ThornProjectileScene.instantiate() as Node3D
	var target_parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	target_parent.add_child(proj)
	proj.global_position = from_pos
	if proj.has_method("setup_direction"):
		proj.call("setup_direction", to_pos, self, attack_damage * 1.25)

func _trigger_shoot_recoil() -> void:
	var cutout = get_node_or_null("PaperCutout")
	if cutout and cutout.has_method("trigger_hit_recoil"):
		cutout.call("trigger_hit_recoil")
		
	var mesh_node: Node3D = get_node_or_null("FacetedRoseMesh")
	if not mesh_node:
		return
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(mesh_node, "scale", Vector3(1.16, 0.82, 1.16), 0.06)
	tw.tween_property(mesh_node, "scale", Vector3.ONE, 0.24)

func trigger_special_ability() -> void:
	if special_timer > 0.0:
		return
	special_timer = special_cooldown
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node3D and global_position.distance_to(e.global_position) <= attack_range:
			if e.has_method("apply_slow"):
				e.call("apply_slow", 0.3, 3.5)
