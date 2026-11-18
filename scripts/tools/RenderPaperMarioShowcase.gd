extends Node3D

const ARTIFACT_DIR = "C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53"
const LOCAL_DIR = "C:/Users/maxri/Project_Garden/assets/screenshots"

func _ready() -> void:
	print("--- Starte 2.5D Paper Mario Showcase Renderer ---")
	_setup_showcase()

func _setup_showcase() -> void:
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	var lvl_scene: PackedScene = load("res://scenes/levels/Level_01.tscn")
	var lvl := lvl_scene.instantiate() as Node3D
	add_child(lvl)

	# PaperOverlay Autoload-Szene instanziieren falls nötig
	var overlay_scene: PackedScene = load("res://scenes/ui/PaperOverlay.tscn")
	if overlay_scene:
		var overlay = overlay_scene.instantiate()
		add_child(overlay)

	# Schnecken auf dem Pfad platzieren
	var path_node: Path3D = lvl.get_node_or_null("Path3D")
	var snail_scene: PackedScene = load("res://scenes/enemies/GardenSnail.tscn")
	var s1: Node3D = null
	var s2: Node3D = null
	
	if path_node and snail_scene:
		s1 = snail_scene.instantiate() as Node3D
		path_node.add_child(s1)
		s1.set("progress_ratio", 0.28)

		s2 = snail_scene.instantiate() as Node3D
		path_node.add_child(s2)
		s2.set("progress_ratio", 0.52)
		var cutout2 = s2.find_child("PaperCutout", true, false)
		if cutout2 and cutout2.has_method("set_facing"):
			cutout2.call("set_facing", false)

		var s3 = snail_scene.instantiate() as Node3D
		path_node.add_child(s3)
		s3.set("progress_ratio", 0.08)

	# Rose auf Spot 1 pflanzen
	var spot1: TowerSpot = lvl.get_node_or_null("TowerSpots/TowerSpot_1")
	var rose_scene: PackedScene = load("res://scenes/towers/ThornRose.tscn")
	var rose: Node3D = null
	if spot1 and rose_scene:
		rose = rose_scene.instantiate() as Node3D
		spot1.add_child(rose)
		spot1.current_plant = rose
		spot1._update_visual_state()

	var cam_rig = lvl.get_node_or_null("CameraRig")
	var cam: Camera3D = lvl.get_node_or_null("CameraRig/Camera3D")
	if cam:
		cam.current = true

	# --- SHOT 1: Taktische Pop-up Diorama Übersicht ---
	print("Render Shot 1: Taktische Übersicht...")
	if cam:
		cam.global_position = Vector3(0.0, 16.5, 12.0)
		cam.look_at(Vector3(0.0, 0.0, 0.5), Vector3.UP)

	await get_tree().create_timer(0.6).timeout
	_capture_and_save("showcase_paper_diorama_overview.png")

	# Deaktiviere CameraRig-Process für gezielte Shots
	if cam_rig:
		cam_rig.set_process(false)
		cam_rig.set_physics_process(false)

	# --- SHOT 2: Nahaufnahme Paper Cutouts & Schatten ---
	print("Render Shot 2: Nahaufnahme Pappaufsteller Schnecke & Rose...")
	if cam:
		cam.global_position = Vector3(-7.8, 2.2, 2.0)
		cam.look_at(Vector3(-10.5, 1.2, -1.0), Vector3.UP)

	await get_tree().create_timer(0.5).timeout
	_capture_and_save("showcase_paper_cutout_closeup.png")

	# --- SHOT 2b: Schnecke auf S-Kurven-Pfad ---
	print("Render Shot 2b: Nahaufnahme Schnecke auf S-Kurve...")
	if cam:
		cam.global_position = Vector3(-0.5, 2.2, 4.2)
		cam.look_at(Vector3(-1.8, 0.4, 1.6), Vector3.UP)

	await get_tree().create_timer(0.4).timeout
	_capture_and_save("showcase_paper_snail_action.png")

	# --- SHOT 3: 1st-Person Blüten-Cockpit ---
	print("Render Shot 3: 1st-Person Rosen-Cockpit mit Aquarell-Blütenrand...")
	if rose:
		GameManager.enter_symbiosis(rose)

	if cam and rose:
		var mount = rose.get_node_or_null("FirstPersonMount")
		if mount:
			cam.global_position = mount.global_position
			cam.look_at(Vector3(-4.2, 0.4, 3.5), Vector3.UP)

	await get_tree().create_timer(0.5).timeout
	_capture_and_save("showcase_paper_firstperson_cockpit.png")

	print("Alle Showcase-Screenshots fertig!")
	get_tree().quit(0)

func _capture_and_save(filename: String) -> void:
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png(ARTIFACT_DIR + "/" + filename)
		img.save_png(LOCAL_DIR + "/" + filename)
		print("Gespeichert: " + filename)
	else:
		printerr("Fehler: Viewport Bild null für " + filename)
