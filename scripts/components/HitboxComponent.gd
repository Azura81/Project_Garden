class_name HitboxComponent
extends Area3D

## HitboxComponent: Erkennt Projektil-/Schadenseinschläge und leitet sie an HealthComponent weiter.

@export var health_component: Node
@export var damage_multiplier: float = 1.0

func apply_damage(amount: float, source: Node = null) -> float:
	var final_dmg: float = amount * damage_multiplier
	if health_component and health_component.has_method("take_damage"):
		health_component.call("take_damage", final_dmg, source)
	return final_dmg
