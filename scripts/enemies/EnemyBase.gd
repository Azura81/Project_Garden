class_name EnemyBase
extends PathFollow3D

## EnemyBase: Basisklasse für Schädlinge auf Path3D.

signal defeated(dewdrops_reward: int)
signal reached_core(damage: int)

@export var enemy_name: String = "Schädling"
@export var speed: float = 2.0
@export var base_dewdrops: int = 10
@export var core_damage: int = 10

var current_speed: float = 2.0
var slow_timer: float = 0.0

@onready var health_component: Node = $HealthComponent

func _ready() -> void:
	add_to_group("enemies")
	loop = false
	current_speed = speed
	if health_component and health_component.has_signal("died"):
		health_component.connect("died", _on_died)

func _process(delta: float) -> void:
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			current_speed = speed

	progress += current_speed * delta

	if progress_ratio >= 1.0:
		_reach_core()

func apply_slow(speed_factor: float, duration: float) -> void:
	current_speed = speed * speed_factor
	slow_timer = duration

func _reach_core() -> void:
	GameManager.damage_core(core_damage)
	reached_core.emit(core_damage)
	queue_free()

func _on_died() -> void:
	var reward := base_dewdrops
	if GameManager.active_symbiosis_tower:
		reward = int(base_dewdrops * 1.25) + 1
	GameManager.add_dewdrops(reward)
	defeated.emit(reward)
	queue_free()
