class_name CameraRig
extends Node3D

## CameraRig: Verwaltet den festen Diorama-Blickwinkel (-25°), sanften Zoom,
## Spot-Fokus-Punch bei Turmauswahl und 1st-Person-Symbiose.

@export var camera: Camera3D

# Feste Diorama-Ausrichtung
@export var tactical_position: Vector3 = Vector3(0, 9.2, 16.5)
@export var tactical_rotation_deg: Vector3 = Vector3(-25, 0, 0)

# Zoom-Einstellungen entlang der Sichtachse
@export var zoom_speed: float = 1.6
@export var min_zoom_dist: float = 13.0
@export var max_zoom_dist: float = 27.0
@export var default_zoom_dist: float = 21.77

# Fokus-Punch bei Turmauswahl
@export var focus_distance: float = 11.2
@export var focus_transition_duration: float = 0.38
@export var spot_frame_offset: Vector3 = Vector3(1.2, 0.35, 0.0)

# Sanftes atmosphärisches Schweben (Ambient Sway)
@export var ambient_sway_enabled: bool = true
@export var ambient_sway_amplitude: Vector2 = Vector2(0.06, 0.03)

# Symbiose-Einstellungen
@export var symbiosis_transition_duration: float = 0.4
@export var slow_mo_duration: float = 1.0
@export var slow_mo_scale: float = 0.5

# Aim-Assist & 1st-Person Steuerung
@export var aim_sensitivity: float = 0.003
@export var max_pitch_deg: float = 45.0

var is_in_symbiosis: bool = false
var active_mount: Marker3D = null
var current_pitch: float = 0.0
var current_yaw: float = 0.0

var current_target_dist: float = 21.77
var current_zoom_dist: float = 21.77
var current_focus_center: Vector3 = Vector3(0, 0, -3.23)
var default_focus_center: Vector3 = Vector3(0, 0, -3.23)
var cam_back_dir: Vector3 = Vector3(0, 0.422618, 0.906308)

var is_focused_on_spot: bool = false
var focused_spot: Area3D = null
var focus_tween: Tween = null

func _ready() -> void:
	if not camera:
		camera = get_node_or_null("Camera3D") as Camera3D

	# Exakte Richtungsachse basierend auf Neigungswinkel berechnen
	var pitch_rad: float = deg_to_rad(absf(tactical_rotation_deg.x))
	cam_back_dir = Vector3(0.0, sin(pitch_rad), cos(pitch_rad)).normalized()
	
	# Standard-Fokuspunkt auf dem Boden berechnen
	if cam_back_dir.y > 0.001:
		default_zoom_dist = tactical_position.y / cam_back_dir.y
		var z_ground: float = tactical_position.z - cam_back_dir.z * default_zoom_dist
		default_focus_center = Vector3(tactical_position.x, 0.0, z_ground)
	
	current_target_dist = default_zoom_dist
	current_zoom_dist = default_zoom_dist
	current_focus_center = default_focus_center

	setup_tactical_view()

	GameManager.symbiosis_entered.connect(_on_symbiosis_entered)
	GameManager.symbiosis_exited.connect(_on_symbiosis_exited)
	GameManager.spot_selected.connect(_on_spot_selected)
	GameManager.spot_deselected.connect(_on_spot_deselected)

func setup_tactical_view() -> void:
	is_in_symbiosis = false
	active_mount = null
	is_focused_on_spot = false
	focused_spot = null
	current_focus_center = default_focus_center
	current_target_dist = default_zoom_dist
	current_zoom_dist = default_zoom_dist

	if camera:
		camera.global_position = default_focus_center + cam_back_dir * default_zoom_dist
		camera.rotation_degrees = tactical_rotation_deg

func _process(delta: float) -> void:
	if is_in_symbiosis:
		return

	# Weiches Heran-/Herausgleiten beim Zoomen
	if not (focus_tween and focus_tween.is_valid() and focus_tween.is_running()):
		current_zoom_dist = lerpf(current_zoom_dist, current_target_dist, delta * 8.0)
		_apply_camera_transform()

func _apply_camera_transform() -> void:
	if not camera:
		return

	var base_pos: Vector3 = current_focus_center + cam_back_dir * current_zoom_dist

	# Dezent schwebendes Atmen (nur im taktischen Gesamtüberblick)
	var sway := Vector3.ZERO
	if ambient_sway_enabled and not is_focused_on_spot:
		var t := Time.get_ticks_msec() * 0.001
		sway.x = sin(t * 0.45) * ambient_sway_amplitude.x
		sway.y = cos(t * 0.65) * ambient_sway_amplitude.y

	camera.global_position = base_pos + sway
	camera.rotation_degrees = tactical_rotation_deg

func _unhandled_input(event: InputEvent) -> void:
	if is_in_symbiosis:
		_handle_first_person_input(event)
	else:
		_handle_tactical_input(event)

func _handle_tactical_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom(-zoom_speed)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom(zoom_speed)

func _zoom(amount: float) -> void:
	current_target_dist = clampf(current_target_dist + amount, min_zoom_dist, max_zoom_dist)

func _on_spot_selected(spot: Area3D) -> void:
	if is_in_symbiosis or not spot:
		return

	is_focused_on_spot = true
	focused_spot = spot

	# Intelligenter Versatz: Platziert die Blume elegant mit komfortablem Abstand neben dem Radial-Menü
	var side_offset_x: float = 5.0 if spot.global_position.x <= 0.0 else -5.0
	var target_center: Vector3 = spot.global_position + Vector3(side_offset_x, spot_frame_offset.y, spot_frame_offset.z)

	if focus_tween and focus_tween.is_valid():
		focus_tween.kill()

	focus_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	focus_tween.tween_property(self, "current_focus_center", target_center, focus_transition_duration)
	focus_tween.tween_property(self, "current_zoom_dist", focus_distance, focus_transition_duration)
	focus_tween.tween_method(func(_v: float): _apply_camera_transform(), 0.0, 1.0, focus_transition_duration)

func _on_spot_deselected() -> void:
	if is_in_symbiosis:
		return

	is_focused_on_spot = false
	focused_spot = null

	if focus_tween and focus_tween.is_valid():
		focus_tween.kill()

	focus_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	focus_tween.tween_property(self, "current_focus_center", default_focus_center, focus_transition_duration)
	focus_tween.tween_property(self, "current_zoom_dist", current_target_dist, focus_transition_duration)
	focus_tween.tween_method(func(_v: float): _apply_camera_transform(), 0.0, 1.0, focus_transition_duration)

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

func _on_symbiosis_entered(tower: Node3D) -> void:
	if not tower:
		return
	var mount := tower.get_node_or_null("FirstPersonMount") as Marker3D
	if not mount:
		return

	if focus_tween and focus_tween.is_valid():
		focus_tween.kill()

	is_focused_on_spot = false
	focused_spot = null
	is_in_symbiosis = true
	active_mount = mount
	current_pitch = 0.0
	current_yaw = mount.global_rotation.y

	# Weicher Tween in die Blüte
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "global_position", mount.global_position, symbiosis_transition_duration)
	tween.tween_property(camera, "global_rotation", mount.global_rotation, symbiosis_transition_duration)

	# Sanfte Zeitlupe zur Orientierung
	Engine.time_scale = slow_mo_scale
	get_tree().create_timer(slow_mo_duration * slow_mo_scale).timeout.connect(func():
		if is_in_symbiosis:
			Engine.time_scale = GameManager.game_speed
	)

func _on_symbiosis_exited() -> void:
	is_in_symbiosis = false
	active_mount = null
	Engine.time_scale = GameManager.game_speed

	current_focus_center = default_focus_center
	var return_pos: Vector3 = default_focus_center + cam_back_dir * current_target_dist

	# Weicher Rückflug zur taktischen Ansicht
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "global_position", return_pos, symbiosis_transition_duration)
	tween.tween_property(camera, "rotation_degrees", tactical_rotation_deg, symbiosis_transition_duration)
	tween.tween_callback(func():
		current_zoom_dist = current_target_dist
	)
