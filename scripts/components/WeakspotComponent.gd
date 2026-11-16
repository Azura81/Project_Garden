class_name WeakspotComponent
extends "res://scripts/components/HitboxComponent.gd"

## WeakspotComponent: Spezieller Trefferbereich mit kritischem Schadensmultiplikator (z.B. Hinterleib von Käfern, Fühler).

@export var crit_multiplier: float = 3.0
@export var weakspot_name: String = "Schwachstelle"

func _init() -> void:
	damage_multiplier = crit_multiplier
