class_name HUDTactical
extends Control

## HUDTactical: Benutzeroberfläche im Taktik-Modus (Vogelperspektive).

@onready var label_dewdrops: Label = $TopLeft/HBoxContainer/LabelDewdrops
@onready var bar_core_hp: ProgressBar = $TopLeft/HBoxContainer/BarCoreHP
@onready var label_wave: Label = $TopRight/HBoxContainer/LabelWave
@onready var btn_speed: Button = $TopRight/HBoxContainer/BtnSpeed
@onready var btn_start_wave: Button = $BottomCenter/BtnStartWave

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

func _update_all() -> void:
	_on_dewdrops_changed(GameManager.dewdrops)
	_on_core_health_changed(GameManager.core_health, GameManager.core_max_health)
	_on_wave_started(GameManager.current_wave, GameManager.total_waves)

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

func _on_wave_completed(_wave: int) -> void:
	if btn_start_wave:
		btn_start_wave.disabled = false

func _on_speed_changed(mult: float) -> void:
	if btn_speed:
		btn_speed.text = str(int(mult)) + "x"
