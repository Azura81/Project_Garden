extends Node

func _ready() -> void:
	print("Applying Ghibli Lawn & Soil Materials...")
	_apply_lawn_material()
	_apply_soil_material()
	_apply_towerspot_material()
	print("All terrain materials applied successfully!")
	get_tree().quit()

func _apply_lawn_material() -> void:
	var path := "res://scenes/environment/GardenBackdrop.tscn"
	var scene: PackedScene = load(path)
	var root: Node3D = scene.instantiate()
	
	var meadow_node: MeshInstance3D = root.get_node_or_null("Meadow")
	if meadow_node:
		var lawn_shader: Shader = load("res://assets/shaders/ghibli_lawn.gdshader")
		var grass_tex: Texture2D = load("res://assets/textures/grass_stylized.png")
		var grass_norm: Texture2D = load("res://assets/textures/grass_normal.png")
		
		var mat := ShaderMaterial.new()
		mat.shader = lawn_shader
		mat.set_shader_parameter("grass_texture", grass_tex)
		mat.set_shader_parameter("grass_normal", grass_norm)
		mat.set_shader_parameter("uv_scale", Vector2(70.0, 70.0))
		mat.set_shader_parameter("col_meadow", Color(0.36, 0.56, 0.22))
		mat.set_shader_parameter("col_sunlit", Color(0.54, 0.74, 0.28))
		mat.set_shader_parameter("normal_scale", 1.4)
		
		meadow_node.set_surface_override_material(0, mat)
		print("Meadow material applied successfully with ghibli_lawn shader!")
	else:
		print("Error: Meadow node not found!")
		
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, path)
	print("GardenBackdrop.tscn saved.")

func _apply_soil_material() -> void:
	var path := "res://scenes/levels/Level_01.tscn"
	var scene: PackedScene = load(path)
	var root: Node3D = scene.instantiate()
	
	var ground_node: MeshInstance3D = root.get_node_or_null("Ground")
	var soil_shader: Shader = load("res://assets/shaders/ghibli_soil.gdshader")
	var soil_tex: Texture2D = load("res://assets/textures/ground_soil.png")
	var soil_norm: Texture2D = load("res://assets/textures/soil_normal.png")
	
	var ground_mat := ShaderMaterial.new()
	ground_mat.shader = soil_shader
	ground_mat.set_shader_parameter("soil_texture", soil_tex)
	ground_mat.set_shader_parameter("soil_normal", soil_norm)
	ground_mat.set_shader_parameter("uv_scale", Vector2(10.0, 5.0))
	ground_mat.set_shader_parameter("soil_warm_tint", Color(0.95, 0.90, 0.85))
	ground_mat.set_shader_parameter("soil_moist_tint", Color(0.70, 0.62, 0.55))
	ground_mat.set_shader_parameter("normal_depth", 1.8)
	ground_mat.set_shader_parameter("wetness_factor", 0.45)
	
	if ground_node:
		ground_node.set_surface_override_material(0, ground_mat)
		
	for i in range(1, 6):
		var r_node: MeshInstance3D = root.get_node_or_null("SoilRidge_%d" % i)
		if r_node:
			var ridge_mat := ShaderMaterial.new()
			ridge_mat.shader = soil_shader
			ridge_mat.set_shader_parameter("soil_texture", soil_tex)
			ridge_mat.set_shader_parameter("soil_normal", soil_norm)
			ridge_mat.set_shader_parameter("uv_scale", Vector2(2.5, 1.5))
			ridge_mat.set_shader_parameter("soil_warm_tint", Color(0.95, 0.90, 0.85))
			ridge_mat.set_shader_parameter("soil_moist_tint", Color(0.72, 0.64, 0.58))
			ridge_mat.set_shader_parameter("normal_depth", 1.8)
			ridge_mat.set_shader_parameter("wetness_factor", 0.3)
			r_node.set_surface_override_material(0, ridge_mat)
			
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, path)
	print("Level_01.tscn soil material applied.")

func _apply_towerspot_material() -> void:
	var path := "res://scenes/levels/TowerSpot.tscn"
	var scene: PackedScene = load(path)
	var root: Area3D = scene.instantiate()
	
	var mound: MeshInstance3D = root.get_node_or_null("MoundMesh")
	if mound:
		var spot_tex: Texture2D = load("res://assets/textures/ground_spot.jpg")
		var soil_norm: Texture2D = load("res://assets/textures/soil_normal.png")
		
		var mound_mat := StandardMaterial3D.new()
		mound_mat.albedo_texture = spot_tex
		mound_mat.normal_enabled = true
		mound_mat.normal_texture = soil_norm
		mound_mat.normal_scale = 1.6
		mound_mat.uv1_scale = Vector3(2.0, 2.0, 1.0)
		mound_mat.roughness = 0.88
		mound.set_surface_override_material(0, mound_mat)
		
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, path)
	print("TowerSpot.tscn mound material updated.")
