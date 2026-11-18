class_name GardenBeetle
extends "res://scripts/enemies/EnemyBase.gd"

## GardenBeetle: Flinker Schmuckkäfer.
## Schneller als die Schnecke (Speed 2.6), wendiger Papier-Flip,
## etwas weniger Lebenspunkte (45 HP) und 15 Tautropfen Belohnung.

func _init() -> void:
	enemy_name = "Schmuckkäfer"
	speed = 2.6
	base_dewdrops = 15
	core_damage = 10

func _ready() -> void:
	super._ready()
	if health_component:
		health_component.max_health = 45.0
		health_component.current_health = 45.0

func knockback(amount: float) -> void:
	progress = maxf(progress - amount * 1.2, 0.0)
