shader_type spatial;
render_mode cull_front, unshaded;

// Inverted Hull Tusche-Kontur-Shader (Backface Extrusion)
uniform vec4 outline_color : source_color = vec4(0.18, 0.08, 0.1, 1.0);
uniform float outline_width : hint_range(0.001, 0.06) = 0.022;

void vertex() {
	// Vertices entlang der Normalen nach außen verschieben
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
