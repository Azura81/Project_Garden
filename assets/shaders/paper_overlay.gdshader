shader_type canvas_item;

// Globales Aquarellpapier-Overlay (Multiplikative KÃ¶rnung + helle BÃ¼ttenpapier-Vignette)
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D paper_grain_tex : filter_linear_mipmap, repeat_enable;
uniform vec2 paper_scale = vec2(3.0, 1.7);
uniform float grain_intensity : hint_range(0.0, 1.0) = 0.22;
uniform vec4 paper_color : source_color = vec4(0.985, 0.972, 0.941, 1.0); // Warmes Naturpapier
uniform float vignette_start : hint_range(0.0, 1.0) = 0.42;
uniform float vignette_end : hint_range(0.0, 1.0) = 0.72;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.48;

void fragment() {
	vec3 base_screen = texture(screen_texture, SCREEN_UV).rgb;
	
	// 1. Texturierte PapierkÃ¶rnung
	vec3 paper_sample = texture(paper_grain_tex, UV * paper_scale).rgb;
	vec3 grain_wash = mix(vec3(1.0), paper_sample * paper_color.rgb, grain_intensity);
	
	// Multiplikativer Blend (Aquarell zieht ins Papier ein)
	vec3 final_rgb = base_screen * grain_wash;
	
	// 2. Weiche, helle Papier-Vignette am Bildschirmrand (Diorama-/Buch-Rahmen)
	vec2 uv_offset = (UV - vec2(0.5)) * vec2(1.1, 1.0);
	float dist = length(uv_offset);
	float vig = smoothstep(vignette_start, vignette_end, dist) * vignette_strength;
	
	final_rgb = mix(final_rgb, paper_color.rgb, vig);
	
	COLOR = vec4(final_rgb, 1.0);
}
