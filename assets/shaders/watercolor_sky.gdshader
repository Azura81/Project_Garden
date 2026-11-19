shader_type sky;

// Sanfter, warmer Aquarell-Himmel (helles Creme-Blau #D9E6E8 oben zu warmem Sonnen-Creme #FFF6E0 am Horizont)
uniform vec4 sky_top_color : source_color = vec4(0.81, 0.88, 0.93, 1.0);       // #D9E6E8 Helles Creme-Blau
uniform vec4 sky_horizon_color : source_color = vec4(1.0, 0.965, 0.878, 1.0);   // #FFF6E0 Warmes Sonnen-Creme
uniform vec4 sun_glow_color : source_color = vec4(1.0, 0.92, 0.78, 1.0);        // Sanfter Sonnen-Schimmer
uniform vec4 cloud_color : source_color = vec4(1.0, 0.99, 0.97, 0.88);          // Weiche gemalte Wolken
uniform vec4 cloud_shadow : source_color = vec4(0.85, 0.82, 0.88, 0.70);        // Pastellige Schattierung

uniform sampler2D paper_noise : filter_linear_mipmap, repeat_enable;
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.36;
uniform float cloud_softness : hint_range(0.01, 0.5) = 0.22;
uniform float time_speed = 0.004;

vec2 hash2_sky(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453123);
}

float sky_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = dot(hash2_sky(i + vec2(0.0, 0.0)) - 0.5, f - vec2(0.0, 0.0));
	float b = dot(hash2_sky(i + vec2(1.0, 0.0)) - 0.5, f - vec2(1.0, 0.0));
	float c = dot(hash2_sky(i + vec2(0.0, 1.0)) - 0.5, f - vec2(0.0, 1.0));
	float d = dot(hash2_sky(i + vec2(1.0, 1.0)) - 0.5, f - vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y) + 0.5;
}

float sky_fbm(vec2 p) {
	float v = 0.0;
	float a = 0.52;
	for (int i = 0; i < 4; i++) {
		v += a * sky_noise(p);
		p = p * 2.1 + vec2(1.7, 2.3);
		a *= 0.48;
	}
	return v;
}

void sky() {
	float elevation = clamp(EYEDIR.y, 0.0, 1.0);

	// 1. Sanfter Aquarell-Himmelsverlauf von #FFF6E0 am Horizont zu #D9E6E8 im Zenit
	vec3 sky_gradient = mix(sky_horizon_color.rgb, sky_top_color.rgb, pow(elevation, 0.65));

	// Subtiler goldener Sonnen-Schimmer
	float sun_factor = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
	float sun_glow = pow(sun_factor, 3.2);
	sky_gradient = mix(sky_gradient, sun_glow_color.rgb, sun_glow * 0.4);

	// 2. Weiche, gemalte Aquarell-Wolken
	if (EYEDIR.y > 0.02) {
		vec2 cloud_coords = (EYEDIR.xz / (EYEDIR.y + 0.28)) * 1.8 + vec2(TIME * time_speed, TIME * time_speed * 0.35);
		float fbm_val = sky_fbm(cloud_coords);
		
		float thresh = 1.0 - cloud_coverage;
		float clouds = smoothstep(thresh - cloud_softness, thresh, fbm_val);

		// Pastell-Schattierung auf der Wolkenunterseite
		float shade_val = smoothstep(thresh - cloud_softness * 0.5, thresh + 0.15, fbm_val);
		vec3 cloud_tint = mix(cloud_shadow.rgb, cloud_color.rgb, shade_val);

		// Sanfter Horizont-Schwund
		float horizon_fade = smoothstep(0.04, 0.22, elevation);
		sky_gradient = mix(sky_gradient, cloud_tint, clouds * horizon_fade * cloud_color.a);
	}

	COLOR = sky_gradient;
}
