class_name TowerBase
extends Node3D

## TowerBase: Basisklasse für alle Verteidigungspflanzen (Blüten & Kräuter).

signal level_upgraded(new_level: int)
signal symbiosis_unlocked()
signal energy_changed(current: float, max_val: float)

@export var plant_name: String = "Basis-Pflanze"
@export var level: int = 1
@export var max_level: int = 3
@export var cost_level_1: int = 50
@export var cost_level_2: int = 75
@export var cost_level_3: int = 140
@export var cost_symbiosis: int = 100

@export var attack_range: float = 6.0
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 0.8

# Symbiose-Werte
@export var has_symbiosis_upgrade: bool = false
@export var max_energy: float = 18.0
var current_energy: float = 18.0
var is_active_in_symbiosis: bool = false

var fire_timer: float = 0.0
var current_target: Node3D = null

@onready var first_person_mount: Marker3D = $FirstPersonMount
@onready var range_area: Area3D = $RangeArea

func _ready() -> void:
	current_energy = max_energy
	if range_area:
		range_area.area_entered.connect(_on_range_area_entered)
		range_area.area_exited.connect(_on_range_area_exited)
	GameManager.symbiosis_entered.connect(_on_symbiosis_entered)
	GameManager.symbiosis_exited.connect(_on_symbiosis_exited)

func _process(delta: float) -> void:
	if is_active_in_symbiosis:
		_process_symbiosis(delta)
	else:
		_process_tactical_autofire(delta)

func _process_tactical_autofire(delta: float) -> void:
	fire_timer -= delta
	if fire_timer <= 0.0 and current_target and is_instance_valid(current_target):
		fire_at_target(current_target)
		fire_timer = attack_cooldown

func _process_symbiosis(delta: float) -> void:
	current_energy = maxf(current_energy - delta, 0.0)
	energy_changed.emit(current_energy, max_energy)
	if current_energy <= 0.0:
		GameManager.exit_symbiosis()

func fire_at_target(target: Node3D) -> void:
	# Wird von abgeleiteten Pflanzen überschrieben (z.B. Dornen-Rose, Löwenzahn)
	pass

func fire_manual(aim_ray: RayCast3D) -> void:
	# Manuelles Schießen im 1st-Person Symbiose Modus
	pass

func trigger_special_ability() -> void:
	# Individuelle Fähigkeit (Rechte Bildschirmhälfte)
	pass

func upgrade_level() -> bool:
	if level >= max_level:
		return false
	var next_cost := get_upgrade_cost()
	if GameManager.spend_dewdrops(next_cost):
		level += 1
		attack_damage *= 1.35
		attack_range *= 1.15
		attack_cooldown *= 0.9
		level_upgraded.emit(level)
		return true
	return false

func unlock_symbiosis() -> bool:
	if has_symbiosis_upgrade or level < 2:
		return false
	if GameManager.spend_dewdrops(cost_symbiosis):
		has_symbiosis_upgrade = true
		symbiosis_unlocked.emit()
		return true
	return false

func get_upgrade_cost() -> int:
	if level == 1:
		return cost_level_2
	elif level == 2:
		return cost_level_3
	return 0

func _on_range_area_entered(area: Area3D) -> void:
	if not current_target and area.owner and area.owner.is_in_group("enemies"):
		current_target = area.owner

func _on_range_area_exited(area: Area3D) -> void:
	if current_target and area.owner == current_target:
		current_target = null

func _on_symbiosis_entered(tower: Node3D) -> void:
	if tower == self:
		is_active_in_symbiosis = true
		current_energy = max_energy

func _on_symbiosis_exited() -> void:
	if is_active_in_symbiosis:
		is_active_in_symbiosis = false
