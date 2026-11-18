class_name PaperCutout3D
extends Sprite3D

## PaperCutout3D
## Wiederverwendbare 2.5D-Pappaufsteller-Komponente im Paper-Mario-Stil.
## Bietet Y-Billboard, echte 3D-Schatten, sanftes Idle-Wobble (Squash & Stretch)
## und 0,15s Paper-Flip-Animation bei Richtungswechseln.

@export_group("Paper Cutout Styling")
@export var align_to_bottom: bool = true
@export var base_scale_multiplier: Vector3 = Vector3.ONE

@export_group("Idle Wobble (Papier-Wippen)")
@export var wobble_enabled: bool = true
@export var wobble_frequency: float = 3.2
@export var wobble_amplitude: float = 0.045
@export var wobble_tilt: float = 0.035
@export var random_phase: bool = true

@export_group("Direction & Paper Flip")
@export var auto_flip: bool = true
@export var flip_duration: float = 0.15
@export var facing_right: bool = true

var _flip_factor: float = 1.0
var _flip_tween: Tween
var _hit_tween: Tween
var _wobble_time: float = 0.0
var _phase_offset: float = 0.0
var _last_global_pos: Vector3 = Vector3.ZERO
var _hit_recoil: float = 0.0

func _ready() -> void:
	# 1. 2.5D Rendering-Einstellungen fÃ¼r Pop-Up-Papier
	shaded = true
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	
	# Initialer Ausrichtungs-Offset
	_update_bottom_alignment()
	
	if random_phase:
		_phase_offset = randf_range(0.0, TAU)
	
	_flip_factor = 1.0 if facing_right else -1.0
	_last_global_pos = global_position

func _update_bottom_alignment() -> void:
	if align_to_bottom and texture:
		# Setzt den Pivot an die Unterkante des Sprites
		offset.y = texture.get_height() * 0.5

func _process(delta: float) -> void:
	# 1. Automatischer Richtungswechsel bei Bewegung
	if auto_flip:
		var cur_pos := global_position
		var delta_x := cur_pos.x - _last_global_pos.x
		if absf(delta_x) > 0.003:
			var want_right := delta_x > 0.0
			if want_right != facing_right:
				set_facing(want_right)
		_last_global_pos = cur_pos

	# 2. Prozedurales Idle-Wobble (Squash & Stretch + Papier-Neigung)
	if wobble_enabled:
		_wobble_time += delta * wobble_frequency
		var squash: float = sin(_wobble_time + _phase_offset) * wobble_amplitude
		squash += _hit_recoil
		
		var sx: float = (1.0 - squash * 0.6) * base_scale_multiplier.x * _flip_factor
		var sy: float = (1.0 + squash) * base_scale_multiplier.y
		var sz: float = base_scale_multiplier.z
		
		scale = Vector3(sx, sy, sz)
		rotation.z = sin((_wobble_time + _phase_offset) * 0.6) * wobble_tilt

func set_facing(is_right: bool) -> void:
	if facing_right == is_right and (_flip_tween == null or not _flip_tween.is_valid()):
		return
		
	facing_right = is_right
	var target_factor: float = 1.0 if facing_right else -1.0
	
	if _flip_tween and _flip_tween.is_valid():
		_flip_tween.kill()
		
	_flip_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	var half_dur: float = flip_duration * 0.5
	
	# Dreht sich flach um die Y-Achse (scale.x -> 0 -> Zielrichtung)
	_flip_tween.tween_property(self, "_flip_factor", 0.0, half_dur)
	_flip_tween.tween_property(self, "_flip_factor", target_factor, half_dur)

func trigger_hit_recoil() -> void:
	if _hit_tween and _hit_tween.is_valid():
		_hit_tween.kill()
	
	_hit_recoil = 0.25
	_hit_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hit_tween.tween_property(self, "_hit_recoil", 0.0, 0.2)
