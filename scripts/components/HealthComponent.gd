class_name HealthComponent
extends Node

## HealthComponent: Verwaltet Lebenspunkte, Schaden und Tod für Einheiten/Kerne.

signal health_changed(current: float, max_val: float)
signal damaged(amount: float, source: Node)
signal died()

@export var max_health: float = 100.0
var current_health: float = 100.0
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float, source: Node = null) -> void:
	if is_dead or amount <= 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	damaged.emit(amount, source)
	if current_health <= 0.0:
		is_dead = true
		died.emit()

func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_health = minf(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
