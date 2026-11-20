class_name HUDTactical
extends Control

## HUDTactical: Benutzeroberfläche im Taktik-Modus mit Wellenvorschau & Geschwindigkeitsregelung.

@onready var label_dewdrops: Label = find_child("LabelDewdrops", true, false)
@onready var bar_core_hp: ProgressBar = find_child("BarCoreHP", true, false)
@onready var label_wave: Label = find_child("LabelWave", true, false)
@onready var btn_speed: Button = find_child("BtnSpeed", true, false)
@onready var btn_camera: Button = find_child("BtnCamera", true, false)
@onready var label_wave_preview: Label = find_child("LabelWavePreview", true, false)
@onready var btn_start_wave: Button = find_child("BtnStartWave", true, false)

const DewdropFlyTexture = preload("res://assets/sprites/ui/dewdrop_fly.png")

const WAVE_INFOS = {
	0: "Nächste: 4x 🐌 Gartenschnecke (Gemächlich)",
	1: "Nächste: 7x 🐌 Gartenschnecke (Flink)",
	2: "Nächste: 10x 🐌 Schneckenschwarm!",
	3: "⚠️ FINALE: 13x 🐌 Schnecken-Großangriff!"
}

func _ready() -> void:
	GameManager.dewdrops_changed.connect(_on_dewdrops_changed)
	GameManager.core_health_changed.connect(_on_core_health_changed)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_completed.connect(_on_wave_completed)
	GameManager.speed_changed.connect(_on_speed_changed)
	GameManager.dewdrop_fly_requested.connect(_on_dewdrop_fly_requested)

	if btn_speed:
		btn_speed.pressed.connect(GameManager.toggle_game_speed)
	if btn_camera:
		btn_camera.pressed.connect(GameManager.toggle_camera_perspective)
	if btn_start_wave:
		btn_start_wave.pressed.connect(GameManager.start_wave)

	_update_all()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		if btn_start_wave and not btn_start_wave.disabled:
			GameManager.start_wave()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_C or event.keycode == KEY_V):
		GameManager.toggle_camera_perspective()

func _update_all() -> void:
	_on_dewdrops_changed(GameManager.dewdrops)
	_on_core_health_changed(GameManager.core_health, GameManager.core_max_health)
	if label_wave:
		label_wave.text = "Welle: " + str(GameManager.current_wave) + "/" + str(GameManager.total_waves)
	if btn_start_wave:
		btn_start_wave.disabled = GameManager.is_wave_active
	_update_wave_preview(GameManager.current_wave)

func _update_wave_preview(current_w: int) -> void:
	if not label_wave_preview:
		return
	if GameManager.is_wave_active:
		label_wave_preview.text = "⚔️ Angriff im Gange..."
		label_wave_preview.add_theme_color_override("font_color", Color(0.72, 0.22, 0.12, 1.0))
	elif current_w >= GameManager.total_waves:
		label_wave_preview.text = "🎉 Alle Wellen abgewehrt!"
		label_wave_preview.add_theme_color_override("font_color", Color(0.2, 0.45, 0.15, 1.0))
	else:
		label_wave_preview.text = WAVE_INFOS.get(current_w, "Nächste Welle vorbereiten")
		label_wave_preview.add_theme_color_override("font_color", Color(0.36, 0.25, 0.15, 1.0))

func _on_dewdrops_changed(amount: int) -> void:
	if label_dewdrops:
		label_dewdrops.text = "💧 " + str(amount)

func _on_core_health_changed(current: int, max_hp: int) -> void:
	if bar_core_hp:
		bar_core_hp.max_value = max_hp
		bar_core_hp.value = current

func _on_wave_started(current: int, total: int) -> void:
	if label_wave:
		label_wave.text = "Welle: " + str(current) + "/" + str(total)
	if btn_start_wave:
		btn_start_wave.disabled = true
	_update_wave_preview(current)

func _on_wave_completed(wave_idx: int) -> void:
	if btn_start_wave:
		btn_start_wave.disabled = false
	_update_wave_preview(wave_idx)

func _on_speed_changed(mult: float) -> void:
	if btn_speed:
		btn_speed.text = str(int(mult)) + "x"

func _on_dewdrop_fly_requested(world_pos: Vector3, _amount: int) -> void:
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
	if cam.is_position_behind(world_pos):
		return
	var screen_start := cam.unproject_position(world_pos)
	_spawn_dewdrop_flight(screen_start)

func _spawn_dewdrop_flight(start_screen_pos: Vector2) -> void:
	if not DewdropFlyTexture:
		return
	var icon := TextureRect.new()
	icon.texture = DewdropFlyTexture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_size := Vector2(36, 36)
	icon.custom_minimum_size = icon_size
	icon.size = icon_size
	icon.pivot_offset = icon_size * 0.5
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)

	var target_screen_pos: Vector2 = Vector2(80, 48)
	if label_dewdrops:
		target_screen_pos = label_dewdrops.global_position + Vector2(20, 14)

	# Bogen nach oben ausbuchtend
	var arc_peak := (start_screen_pos + target_screen_pos) * 0.5
	arc_peak.y -= randf_range(80.0, 140.0)
	arc_peak.x += randf_range(-40.0, 40.0)

	icon.global_position = start_screen_pos - icon.pivot_offset
	icon.scale = Vector2(0.4, 0.4)
	icon.modulate = Color(1.2, 1.2, 1.2, 0.95)

	var tw := create_tween()
	var duration: float = 0.58
	tw.tween_method(func(progress: float):
		if not is_instance_valid(icon):
			return
		# Quadratische Bézier-Kurve
		var p0 := start_screen_pos
		var p1 := arc_peak
		var p2 := target_screen_pos
		var one_minus := 1.0 - progress
		var pos := one_minus * one_minus * p0 + 2.0 * one_minus * progress * p1 + progress * progress * p2
		icon.global_position = pos - icon.pivot_offset

		# Sanfte Größenänderung & Drehung
		if progress < 0.3:
			icon.scale = Vector2.ONE * lerpf(0.4, 1.25, progress / 0.3)
		else:
			icon.scale = Vector2.ONE * lerpf(1.25, 0.7, (progress - 0.3) / 0.7)
		icon.rotation = (p2 - p0).angle() + sin(progress * 12.0) * 0.2
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tw.tween_callback(func():
		if is_instance_valid(icon):
			icon.queue_free()
		# Kleiner Hüpfeffekt auf dem Tautropfen-Zähler
		if label_dewdrops:
			var tw_bounce := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw_bounce.tween_property(label_dewdrops, "scale", Vector2(1.28, 1.28), 0.08)
			tw_bounce.tween_property(label_dewdrops, "scale", Vector2.ONE, 0.14)
	)
