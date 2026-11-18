shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D grass_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap, repeat_enable;

// Two-tone warm Ghibli meadow palette
uniform vec4 col_sunlit : source_color = vec4(0.54, 0.74, 0.28, 1.0);
uniform vec4 col_meadow : source_color = vec4(0.36, 0.56, 0.22, 1.0);

uniform vec2 uv_scale = vec2(70.0, 70.0);
uniform float macro_noise_scale = 0.035;
uniform float normal_scale : hint_range(0.0, 3.0) = 1.4;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = UV * uv_scale;
	vec4 tex = texture(grass_texture, uv);
	vec3 n_tex = texture(grass_normal, uv).rgb * 2.0 - 1.0;
	
	// World-space organic macro color blending (breaks tiling repetition)
	float n1 = sin(v_world_pos.x * macro_noise_scale) * cos(v_world_pos.z * macro_noise_scale * 0.85);
	float n2 = sin((v_world_pos.x + v_world_pos.z) * macro_noise_scale * 1.5) * 0.35;
	float blend = clamp((n1 + n2) * 0.6 + 0.5, 0.0, 1.0);
	
	// Soft wind wave rolling across the meadow
	float wind_wave = sin(v_world_pos.x * 0.1 + v_world_pos.z * 0.08 + TIME * 1.2) * 0.07;
	blend = clamp(blend + wind_wave, 0.0, 1.0);
	
	vec3 tone = mix(col_meadow.rgb, col_sunlit.rgb, blend);
	
	ALBEDO = tone * mix(vec3(1.0), tex.rgb * 1.6, 0.4);
	NORMAL_MAP = n_tex;
	NORMAL_MAP_DEPTH = normal_scale;
	ROUGHNESS = 0.85;
	SPECULAR = 0.12;
}
