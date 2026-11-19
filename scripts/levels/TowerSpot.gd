class_name TowerSpot
extends Area3D

## TowerSpot: Natürlicher Erd-Pflanzplatz mit magischem Runenring & Setzling-Indikator.

signal spot_clicked(spot: Area3D)

@export var spot_id: int = 1
var current_plant: Node3D = null

@onready var mesh_instance: MeshInstance3D = get_node_or_null("MoundMesh")
@onready var magic_ring: Node3D = get_node_or_null("MagicRing")
@onready var idle_sprout: Node3D = get_node_or_null("IdleSprout")
@onready var spot_light: OmniLight3D = get_node_or_null("SpotLight")

func _ready() -> void:
	input_ray_pickable = true
	input_event.connect(_on_input_event)
	_update_visual_state()

func _process(delta: float) -> void:
	if not is_empty():
		return
	var t := Time.get_ticks_msec() * 0.001
	if magic_ring:
		magic_ring.rotation.y += delta * 0.4
		var breathe := sin(t * 2.5 + float(spot_id) * 1.4)
		magic_ring.scale = Vector3.ONE * (1.0 + breathe * 0.05)
		if magic_ring is Sprite3D:
			(magic_ring as Sprite3D).modulate.a = 0.85 + breathe * 0.15
	if idle_sprout:
		idle_sprout.rotation.z = sin(t * 2.2 + float(spot_id)) * 0.06
		idle_sprout.position.y = 0.22 + sin(t * 2.5 + float(spot_id)) * 0.012
	if spot_light:
		spot_light.light_energy = 1.3 + sin(t * 2.8 + float(spot_id) * 1.4) * 0.35

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
	if spot_light:
		spot_light.visible = empty

func _on_input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		spot_clicked.emit(self)
