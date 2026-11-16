class_name TowerSpot
extends Area3D

## TowerSpot: Fester Erd-Pflanzplatz im Beet für saubere Sichtlinien im 1st-Person-Modus.

signal spot_clicked(spot: Area3D)

@export var spot_id: int = 1
var current_plant: Node3D = null

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	input_ray_pickable = true
	input_event.connect(_on_input_event)

func is_empty() -> bool:
	return current_plant == null

func plant_tower(tower_scene: PackedScene) -> Node3D:
	if not is_empty() or not tower_scene:
		return null
	var tower := tower_scene.instantiate() as Node3D
	add_child(tower)
	current_plant = tower
	return tower

func remove_plant() -> void:
	if current_plant:
		current_plant.queue_free()
		current_plant = null

func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		spot_clicked.emit(self)
