extends Node3D

func _ready() -> void:
	# Clean up any template environment/lights from RenderShowcase.tscn
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	
	var lvl_scene: PackedScene = load("res://scenes/levels/Level_01.tscn")
	var lvl := lvl_scene.instantiate() as Node3D
	get_tree().root.add_child(lvl)
	
	# Plant a rose on TowerSpot_1 and TowerSpot_4 to showcase contrast
	var spot1: TowerSpot = lvl.get_node_or_null("TowerSpots/TowerSpot_1")
	var rose_scene: PackedScene = load("res://scenes/towers/ThornRose.tscn")
	if spot1 and rose_scene:
		spot1.plant_tower(rose_scene)
		
	var spot4: TowerSpot = lvl.get_node_or_null("TowerSpots/TowerSpot_4")
	if spot4 and rose_scene:
		spot4.plant_tower(rose_scene)
	
	await get_tree().create_timer(0.6).timeout
	
	# 1. Overhead Tactical View
	var cam: Camera3D = lvl.get_node_or_null("CameraRig/Camera3D")
	if cam:
		cam.current = true
	await get_tree().create_timer(0.3).timeout
	var img1 := get_viewport().get_texture().get_image()
	img1.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_garden_upgrade.png")
	
	# 2. Cinematic Close-up Angle of the Golden Sprout & Bed Border & River Stones
	var close_cam := Camera3D.new()
	lvl.add_child(close_cam)
	close_cam.position = Vector3(10.5, 2.8, 6.2)
	close_cam.look_at(Vector3(13.8, 1.4, 2.5), Vector3.UP)
	close_cam.current = true
	await get_tree().create_timer(0.3).timeout
	var img2 := get_viewport().get_texture().get_image()
	img2.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_golden_sprout.png")
	
	get_tree().quit()
