shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_schlick_ggx;

// 3D-Beet & Aquarell-Umgebung: Lebendige Aquarell-Erde mit Feuchtigkeitsflecken & weichen Wegrändern
uniform vec4 base_color : source_color = vec4(0.55, 0.38, 0.22, 1.0);       // Warmes Erdbraun (#8C6138)
uniform vec4 shade_color : source_color = vec4(0.36, 0.22, 0.12, 1.0);      // Dunkles Umbra (#5C381F)
uniform vec4 moisture_color : source_color = vec4(0.20, 0.11, 0.06, 1.0);   // Nasse Erde / Feuchtigkeitsflecken (#331C0F)
uniform vec4 path_color : source_color = vec4(0.85, 0.72, 0.52, 1.0);       // Heller sandiger Weg (#D9B885)
uniform vec4 ink_edge_color : source_color = vec4(0.169, 0.129, 0.094, 1.0); // #2B2118 Tusche

uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(3.5, 3.5);
uniform float noise_strength : hint_range(0.0, 1.0) = 0.45;
uniform float moisture_strength : hint_range(0.0, 1.0) = 0.70;
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
	float combined_noise = mix(n1, n2, 0.4);

	vec3 wash;

	if (is_path) {
		// Weg: Sandiger heller Kern, der zu den Rändern weich in die Beeterde ausfranst
		float pigment = smoothstep(0.2, 0.8, combined_noise);
		vec3 sand_wash = mix(path_color.rgb * 0.92, path_color.rgb * 1.08, pigment);
		vec3 edge_soil = mix(shade_color.rgb, base_color.rgb, pigment);
		
		// In CSGPolygon3D mit mode 2 (Path) ist v_uv.y der Querschnitt von 0.0 bis 1.0
		float cross_dist = abs(v_uv.y - 0.5) * 2.0;
		
		// Organisches Aquarell-Ausfransen am Rand (weicher Übergang in die Beeterde)
		float bleed = (combined_noise - 0.5) * 0.35;
		float edge_mix = smoothstep(0.40 + bleed, 0.95 + bleed, cross_dist);
		
		wash = mix(sand_wash, edge_soil, edge_mix);
	} else {
		// Beeterde: Lebendige Aquarell-Schattierungen mit wolkigen Nässeflecken und Ocker-Nuancen
		float pigment_flow = smoothstep(0.20, 0.78, combined_noise);
		wash = mix(shade_color.rgb, base_color.rgb, pigment_flow);

		// Feuchtigkeitsflecken (dunklere, feuchte Erde wie im Referenzbild)
		float moisture_mask = smoothstep(0.48, 0.82, n1 * 0.65 + (1.0 - n2) * 0.35);
		float wet_rim = smoothstep(0.46, 0.50, n1) * smoothstep(0.55, 0.50, n1);
		wash = mix(wash, moisture_color.rgb, moisture_mask * moisture_strength);
		wash = mix(wash, ink_edge_color.rgb * 0.75, wet_rim * 0.30);
	}

	// Papierkörnung & Granulierung
	wash *= (0.86 + 0.28 * n2);

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
