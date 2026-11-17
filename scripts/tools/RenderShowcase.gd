extends Node3D

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_capture_rose()

func _capture_rose() -> void:
	var rose_scene: PackedScene = load("res://scenes/towers/ThornRose.tscn")
	var rose := rose_scene.instantiate() as Node3D
	$ModelRoot.add_child(rose)
	$Camera3D.position = Vector3(0.3, 1.25, 2.0)
	$Camera3D.look_at(Vector3(0, 1.05, 0))
	await get_tree().create_timer(0.4).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_faceted_rose.png")
	rose.queue_free()
	await get_tree().process_frame
	_capture_snail()

func _capture_snail() -> void:
	var snail_scene: PackedScene = load("res://scenes/enemies/GardenSnail.tscn")
	var snail := snail_scene.instantiate() as Node3D
	$ModelRoot.add_child(snail)
	$Camera3D.position = Vector3(0.9, 0.7, 1.3)
	$Camera3D.look_at(Vector3(0, 0.28, 0))
	await get_tree().create_timer(0.4).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_outlined_snail.png")
	get_tree().quit()
