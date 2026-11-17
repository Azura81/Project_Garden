class_name RangeIndicator
extends Node3D

## RangeIndicator: Zeigt die Angriffsreichweite der Pflanze mit sanftem Blütenglanz auf der Erde an.

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var current_tween: Tween = null

func _ready() -> void:
	visible = false
	scale = Vector3.ZERO

func show_range(spot_pos: Vector3, range_radius: float) -> void:
	global_position = Vector3(spot_pos.x, 0.08, spot_pos.z)
	visible = true

	var target_scale := Vector3(range_radius * 2.0, 1.0, range_radius * 2.0)

	if current_tween and current_tween.is_valid():
		current_tween.kill()

	current_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(self, "scale", target_scale, 0.28)

func hide_range() -> void:
	if not visible:
		return

	if current_tween and current_tween.is_valid():
		current_tween.kill()

	current_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	current_tween.tween_property(self, "scale", Vector3.ZERO, 0.2)
	current_tween.tween_callback(func():
		visible = false
	)
