shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_schlick_ggx;

// 3D-Beet & Aquarell-Umgebung: Weiches Cel-Shading, Noise-Farbauftrag und Tusche-Kanten
// Exakte Referenz-Farbpalette: Ocker/Sandbraun (#C8A27A / #8C6239), Tusche (#2B2118)
uniform vec4 base_color : source_color = vec4(0.784, 0.635, 0.478, 1.0);     // #C8A27A Warmes Ocker
uniform vec4 shade_color : source_color = vec4(0.549, 0.384, 0.224, 1.0);    // #8C6239 Sandbraun
uniform vec4 ink_edge_color : source_color = vec4(0.169, 0.129, 0.094, 1.0); // #2B2118 Dunkle Tusche

uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(3.5, 3.5);
uniform float noise_strength : hint_range(0.0, 1.0) = 0.38;
uniform float ink_edge_threshold : hint_range(0.0, 1.0) = 0.68;
uniform float ink_edge_strength : hint_range(0.0, 1.0) = 0.82;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.95;
uniform bool use_world_coords = true;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 sample_uv = use_world_coords ? (v_world_pos.xz * uv_scale * 0.12) : (UV * uv_scale);
	float n = texture(noise_texture, sample_uv).r;
	
	// Organischer Aquarell-Verlauf mit Pigment-Pools (Drying Edges)
	float pigment_flow = smoothstep(0.2, 0.78, n);
	vec3 wash = mix(shade_color.rgb, base_color.rgb, pigment_flow);
	
	// PapierkÃ¶rnung & Granulierung
	wash *= (0.85 + 0.28 * n);

	// Tusche-Kontur am Rand (Fresnel & KrÃ¼mmungskanten)
	float fresnel = 1.0 - max(dot(NORMAL, VIEW), 0.0);
	float ink = smoothstep(ink_edge_threshold, 1.0, fresnel) * ink_edge_strength;
	
	ALBEDO = mix(wash, ink_edge_color.rgb, ink);
	ROUGHNESS = roughness_val;
	METALLIC = 0.0;
	SPECULAR = 0.04;
}

void light() {
	float ndotl = dot(NORMAL, LIGHT);
	float att = ATTENUATION;
	float light_intensity = clamp(ndotl, 0.0, 1.0) * att;
	
	// Sanfter Aquarell-Cel-Ãœbergang
	float cel_step = smoothstep(0.12, 0.32, light_intensity);
	vec3 shade_tint = mix(shade_color.rgb * 1.1, vec3(1.0), cel_step);
	
	DIFFUSE_LIGHT += LIGHT_COLOR * shade_tint * ALBEDO * att;
}
