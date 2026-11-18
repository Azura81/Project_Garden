shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled;

// Bildschirmweiter Tusche-Kanten-Shader (Post-Processing Edge Detection)
// Zeichnet feine Tuschelinien (#2B2118, ~1.5 - 2px) um 3D-Geometrie, Kanten und Konturen
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;

uniform vec4 ink_color : source_color = vec4(0.169, 0.129, 0.094, 1.0); // #2B2118
uniform float line_thickness : hint_range(0.5, 4.0) = 1.6;
uniform float depth_threshold : hint_range(0.001, 0.1) = 0.012;
uniform float color_threshold : hint_range(0.01, 0.5) = 0.09;
uniform float ink_strength : hint_range(0.0, 1.0) = 0.90;

void vertex() {
	// Fullscreen Quad im NDC-Raum
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float get_depth(vec2 uv, mat4 inv_proj) {
	float raw_depth = texture(depth_texture, uv).r;
	vec4 upos = inv_proj * vec4(uv * 2.0 - 1.0, raw_depth, 1.0);
	return -upos.z / upos.w;
}

float get_luminance(vec3 col) {
	return dot(col, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 texel = (1.0 / VIEWPORT_SIZE) * line_thickness;
	vec3 base_col = texture(screen_texture, SCREEN_UV).rgb;
	
	// 1. Depth-Edge (Silhouetten von Haus, Veranda, Zaun, BÃ¤umen, Steinen, Beetbalken)
	float d_c = get_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	float d_l = get_depth(SCREEN_UV - vec2(texel.x, 0.0), INV_PROJECTION_MATRIX);
	float d_r = get_depth(SCREEN_UV + vec2(texel.x, 0.0), INV_PROJECTION_MATRIX);
	float d_u = get_depth(SCREEN_UV - vec2(0.0, texel.y), INV_PROJECTION_MATRIX);
	float d_d = get_depth(SCREEN_UV + vec2(0.0, texel.y), INV_PROJECTION_MATRIX);
	
	float depth_edge = 0.0;
	if (d_c < 150.0) {
		float d_diff_x = abs(d_r - d_l);
		float d_diff_y = abs(d_d - d_u);
		float max_d_diff = max(d_diff_x, d_diff_y);
		float thresh = depth_threshold * max(1.0, d_c * 0.12);
		depth_edge = smoothstep(thresh, thresh * 1.8, max_d_diff);
	}
	
	// 2. Color / Luminance Sobel (Feldsteine, Holzplanken, Kanten, Pfadbegrenzung)
	float l_l = get_luminance(texture(screen_texture, SCREEN_UV - vec2(texel.x, 0.0)).rgb);
	float l_r = get_luminance(texture(screen_texture, SCREEN_UV + vec2(texel.x, 0.0)).rgb);
	float l_u = get_luminance(texture(screen_texture, SCREEN_UV - vec2(0.0, texel.y)).rgb);
	float l_d = get_luminance(texture(screen_texture, SCREEN_UV + vec2(0.0, texel.y)).rgb);
	
	// Diagonale Taps fÃ¼r saubere runde Konturen
	float l_ul = get_luminance(texture(screen_texture, SCREEN_UV + vec2(-texel.x, -texel.y)).rgb);
	float l_ur = get_luminance(texture(screen_texture, SCREEN_UV + vec2(texel.x, -texel.y)).rgb);
	float l_dl = get_luminance(texture(screen_texture, SCREEN_UV + vec2(-texel.x, texel.y)).rgb);
	float l_dr = get_luminance(texture(screen_texture, SCREEN_UV + vec2(texel.x, texel.y)).rgb);
	
	float sx = (l_ur + 2.0 * l_r + l_dr) - (l_ul + 2.0 * l_l + l_dl);
	float sy = (l_dl + 2.0 * l_d + l_dr) - (l_ul + 2.0 * l_u + l_ur);
	float sobel = sqrt(sx * sx + sy * sy);
	float color_edge = smoothstep(color_threshold, color_threshold * 2.0, sobel);
	
	// 3. Tuschekante zusammenfÃ¼hren
	float edge = clamp(depth_edge + color_edge * 0.85, 0.0, 1.0) * ink_strength;
	
	ALBEDO = mix(base_col, ink_color.rgb, edge);
}
