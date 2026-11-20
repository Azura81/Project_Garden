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

	# PaperOverlay Autoload-Szene instanziieren falls nicht vorhanden
	var overlay_scene: PackedScene = load("res://scenes/ui/PaperOverlay.tscn")
	if overlay_scene:
		var overlay = overlay_scene.instantiate()
		add_child(overlay)

	# Schnecke und Käfer auf dem Pfad platzieren
	var path_node: Path3D = lvl.get_node_or_null("Path3D")
	var snail_scene: PackedScene = load("res://scenes/enemies/GardenSnail.tscn")
	var beetle_scene: PackedScene = load("res://scenes/enemies/GardenBeetle.tscn")
	
	if path_node:
		if snail_scene:
			var s1 = snail_scene.instantiate() as Node3D
			path_node.add_child(s1)
			s1.set("progress_ratio", 0.32)

		if beetle_scene:
			var b1 = beetle_scene.instantiate() as Node3D
			path_node.add_child(b1)
			b1.set("progress_ratio", 0.55)
			var cutout_b = b1.find_child("PaperCutout", true, false)
			if cutout_b and cutout_b.has_method("set_facing"):
				cutout_b.call("set_facing", false)

			var b2 = beetle_scene.instantiate() as Node3D
			path_node.add_child(b2)
			b2.set("progress_ratio", 0.12)

	# Rose auf Spot 1 pflanzen und auf Stufe 3 (Symbiose) upgraden
	var spot1: TowerSpot = lvl.get_node_or_null("TowerSpots/TowerSpot_1")
	var rose_scene: PackedScene = load("res://scenes/towers/ThornRose.tscn")
	var rose: Node3D = null
	if spot1 and rose_scene:
		rose = rose_scene.instantiate() as Node3D
		spot1.add_child(rose)
		spot1.current_plant = rose
		spot1._update_visual_state()
		if rose.has_method("_update_symbiosis_indicator"):
			rose.set("level", 3)
			rose.set("has_symbiosis_upgrade", true)
			rose.call("_update_symbiosis_indicator")
			var spr = rose.find_child("Sprite3D", true, false) as Sprite3D
			if spr:
				spr.scale *= 1.30

	# Pusteblume auf Spot 2 pflanzen
	var spot2: TowerSpot = lvl.get_node_or_null("TowerSpots/TowerSpot_2")
	var dandelion_scene: PackedScene = load("res://scenes/towers/DandelionCatapult.tscn")
	var dandelion: Node3D = null
	if spot2 and dandelion_scene:
		dandelion = dandelion_scene.instantiate() as Node3D
		spot2.add_child(dandelion)
		spot2.current_plant = dandelion
		spot2._update_visual_state()

	# Schmetterling sichtbar über dem Beet positionieren
	var bfly: Node3D = lvl.get_node_or_null("Butterfly")
	if bfly:
		bfly.global_position = Vector3(2.5, 2.2, 0.5)

	var cam_rig = lvl.get_node_or_null("CameraRig")
	var cam: Camera3D = lvl.get_node_or_null("CameraRig/Camera3D")
	if cam:
		cam.current = true

	# --- SHOT 1: Diagonale Pop-up Diorama Übersicht (wie in ref_perspective_1.jpg) ---
	print("Render Shot 1: Diagonale Pop-up Diorama Übersicht...")
	if cam_rig and cam_rig.has_method("setup_tactical_view"):
		cam_rig.call("setup_tactical_view")

	await get_tree().create_timer(0.6).timeout
	_capture_and_save("showcase_paper_diorama_overview.png")

	# --- SHOT 1b: Taktische Vogelperspektive Top-Down (wie in ref_topdown.jpg) ---
	print("Render Shot 1b: Taktische Vogelperspektive Top-Down...")
	if cam_rig and cam_rig.has_method("toggle_perspective"):
		cam_rig.call("toggle_perspective")
		await get_tree().create_timer(0.7).timeout
		_capture_and_save("showcase_paper_topdown_view.png")
		# Wieder zurück auf Diorama
		cam_rig.call("toggle_perspective")
		await get_tree().create_timer(0.7).timeout

	# Deaktiviere CameraRig-Process für gezielte Shots
	if cam_rig:
		cam_rig.set_process(false)
		cam_rig.set_physics_process(false)

	# --- SHOT 2: Nahaufnahme Pusteblume, Steine & 2.5D Deko ---
	print("Render Shot 2: Nahaufnahme Pusteblume, Steingruppen & 2.5D-Gartendeko...")
	if cam:
		cam.global_position = Vector3(-6.8, 2.6, 7.8)
		cam.look_at(Vector3(-1.5, 1.0, 1.2), Vector3.UP)

	await get_tree().create_timer(0.5).timeout
	_capture_and_save("showcase_paper_cutout_closeup.png")

	# --- SHOT 2b: Käfer & Schnecke auf S-Kurven-Pfad mit weichen Rändern ---
	print("Render Shot 2b: S-Kurven-Pfad mit weichen Aquarell-Rändern...")
	if cam:
		cam.global_position = Vector3(-4.5, 3.2, 8.5)
		cam.look_at(Vector3(1.8, 0.4, 0.2), Vector3.UP)

	await get_tree().create_timer(0.4).timeout
	_capture_and_save("showcase_paper_snail_action.png")

	# --- SHOT 3: 1st-Person Blüten-Cockpit ---
	print("Render Shot 3: 1st-Person Rosen-Cockpit mit Fadenkreuz & Aquarell-Blütenrand...")
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
