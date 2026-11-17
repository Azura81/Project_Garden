@tool
extends SceneTree

func _init() -> void:
	print("Generating Stylized Terrain Textures & Normal Maps...")
	_generate_soil_normal_map()
	_generate_stylized_grass_textures()
	print("Terrain textures generated successfully!")
	quit()

func _generate_soil_normal_map() -> void:
	var soil_img := Image.load_from_file("res://assets/textures/ground_soil.png")
	if not soil_img:
		print("Error: Could not load ground_soil.png")
		return
		
	var w := mini(soil_img.get_width(), 1024)
	var h := mini(soil_img.get_height(), 1024)
	if soil_img.get_width() != w or soil_img.get_height() != h:
		soil_img.resize(w, h, Image.INTERPOLATE_BILINEAR)
		
	var normal_img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var strength: float = 2.4
	
	for y in range(h):
		var y_prev := (y - 1 + h) % h
		var y_next := (y + 1) % h
		for x in range(w):
			var x_prev := (x - 1 + w) % w
			var x_next := (x + 1) % w
			
			var c_l := soil_img.get_pixel(x_prev, y).get_luminance()
			var c_r := soil_img.get_pixel(x_next, y).get_luminance()
			var c_u := soil_img.get_pixel(x, y_prev).get_luminance()
			var c_d := soil_img.get_pixel(x, y_next).get_luminance()
			
			var dx := (c_r - c_l) * strength
			var dy := (c_d - c_u) * strength
			
			var n := Vector3(-dx, -dy, 1.0).normalized()
			var rgb := (n + Vector3.ONE) * 0.5
			normal_img.set_pixel(x, y, Color(rgb.x, rgb.y, rgb.z, 1.0))
			
	normal_img.save_png("res://assets/textures/soil_normal.png")
	print("Saved res://assets/textures/soil_normal.png (1024x1024)")

func _generate_stylized_grass_textures() -> void:
	var size := 1024
	var grass_img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var normal_img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var noise_base := FastNoiseLite.new()
	noise_base.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_base.frequency = 0.02
	noise_base.fractal_octaves = 3
	
	var noise_blades := FastNoiseLite.new()
	noise_blades.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise_blades.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	noise_blades.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
	noise_blades.frequency = 0.08
	
	var noise_fibers := FastNoiseLite.new()
	noise_fibers.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_fibers.frequency = 0.18
	noise_fibers.fractal_octaves = 2

	# Ghibli Palette
	var col_fresh := Color(0.36, 0.58, 0.22)   # lush summer grass
	var col_warm := Color(0.56, 0.74, 0.26)    # sunlit warm tips
	var col_deep := Color(0.24, 0.42, 0.16)    # deep meadow shade
	var col_flower_dot := Color(0.92, 0.88, 0.35) # tiny buttercup speckles
	
	# Seamless wrapping coordinate evaluation
	for y in range(size):
		var v_coord := float(y) / float(size)
		var angle_v := v_coord * TAU
		var sin_v := sin(angle_v)
		var cos_v := cos(angle_v)
		
		for x in range(size):
			var u_coord := float(x) / float(size)
			var angle_u := u_coord * TAU
			var sin_u := sin(angle_u)
			var cos_u := cos(angle_u)
			
			# 4D torus mapping for 100% seamless tiling
			var scale_f := 35.0
			var nx := cos_u * scale_f
			var ny := sin_u * scale_f
			var nz := cos_v * scale_f
			var nw := sin_v * scale_f
			
			var n_base := (noise_base.get_noise_2d(nx + nz, ny + nw) + 1.0) * 0.5
			var n_blade := (noise_blades.get_noise_2d(nx * 1.8 + nz, ny * 1.8 + nw) + 1.0) * 0.5
			var n_fiber := (noise_fibers.get_noise_2d(nx * 3.0, nz * 3.0) + 1.0) * 0.5
			
			# Blend base grass colors
			var col := col_fresh.lerp(col_warm, n_base * 0.7 + n_blade * 0.3)
			col = col.lerp(col_deep, (1.0 - n_blade) * 0.35)
			
			# Subtle painterly fiber stroke
			col = col.lerp(col_warm, n_fiber * 0.18)
			
			# Tiny rare yellow buttercup / dandelion dots in the lawn
			if n_blade > 0.88 and n_base > 0.65:
				col = col.lerp(col_flower_dot, 0.4)
				
			grass_img.set_pixel(x, y, col)
			
	# Generate normal map from grass brightness
	var strength: float = 1.6
	for y in range(size):
		var y_prev := (y - 1 + size) % size
		var y_next := (y + 1) % size
		for x in range(size):
			var x_prev := (x - 1 + size) % size
			var x_next := (x + 1) % size
			
			var c_l := grass_img.get_pixel(x_prev, y).get_luminance()
			var c_r := grass_img.get_pixel(x_next, y).get_luminance()
			var c_u := grass_img.get_pixel(x, y_prev).get_luminance()
			var c_d := grass_img.get_pixel(x, y_next).get_luminance()
			
			var dx := (c_r - c_l) * strength
			var dy := (c_d - c_u) * strength
			
			var n := Vector3(-dx, -dy, 1.0).normalized()
			var rgb := (n + Vector3.ONE) * 0.5
			normal_img.set_pixel(x, y, Color(rgb.x, rgb.y, rgb.z, 1.0))
			
	grass_img.save_png("res://assets/textures/grass_stylized.png")
	normal_img.save_png("res://assets/textures/grass_normal.png")
	print("Saved res://assets/textures/grass_stylized.png and grass_normal.png (1024x1024)")
