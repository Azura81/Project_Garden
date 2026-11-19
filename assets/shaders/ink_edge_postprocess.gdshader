shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled;

// Bildschirmweiter Tusche-Kanten-Shader (Post-Processing Edge Detection)
// Weiches, warmes Dunkelbraun (#3B2A1E mit 75% Deckkraft) wie eine handgezeichnete Tuschefeder
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;

uniform vec4 ink_color : source_color = vec4(0.231, 0.165, 0.118, 0.75); // #3B2A1E Warmes Dunkelbraun
uniform float line_thickness : hint_range(0.5, 4.0) = 1.4;
uniform float depth_threshold : hint_range(0.001, 0.2) = 0.045;
uniform float color_threshold : hint_range(0.01, 0.5) = 0.22;
uniform float ink_strength : hint_range(0.0, 1.0) = 0.75;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

vec3 get_view_pos(vec2 uv, mat4 inv_proj) {
	float raw_depth = texture(depth_texture, uv).r;
	vec4 upos = inv_proj * vec4(uv * 2.0 - 1.0, raw_depth, 1.0);
	return upos.xyz / upos.w;
}

float get_luminance(vec3 col) {
	return dot(col, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 texel = (1.0 / VIEWPORT_SIZE) * line_thickness;
	vec3 base_col = texture(screen_texture, SCREEN_UV).rgb;

	// View-Space Positionen für Normalen- und Tiefenberechnung
	vec3 p_c = get_view_pos(SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 p_r = get_view_pos(SCREEN_UV + vec2(texel.x, 0.0), INV_PROJECTION_MATRIX);
	vec3 p_l = get_view_pos(SCREEN_UV - vec2(texel.x, 0.0), INV_PROJECTION_MATRIX);
	vec3 p_d = get_view_pos(SCREEN_UV + vec2(0.0, texel.y), INV_PROJECTION_MATRIX);
	vec3 p_u = get_view_pos(SCREEN_UV - vec2(0.0, texel.y), INV_PROJECTION_MATRIX);

	// Oberflächen-Normale im View- und World-Space
	vec3 v_norm = normalize(cross(p_r - p_l, p_d - p_u));
	vec3 w_norm = (INV_VIEW_MATRIX * vec4(v_norm, 0.0)).xyz;

	// 1. Depth-Edge (Silhouetten von Haus, Veranda, Zaun, Bäumen, Steinen, Beetbalken)
	float d_c = -p_c.z;
	float depth_edge = 0.0;

	// Horizontale Bodenflächen (Wiese, Beeterde, Pfad: w_norm.y > 0.80) ausschließen,
	// um Tiefen-Banding und horizontale Streifen bei flachem Kamerawinkel komplett zu eliminieren!
	if (w_norm.y < 0.80 && d_c < 180.0) {
		float d_diff_x = max(abs(p_r.z - p_c.z), abs(p_l.z - p_c.z));
		float d_diff_y = max(abs(p_d.z - p_c.z), abs(p_u.z - p_c.z));
		float max_d_diff = max(d_diff_x, d_diff_y);

		// Blickwinkel-Kompensation gegen False-Positives
		float n_dot_v = max(abs(dot(v_norm, normalize(-p_c))), 0.08);
		float thresh = depth_threshold * (1.0 + d_c * 0.06) / n_dot_v;
		depth_edge = smoothstep(thresh, thresh * 2.0, max_d_diff);
	}

	// 2. Color / Luminance Sobel für Objektkonturen & Materialgrenzen
	float l_l = get_luminance(texture(screen_texture, SCREEN_UV - vec2(texel.x, 0.0)).rgb);
	float l_r = get_luminance(texture(screen_texture, SCREEN_UV + vec2(texel.x, 0.0)).rgb);
	float l_u = get_luminance(texture(screen_texture, SCREEN_UV - vec2(0.0, texel.y)).rgb);
	float l_d = get_luminance(texture(screen_texture, SCREEN_UV + vec2(0.0, texel.y)).rgb);

	float l_ul = get_luminance(texture(screen_texture, SCREEN_UV + vec2(-texel.x, -texel.y)).rgb);
	float l_ur = get_luminance(texture(screen_texture, SCREEN_UV + vec2(texel.x, -texel.y)).rgb);
	float l_dl = get_luminance(texture(screen_texture, SCREEN_UV + vec2(-texel.x, texel.y)).rgb);
	float l_dr = get_luminance(texture(screen_texture, SCREEN_UV + vec2(texel.x, texel.y)).rgb);

	float sx = (l_ur + 2.0 * l_r + l_dr) - (l_ul + 2.0 * l_l + l_dl);
	float sy = (l_dl + 2.0 * l_d + l_dr) - (l_ul + 2.0 * l_u + l_ur);
	float sobel = sqrt(sx * sx + sy * sy);
	float color_edge = smoothstep(color_threshold, color_threshold * 2.2, sobel);

	// 3. Tuschekante zusammenführen (weiches Warmbraun #3B2A1E mit sanfter Deckkraft)
	float edge = clamp(depth_edge + color_edge * 0.75, 0.0, 1.0) * ink_strength;

	ALBEDO = mix(base_col, ink_color.rgb, edge * ink_color.a);
}
