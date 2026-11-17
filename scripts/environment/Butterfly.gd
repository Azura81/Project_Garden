class_name Butterfly
extends Node3D

## Butterfly: Malerischer Ghibli-Schmetterling, der sanft über den Blumen im Beet flattert.

@export var flight_speed: float = 0.5
@export var path_radius_x: float = 12.0
@export var path_radius_z: float = 5.5
@export var base_height: float = 1.3

@onready var wing_left: Node3D = $WingLeft
@onready var wing_right: Node3D = $WingRight

var time_offset: float = 0.0

func _ready() -> void:
	time_offset = randf() * 100.0

func _process(delta: float) -> void:
	var t: float = (Time.get_ticks_msec() * 0.001 + time_offset) * flight_speed

	# Organische Flugbahn über dem Beet
	var target_x: float = sin(t * 0.8) * path_radius_x
	var target_z: float = cos(t * 1.1) * path_radius_z
	var target_y: float = base_height + sin(t * 2.8) * 0.35

	var target_pos := Vector3(target_x, target_y, target_z)
	var move_dir := target_pos - position
	if move_dir.length_squared() > 0.0001:
		var target_rot_y := atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot_y, delta * 6.0)

	position = target_pos

	# Flügelschlagen (ca. 14 Hz mit sanfter Pause)
	var flap: float = sin(Time.get_ticks_msec() * 0.016)
	if wing_left:
		wing_left.rotation.z = flap * 0.85
	if wing_right:
		wing_right.rotation.z = -flap * 0.85
