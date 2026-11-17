extends Node3D

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	var rose_scene: PackedScene = load("res://scenes/towers/ThornRose.tscn")
	var colors = [
		{"name": "Rot", "base": Color(0.82, 0.16, 0.32, 1.0), "grad": Color(0.98, 0.44, 0.62, 1.0), "shadow": Color(0.45, 0.08, 0.18, 1.0), "rim": Color(1.0, 0.65, 0.78, 1.0), "outline": Color(0.26, 0.04, 0.1, 1.0)},
		{"name": "Gelb", "base": Color(0.94, 0.72, 0.12, 1.0), "grad": Color(1.0, 0.92, 0.42, 1.0), "shadow": Color(0.62, 0.42, 0.06, 1.0), "rim": Color(1.0, 0.96, 0.68, 1.0), "outline": Color(0.32, 0.2, 0.03, 1.0)},
		{"name": "Violett", "base": Color(0.64, 0.2, 0.76, 1.0), "grad": Color(0.86, 0.5, 0.96, 1.0), "shadow": Color(0.36, 0.08, 0.44, 1.0), "rim": Color(0.94, 0.72, 1.0, 1.0), "outline": Color(0.2, 0.05, 0.26, 1.0)},
		{"name": "Blau", "base": Color(0.18, 0.44, 0.86, 1.0), "grad": Color(0.45, 0.74, 1.0, 1.0), "shadow": Color(0.08, 0.22, 0.52, 1.0), "rim": Color(0.68, 0.88, 1.0, 1.0), "outline": Color(0.05, 0.12, 0.3, 1.0)},
		{"name": "Orange", "base": Color(0.92, 0.38, 0.12, 1.0), "grad": Color(1.0, 0.68, 0.34, 1.0), "shadow": Color(0.58, 0.2, 0.05, 1.0), "rim": Color(1.0, 0.82, 0.58, 1.0), "outline": Color(0.32, 0.1, 0.02, 1.0)}
	]
	
	for i in range(colors.size()):
		var rose := rose_scene.instantiate() as Node3D
		$ModelRoot.add_child(rose)
		rose.position = Vector3(float(i - 2) * 1.05, 0, 0)
		
		# Override theme explicitly
		var theme = colors[i]
		var mesh_node: MeshInstance3D = rose.get_node_or_null("FacetedRoseMesh")
		if mesh_node:
			var mat_orig := mesh_node.get_surface_override_material(2)
			if mat_orig and mat_orig is ShaderMaterial:
				var mat_dup: ShaderMaterial = mat_orig.duplicate(true)
				mat_dup.set_shader_parameter("base_color", theme["base"])
				mat_dup.set_shader_parameter("gradient_color", theme["grad"])
				mat_dup.set_shader_parameter("shadow_color", theme["shadow"])
				mat_dup.set_shader_parameter("rim_color", theme["rim"])
				if mat_dup.next_pass and mat_dup.next_pass is ShaderMaterial:
					var outl_dup: ShaderMaterial = mat_dup.next_pass.duplicate(true)
					outl_dup.set_shader_parameter("outline_color", theme["outline"])
					mat_dup.next_pass = outl_dup
				mesh_node.set_surface_override_material(2, mat_dup)

	$Camera3D.position = Vector3(0, 1.3, 3.8)
	$Camera3D.look_at(Vector3(0, 1.05, 0))
	
	await get_tree().create_timer(0.4).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_rose_palette.png")
	get_tree().quit()
