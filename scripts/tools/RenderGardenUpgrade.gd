extends Node3D

func _ready() -> void:
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	
	var lvl_scene: PackedScene = load("res://scenes/levels/Level_01.tscn")
	var lvl := lvl_scene.instantiate() as Node3D
	get_tree().root.add_child(lvl)
	
	# Plant roses on spots 1 and 4 for realistic display
	var spot1: TowerSpot = lvl.get_node_or_null("TowerSpots/TowerSpot_1")
	var rose_scene: PackedScene = load("res://scenes/towers/ThornRose.tscn")
	if spot1 and rose_scene:
		spot1.plant_tower(rose_scene)
		
	var spot4: TowerSpot = lvl.get_node_or_null("TowerSpots/TowerSpot_4")
	if spot4 and rose_scene:
		spot4.plant_tower(rose_scene)
	
	await get_tree().create_timer(0.6).timeout
	
	# 1. Tactical Camera View
	var cam: Camera3D = lvl.get_node_or_null("CameraRig/Camera3D")
	if cam:
		cam.current = true
	await get_tree().create_timer(0.3).timeout
	var img1 := get_viewport().get_texture().get_image()
	img1.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_garden_upgrade.png")
	
	# 2. Cinematic Close-up Angle of the Snail Entrance Opening, Thicket, and Smooth Dirt Path
	var close_cam := Camera3D.new()
	lvl.add_child(close_cam)
	close_cam.position = Vector3(-13.5, 4.5, -0.5)
	close_cam.look_at(Vector3(-17.5, 0.8, -4.5), Vector3.UP)
	close_cam.fov = 65.0
	close_cam.current = true
	await get_tree().create_timer(0.3).timeout
	var img2 := get_viewport().get_texture().get_image()
	img2.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_entrance_detail.png")
	
	# 3. Cinematic Angle of the New Brick Path, Flowerpots, and Mushrooms leading to the Porch
	close_cam.position = Vector3(-8.0, 5.0, -5.0)
	close_cam.look_at(Vector3(-2.0, 1.2, -22.0), Vector3.UP)
	close_cam.fov = 60.0
	await get_tree().create_timer(0.3).timeout
	var img3 := get_viewport().get_texture().get_image()
	img3.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_brick_path.png")

	get_tree().quit()
