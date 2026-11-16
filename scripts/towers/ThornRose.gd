class_name ThornRose
extends "res://scripts/towers/TowerBase.gd"

## ThornRose: Schnellfeuer-Schütze (Dornen) mit Dornensturm im Symbiose-Modus und Duftwolken-Fähigkeit.

@export var thorn_speed: float = 18.0
var combo_hits: int = 0
var special_cooldown: float = 8.0
var special_timer: float = 0.0

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
	var target_pos := target.global_position
	_spawn_thorn(first_person_mount.global_position, target_pos)
	var hc = target.get_node_or_null("HealthComponent")
	if hc and hc.has_method("take_damage"):
		hc.call("take_damage", attack_damage, self)
	elif target.has_method("take_damage"):
		target.call("take_damage", attack_damage)

func fire_manual(aim_ray: RayCast3D) -> void:
	var target_pos: Vector3
	if aim_ray and aim_ray.is_colliding():
		target_pos = aim_ray.get_collision_point()
		var col := aim_ray.get_collider()
		if col and col.has_method("apply_damage"):
			col.call("apply_damage", attack_damage * 1.25, self)
			combo_hits += 1
	else:
		target_pos = first_person_mount.global_position - first_person_mount.global_transform.basis.z * attack_range
	_spawn_thorn(first_person_mount.global_position, target_pos)

func trigger_special_ability() -> void:
	if special_timer > 0.0:
		return
	special_timer = special_cooldown
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node3D and global_position.distance_to(e.global_position) <= attack_range:
			if e.has_method("apply_slow"):
				e.call("apply_slow", 0.3, 3.5)

func _spawn_thorn(_from_pos: Vector3, _to_pos: Vector3) -> void:
	# Dornen-Projektil Effekt
	pass
