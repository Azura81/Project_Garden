class_name RadialMenu
extends Control

## RadialMenu: Ring-Menü zum Pflanzen, Gießen (Upgraden), Symbiose freischalten & Einsteigen.

@export var rose_scene: PackedScene = preload("res://scenes/towers/ThornRose.tscn")
@export var dandelion_scene: PackedScene = preload("res://scenes/towers/DandelionCatapult.tscn")

@onready var btn_plant_rose: Button = $Panel/VBoxContainer/BtnPlantRose
@onready var btn_plant_dandelion: Button = $Panel/VBoxContainer/BtnPlantDandelion
@onready var btn_upgrade: Button = $Panel/VBoxContainer/BtnUpgrade
@onready var btn_symbiosis_unlock: Button = $Panel/VBoxContainer/BtnSymbiosisUnlock
@onready var btn_enter_symbiosis: Button = $Panel/VBoxContainer/BtnEnterSymbiosis
@onready var btn_close: Button = $Panel/VBoxContainer/BtnClose

var target_spot: Area3D = null

func _ready() -> void:
	visible = false
	if btn_plant_rose:
		btn_plant_rose.pressed.connect(_on_plant_rose_pressed)
	if btn_plant_dandelion:
		btn_plant_dandelion.pressed.connect(_on_plant_dandelion_pressed)
	if btn_upgrade:
		btn_upgrade.pressed.connect(_on_upgrade_pressed)
	if btn_symbiosis_unlock:
		btn_symbiosis_unlock.pressed.connect(_on_symbiosis_unlock_pressed)
	if btn_enter_symbiosis:
		btn_enter_symbiosis.pressed.connect(_on_enter_symbiosis_pressed)
	if btn_close:
		btn_close.pressed.connect(close)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		close()
		get_viewport().set_input_as_handled()

func open_for_spot(spot: Area3D) -> void:
	target_spot = spot
	visible = true
	_update_buttons()
	GameManager.select_spot(spot)

func close() -> void:
	if visible:
		visible = false
		target_spot = null
		GameManager.deselect_spot()

func _update_buttons() -> void:
	if not target_spot:
		return
	var spot_is_empty: bool = true
	if target_spot.has_method("is_empty"):
		spot_is_empty = target_spot.is_empty()

	if btn_plant_rose:
		btn_plant_rose.visible = spot_is_empty
		btn_plant_rose.text = "🌹 Rose pflanzen (50💧)"
		btn_plant_rose.disabled = not GameManager.can_afford(50)

	if btn_plant_dandelion:
		btn_plant_dandelion.visible = spot_is_empty
		btn_plant_dandelion.text = "🌼 Pusteblume (70💧)"
		btn_plant_dandelion.disabled = not GameManager.can_afford(70)

	var current_plant: Node3D = null
	if target_spot.get("current_plant") != null:
		current_plant = target_spot.get("current_plant") as Node3D

	if not spot_is_empty and current_plant:
		var plant_level: int = int(current_plant.get("level"))
		var max_lvl: int = int(current_plant.get("max_level"))
		if btn_upgrade:
			btn_upgrade.visible = plant_level < max_lvl
			var cost: int = 75
			if current_plant.has_method("get_upgrade_cost"):
				cost = current_plant.get_upgrade_cost()
			btn_upgrade.text = "💧 Gießen (Stufe " + str(plant_level + 1) + ") - " + str(cost) + "💧"
			btn_upgrade.disabled = not GameManager.can_afford(cost)

		var has_symb: bool = bool(current_plant.get("has_symbiosis_upgrade"))
		if btn_symbiosis_unlock:
			btn_symbiosis_unlock.visible = not has_symb
			var symb_cost: int = int(current_plant.get("cost_symbiosis"))
			btn_symbiosis_unlock.text = "✨ Symbiose freischalten (" + str(symb_cost) + "💧)"
			btn_symbiosis_unlock.disabled = not GameManager.can_afford(symb_cost)

		if btn_enter_symbiosis:
			btn_enter_symbiosis.visible = has_symb
			btn_enter_symbiosis.text = "🐝 In die Blüte schlüpfen (1st-Person)"
	else:
		if btn_upgrade:
			btn_upgrade.visible = false
		if btn_symbiosis_unlock:
			btn_symbiosis_unlock.visible = false
		if btn_enter_symbiosis:
			btn_enter_symbiosis.visible = false

func _on_plant_rose_pressed() -> void:
	if target_spot and target_spot.has_method("is_empty") and target_spot.is_empty():
		if GameManager.spend_dewdrops(50):
			target_spot.call("plant_tower", rose_scene)
			close()

func _on_plant_dandelion_pressed() -> void:
	if target_spot and target_spot.has_method("is_empty") and target_spot.is_empty():
		if GameManager.spend_dewdrops(70):
			target_spot.call("plant_tower", dandelion_scene)
			close()

func _on_upgrade_pressed() -> void:
	if target_spot and target_spot.get("current_plant"):
		var p: Node3D = target_spot.get("current_plant")
		if p.has_method("upgrade_level") and p.upgrade_level():
			_update_buttons()

func _on_symbiosis_unlock_pressed() -> void:
	if target_spot and target_spot.get("current_plant"):
		var p: Node3D = target_spot.get("current_plant")
		if p.has_method("unlock_symbiosis") and p.unlock_symbiosis():
			_update_buttons()

func _on_enter_symbiosis_pressed() -> void:
	if target_spot and target_spot.get("current_plant"):
		var p: Node3D = target_spot.get("current_plant")
		GameManager.enter_symbiosis(p)
		close()
