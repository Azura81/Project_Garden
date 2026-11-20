class_name CameraRig
extends Node3D

## CameraRig: Verwaltet den festen Diorama-Blickwinkel (-25°), sanften Zoom,
## Spot-Fokus-Punch bei Turmauswahl und 1st-Person-Symbiose.

@export var camera: Camera3D

# Feste Diorama-Ausrichtung (35° diagonaler Winkel wie in ref_perspective_1.jpg)
@export var tactical_position: Vector3 = Vector3(-10.5, 9.6, 16.8)
@export var tactical_rotation_deg: Vector3 = Vector3(-26.0, -34.0, 0.0)

# Taktische Top-Down-Vogelperspektive (wie in ref_topdown.jpg)
@export var topdown_focus_center: Vector3 = Vector3(0.0, 0.0, 0.0)
@export var topdown_rotation_deg: Vector3 = Vector3(-68.0, 0.0, 0.0)
@export var topdown_zoom_dist: float = 21.0

enum PerspectiveMode {
	DIORAMA,
	TOP_DOWN
}
var current_perspective: PerspectiveMode = PerspectiveMode.DIORAMA
var is_switching_perspective: bool = false
var perspective_tween: Tween = null

# Zoom-Einstellungen entlang der Sichtachse
@export var zoom_speed: float = 1.6
@export var min_zoom_dist: float = 12.0
@export var max_zoom_dist: float = 28.0
@export var default_zoom_dist: float = 21.5

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

var current_target_dist: float = 21.5
var current_zoom_dist: float = 21.5
var current_focus_center: Vector3 = Vector3(0.0, 0.0, 0.5)
var default_focus_center: Vector3 = Vector3(0.0, 0.0, 0.5)
var cam_back_dir: Vector3 = Vector3(-0.496, 0.438, 0.750)

var is_focused_on_spot: bool = false
var focused_spot: Area3D = null
var focus_tween: Tween = null

func _ready() -> void:
	if not camera:
		camera = get_node_or_null("Camera3D") as Camera3D

	_update_cam_vectors()
	setup_tactical_view()

	GameManager.symbiosis_entered.connect(_on_symbiosis_entered)
	GameManager.symbiosis_exited.connect(_on_symbiosis_exited)
	GameManager.spot_selected.connect(_on_spot_selected)
	GameManager.spot_deselected.connect(_on_spot_deselected)
	GameManager.camera_perspective_toggle_requested.connect(toggle_perspective)

func _update_cam_vectors() -> void:
	var basis_rot := Basis.from_euler(Vector3(
		deg_to_rad(tactical_rotation_deg.x),
		deg_to_rad(tactical_rotation_deg.y),
		deg_to_rad(tactical_rotation_deg.z)
	))
	cam_back_dir = basis_rot.z.normalized()
	current_target_dist = default_zoom_dist
	current_zoom_dist = default_zoom_dist
	current_focus_center = default_focus_center

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
	if not camera or is_switching_perspective:
		return

	# Dezent schwebendes Atmen (nur im taktischen Gesamtüberblick)
	var sway := Vector3.ZERO
	if ambient_sway_enabled and not is_focused_on_spot:
		var t := Time.get_ticks_msec() * 0.001
		sway.x = sin(t * 0.45) * ambient_sway_amplitude.x
		sway.y = cos(t * 0.65) * ambient_sway_amplitude.y

	if current_perspective == PerspectiveMode.TOP_DOWN:
		var basis_topdown := Basis.from_euler(Vector3(
			deg_to_rad(topdown_rotation_deg.x),
			deg_to_rad(topdown_rotation_deg.y),
			deg_to_rad(topdown_rotation_deg.z)
		))
		var topdown_back := basis_topdown.z.normalized()
		var base_pos: Vector3 = topdown_focus_center + topdown_back * topdown_zoom_dist
		camera.global_position = base_pos + sway
		camera.rotation_degrees = topdown_rotation_deg
	else:
		var base_pos: Vector3 = current_focus_center + cam_back_dir * current_zoom_dist
		camera.global_position = base_pos + sway
		camera.rotation_degrees = tactical_rotation_deg

func toggle_perspective() -> void:
	if is_in_symbiosis:
		return

	if perspective_tween and perspective_tween.is_valid():
		perspective_tween.kill()

	is_switching_perspective = true

	var target_pos: Vector3
	var target_rot: Vector3
	var duration: float = 0.6

	if current_perspective == PerspectiveMode.DIORAMA:
		var basis_topdown := Basis.from_euler(Vector3(
			deg_to_rad(topdown_rotation_deg.x),
			deg_to_rad(topdown_rotation_deg.y),
			deg_to_rad(topdown_rotation_deg.z)
		))
		var topdown_back := basis_topdown.z.normalized()
		target_pos = topdown_focus_center + topdown_back * topdown_zoom_dist
		target_rot = topdown_rotation_deg
		current_perspective = PerspectiveMode.TOP_DOWN
	else:
		target_pos = default_focus_center + cam_back_dir * current_zoom_dist
		target_rot = tactical_rotation_deg
		current_perspective = PerspectiveMode.DIORAMA

	perspective_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	perspective_tween.tween_property(camera, "global_position", target_pos, duration)
	perspective_tween.tween_property(camera, "rotation_degrees", target_rot, duration)
	perspective_tween.chain().tween_callback(func():
		is_switching_perspective = false
	)

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
	var basis_rot := Basis.from_euler(Vector3(
		deg_to_rad(tactical_rotation_deg.x),
		deg_to_rad(tactical_rotation_deg.y),
		deg_to_rad(tactical_rotation_deg.z)
	))
	var cam_right := basis_rot.x.normalized()
	var target_center: Vector3 = spot.global_position - cam_right * 2.8 + Vector3(0.0, spot_frame_offset.y, 0.0)

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
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var dx: float = -mm.relative.x * aim_sensitivity
		var dy: float = -mm.relative.y * aim_sensitivity
		current_yaw += dx
		current_pitch = clampf(current_pitch + dy, deg_to_rad(-max_pitch_deg), deg_to_rad(max_pitch_deg))
		if camera and active_mount:
			camera.rotation.y = current_yaw
			camera.rotation.x = current_pitch
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_shoot_first_person()
	elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		GameManager.exit_symbiosis()

func _shoot_first_person() -> void:
	var tower := GameManager.active_symbiosis_tower
	if not tower or not is_instance_valid(tower) or not camera:
		return
	
	var vp_size := get_viewport().get_visible_rect().size
	var ray_origin := camera.project_ray_origin(vp_size * 0.5)
	var ray_dir := camera.project_ray_normal(vp_size * 0.5)
	
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * 80.0)
	var result := space_state.intersect_ray(query)
	
	var target_point := ray_origin + ray_dir * 35.0
	if not result.is_empty():
		target_point = result["position"]
		
	if tower.has_method("fire_manual_target"):
		tower.call("fire_manual_target", target_point)
	elif tower.has_method("fire_manual"):
		tower.call("fire_manual", null)

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
