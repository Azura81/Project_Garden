shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

// Kombinierter Toon- & Aquarell-Shader mit weichen Farbstufen
uniform vec4 base_color : source_color = vec4(0.9, 0.22, 0.38, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.55, 0.1, 0.24, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.6, 0.7, 1.0);
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.55;
uniform float wind_strength : hint_range(0.0, 0.2) = 0.04;
uniform float wind_speed : hint_range(0.0, 5.0) = 2.2;

void vertex() {
	// Sanftes, organisches Wiegen im Wind (oben stärker als an der Wurzel)
	float height_factor = clamp(VERTEX.y * 0.5, 0.0, 1.0);
	float sway = sin(TIME * wind_speed + VERTEX.y * 1.5) * wind_strength * height_factor;
	VERTEX.x += sway;
	VERTEX.z += cos(TIME * wind_speed * 0.8 + VERTEX.y) * wind_strength * 0.6 * height_factor;
}

void fragment() {
	// Weicher Farbverlauf & Rim-Glow an den Kanten
	float fresnel = 1.0 - max(dot(NORMAL, VIEW), 0.0);
	float rim = smoothstep(1.0 - rim_threshold, 1.0, fresnel);
	
	vec3 col = base_color.rgb;
	col = mix(col, rim_color.rgb, rim * 0.35);
	
	ALBEDO = col;
	ROUGHNESS = 0.85;
	METALLIC = 0.0;
}

void light() {
	// 2-Stufen Toon-Cel-Shading
	float NdotL = dot(NORMAL, LIGHT);
	float light_step = smoothstep(-0.1, 0.15, NdotL);
	
	vec3 light_col = mix(shadow_color.rgb, LIGHT_COLOR.rgb, light_step);
	DIFFUSE_LIGHT += light_col * ATTENUATION * ALBEDO;
}
