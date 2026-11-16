shader_type canvas_item;

// Sanfter Papier-Korn-Overlay-Shader für den handgezeichneten Aquarell-Look
uniform float grain_strength : hint_range(0.0, 0.2) = 0.04;
uniform vec4 tint_color : source_color = vec4(0.98, 0.96, 0.92, 1.0);

float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float noise = (random(UV * 250.0) - 0.5) * grain_strength;
	col.rgb = mix(col.rgb, tint_color.rgb, 0.05) + vec3(noise);
	COLOR = col;
}
