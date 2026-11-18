class_name GardenSnail
extends "res://scripts/enemies/EnemyBase.gd"

## GardenSnail: Standard-Schnecke mit 10 Tautropfen Belohnung.

func _init() -> void:
	enemy_name = "Gartenschnecke"
	speed = 1.4
	base_dewdrops = 10
	core_damage = 10

func _ready() -> void:
	super._ready()
	if health_component:
		health_component.max_health = 65.0
		health_component.current_health = 65.0

func knockback(amount: float) -> void:
	progress = maxf(progress - amount, 0.0)
