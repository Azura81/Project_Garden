class_name DandelionSeedProjectile
extends Node3D

## DandelionSeedProjectile: Flauschige Pusteblumen-Samenkugel.
## Fliegt in hoher Parabel-Kurve zum Ziel und erzeugt bei Aufprall
## Flächenschaden (22 DMG) und 40% Verlangsamung für 2 Sekunden.

@export var speed: float = 12.0
@export var damage: float = 22.0
@export var splash_radius: float = 2.4
@export var slow_factor: float = 0.6  # 40% Verlangsamung (Geschwindigkeit = 60%)
@export var slow_duration: float = 2.0
@export var arc_height: float = 2.8

var start_pos: Vector3 = Vector3.ZERO
var target_pos: Vector3 = Vector3.ZERO
var progress_t: float = 0.0
var flight_duration: float = 1.0
var source_tower: Node3D = null

func setup_arc(p_start: Vector3, p_target: Vector3, p_source: Node3D, p_damage: float) -> void:
	start_pos = p_start
	target_pos = p_target
	source_tower = p_source
	damage = p_damage
	global_position = p_start
	var dist := p_start.distance_to(p_target)
	flight_duration = clampf(dist / speed, 0.45, 1.6)
	progress_t = 0.0

func _process(delta: float) -> void:
	progress_t += delta / maxf(flight_duration, 0.01)
	
	if progress_t >= 1.0:
		global_position = target_pos
		_explode()
		return

	# Parabolische Flugbahn (Interpolation + Sinus-Bogen)
	var base_pos := start_pos.lerp(target_pos, progress_t)
	var arc_y := sin(progress_t * PI) * arc_height
	global_position = base_pos + Vector3(0, arc_y, 0)
	
	# Sanfte Rotation der Samenkugel
	rotation.y += delta * 4.0
	rotation.z = sin(progress_t * TAU) * 0.2

func _explode() -> void:
	_spawn_seed_burst(global_position)
	
	# Flächenschaden & Verlangsamung auf alle Gegner im Umkreis
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node3D and is_instance_valid(e):
			var dist := global_position.distance_to(e.global_position)
			if dist <= splash_radius:
				# Schaden
				var hc: Node = e.get_node_or_null("HealthComponent")
				if hc and hc.has_method("take_damage"):
					hc.call("take_damage", damage, source_tower)
				elif e.has_method("take_damage"):
					e.call("take_damage", damage)
				
				# 40% Verlangsamung für 2s
				if e.has_method("apply_slow"):
					e.call("apply_slow", slow_factor, slow_duration)

	queue_free()

func _spawn_seed_burst(pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 24
	p.lifetime = 0.8
	p.direction = Vector3(0, 1, 0)
	p.spread = 80.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.5
	p.gravity = Vector3(0, -3.5, 0)

	var mesh := SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.96, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.9
	mesh.material = mat
	p.mesh = mesh

	var parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	parent.add_child(p)
	p.global_position = pos + Vector3(0, 0.1, 0)
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)
