extends Node

## GameManager: Zentraler Autoload für Ökonomie, Wellen und Spielstatus.

signal dewdrops_changed(new_amount: int)
signal core_health_changed(current: int, max_hp: int)
signal wave_started(wave_index: int, total_waves: int)
signal wave_completed(wave_index: int)
signal game_over(victory: bool)
signal symbiosis_entered(tower: Node3D)
signal symbiosis_exited()
signal spot_selected(spot: Area3D)
signal spot_deselected()
signal speed_changed(multiplier: float)
signal camera_perspective_toggle_requested()
signal dewdrop_fly_requested(start_world_pos: Vector3, amount: int)

@export var start_dewdrops: int = 150
var dewdrops: int = 150
var core_health: int = 100
var core_max_health: int = 100
var current_wave: int = 0
var total_waves: int = 4
var is_wave_active: bool = false
var active_symbiosis_tower: Node3D = null
var game_speed: float = 1.0

func _ready() -> void:
	reset_level_state()

func reset_level_state() -> void:
	dewdrops = start_dewdrops
	core_max_health = 100
	core_health = core_max_health
	current_wave = 0
	is_wave_active = false
	active_symbiosis_tower = null
	set_game_speed(1.0)
	dewdrops_changed.emit(dewdrops)
	core_health_changed.emit(core_health, core_max_health)

func add_dewdrops(amount: int) -> void:
	dewdrops += amount
	dewdrops_changed.emit(dewdrops)

func can_afford(cost: int) -> bool:
	return dewdrops >= cost

func spend_dewdrops(amount: int) -> bool:
	if can_afford(amount):
		dewdrops -= amount
		dewdrops_changed.emit(dewdrops)
		return true
	return false

func damage_core(amount: int) -> void:
	core_health = clampi(core_health - amount, 0, core_max_health)
	core_health_changed.emit(core_health, core_max_health)
	if core_health <= 0:
		is_wave_active = false
		game_over.emit(false)

func start_wave() -> void:
	if is_wave_active:
		return
	current_wave += 1
	is_wave_active = true
	wave_started.emit(current_wave, total_waves)

func complete_wave() -> void:
	is_wave_active = false
	wave_completed.emit(current_wave)
	if current_wave >= total_waves and core_health > 0:
		game_over.emit(true)

func enter_symbiosis(tower: Node3D) -> void:
	active_symbiosis_tower = tower
	symbiosis_entered.emit(tower)

func exit_symbiosis() -> void:
	active_symbiosis_tower = null
	symbiosis_exited.emit()

func select_spot(spot: Area3D) -> void:
	spot_selected.emit(spot)

func deselect_spot() -> void:
	spot_deselected.emit()

func set_game_speed(multiplier: float) -> void:
	game_speed = multiplier
	Engine.time_scale = multiplier
	speed_changed.emit(multiplier)

func toggle_game_speed() -> void:
	if is_equal_approx(game_speed, 1.0):
		set_game_speed(2.0)
	else:
		set_game_speed(1.0)

func toggle_camera_perspective() -> void:
	camera_perspective_toggle_requested.emit()
