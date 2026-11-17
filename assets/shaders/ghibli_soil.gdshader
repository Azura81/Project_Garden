shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D soil_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D soil_normal : hint_normal, filter_linear_mipmap, repeat_enable;

uniform vec4 soil_warm_tint : source_color = vec4(0.95, 0.90, 0.85, 1.0);
uniform vec4 soil_moist_tint : source_color = vec4(0.70, 0.62, 0.55, 1.0);

uniform vec2 uv_scale = vec2(10.0, 5.0);
uniform float normal_depth : hint_range(0.0, 3.0) = 1.8;
uniform float wetness_factor : hint_range(0.0, 1.0) = 0.45;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = UV * uv_scale;
	vec4 tex = texture(soil_texture, uv);
	vec3 n_tex = texture(soil_normal, uv).rgb * 2.0 - 1.0;
	
	// Darker, richer moisture around wooden border edges
	float edge_dist_x = abs(v_world_pos.x) / 16.0;
	float edge_dist_z = abs(v_world_pos.z) / 8.0;
	float edge_factor = smoothstep(0.65, 0.98, max(edge_dist_x, edge_dist_z));
	
	// Gentle organic patches of richer loam
	float patch_noise = (sin(v_world_pos.x * 0.4) * cos(v_world_pos.z * 0.6) + 1.0) * 0.5;
	float moist_blend = clamp(edge_factor * 0.6 + patch_noise * wetness_factor, 0.0, 1.0);
	
	vec3 tint = mix(soil_warm_tint.rgb, soil_moist_tint.rgb, moist_blend);
	
	ALBEDO = tex.rgb * tint;
	NORMAL_MAP = n_tex;
	NORMAL_MAP_DEPTH = normal_depth;
	
	// Moist soil has a gentle sheen in the sunlight
	ROUGHNESS = mix(0.90, 0.68, moist_blend);
	SPECULAR = mix(0.08, 0.28, moist_blend);
}
