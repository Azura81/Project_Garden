class_name PathArrow
extends Node3D

## PathArrow: Animierter Richtungspfeil am Pfadanfang, der anzeigt wohin Schädlinge laufen.

@export var pulse_distance: float = 0.5
@export var pulse_speed: float = 3.5

var start_x: float = 0.0

func _ready() -> void:
	start_x = position.x

func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.001 * pulse_speed
	var offset: float = (sin(t) * 0.5 + 0.5) * pulse_distance
	position.x = start_x + offset
