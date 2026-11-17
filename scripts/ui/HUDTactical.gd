class_name HUDTactical
extends Control

## HUDTactical: Benutzeroberfläche im Taktik-Modus mit Wellenvorschau & Geschwindigkeitsregelung.

@onready var label_dewdrops: Label = $TopLeft/HBoxContainer/LabelDewdrops
@onready var bar_core_hp: ProgressBar = $TopLeft/HBoxContainer/BarCoreHP
@onready var label_wave: Label = $TopRight/VBoxContainer/HBoxContainer/LabelWave
@onready var btn_speed: Button = $TopRight/VBoxContainer/HBoxContainer/BtnSpeed
@onready var label_wave_preview: Label = $TopRight/VBoxContainer/LabelWavePreview
@onready var btn_start_wave: Button = $BottomCenter/BtnStartWave

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

	if btn_speed:
		btn_speed.pressed.connect(GameManager.toggle_game_speed)
	if btn_start_wave:
		btn_start_wave.pressed.connect(GameManager.start_wave)

	_update_all()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		if btn_start_wave and not btn_start_wave.disabled:
			GameManager.start_wave()

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
		label_wave_preview.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4, 0.95))
	elif current_w >= GameManager.total_waves:
		label_wave_preview.text = "🎉 Alle Wellen abgewehrt!"
		label_wave_preview.add_theme_color_override("font_color", Color(0.6, 1.0, 0.5, 0.95))
	else:
		label_wave_preview.text = WAVE_INFOS.get(current_w, "Nächste Welle vorbereiten")
		label_wave_preview.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 0.95))

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
