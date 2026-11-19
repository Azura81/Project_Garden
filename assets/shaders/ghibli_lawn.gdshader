shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D grass_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap, repeat_enable;

// Sonniges, wolkiges Aquarell-Muster: Warmes Gelbgrün (#9AB365) und Salbeigrün (#6E8B4E)
uniform vec4 col_sunlit : source_color = vec4(0.604, 0.702, 0.396, 1.0); // #9AB365 Warmes Gelbgrün
uniform vec4 col_meadow : source_color = vec4(0.431, 0.545, 0.306, 1.0); // #6E8B4E Salbeigrün
uniform vec4 col_shadow : source_color = vec4(0.320, 0.420, 0.220, 1.0); // Sanftes Schattengrün

uniform vec2 uv_scale = vec2(60.0, 60.0);
uniform float macro_noise_scale = 0.22;
uniform float normal_scale : hint_range(0.0, 3.0) = 1.2;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = UV * uv_scale;
	vec4 tex = texture(grass_texture, uv);
	vec3 n_tex = texture(grass_normal, uv).rgb * 2.0 - 1.0;

	// Wolkige, organische Aquarell-Farbflecken auf der Wiese
	float n1 = sin(v_world_pos.x * macro_noise_scale) * cos(v_world_pos.z * macro_noise_scale * 0.9);
	float n2 = sin((v_world_pos.x * 0.8 + v_world_pos.z * 1.2) * macro_noise_scale * 1.6) * 0.4;
	float n3 = cos((v_world_pos.x * 1.4 - v_world_pos.z * 0.7) * macro_noise_scale * 2.2) * 0.25;

	float blend = clamp((n1 + n2 + n3) * 0.65 + 0.52, 0.0, 1.0);

	// Sanfte Sommerbrise-Welle
	float wind_wave = sin(v_world_pos.x * 0.08 + v_world_pos.z * 0.06 + TIME * 0.8) * 0.06;
	blend = clamp(blend + wind_wave, 0.0, 1.0);

	// Dreistufiger malerischer Aquarell-Farbverlauf
	vec3 tone = mix(col_shadow.rgb, col_meadow.rgb, smoothstep(0.0, 0.45, blend));
	tone = mix(tone, col_sunlit.rgb, smoothstep(0.40, 1.0, blend));

	// Papierkörnung & feine Gras-Struktur
	ALBEDO = tone * mix(vec3(0.92), tex.rgb * 1.4, 0.32);
	NORMAL_MAP = n_tex;
	NORMAL_MAP_DEPTH = normal_scale;
	ROUGHNESS = 0.90;
	SPECULAR = 0.04;
}
