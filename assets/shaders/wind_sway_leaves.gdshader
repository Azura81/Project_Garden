shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_toon, specular_toon;

uniform vec4 albedo_color : source_color = vec4(0.38, 0.62, 0.22, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.22, 0.42, 0.14, 1.0);
uniform float wind_strength : hint_range(0.0, 0.3) = 0.055;
uniform float wind_speed : hint_range(0.0, 6.0) = 2.4;
uniform float wind_detail : hint_range(0.0, 10.0) = 2.8;

void vertex() {
	// Sanftes natürliches Flattern und Schwingen im Wind
	float wave = sin(TIME * wind_speed + VERTEX.x * wind_detail + VERTEX.z * 1.4);
	float wave_y = cos(TIME * wind_speed * 1.3 + VERTEX.y * wind_detail);
	VERTEX.x += wave * wind_strength;
	VERTEX.z += wave_y * (wind_strength * 0.7);
}

void fragment() {
	float ndotl = max(dot(NORMAL, vec3(0.4, 0.8, 0.4)), 0.0);
	vec3 col = mix(shadow_color.rgb, albedo_color.rgb, smoothstep(0.15, 0.65, ndotl));
	ALBEDO = col;
	ROUGHNESS = 0.85;
	METALLIC = 0.0;
}
