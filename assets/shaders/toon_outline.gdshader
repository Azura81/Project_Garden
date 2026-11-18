shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_toon, specular_disabled;

// Toon- & Aquarell-Shader mit weichem Farbverlauf (matte Papier-Ästhetik ohne Glitzer)
uniform vec4 base_color : source_color = vec4(0.85, 0.18, 0.35, 1.0);
uniform vec4 gradient_color : source_color = vec4(0.98, 0.45, 0.62, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.48, 0.08, 0.2, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.65, 0.78, 1.0);

uniform float gradient_strength : hint_range(0.0, 1.0) = 0.65;
uniform float gradient_min_y = 0.0;
uniform float gradient_max_y = 1.6;

uniform float facet_variation : hint_range(0.0, 0.4) = 0.0;
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.85;
uniform float wind_strength : hint_range(0.0, 0.2) = 0.035;
uniform float wind_speed : hint_range(0.0, 5.0) = 2.2;

uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

varying float v_y;
varying vec3 v_normal;

void vertex() {
	v_y = VERTEX.y;
	v_normal = NORMAL;
	
	// Sanftes, organisches Wiegen im Wind (oben stärker als an der Wurzel)
	float height_factor = clamp(VERTEX.y * 0.5, 0.0, 1.0);
	float sway = sin(TIME * wind_speed + VERTEX.y * 1.5) * wind_strength * height_factor;
	VERTEX.x += sway;
	VERTEX.z += cos(TIME * wind_speed * 0.8 + VERTEX.y) * wind_strength * 0.6 * height_factor;
}

void fragment() {
	// 1. Natürlicher Farbverlauf entlang der Höhe
	float t = clamp((v_y - gradient_min_y) / max(gradient_max_y - gradient_min_y, 0.01), 0.0, 1.0);
	vec3 grad_rgb = mix(base_color.rgb, gradient_color.rgb, t * gradient_strength);
	
	ALBEDO = mix(grad_rgb, flash_color.rgb, hit_flash);
	EMISSION = flash_color.rgb * (hit_flash * 0.75);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}

void light() {
	// 2-Stufen Toon-Cel-Shading
	float NdotL = dot(NORMAL, LIGHT);
	float light_step = smoothstep(-0.1, 0.18, NdotL);
	
	vec3 light_col = mix(shadow_color.rgb, LIGHT_COLOR.rgb, light_step);
	DIFFUSE_LIGHT += light_col * ATTENUATION * ALBEDO;
}
