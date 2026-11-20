class_name Butterfly
extends Node3D

## Butterfly: Gemütlich flatternder 2.5D-Aquarell-Bonusschmetterling.
## Erscheint alle 25 Sekunden über dem Beet. Bei Klick: Goldener Funkenregen + 25 Bonus-Tautropfen!

@export var cycle_interval: float = 25.0
@export var flight_duration: float = 14.0
@export var reward_amount: int = 25

@onready var sprite: Sprite3D = $Sprite3D
@onready var click_area: Area3D = $ClickArea
@onready var spark_particles: CPUParticles3D = $SparkParticles

var cycle_timer: float = 3.0 # Erster Auftritt bereits nach 3 Sekunden
var is_flying: bool = false
var flight_timer: float = 0.0
var is_collected: bool = false

# Flugpunkte (von links nach rechts über das Beet)
var start_pos: Vector3 = Vector3(-18.0, 2.6, 2.5)
var end_pos: Vector3 = Vector3(18.0, 3.0, -2.0)
var flight_dir: float = 1.0

func _ready() -> void:
	if click_area:
		click_area.input_ray_pickable = true
		click_area.input_event.connect(_on_click_area_input)
	visible = false

func _process(delta: float) -> void:
	if not is_flying:
		cycle_timer -= delta
		if cycle_timer <= 0.0:
			_start_flight()
		return

	if is_collected:
		return

	flight_timer += delta
	var progress: float = clampf(flight_timer / flight_duration, 0.0, 1.0)

	var t := Time.get_ticks_msec() * 0.001

	# Organische Flugbahn über dem Beet
	var current_base := start_pos.lerp(end_pos, progress)
	current_base.y += sin(progress * PI * 3.0 + t * 2.0) * 0.45 + sin(t * 3.8) * 0.25
	current_base.z += sin(progress * PI * 2.0) * 2.8

	global_position = current_base

	# 2.5D Papier-Flügelschlag (Faltung entlang der vertikalen Achse)
	if sprite:
		var flap: float = absf(sin(t * 16.0)) * 0.75 + 0.25
		sprite.scale.x = flap * flight_dir
		sprite.rotation.z = sin(t * 4.0) * 0.15

	if progress >= 1.0:
		_end_flight()

func _start_flight() -> void:
	is_flying = true
	is_collected = false
	flight_timer = 0.0
	visible = true

	# Wechsle gelegentlich die Flugrichtung
	if randf() > 0.5:
		start_pos = Vector3(-18.0, 2.6, randf_range(0.0, 4.0))
		end_pos = Vector3(18.0, 3.2, randf_range(-3.0, 1.0))
		flight_dir = 1.0
	else:
		start_pos = Vector3(18.0, 3.2, randf_range(-3.0, 1.0))
		end_pos = Vector3(-18.0, 2.6, randf_range(0.0, 4.0))
		flight_dir = -1.0

	global_position = start_pos
	if sprite:
		sprite.scale = Vector3(flight_dir, 1.0, 1.0)
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _end_flight() -> void:
	is_flying = false
	visible = false
	cycle_timer = cycle_interval

func _on_click_area_input(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not is_flying or is_collected:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_collect_bonus()

func _collect_bonus() -> void:
	is_collected = true

	# 1. Goldener Funkenregen
	if spark_particles:
		spark_particles.emitting = true

	# 2. Belohnung vergeben & Tautropfen-Flug zur UI
	GameManager.add_dewdrops(reward_amount)
	GameManager.dewdrop_fly_requested.emit(global_position + Vector3(0.0, 0.4, 0.0), reward_amount)

	# 3. Schwebender +25 Bonus-Text
	_spawn_floating_bonus_text()

	# 4. Elegantes Entflattern nach oben mit Verschwinden
	if sprite:
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "global_position:y", global_position.y + 4.5, 0.6)
		tw.tween_property(sprite, "scale", Vector3.ZERO, 0.5)
		tw.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tw.chain().tween_callback(func():
			_end_flight()
		)
	else:
		_end_flight()

func _spawn_floating_bonus_text() -> void:
	var label := Label3D.new()
	label.text = "+25 💧"
	label.font_size = 48
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.88, 0.35, 1.0)
	label.outline_render_priority = 5
	label.outline_modulate = Color(0.25, 0.16, 0.08, 1.0)
	label.outline_size = 12
	label.no_depth_test = true
	label.render_priority = 6

	get_tree().current_scene.add_child(label)
	label.global_position = global_position + Vector3(0.0, 0.8, 0.0)

	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "global_position:y", label.global_position.y + 1.6, 0.9)
	tw.tween_property(label, "scale", Vector3(1.3, 1.3, 1.3), 0.2)
	tw.chain().tween_property(label, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(label.queue_free)
