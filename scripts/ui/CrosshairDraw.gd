class_name CrosshairDraw
extends Control

## CrosshairDraw: Elegantes handgezeichnetes Tusche-Fadenkreuz für den 1st-Person-Symbiose-Modus.

@export var ink_color: Color = Color(0.169, 0.129, 0.094, 0.92) # #2B2118
@export var glow_color: Color = Color(1.0, 0.95, 0.85, 0.5)

func _draw() -> void:
	var center := size * 0.5
	var inner_r := 7.0
	var outer_r := 18.0
	var width := 2.2
	
	# Subtiler heller Schein dahinter für perfekten Kontrast
	draw_circle(center, 3.5, glow_color)
	draw_line(center - Vector2(outer_r + 1.0, 0.0), center - Vector2(inner_r - 1.0, 0.0), glow_color, width + 1.5)
	draw_line(center + Vector2(inner_r - 1.0, 0.0), center + Vector2(outer_r + 1.0, 0.0), glow_color, width + 1.5)
	draw_line(center - Vector2(0.0, outer_r + 1.0), center - Vector2(0.0, inner_r - 1.0), glow_color, width + 1.5)
	draw_line(center + Vector2(0.0, inner_r - 1.0), center + Vector2(0.0, outer_r + 1.0), glow_color, width + 1.5)
	
	# Dunkle Tuschestriche
	draw_circle(center, 2.2, ink_color)
	draw_line(center - Vector2(outer_r, 0.0), center - Vector2(inner_r, 0.0), ink_color, width)
	draw_line(center + Vector2(inner_r, 0.0), center + Vector2(outer_r, 0.0), ink_color, width)
	draw_line(center - Vector2(0.0, outer_r), center - Vector2(0.0, inner_r), ink_color, width)
	draw_line(center + Vector2(0.0, inner_r), center + Vector2(0.0, outer_r), ink_color, width)
