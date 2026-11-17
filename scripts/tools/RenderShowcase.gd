extends Node3D

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_capture_rose()

func _capture_rose() -> void:
	var rose_scene: PackedScene = load("res://scenes/towers/ThornRose.tscn")
	var rose := rose_scene.instantiate() as Node3D
	$ModelRoot.add_child(rose)
	$Camera3D.position = Vector3(0.5, 1.3, 2.2)
	$Camera3D.look_at(Vector3(0, 1.1, 0))
	await get_tree().create_timer(0.4).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("C:/Users/maxri/.gemini/antigravity/brain/c4b57433-d9b8-4684-a230-f8ebc51e9a53/showcase_toon_rose.png")
	get_tree().quit()
