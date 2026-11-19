shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_schlick_ggx;

// 3D-Beet & Aquarell-Umgebung: Lebendige Aquarell-Erde mit Feuchtigkeitsflecken & weichen Wegrändern
uniform vec4 base_color : source_color = vec4(0.58, 0.40, 0.24, 1.0);       // Warmes Ocker-Erdbraun (#94663D)
uniform vec4 shade_color : source_color = vec4(0.36, 0.22, 0.12, 1.0);      // Dunkles Umbra (#5C381F)
uniform vec4 moisture_color : source_color = vec4(0.20, 0.11, 0.06, 1.0);   // Nasse Erde / Feuchtigkeitsflecken (#331C0F)
uniform vec4 path_color : source_color = vec4(0.88, 0.76, 0.55, 1.0);       // Heller sandiger Weg (#E0C28C)
uniform vec4 ink_edge_color : source_color = vec4(0.231, 0.165, 0.118, 0.75); // Handgezeichnete Tusche

uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(3.5, 3.5);
uniform float noise_strength : hint_range(0.0, 1.0) = 0.55;
uniform float moisture_strength : hint_range(0.0, 1.0) = 0.75;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.95;
uniform bool is_path = false;

varying vec3 v_world_pos;
varying vec2 v_uv;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_uv = UV;
}

void fragment() {
	vec2 sample_uv1 = v_world_pos.xz * uv_scale * 0.10;
	vec2 sample_uv2 = v_world_pos.zx * uv_scale * 0.22 + vec2(0.35, 0.72);

	float n1 = texture(noise_texture, sample_uv1).r;
	float n2 = texture(noise_texture, sample_uv2).r;
	float gn1 = clamp((n1 - 0.82) / 0.17, 0.0, 1.0);
	float gn2 = clamp((n2 - 0.82) / 0.17, 0.0, 1.0);

	// Großflächige malerische Aquarell-Wolken (wie in ref_perspective_1.jpg)
	float w1 = sin(v_world_pos.x * 0.35) * cos(v_world_pos.z * 0.45);
	float w2 = sin((v_world_pos.x * 0.70 - v_world_pos.z * 0.50) * 0.65) * 0.45;
	float w3 = cos((v_world_pos.x * 0.40 + v_world_pos.z * 0.90) * 0.85) * 0.30;
	float macro_clouds = clamp((w1 + w2 + w3) * 0.60 + 0.50, 0.0, 1.0);

	// Kombination aus Makro-Farbflecken und Papierkörnung
	float combined_noise = mix(macro_clouds, gn1, 0.35);

	vec3 wash;

	if (is_path) {
		// Weg: Sandiger heller Kern, der zu den Rändern weich in die Beeterde ausfranst
		float pigment = smoothstep(0.20, 0.80, combined_noise);
		vec3 sand_wash = mix(path_color.rgb * 0.92, path_color.rgb * 1.08, pigment);
		vec3 edge_soil = mix(shade_color.rgb, base_color.rgb, pigment);
		
		// In CSGPolygon3D mit mode 2 (Path) ist v_uv.y der Querschnitt von 0.0 bis 1.0
		float cross_dist = abs(v_uv.y - 0.5) * 2.0;
		
		// Organisches Aquarell-Ausfransen am Rand (weicher Übergang in die Beeterde)
		float bleed = (macro_clouds - 0.50) * 0.35;
		float edge_mix = smoothstep(0.35 + bleed, 0.90 + bleed, cross_dist);
		
		wash = mix(sand_wash, edge_soil, edge_mix);
	} else {
		// Beeterde: Lebendige Aquarell-Schattierungen mit wolkigen Nässeflecken und Ocker-Nuancen
		float pigment_flow = smoothstep(0.25, 0.75, combined_noise);
		wash = mix(shade_color.rgb, base_color.rgb, pigment_flow);

		// Nasse Erde / Feuchtigkeitsflecken unter Pflanzplätzen und am Beetrand
		vec2 s1 = vec2(-6.0, 1.2);
		vec2 s2 = vec2(-1.5, -1.8);
		vec2 s3 = vec2(2.5, 2.2);
		vec2 s4 = vec2(6.5, -0.6);
		float d_spots = min(min(length(v_world_pos.xz - s1), length(v_world_pos.xz - s2)),
		                    min(length(v_world_pos.xz - s3), length(v_world_pos.xz - s4)));
		float spot_moist = smoothstep(3.2, 0.7, d_spots) * 0.55;
		float border_moist = smoothstep(4.8, 6.2, abs(v_world_pos.z)) * 0.35;
		float moist_puddle = smoothstep(0.58, 0.85, macro_clouds) * 0.40;
		float total_moist = clamp(spot_moist + border_moist + moist_puddle, 0.0, 1.0);

		wash = mix(wash, moisture_color.rgb, total_moist * moisture_strength);

		// Sanfter dunkler Aquarell-Tuscherand um Pigmentpfützen
		float wet_rim = smoothstep(0.50, 0.54, macro_clouds) * smoothstep(0.60, 0.55, macro_clouds);
		wash = mix(wash, ink_edge_color.rgb * 0.75, wet_rim * 0.25);
	}

	// Papierkörnung & Granulierung
	wash *= (0.88 + 0.22 * gn2);

	ALBEDO = wash;
	ROUGHNESS = roughness_val;
	METALLIC = 0.0;
	SPECULAR = 0.02;
}

void light() {
	float ndotl = dot(NORMAL, LIGHT);
	float att = ATTENUATION;
	float light_intensity = clamp(ndotl, 0.0, 1.0) * att;
	
	// Sanfter Cel-Übergang mit warmem Schattenton
	float cel_step = smoothstep(0.12, 0.35, light_intensity);
	vec3 shade_tint = mix(shade_color.rgb * 1.05, vec3(1.0), cel_step);
	
	DIFFUSE_LIGHT += LIGHT_COLOR * shade_tint * ALBEDO * att;
}
