shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Aquarell-Post-Processing & Pflanzen-Shader mit dezenten Konturen und weichen Verläufen
uniform vec4 base_color : source_color = vec4(0.85, 0.4, 0.45, 1.0);
uniform vec4 edge_color : source_color = vec4(0.35, 0.15, 0.2, 1.0);
uniform float roughness_val : hint_range(0.0, 1.0) = 0.8;
uniform float watercolor_softness : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	float fresnel = 1.0 - max(dot(NORMAL, VIEW), 0.0);
	float edge = smoothstep(1.0 - watercolor_softness, 1.0, fresnel);
	vec3 final_rgb = mix(base_color.rgb, edge_color.rgb, edge * 0.4);
	
	ALBEDO = final_rgb;
	ROUGHNESS = roughness_val;
	METALLIC = 0.05;
}
