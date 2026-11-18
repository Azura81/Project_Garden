class_name GoldenSprout
extends Node3D

## GoldenSprout: Der magische goldene Spross im Herzen des Gartens.
## Ersetzt die abstrakte Kern-Kugel mit einem lebendigen, leuchtenden Baumling.

@onready var model: Node3D = get_node_or_null("PaperCutout") if get_node_or_null("PaperCutout") else get_node_or_null("MeshInstance3D")
@onready var aura_light: OmniLight3D = $OmniLight3D
@onready var particles: CPUParticles3D = $CPUParticles3D
@onready var ground_ring: MeshInstance3D = get_node_or_null("GroundRing")

var _base_y: float = 0.0
var _shake_timer: float = 0.0
var _prev_hp: int = 100

func _ready() -> void:
	_base_y = position.y
	_prev_hp = GameManager.core_health
	if GameManager.has_signal("core_health_changed"):
		GameManager.core_health_changed.connect(_on_health_changed)

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	
	# Sanftes Atmen / Schweben
	var bob := sin(t * 1.8) * 0.04
	var sway := sin(t * 1.2) * 0.02
	if model:
		model.position.y = bob
		model.rotation.z = sway
		model.rotation.y = sin(t * 0.6) * 0.05
	
	# Leichtes Pulsieren des Lichts
	if aura_light:
		aura_light.light_energy = 1.35 + sin(t * 3.0) * 0.25
		
	# Rotierender Boden-Magiering
	if ground_ring:
		ground_ring.rotation.y += delta * 0.4
		
	# Erschütterung bei Schaden
	if _shake_timer > 0.0:
		_shake_timer -= delta
		if model:
			model.position.x = (randf() - 0.5) * 0.12
			model.position.z = (randf() - 0.5) * 0.12
		if _shake_timer <= 0.0 and model:
			model.position.x = 0.0
			model.position.z = 0.0

func _on_health_changed(current: int, _max_hp: int) -> void:
	if current < _prev_hp:
		_shake_timer = 0.4
		if aura_light:
			var tw := create_tween()
			tw.tween_property(aura_light, "light_color", Color(1.0, 0.35, 0.2), 0.1)
			tw.tween_property(aura_light, "light_color", Color(1.0, 0.86, 0.42), 0.35)
	_prev_hp = current
