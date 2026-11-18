extends Node3D

func _ready() -> void:
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	var root := Node3D.new()
	get_tree().root.add_child(root)

	# 1. World Environment & Warm Afternoon Sun (wie im Spiel)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.92, 0.89, 0.82)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.96, 0.92, 0.84)
	env.ambient_light_energy = 1.15
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_bloom = 0.12

	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)

	var light := DirectionalLight3D.new()
	light.light_color = Color(1.0, 0.95, 0.84)
	light.light_energy = 1.25
	light.shadow_enabled = true
	light.transform = Transform3D(Basis.from_euler(Vector3(-0.55, 0.65, 0.0)), Vector3(0, 5, 0))
	root.add_child(light)

	# 2. Shader vorbereiten
	var toon_shd: Shader = load("res://assets/shaders/toon_outline.gdshader")
	var outl_shd: Shader = load("res://assets/shaders/outline_pass.gdshader")

	# Material Petalen (Samtiges Rubinrot wie im Gemini-Bild)
	var mat_petals := ShaderMaterial.new()
	mat_petals.shader = toon_shd
	mat_petals.set_shader_parameter("base_color", Color(0.82, 0.14, 0.26))
	mat_petals.set_shader_parameter("gradient_color", Color(0.96, 0.30, 0.45))
	mat_petals.set_shader_parameter("shadow_color", Color(0.48, 0.06, 0.14))
	mat_petals.set_shader_parameter("rim_color", Color(1.0, 0.68, 0.78))
	mat_petals.set_shader_parameter("gradient_strength", 0.45)
	mat_petals.set_shader_parameter("gradient_min_y", 1.25)
	mat_petals.set_shader_parameter("gradient_max_y", 1.85)
	mat_petals.set_shader_parameter("facet_variation", 0.0)
	mat_petals.set_shader_parameter("rim_threshold", 0.55)
	mat_petals.set_shader_parameter("wind_strength", 0.03)

	var outl_petals := ShaderMaterial.new()
	outl_petals.shader = outl_shd
	outl_petals.set_shader_parameter("outline_color", Color(0.24, 0.03, 0.07))
	outl_petals.set_shader_parameter("outline_width", 0.007)
	mat_petals.next_pass = outl_petals

	# Material Stängel
	var mat_stem := ShaderMaterial.new()
	mat_stem.shader = toon_shd
	mat_stem.set_shader_parameter("base_color", Color(0.32, 0.54, 0.18))
	mat_stem.set_shader_parameter("gradient_color", Color(0.48, 0.72, 0.25))
	mat_stem.set_shader_parameter("shadow_color", Color(0.16, 0.28, 0.08))
	mat_stem.set_shader_parameter("rim_color", Color(0.75, 0.92, 0.5))
	mat_stem.set_shader_parameter("wind_strength", 0.04)

	var outl_stem := ShaderMaterial.new()
	outl_stem.shader = outl_shd
	outl_stem.set_shader_parameter("outline_color", Color(0.12, 0.18, 0.06))
	outl_stem.set_shader_parameter("outline_width", 0.014)
	mat_stem.next_pass = outl_stem

	# Material Blätter & Sepalen
	var mat_leaves := ShaderMaterial.new()
	mat_leaves.shader = toon_shd
	mat_leaves.set_shader_parameter("base_color", Color(0.28, 0.50, 0.16))
	mat_leaves.set_shader_parameter("gradient_color", Color(0.45, 0.68, 0.22))
	mat_leaves.set_shader_parameter("shadow_color", Color(0.14, 0.25, 0.07))
	mat_leaves.set_shader_parameter("rim_color", Color(0.72, 0.88, 0.48))
	mat_leaves.set_shader_parameter("wind_strength", 0.045)
	mat_leaves.next_pass = outl_stem

	# Material Dornen (rötlich-braun holzig)
	var mat_thorns := StandardMaterial3D.new()
	mat_thorns.albedo_color = Color(0.52, 0.22, 0.15)
	mat_thorns.roughness = 0.75

	# 3. Neue Ghibli-Rose laden & instanziieren
	var rose_mesh: ArrayMesh = load("res://assets/models/ghibli_rose.obj")
	var new_rose := MeshInstance3D.new()
	new_rose.mesh = rose_mesh
	root.add_child(new_rose)
	new_rose.position = Vector3(0.0, -0.65, 0.0)

	print("Anzahl Surfaces in ghibli_rose.obj: ", rose_mesh.get_surface_count())
	for s in range(rose_mesh.get_surface_count()):
		var s_name := rose_mesh.surface_get_name(s)
		print("Surface ", s, ": ", s_name)
		if s_name.begins_with("mat_petals") or s_name.begins_with("Petals") or s_name.begins_with("Bud"):
			new_rose.set_surface_override_material(s, mat_petals)
		elif s_name.begins_with("mat_thorns") or s_name.begins_with("Thorns"):
			new_rose.set_surface_override_material(s, mat_thorns)
		elif s_name.begins_with("mat_leaves") or s_name.begins_with("Leaves") or s_name.begins_with("Sepals"):
			new_rose.set_surface_override_material(s, mat_leaves)
		else:
			new_rose.set_surface_override_material(s, mat_stem)

	# 4. Kamera 1: Taktische Spiel-Perspektive (Leicht von oben auf die Blüte und den geschwungenen Stängel)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(0.65, 1.85, 1.75)
	cam.look_at(Vector3(-0.02, 1.15, 0.15), Vector3.UP)
	cam.current = true

	await get_tree().create_timer(0.4).timeout
	var img1 := get_viewport().get_texture().get_image()
	img1.save_png("C:/Users/maxri/Project_Garden/assets/screenshots/showcase_ghibli_rose_front.png")
	img1.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_ghibli_rose_front.png")

	# 5. Kamera 2: Direkter Blick in die samtige Blüten-Rosette (Vogelperspektive auf den Blütenkopf)
	cam.position = Vector3(0.1, 2.2, 0.85)
	cam.look_at(Vector3(0.0, 1.45, 0.22), Vector3.UP)
	await get_tree().create_timer(0.3).timeout
	var img2 := get_viewport().get_texture().get_image()
	img2.save_png("C:/Users/maxri/Project_Garden/assets/screenshots/showcase_ghibli_rose_closeup.png")
	img2.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_ghibli_rose_closeup.png")

	# 6. Kamera 3: Halbtotale mit Stängel, Dornen und Seitenknospe
	cam.position = Vector3(1.1, 1.1, 1.8)
	cam.look_at(Vector3(-0.1, 0.75, 0.0), Vector3.UP)
	await get_tree().create_timer(0.3).timeout
	var img3 := get_viewport().get_texture().get_image()
	img3.save_png("C:/Users/maxri/Project_Garden/assets/screenshots/showcase_ghibli_rose_angle.png")
	img3.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_ghibli_rose_angle.png")

	print("RenderGhibliRoseShowcase erfolgreich abgeschlossen!")
	get_tree().quit(0)
