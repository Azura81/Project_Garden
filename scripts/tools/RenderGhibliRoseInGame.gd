extends Node3D

func _ready() -> void:
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	var lvl_scene: PackedScene = load("res://scenes/levels/Level_01.tscn")
	var lvl := lvl_scene.instantiate() as Node3D
	get_tree().root.add_child(lvl)

	# Pflanze die neue Ghibli-Rose auf Spot 1
	var spot1: TowerSpot = lvl.get_node_or_null("TowerSpots/TowerSpot_1")
	var rose_mesh: ArrayMesh = load("res://assets/models/ghibli_rose.obj")
	var toon_shd: Shader = load("res://assets/shaders/toon_outline.gdshader")
	var outl_shd: Shader = load("res://assets/shaders/outline_pass.gdshader")

	var mat_petals := ShaderMaterial.new()
	mat_petals.shader = toon_shd
	mat_petals.set_shader_parameter("base_color", Color(0.82, 0.14, 0.26))
	mat_petals.set_shader_parameter("gradient_color", Color(0.96, 0.32, 0.45))
	mat_petals.set_shader_parameter("shadow_color", Color(0.48, 0.06, 0.14))
	mat_petals.set_shader_parameter("rim_color", Color(1.0, 0.65, 0.75))
	mat_petals.set_shader_parameter("gradient_strength", 0.45)
	mat_petals.set_shader_parameter("gradient_min_y", 1.25)
	mat_petals.set_shader_parameter("gradient_max_y", 1.85)
	mat_petals.set_shader_parameter("facet_variation", 0.0)

	var mat_stem := ShaderMaterial.new()
	mat_stem.shader = toon_shd
	mat_stem.set_shader_parameter("base_color", Color(0.32, 0.54, 0.18))
	mat_stem.set_shader_parameter("gradient_color", Color(0.48, 0.72, 0.25))
	mat_stem.set_shader_parameter("shadow_color", Color(0.16, 0.28, 0.08))

	var mat_thorns := StandardMaterial3D.new()
	mat_thorns.albedo_color = Color(0.52, 0.22, 0.15)

	if spot1 and rose_mesh:
		var rose_inst := MeshInstance3D.new()
		rose_inst.mesh = rose_mesh
		for s in range(rose_mesh.get_surface_count()):
			var s_name := rose_mesh.surface_get_name(s)
			if s_name.begins_with("mat_petals") or s_name.begins_with("Petals") or s_name.begins_with("Bud"):
				rose_inst.set_surface_override_material(s, mat_petals)
			elif s_name.begins_with("mat_thorns") or s_name.begins_with("Thorns"):
				rose_inst.set_surface_override_material(s, mat_thorns)
			else:
				rose_inst.set_surface_override_material(s, mat_stem)
		spot1.add_child(rose_inst)
		spot1.current_plant = rose_inst
		spot1._update_visual_state()

	# Kamera auf Spot 1 fokussieren
	var cam: Camera3D = lvl.get_node_or_null("CameraRig/Camera3D")
	var cam_rig: CameraRig = lvl.get_node_or_null("CameraRig")
	if cam:
		cam.current = true
	if cam_rig and spot1:
		cam_rig._on_spot_selected(spot1)

	await get_tree().create_timer(0.6).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("C:/Users/maxri/Project_Garden/assets/screenshots/showcase_ghibli_rose_in_game.png")
	img.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_ghibli_rose_in_game.png")

	print("RenderGhibliRoseInGame abgeschlossen!")
	get_tree().quit(0)
