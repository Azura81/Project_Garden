shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform vec4 ring_color : source_color = vec4(1.0, 0.92, 0.52, 0.85);
uniform vec4 fill_color : source_color = vec4(0.72, 0.95, 0.45, 0.14);
uniform float ring_thickness : hint_range(0.01, 0.15) = 0.045;
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.4;
uniform float dash_count : hint_range(0.0, 60.0) = 36.0;

void fragment() {
	// UV zentrieren (-0.5 bis +0.5)
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv) * 2.0; // 0.0 im Zentrum, 1.0 am Rand
	
	if (dist > 1.0) {
		discard;
	}
	
	// Pulsieren
	float pulse = 0.9 + 0.1 * sin(TIME * pulse_speed);
	
	// Äußerer Leuchtring
	float ring = smoothstep(1.0 - ring_thickness, 1.0, dist) * pulse;
	
	// Sanftes, rotierendes Blüten-Punktmuster am Rand
	float angle = atan(uv.y, uv.x) + TIME * 0.4;
	float dashes = 0.75 + 0.25 * sin(angle * dash_count);
	
	// Füllung im Inneren (sehr zart)
	float fill = (1.0 - dist) * 0.25;
	
	vec4 col = mix(fill_color, ring_color * dashes, ring);
	col.a = max(fill * fill_color.a, ring * ring_color.a * dashes);
	
	ALBEDO = col.rgb;
	ALPHA = clamp(col.a, 0.0, 1.0);
}
