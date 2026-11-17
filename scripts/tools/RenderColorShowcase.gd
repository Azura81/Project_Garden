extends Node3D

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	var lvl_scene: PackedScene = load("res://scenes/levels/Level_01.tscn")
	var lvl := lvl_scene.instantiate() as Node3D
	get_tree().root.add_child(lvl)
	
	$Camera3D.current = false
	var cam: Camera3D = lvl.get_node_or_null("CameraRig/Camera3D")
	if cam:
		cam.current = true
		
	await get_tree().create_timer(0.6).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_rectangular_bed.png")
	get_tree().quit()
