class_name ThornProjectile
extends Node3D

## ThornProjectile: Sichtbarer fliegender Dorn mit Trefferwirkung im automatischen & manuellen Modus.

@export var speed: float = 28.0
@export var damage: float = 15.0

var target: Node3D = null
var target_pos: Vector3 = Vector3.ZERO
var has_target: bool = false
var flight_direction: Vector3 = Vector3.FORWARD
var is_directional: bool = false
var source_tower: Node3D = null
var lifetime: float = 3.0

func setup(p_target: Node3D, p_source: Node3D, p_damage: float) -> void:
	target = p_target
	source_tower = p_source
	damage = p_damage
	has_target = true
	is_directional = false
	if target and is_instance_valid(target):
		target_pos = target.global_position + Vector3(0, 0.3, 0)
		if not global_position.is_equal_approx(target_pos):
			look_at(target_pos, Vector3.UP)

func setup_direction(p_target_pos: Vector3, p_source: Node3D, p_damage: float) -> void:
	source_tower = p_source
	damage = p_damage
	has_target = false
	is_directional = true
	target_pos = p_target_pos
	flight_direction = (p_target_pos - global_position).normalized()
	if not global_position.is_equal_approx(global_position + flight_direction):
		look_at(global_position + flight_direction, Vector3.UP)

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	if is_directional:
		var step := flight_direction * speed * delta
		global_position += step
		
		# Trefferabfrage auf alle Gegner im Flug
		var enemies := get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if e is Node3D and is_instance_valid(e):
				if global_position.distance_to(e.global_position + Vector3(0, 0.35, 0)) <= 0.85:
					_damage_target(e)
					queue_free()
					return
		if global_position.y < 0.05:
			_spawn_hit_spark(global_position)
			queue_free()
			return
	else:
		if has_target and target and is_instance_valid(target):
			target_pos = target.global_position + Vector3(0, 0.3, 0)
			if not global_position.is_equal_approx(target_pos):
				look_at(target_pos, Vector3.UP)

		var move_step: float = speed * delta
		var dist: float = global_position.distance_to(target_pos)

		if dist <= move_step or dist < 0.45:
			if target and is_instance_valid(target):
				_damage_target(target)
			queue_free()
			return

		global_position = global_position.move_toward(target_pos, move_step)

func _damage_target(tgt: Node) -> void:
	_spawn_hit_spark(global_position)
	var hc: Node = tgt.get_node_or_null("HealthComponent")
	if hc and hc.has_method("take_damage"):
		hc.call("take_damage", damage, source_tower)
	elif tgt.has_method("take_damage"):
		tgt.call("take_damage", damage)

func _spawn_hit_spark(pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 8
	p.lifetime = 0.35
	p.direction = Vector3(0, 1, 0)
	p.spread = 70.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	p.gravity = Vector3(0, -6, 0)
	var mesh := SphereMesh.new()
	mesh.radius = 0.04
	mesh.height = 0.08
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.25, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.3)
	mesh.material = mat
	p.mesh = mesh
	var parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(0.4).timeout.connect(p.queue_free)
