extends Node

func _ready() -> void:
	print("Starting Scene Updates for Option 2 & Option 4...")
	_update_beet_border()
	_update_level_01()
	_update_garden_backdrop()
	print("All scenes successfully updated!")
	get_tree().quit()

func _update_beet_border() -> void:
	var scene_path := "res://scenes/environment/BeetBorder.tscn"
	var scene: PackedScene = load(scene_path)
	var root: Node3D = scene.instantiate()
	
	# Clean up any previously added dynamic nodes
	for child in root.get_children():
		var cn: String = child.name
		if cn.begins_with("Post_") or cn.begins_with("Ivy_") or cn.begins_with("GardenProps_") or cn.begins_with("Pot_"):
			root.remove_child(child)
			child.free()
			
	var post_mesh: ArrayMesh = load("res://assets/models/corner_post.obj")
	var ivy_mesh: ArrayMesh = load("res://assets/models/ivy_vines.obj")
	var props_mesh: ArrayMesh = load("res://assets/models/garden_props.obj")
	var pot_mesh: ArrayMesh = load("res://assets/models/flower_pot.obj")
	
	var beam_node: MeshInstance3D = root.get_node_or_null("Beam_N1")
	var wood_mat: Material = beam_node.get_surface_override_material(0) if beam_node else null
	
	var grass_node: MeshInstance3D = root.get_node_or_null("G_NW")
	var foliage_mat: Material = grass_node.get_surface_override_material(0) if grass_node else null
	
	var vine_stem_mat := StandardMaterial3D.new()
	vine_stem_mat.albedo_color = Color(0.32, 0.24, 0.15)
	vine_stem_mat.roughness = 0.9
	
	var props_wood_mat := StandardMaterial3D.new()
	props_wood_mat.albedo_color = Color(0.76, 0.62, 0.44)
	props_wood_mat.roughness = 0.82
	
	var props_metal_mat := StandardMaterial3D.new()
	props_metal_mat.albedo_color = Color(0.70, 0.74, 0.76)
	props_metal_mat.metallic = 0.8
	props_metal_mat.roughness = 0.3
	
	var pot_clay_mat := StandardMaterial3D.new()
	pot_clay_mat.albedo_color = Color(0.80, 0.44, 0.28)
	pot_clay_mat.roughness = 0.82
	
	var pot_dirt_mat := StandardMaterial3D.new()
	pot_dirt_mat.albedo_color = Color(0.24, 0.16, 0.10)
	pot_dirt_mat.roughness = 0.95
	
	# 1. Corner Posts
	var post_coords := [
		{"name": "Post_NW", "pos": Vector3(-16.0, 0, -8.0)},
		{"name": "Post_NE", "pos": Vector3(16.0, 0, -8.0)},
		{"name": "Post_SW", "pos": Vector3(-16.0, 0, 8.0)},
		{"name": "Post_SE", "pos": Vector3(16.0, 0, 8.0)},
		{"name": "Post_Entrance_North", "pos": Vector3(-16.0, 0, -6.1)},
		{"name": "Post_Entrance_South", "pos": Vector3(-16.0, 0, -2.9)}
	]
	for p_info in post_coords:
		var mi := MeshInstance3D.new()
		mi.name = p_info["name"]
		mi.mesh = post_mesh
		mi.position = p_info["pos"]
		if wood_mat:
			mi.set_surface_override_material(0, wood_mat)
		root.add_child(mi)
		mi.owner = root

	# 2. Ivy Vines
	var ivy_configs := [
		{"name": "Ivy_N1", "pos": Vector3(-8.0, 0.05, -8.0), "rot": Vector3(0, 0, 0)},
		{"name": "Ivy_N2", "pos": Vector3(5.0, 0.05, -8.0), "rot": Vector3(0, 0, 0)},
		{"name": "Ivy_S1", "pos": Vector3(-3.0, 0.05, 8.0), "rot": Vector3(0, 180, 0)},
		{"name": "Ivy_S2", "pos": Vector3(9.0, 0.05, 8.0), "rot": Vector3(0, 180, 0)},
		{"name": "Ivy_Entrance", "pos": Vector3(-16.0, 0.05, -2.8), "rot": Vector3(0, -90, 0)},
		{"name": "Ivy_E_Mid", "pos": Vector3(16.0, 0.05, 1.5), "rot": Vector3(0, 90, 0)}
	]
	for iv in ivy_configs:
		var mi := MeshInstance3D.new()
		mi.name = iv["name"]
		mi.mesh = ivy_mesh
		mi.position = iv["pos"]
		mi.rotation_degrees = iv["rot"]
		mi.set_surface_override_material(0, vine_stem_mat)
		if foliage_mat:
			mi.set_surface_override_material(1, foliage_mat)
		root.add_child(mi)
		mi.owner = root

	# 3. Garden Props
	var prop_configs := [
		{"name": "GardenProps_Corner", "pos": Vector3(-14.8, 0, 6.8), "rot": Vector3(0, 25, 0), "scale": Vector3(1.1, 1.1, 1.1)},
		{"name": "GardenProps_Sign_Rose", "pos": Vector3(-9.6, 0, 1.8), "rot": Vector3(0, -18, 0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"name": "GardenProps_Sign_Sprout", "pos": Vector3(13.2, 0, 1.2), "rot": Vector3(0, -35, 0), "scale": Vector3(1.0, 1.0, 1.0)}
	]
	for pr in prop_configs:
		var mi := MeshInstance3D.new()
		mi.name = pr["name"]
		mi.mesh = props_mesh
		mi.position = pr["pos"]
		mi.rotation_degrees = pr["rot"]
		mi.scale = pr["scale"]
		mi.set_surface_override_material(0, props_wood_mat)
		mi.set_surface_override_material(1, props_metal_mat)
		root.add_child(mi)
		mi.owner = root

	# 4. Realistic Pots
	var pot_configs := [
		{"name": "Pot_Entrance_L", "pos": Vector3(-17.2, 0, -2.1), "rot": Vector3(0, 30, 0), "scale": Vector3(0.26, 0.26, 0.26)},
		{"name": "Pot_Entrance_R", "pos": Vector3(-17.2, 0, -6.8), "rot": Vector3(0, -20, 0), "scale": Vector3(0.24, 0.24, 0.24)},
		{"name": "Pot_SE", "pos": Vector3(15.4, 0, 7.3), "rot": Vector3(0, -20, 0), "scale": Vector3(0.28, 0.28, 0.28)},
		{"name": "Pot_NW", "pos": Vector3(-15.4, 0, -7.3), "rot": Vector3(0, 45, 0), "scale": Vector3(0.25, 0.25, 0.25)}
	]
	for pt in pot_configs:
		var mi := MeshInstance3D.new()
		mi.name = pt["name"]
		mi.mesh = pot_mesh
		mi.position = pt["pos"]
		mi.rotation_degrees = pt["rot"]
		mi.scale = pt["scale"]
		mi.set_surface_override_material(0, pot_clay_mat)
		mi.set_surface_override_material(1, pot_dirt_mat)
		root.add_child(mi)
		mi.owner = root

	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, scene_path)
	print("BeetBorder.tscn saved cleanly.")

func _update_level_01() -> void:
	var scene_path := "res://scenes/levels/Level_01.tscn"
	var scene: PackedScene = load(scene_path)
	var root: Node3D = scene.instantiate()
	
	for child in root.get_children():
		if child.name.begins_with("SoilRidge_"):
			root.remove_child(child)
			child.free()
			
	var ridges_mesh: ArrayMesh = load("res://assets/models/soil_ridges.obj")
	var dirt_tex: Texture2D = load("res://assets/textures/ground_soil.png")
	
	var ridge_dirt_mat := StandardMaterial3D.new()
	ridge_dirt_mat.albedo_color = Color(0.92, 0.88, 0.82)
	ridge_dirt_mat.albedo_texture = dirt_tex
	ridge_dirt_mat.uv1_scale = Vector3(2.5, 1.5, 2.5)
	ridge_dirt_mat.roughness = 0.92
	
	var ridge_configs := [
		{"name": "SoilRidge_1", "pos": Vector3(-8.0, 0, -6.2), "rot": Vector3(0, 0, 0), "scale": Vector3(0.9, 1.5, 0.9)},
		{"name": "SoilRidge_2", "pos": Vector3(-6.0, 0, 5.8), "rot": Vector3(0, 0, 0), "scale": Vector3(1.0, 1.5, 1.0)},
		{"name": "SoilRidge_3", "pos": Vector3(8.0, 0, -5.5), "rot": Vector3(0, 0, 0), "scale": Vector3(0.9, 1.5, 0.9)},
		{"name": "SoilRidge_4", "pos": Vector3(10.5, 0, -1.2), "rot": Vector3(0, 90, 0), "scale": Vector3(0.7, 1.4, 0.8)},
		{"name": "SoilRidge_5", "pos": Vector3(3.5, 0, 5.2), "rot": Vector3(0, 0, 0), "scale": Vector3(0.85, 1.4, 0.85)}
	]
	for r_cfg in ridge_configs:
		var mi := MeshInstance3D.new()
		mi.name = r_cfg["name"]
		mi.mesh = ridges_mesh
		mi.position = r_cfg["pos"]
		mi.rotation_degrees = r_cfg["rot"]
		mi.scale = r_cfg["scale"]
		mi.set_surface_override_material(0, ridge_dirt_mat)
		root.add_child(mi)
		mi.owner = root
		
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, scene_path)
	print("Level_01.tscn saved cleanly.")

func _update_garden_backdrop() -> void:
	var scene_path := "res://scenes/environment/GardenBackdrop.tscn"
	var scene: PackedScene = load(scene_path)
	var root: Node3D = scene.instantiate()
	
	# Fix soil on existing flower pots in backdrop
	var pot_dirt_mat := StandardMaterial3D.new()
	pot_dirt_mat.albedo_color = Color(0.24, 0.16, 0.10)
	pot_dirt_mat.roughness = 0.95
	for pot_name in ["Pot_Porch_L", "Pot_Porch_R", "Pot_Path_1"]:
		var p_node: MeshInstance3D = root.get_node_or_null(pot_name)
		if p_node:
			p_node.set_surface_override_material(1, pot_dirt_mat)

	# Clean up any previously added dynamic nodes
	for child in root.get_children():
		var cn: String = child.name
		if cn.begins_with("AppleTree_") or cn.begins_with("RainBarrel_") or cn.begins_with("Lawn_WF_") or cn.begins_with("Lawn_Grass_Extra_"):
			root.remove_child(child)
			child.free()
			
	# Remove old background tree spheres
	var nodes_to_clean := [
		"Tree_Right_Trunk", "Tree_Right_Canopy_1", "Tree_Right_Canopy_2",
		"Tree_Right_Canopy_3", "Tree_Right_Canopy_4",
		"Tree_Left_Trunk", "Tree_Left_Canopy_1", "Tree_Left_Canopy_2",
		"Tree_Left_Canopy_3", "Tree_Left_Canopy_4"
	]
	for n_name in nodes_to_clean:
		var old_node: Node = root.get_node_or_null(n_name)
		if old_node:
			root.remove_child(old_node)
			old_node.free()

	var apple_tree_mesh: ArrayMesh = load("res://assets/models/apple_tree.obj")
	var barrel_mesh: ArrayMesh = load("res://assets/models/rain_barrel.obj")
	var wildflower_mesh: ArrayMesh = load("res://assets/models/wildflower_cluster.obj")
	var grass_mesh: ArrayMesh = load("res://assets/models/grass_tuft.obj")
	
	var tree_trunk_mat := StandardMaterial3D.new()
	tree_trunk_mat.albedo_color = Color(0.48, 0.38, 0.28)
	tree_trunk_mat.roughness = 0.88
	
	var bush_node: MeshInstance3D = root.get_node_or_null("Tree_Right_Bush")
	var canopy_foliage_mat: Material = bush_node.get_surface_override_material(0) if bush_node else null
	
	var apple_mat := StandardMaterial3D.new()
	apple_mat.albedo_color = Color(0.88, 0.16, 0.14)
	apple_mat.roughness = 0.3
	
	var barrel_wood_mat := StandardMaterial3D.new()
	barrel_wood_mat.albedo_color = Color(0.55, 0.42, 0.30)
	barrel_wood_mat.roughness = 0.85
	
	var barrel_metal_mat := StandardMaterial3D.new()
	barrel_metal_mat.albedo_color = Color(0.24, 0.25, 0.28)
	barrel_metal_mat.metallic = 0.8
	barrel_metal_mat.roughness = 0.4
	
	var barrel_water_mat := StandardMaterial3D.new()
	barrel_water_mat.albedo_color = Color(0.12, 0.24, 0.26)
	barrel_water_mat.metallic = 0.1
	barrel_water_mat.roughness = 0.05
	
	var barrel_spigot_mat := StandardMaterial3D.new()
	barrel_spigot_mat.albedo_color = Color(0.85, 0.72, 0.32)
	barrel_spigot_mat.metallic = 0.85
	barrel_spigot_mat.roughness = 0.25
	
	var wf_node: MeshInstance3D = root.get_node_or_null("Foreground_Wildflowers_L")
	var wf_stem_mat: Material = wf_node.get_surface_override_material(0) if wf_node else null
	var wf_puff_mat: Material = wf_node.get_surface_override_material(1) if wf_node else null
	var wf_petal_mat: Material = wf_node.get_surface_override_material(2) if wf_node else null
	var wf_center_mat: Material = wf_node.get_surface_override_material(3) if wf_node else null
	
	var lawn_grass_node: MeshInstance3D = root.get_node_or_null("Lawn_Grass_1")
	var lawn_grass_mat: Material = lawn_grass_node.get_surface_override_material(0) if lawn_grass_node else null

	# Apple Trees
	var at_right := MeshInstance3D.new()
	at_right.name = "AppleTree_Right"
	at_right.mesh = apple_tree_mesh
	at_right.position = Vector3(22.5, 0, -9.0)
	at_right.rotation_degrees = Vector3(0, 25, 0)
	at_right.scale = Vector3(1.15, 1.15, 1.15)
	at_right.set_surface_override_material(0, tree_trunk_mat)
	if canopy_foliage_mat:
		at_right.set_surface_override_material(1, canopy_foliage_mat)
	at_right.set_surface_override_material(2, apple_mat)
	root.add_child(at_right)
	at_right.owner = root

	var at_left := MeshInstance3D.new()
	at_left.name = "AppleTree_Left"
	at_left.mesh = apple_tree_mesh
	at_left.position = Vector3(-22.5, 0, -10.0)
	at_left.rotation_degrees = Vector3(0, -40, 0)
	at_left.scale = Vector3(1.1, 1.1, 1.1)
	at_left.set_surface_override_material(0, tree_trunk_mat)
	if canopy_foliage_mat:
		at_left.set_surface_override_material(1, canopy_foliage_mat)
	at_left.set_surface_override_material(2, apple_mat)
	root.add_child(at_left)
	at_left.owner = root

	# Rain Barrels
	var barrel_configs := [
		{"name": "RainBarrel_L", "pos": Vector3(-13.4, 0, -16.5), "rot": Vector3(0, 15, 0)},
		{"name": "RainBarrel_R", "pos": Vector3(13.4, 0, -16.5), "rot": Vector3(0, -15, 0)}
	]
	for b_cfg in barrel_configs:
		var mi := MeshInstance3D.new()
		mi.name = b_cfg["name"]
		mi.mesh = barrel_mesh
		mi.position = b_cfg["pos"]
		mi.rotation_degrees = b_cfg["rot"]
		mi.set_surface_override_material(0, barrel_wood_mat)
		mi.set_surface_override_material(1, barrel_metal_mat)
		mi.set_surface_override_material(2, barrel_water_mat)
		mi.set_surface_override_material(3, barrel_spigot_mat)
		root.add_child(mi)
		mi.owner = root

	# Lawn Wildflowers & Grass
	var lawn_wf_configs := [
		{"pos": Vector3(-10.0, 0, 11.0), "rot": 10.0, "scale": 1.2},
		{"pos": Vector3(-6.0, 0, 12.0), "rot": -25.0, "scale": 1.15},
		{"pos": Vector3(6.0, 0, 11.5), "rot": 35.0, "scale": 1.25},
		{"pos": Vector3(10.0, 0, 12.0), "rot": -15.0, "scale": 1.1},
		{"pos": Vector3(-1.8, 0, -12.5), "rot": 40.0, "scale": 0.95},
		{"pos": Vector3(1.8, 0, -13.5), "rot": -30.0, "scale": 1.05},
		{"pos": Vector3(-20.0, 0, -8.0), "rot": 15.0, "scale": 1.3},
		{"pos": Vector3(20.0, 0, -7.0), "rot": -20.0, "scale": 1.35}
	]
	for idx in range(lawn_wf_configs.size()):
		var wf_cfg: Dictionary = lawn_wf_configs[idx]
		var mi := MeshInstance3D.new()
		mi.name = "Lawn_WF_%d" % (idx + 1)
		mi.mesh = wildflower_mesh
		mi.position = wf_cfg["pos"]
		mi.rotation_degrees = Vector3(0, wf_cfg["rot"], 0)
		var sc: float = wf_cfg["scale"]
		mi.scale = Vector3(sc, sc, sc)
		if wf_stem_mat:
			mi.set_surface_override_material(0, wf_stem_mat)
			mi.set_surface_override_material(1, wf_puff_mat)
			mi.set_surface_override_material(2, wf_petal_mat)
			mi.set_surface_override_material(3, wf_center_mat)
		root.add_child(mi)
		mi.owner = root

	var extra_grass_configs := [
		{"pos": Vector3(-8.0, 0, 10.5), "rot": 12.0, "scale": 1.3},
		{"pos": Vector3(8.0, 0, 10.5), "rot": -18.0, "scale": 1.25},
		{"pos": Vector3(-2.8, 0, -14.5), "rot": 45.0, "scale": 1.1},
		{"pos": Vector3(2.8, 0, -15.2), "rot": -35.0, "scale": 1.15},
		{"pos": Vector3(-24.5, 0, -12.0), "rot": 20.0, "scale": 1.4},
		{"pos": Vector3(24.5, 0, -11.0), "rot": -25.0, "scale": 1.4},
		{"pos": Vector3(-17.5, 0, 3.0), "rot": 50.0, "scale": 1.2},
		{"pos": Vector3(17.5, 0, 2.5), "rot": -40.0, "scale": 1.25}
	]
	for idx in range(extra_grass_configs.size()):
		var eg_cfg: Dictionary = extra_grass_configs[idx]
		var mi := MeshInstance3D.new()
		mi.name = "Lawn_Grass_Extra_%d" % (idx + 1)
		mi.mesh = grass_mesh
		mi.position = eg_cfg["pos"]
		mi.rotation_degrees = Vector3(0, eg_cfg["rot"], 0)
		var sc: float = eg_cfg["scale"]
		mi.scale = Vector3(sc, sc, sc)
		if lawn_grass_mat:
			mi.set_surface_override_material(0, lawn_grass_mat)
		root.add_child(mi)
		mi.owner = root

	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, scene_path)
	print("GardenBackdrop.tscn saved cleanly.")
