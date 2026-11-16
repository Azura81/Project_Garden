class_name HUDFirstPerson
extends Control

## HUDFirstPerson: 1st-Person-Symbiose-HUD mit Fadenkreuz, Energie-Balken, Spezialfähigkeit & Aussteigen-Button.

@onready var btn_exit: Button = $TopLeft/BtnExit
@onready var btn_special: Button = $BottomRight/BtnSpecial
@onready var energy_bar: ProgressBar = $CenterContainer/Crosshair/EnergyBar
@onready var crosshair: Control = $CenterContainer/Crosshair

var active_tower: Node3D = null

func _ready() -> void:
	if btn_exit:
		btn_exit.pressed.connect(GameManager.exit_symbiosis)
	if btn_special:
		btn_special.pressed.connect(_on_special_pressed)

	GameManager.symbiosis_entered.connect(_on_symbiosis_entered)
	GameManager.symbiosis_exited.connect(_on_symbiosis_exited)

func _process(_delta: float) -> void:
	if active_tower and energy_bar:
		var max_e: float = float(active_tower.get("max_energy"))
		var cur_e: float = float(active_tower.get("current_energy"))
		energy_bar.max_value = max_e
		energy_bar.value = cur_e

func _on_special_pressed() -> void:
	if active_tower and active_tower.has_method("trigger_special_ability"):
		active_tower.call("trigger_special_ability")

func _on_symbiosis_entered(tower: Node3D) -> void:
	active_tower = tower

func _on_symbiosis_exited() -> void:
	active_tower = null
