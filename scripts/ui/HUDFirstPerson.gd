class_name HUDFirstPerson
extends Control

## HUDFirstPerson: 1st-Person-Symbiose-HUD mit Fadenkreuz, Energie-Balken, Spezialfähigkeit & Aussteigen-Button.

@onready var btn_exit: Button = $TopLeft/BtnExit
@onready var btn_special: Button = $BottomRight/BtnSpecial
@onready var energy_bar: ProgressBar = $CenterContainer/Crosshair/EnergyBar
@onready var crosshair: Control = $CenterContainer/Crosshair
@onready var cockpit_overlay: TextureRect = $CockpitOverlay

var active_tower: Node3D = null

func _ready() -> void:
	if btn_exit:
		btn_exit.pressed.connect(GameManager.exit_symbiosis)
	if btn_special:
		btn_special.pressed.connect(_on_special_pressed)

	GameManager.symbiosis_entered.connect(_on_symbiosis_entered)
	GameManager.symbiosis_exited.connect(_on_symbiosis_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		GameManager.exit_symbiosis()
		get_viewport().set_input_as_handled()

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
	visible = true
	if cockpit_overlay:
		if tower is ThornRose or tower.name.begins_with("ThornRose"):
			cockpit_overlay.texture = preload("res://assets/sprites/cockpits/rose_cockpit.png")
			cockpit_overlay.visible = true
		else:
			cockpit_overlay.visible = false
	if crosshair and crosshair.has_method("queue_redraw"):
		crosshair.queue_redraw()

func _on_symbiosis_exited() -> void:
	active_tower = null
	visible = false
