class_name ThornProjectile
extends Node3D

## ThornProjectile: Sichtbarer fliegender Dorn mit Trefferwirkung.

@export var speed: float = 26.0
@export var damage: float = 15.0

var target: Node3D = null
var target_pos: Vector3 = Vector3.ZERO
var has_target: bool = false
var source_tower: Node3D = null
var lifetime: float = 2.5

func setup(p_target: Node3D, p_source: Node3D, p_damage: float) -> void:
	target = p_target
	source_tower = p_source
	damage = p_damage
	if target and is_instance_valid(target):
		target_pos = target.global_position + Vector3(0, 0.3, 0)
		has_target = true
		if not global_position.is_equal_approx(target_pos):
			look_at(target_pos, Vector3.UP)

func setup_direction(p_target_pos: Vector3, p_source: Node3D, p_damage: float) -> void:
	source_tower = p_source
	damage = p_damage
	has_target = false
	target_pos = p_target_pos
	if not global_position.is_equal_approx(target_pos):
		look_at(target_pos, Vector3.UP)

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	if has_target and target and is_instance_valid(target):
		target_pos = target.global_position + Vector3(0, 0.3, 0)
		if not global_position.is_equal_approx(target_pos):
			look_at(target_pos, Vector3.UP)

	var move_step: float = speed * delta
	var dist: float = global_position.distance_to(target_pos)

	if dist <= move_step or dist < 0.35:
		_on_hit()
		return

	global_position = global_position.move_toward(target_pos, move_step)

func _on_hit() -> void:
	if has_target and target and is_instance_valid(target):
		var hc: Node = target.get_node_or_null("HealthComponent")
		if hc and hc.has_method("take_damage"):
			hc.call("take_damage", damage, source_tower)
		elif target.has_method("take_damage"):
			target.call("take_damage", damage)
	queue_free()
