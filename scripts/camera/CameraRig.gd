class_name CameraRig
extends Node3D

## CameraRig: Steuer- und Übergangssystem zwischen taktischer Vogelperspektive und 1st-Person-Symbiose.

@export var camera: Camera3D

# Taktische Kamera-Einstellungen
@export var tactical_position: Vector3 = Vector3(0, 10, 10)
@export var tactical_rotation_deg: Vector3 = Vector3(-45, 0, 0)
@export var pan_speed: float = 0.02
@export var zoom_speed: float = 0.5
@export var min_zoom: float = 5.0
@export var max_zoom: float = 16.0

# Symbiose-Einstellungen
@export var transition_duration: float = 0.4
@export var slow_mo_duration: float = 1.0
@export var slow_mo_scale: float = 0.5

# Aim-Assist & 1st-Person Steuerung
@export var aim_sensitivity: float = 0.003
@export var max_pitch_deg: float = 45.0

var is_in_symbiosis: bool = false
var active_mount: Marker3D = null
var current_pitch: float = 0.0
var current_yaw: float = 0.0
var is_dragging: bool = false
var last_touch_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	if not camera:
		camera = get_node_or_null("Camera3D") as Camera3D
	setup_tactical_view()
	GameManager.symbiosis_entered.connect(_on_symbiosis_entered)
	GameManager.symbiosis_exited.connect(_on_symbiosis_exited)

func setup_tactical_view() -> void:
	is_in_symbiosis = false
	active_mount = null
	if camera:
		camera.global_position = tactical_position
		camera.rotation_degrees = tactical_rotation_deg

func _unhandled_input(event: InputEvent) -> void:
	if is_in_symbiosis:
		_handle_first_person_input(event)
	else:
		_handle_tactical_input(event)

func _handle_tactical_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = mb.pressed
			last_touch_pos = mb.position
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(-zoom_speed)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(zoom_speed)
	elif event is InputEventMouseMotion and is_dragging:
		var mm := event as InputEventMouseMotion
		var delta: Vector2 = mm.position - last_touch_pos
		last_touch_pos = mm.position
		_pan(delta)

func _handle_first_person_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
		var mm := event as InputEventMouseMotion
		var dx: float = -mm.relative.x * aim_sensitivity
		var dy: float = -mm.relative.y * aim_sensitivity
		current_yaw += dx
		current_pitch = clampf(current_pitch + dy, deg_to_rad(-max_pitch_deg), deg_to_rad(max_pitch_deg))
		if camera and active_mount:
			camera.rotation.y = current_yaw
			camera.rotation.x = current_pitch

func _pan(delta: Vector2) -> void:
	var move_vec := Vector3(-delta.x * pan_speed, 0, -delta.y * pan_speed)
	global_position += move_vec
	# Begrenzung auf Beet-Bereich
	global_position.x = clampf(global_position.x, -15.0, 15.0)
	global_position.z = clampf(global_position.z, -15.0, 15.0)

func _zoom(amount: float) -> void:
	if camera:
		var new_y: float = clampf(camera.position.y + amount, min_zoom, max_zoom)
		var new_z: float = clampf(camera.position.z + amount, min_zoom, max_zoom)
		camera.position.y = new_y
		camera.position.z = new_z

func _on_symbiosis_entered(tower: Node3D) -> void:
	if not tower:
		return
	var mount := tower.get_node_or_null("FirstPersonMount") as Marker3D
	if not mount:
		return

	is_in_symbiosis = true
	active_mount = mount
	current_pitch = 0.0
	current_yaw = mount.global_rotation.y

	# Weicher 0.4s Tween in die Blüte
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "global_position", mount.global_position, transition_duration)
	tween.tween_property(camera, "global_rotation", mount.global_rotation, transition_duration)

	# 1 Sekunde sanfte Zeitlupe zur Orientierung
	Engine.time_scale = slow_mo_scale
	get_tree().create_timer(slow_mo_duration * slow_mo_scale).timeout.connect(func():
		if is_in_symbiosis:
			Engine.time_scale = GameManager.game_speed
	)

func _on_symbiosis_exited() -> void:
	is_in_symbiosis = false
	active_mount = null
	Engine.time_scale = GameManager.game_speed

	# Rückflug zur Vogelperspektive
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "global_position", tactical_position + global_position, transition_duration)
	tween.tween_property(camera, "rotation_degrees", tactical_rotation_deg, transition_duration)
