extends Node3D

func _ready() -> void:
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	var lvl_scene: PackedScene = load("res://scenes/levels/Level_01.tscn")
	var lvl := lvl_scene.instantiate() as Node3D
	get_tree().root.add_child(lvl)

	var spot1: TowerSpot = lvl.get_node_or_null("TowerSpots/TowerSpot_1")
	var rose_scene: PackedScene = load("res://scenes/towers/ThornRose.tscn")
	if spot1 and rose_scene:
		spot1.plant_tower(rose_scene)

	var spot4: TowerSpot = lvl.get_node_or_null("TowerSpots/TowerSpot_4")
	if spot4 and rose_scene:
		spot4.plant_tower(rose_scene)

	var cam_rig: CameraRig = lvl.get_node_or_null("CameraRig")
	var cam: Camera3D = lvl.get_node_or_null("CameraRig/Camera3D")
	if cam:
		cam.current = true

	await get_tree().create_timer(0.6).timeout

	# 1. Standard Tactical Overview
	var img1 := get_viewport().get_texture().get_image()
	img1.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_cam_overview.png")

	# 2. Zoomed in via Mouse Wheel
	if cam_rig:
		cam_rig._zoom(-4.0)
	await get_tree().create_timer(0.4).timeout
	var img2 := get_viewport().get_texture().get_image()
	img2.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_cam_zoomed.png")

	# 3. Focus-Punch on TowerSpot 1 with Radial Menu Open
	var radial: RadialMenu = lvl.get_node_or_null("UI/RadialMenu")
	if radial and spot1:
		radial.open_for_spot(spot1)
	await get_tree().create_timer(0.5).timeout
	var img3 := get_viewport().get_texture().get_image()
	img3.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_cam_focus_punch.png")

	print("RenderCameraOptionB completed successfully!")
	get_tree().quit(0)
