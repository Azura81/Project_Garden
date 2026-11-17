class_name TowerSpot
extends Area3D

## TowerSpot: Natürlicher Erd-Pflanzplatz mit magischem Runenring & Setzling-Indikator.

signal spot_clicked(spot: Area3D)

@export var spot_id: int = 1
var current_plant: Node3D = null

@onready var mesh_instance: MeshInstance3D = get_node_or_null("MoundMesh")
@onready var magic_ring: Node3D = get_node_or_null("MagicRing")
@onready var idle_sprout: Node3D = get_node_or_null("IdleSprout")

func _ready() -> void:
	input_ray_pickable = true
	input_event.connect(_on_input_event)
	_update_visual_state()

func _process(delta: float) -> void:
	if not is_empty():
		return
	var t := Time.get_ticks_msec() * 0.001
	if magic_ring:
		magic_ring.rotation.y += delta * 0.75
		magic_ring.position.y = 0.2 + sin(t * 2.4 + float(spot_id)) * 0.025
	if idle_sprout:
		idle_sprout.rotation.y = sin(t * 1.5 + float(spot_id)) * 0.1
		idle_sprout.position.y = sin(t * 2.0 + float(spot_id)) * 0.015

func is_empty() -> bool:
	return current_plant == null

func plant_tower(tower_scene: PackedScene) -> Node3D:
	if not is_empty() or not tower_scene:
		return null
	var tower := tower_scene.instantiate() as Node3D
	add_child(tower)
	current_plant = tower
	_update_visual_state()
	return tower

func remove_plant() -> void:
	if current_plant:
		current_plant.queue_free()
		current_plant = null
	_update_visual_state()

func _update_visual_state() -> void:
	var empty := is_empty()
	if magic_ring:
		magic_ring.visible = empty
	if idle_sprout:
		idle_sprout.visible = empty

func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		spot_clicked.emit(self)
