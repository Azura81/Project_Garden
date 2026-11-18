extends CanvasLayer

## PaperOverlay: Globales Aquarellpapier-Overlay (Autoload)
## Zieht eine feine PapierkÃ¶rnung und eine sanfte BÃ¼ttenpapier-Vignette Ã¼ber das gesamte Bild.

@export var overlay_visible: bool = true:
	set(val):
		overlay_visible = val
		if _rect:
			_rect.visible = val

var _rect: ColorRect

func _ready() -> void:
	layer = 20 # Liegt sanft Ã¼ber dem Bild
	_setup_overlay()

func _setup_overlay() -> void:
	_rect = ColorRect.new()
	_rect.name = "PaperVignetteRect"
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/paper_overlay.gdshader")
	var paper_tex := preload("res://assets/textures/watercolor_paper.png")
	mat.set_shader_parameter("paper_grain_tex", paper_tex)
	mat.set_shader_parameter("paper_scale", Vector2(3.0, 1.7))
	mat.set_shader_parameter("grain_intensity", 0.18)
	mat.set_shader_parameter("paper_color", Color("fcf8f0"))
	mat.set_shader_parameter("vignette_start", 0.45)
	mat.set_shader_parameter("vignette_end", 0.72)
	mat.set_shader_parameter("vignette_strength", 0.42)
	
	_rect.material = mat
	add_child(_rect)
