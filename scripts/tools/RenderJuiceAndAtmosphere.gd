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
	var rose: Node3D = null
	if spot1 and rose_scene:
		rose = spot1.plant_tower(rose_scene)

	var spot4: TowerSpot = lvl.get_node_or_null("TowerSpots/TowerSpot_4")
	if spot4 and rose_scene:
		spot4.plant_tower(rose_scene)

	var cam: Camera3D = lvl.get_node_or_null("CameraRig/Camera3D")
	if cam:
		cam.current = true

	# Wait for particles (smoke, pollen, butterfly) to settle
	await get_tree().create_timer(1.0).timeout

	# 1. Capture Atmosphere & Living World (Pollen, Chimney Smoke, Butterfly, Wave Preview)
	var img_atmo := get_viewport().get_texture().get_image()
	img_atmo.save_png("C:/Users/maxri/Project_Garden/assets/screenshots/showcase_atmosphere_living.png")
	img_atmo.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_atmosphere_living.png")

	# 2. Capture Range Indicator & Spot Focus
	var radial: RadialMenu = lvl.get_node_or_null("UI/RadialMenu")
	if radial and spot1:
		radial.open_for_spot(spot1)
	await get_tree().create_timer(0.6).timeout
	var img_range := get_viewport().get_texture().get_image()
	img_range.save_png("C:/Users/maxri/Project_Garden/assets/screenshots/showcase_range_indicator.png")
	img_range.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_range_indicator.png")

	# Close radial menu
	if radial:
		radial.close()
	await get_tree().create_timer(0.5).timeout

	# 3. Spawn a snail and simulate hit feedback / slime splash
	var snail_scene: PackedScene = load("res://scenes/enemies/GardenSnail.tscn")
	var path3d: Path3D = lvl.get_node_or_null("Path3D")
	if snail_scene and path3d:
		var snail := snail_scene.instantiate() as PathFollow3D
		path3d.add_child(snail)
		snail.progress = 6.2 # Position near spot 1
		await get_tree().process_frame

		# Trigger damage on snail
		var hc: HealthComponent = snail.get_node_or_null("HealthComponent")
		if hc:
			hc.take_damage(20.0)

		# Trigger recoil on rose
		if rose and rose.has_method("_trigger_shoot_recoil"):
			rose.call("_trigger_shoot_recoil")

		# Close-up camera on the combat interaction
		var combat_cam := Camera3D.new()
		lvl.add_child(combat_cam)
		combat_cam.position = Vector3(-8.5, 3.2, 5.0)
		combat_cam.look_at(snail.global_position + Vector3(0, 0.4, 0), Vector3.UP)
		combat_cam.current = true

		await get_tree().create_timer(0.06).timeout
		var img_hit := get_viewport().get_texture().get_image()
		img_hit.save_png("C:/Users/maxri/Project_Garden/assets/screenshots/showcase_hit_and_combat.png")
		img_hit.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_hit_and_combat.png")

	print("RenderJuiceAndAtmosphere finished successfully!")
	get_tree().quit(0)
