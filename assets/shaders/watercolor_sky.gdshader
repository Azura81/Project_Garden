shader_type sky;

// Warmes Aquarell-Himmel-Panorama mit weichen, pastelligen Wolken & Papierkörnung
uniform vec4 sky_top_color : source_color = vec4(0.42, 0.64, 0.84, 1.0);       // Warmes Himmelblau (#6BA3D6)
uniform vec4 sky_horizon_color : source_color = vec4(0.96, 0.91, 0.82, 1.0);   // Warmes Horizont-Goldweiß (#F5E8D1)
uniform vec4 sun_glow_color : source_color = vec4(0.98, 0.84, 0.68, 1.0);      // Pfirsich/Gold-Sonnenlicht (#FAD6AD)
uniform vec4 cloud_color : source_color = vec4(1.0, 0.98, 0.94, 0.92);         // Helle weiche Wolken
uniform vec4 cloud_shadow : source_color = vec4(0.84, 0.79, 0.82, 0.85);       // Pastellige Wolkenschattierung

uniform sampler2D paper_noise : filter_linear_mipmap, repeat_enable;
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.44;
uniform float cloud_softness : hint_range(0.01, 0.5) = 0.24;
uniform float time_speed = 0.006;

void sky() {
	float elevation = clamp(EYEDIR.y, 0.0, 1.0);
	
	// 1. Sanfter Aquarell-Himmelsverlauf von warmem Goldweiß am Horizont zu sanftem Blau im Zenit
	vec3 sky_gradient = mix(sky_horizon_color.rgb, sky_top_color.rgb, pow(elevation, 0.62));
	
	// Subtiler goldener Sonnenglow
	float sun_factor = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
	float sun_glow = pow(sun_factor, 4.0);
	sky_gradient = mix(sky_gradient, sun_glow_color.rgb, sun_glow * 0.40);

	// 2. Weiche, pastellige Aquarell-Wolken
	if (EYEDIR.y > 0.01) {
		vec2 cloud_uv = (EYEDIR.xz / (EYEDIR.y + 0.38)) * 0.16 + vec2(TIME * time_speed, TIME * time_speed * 0.35);
		float c1 = texture(paper_noise, cloud_uv).r;
		float c2 = texture(paper_noise, cloud_uv * 2.3 + vec2(0.4, 0.6)).r;
		float combined = c1 * 0.65 + c2 * 0.35;
		
		float clouds = smoothstep(1.0 - cloud_coverage - cloud_softness, 1.0 - cloud_coverage, combined);
		
		// Sanfte Wolkenschattierung im Ghibli-/Bilderbuch-Stil
		float cloud_shading = smoothstep(0.35, 0.78, c2);
		vec3 cloud_tint = mix(cloud_shadow.rgb, cloud_color.rgb, cloud_shading);
		
		// Sanftes Ausblenden zum Horizont hin
		float horizon_fade = smoothstep(0.01, 0.22, elevation);
		sky_gradient = mix(sky_gradient, cloud_tint, clouds * horizon_fade * cloud_color.a);
	}

	COLOR = sky_gradient;
}
