class_name EnemyBase
extends PathFollow3D

## EnemyBase: Basisklasse für Schädlinge auf Path3D mit Hit-Flash, Slime-Partikeln & Defeat-Puff.

const SfxDefeat = preload("res://assets/audio/snail_defeat.wav")

signal defeated(dewdrops_reward: int)
signal reached_core(damage: int)

@export var enemy_name: String = "Schädling"
@export var speed: float = 2.0
@export var base_dewdrops: int = 10
@export var core_damage: int = 10

var current_speed: float = 2.0
var slow_timer: float = 0.0
var is_dying: bool = false

@onready var health_component: Node = $HealthComponent

var _flashable_materials: Array[ShaderMaterial] = []

func _ready() -> void:
	add_to_group("enemies")
	loop = false
	current_speed = speed

	_setup_materials()

	if health_component:
		if health_component.has_signal("damaged"):
			health_component.connect("damaged", _on_damaged)
		if health_component.has_signal("died"):
			health_component.connect("died", _on_died)

func _setup_materials() -> void:
	_flashable_materials.clear()
	for child in find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		# Material im Mesh oder Surface-Override prüfen
		var mat := mi.get_surface_override_material(0)
		if not mat and mi.mesh and mi.mesh.material:
			mat = mi.mesh.material
		
		if mat and mat is ShaderMaterial:
			var dup: ShaderMaterial = mat.duplicate(true)
			mi.set_surface_override_material(0, dup)
			_flashable_materials.append(dup)

func _process(delta: float) -> void:
	if is_dying:
		return

	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			current_speed = speed

	progress += current_speed * delta

	if progress_ratio >= 1.0:
		_reach_core()

func apply_slow(speed_factor: float, duration: float) -> void:
	current_speed = speed * speed_factor
	slow_timer = duration

func _reach_core() -> void:
	GameManager.damage_core(core_damage)
	reached_core.emit(core_damage)
	queue_free()

func _on_damaged(_amount: float, _source: Node) -> void:
	if is_dying:
		return
	
	# 1. Weißer / Heller Hit-Flash
	for mat in _flashable_materials:
		mat.set_shader_parameter("hit_flash", 1.0)
	
	var tw_flash := create_tween()
	tw_flash.tween_method(func(val: float):
		for mat in _flashable_materials:
			mat.set_shader_parameter("hit_flash", val)
	, 1.0, 0.0, 0.09)

	# 2. Schleimspritzer auf dem Boden
	_spawn_slime_splash(global_position)

	# 3. Kleiner Squash-Effekt
	var tw_squash := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_squash.tween_property(self, "scale", Vector3(1.15, 0.85, 1.15), 0.05)
	tw_squash.tween_property(self, "scale", Vector3.ONE, 0.16)

func _spawn_slime_splash(pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 10
	p.lifetime = 0.4
	p.direction = Vector3(0.0, 1.0, 0.0)
	p.spread = 75.0
	p.initial_velocity_min = 2.2
	p.initial_velocity_max = 4.2
	p.gravity = Vector3(0.0, -12.0, 0.0)

	var mesh := SphereMesh.new()
	mesh.radius = 0.04
	mesh.height = 0.08
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.92, 0.25, 0.9)
	mat.roughness = 0.25
	mesh.material = mat
	p.mesh = mesh

	get_tree().current_scene.add_child(p)
	p.global_position = pos + Vector3(0.0, 0.2, 0.0)
	p.emitting = true
	get_tree().create_timer(0.5).timeout.connect(p.queue_free)

func _on_died() -> void:
	if is_dying:
		return
	is_dying = true

	_play_defeat_sound()
	_spawn_defeat_puff(global_position)

	var reward := base_dewdrops
	if GameManager.active_symbiosis_tower:
		reward = int(base_dewdrops * 1.25) + 1
	GameManager.add_dewdrops(reward)
	defeated.emit(reward)

	# Niedlicher Pop-Shrink vor dem Löschen
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector3.ZERO, 0.2)
	tw.tween_callback(queue_free)

func _spawn_defeat_puff(pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 16
	p.lifetime = 0.65
	p.direction = Vector3(0.0, 1.0, 0.0)
	p.spread = 180.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	p.gravity = Vector3(0.0, -3.0, 0.0)

	var mesh := SphereMesh.new()
	mesh.radius = 0.1
	mesh.height = 0.2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.96, 0.88, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.85
	mesh.material = mat
	p.mesh = mesh

	get_tree().current_scene.add_child(p)
	p.global_position = pos + Vector3(0.0, 0.25, 0.0)
	p.emitting = true
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)

func _play_defeat_sound() -> void:
	if SfxDefeat:
		var p := AudioStreamPlayer3D.new()
		p.stream = SfxDefeat
		p.pitch_scale = randf_range(0.92, 1.12)
		p.volume_db = 2.0
		p.unit_size = 15.0
		get_tree().current_scene.add_child(p)
		p.global_position = global_position
		p.play()
		p.finished.connect(p.queue_free)
