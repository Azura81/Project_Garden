@tool
extends SceneTree

func _init() -> void:
	var obj_path := "res://assets/models/faceted_rose.obj"
	DirAccess.make_dir_recursive_absolute("res://assets/models")
	
	var verts: Array[Vector3] = []
	var faces_stem: Array[PackedInt32Array] = []
	var faces_leaves: Array[PackedInt32Array] = []
	var faces_petals: Array[PackedInt32Array] = []
	
	# 1. SLENDER STEM (6-sided cylinder with joints)
	var stem_rad := 0.038
	var stem_points: Array[Vector3] = [
		Vector3(0, 0, 0),
		Vector3(0.015, 0.35, -0.01),
		Vector3(-0.01, 0.7, 0.015),
		Vector3(0.02, 1.05, 0.0),
		Vector3(0.0, 1.4, 0.0)
	]
	
	var prev_ring: Array[int] = []
	for p_idx in range(stem_points.size()):
		var center := stem_points[p_idx]
		var curr_ring: Array[int] = []
		for i in range(6):
			var angle := float(i) * TAU / 6.0
			var vx := center.x + cos(angle) * stem_rad
			var vz := center.z + sin(angle) * stem_rad
			verts.append(Vector3(vx, center.y, vz))
			curr_ring.append(verts.size()) # 1-based obj index
			
		if p_idx > 0:
			for i in range(6):
				var next_i := (i + 1) % 6
				faces_stem.append(PackedInt32Array([prev_ring[i], next_i_idx(prev_ring, i), next_i_idx(curr_ring, i)]))
				faces_stem.append(PackedInt32Array([prev_ring[i], next_i_idx(curr_ring, i), curr_ring[i]]))
		prev_ring = curr_ring
		
	# 2. DIAMOND LEAVES (faceted with central spine fold)
	var leaf_defs := [
		{"pos": Vector3(0.015, 0.42, 0), "dir": Vector3(0.35, 0.15, 0.15), "size": 0.28},
		{"pos": Vector3(-0.01, 0.65, 0), "dir": Vector3(-0.38, 0.18, -0.1), "size": 0.32},
		{"pos": Vector3(0.02, 0.92, 0), "dir": Vector3(0.32, 0.2, -0.22), "size": 0.3},
		{"pos": Vector3(-0.01, 1.15, 0), "dir": Vector3(-0.28, 0.18, 0.2), "size": 0.26}
	]
	
	for ld in leaf_defs:
		_add_diamond_leaf(verts, faces_leaves, ld.pos, ld.dir, ld.size)
		
	# 3. SIDE BUD (zierliche Nebenknospe wie im Referenzbild)
	var bud_branch_start := Vector3(0.01, 0.85, 0)
	var bud_pos := Vector3(0.28, 1.15, 0.15)
	_add_branch(verts, faces_stem, bud_branch_start, bud_pos, 0.02)
	_add_faceted_bud(verts, faces_petals, faces_leaves, bud_pos, 0.18)
	
	# 4. MAIN ROSE BLOSSOM (Faceted concentric spiraling petals)
	var blossom_center := Vector3(0, 1.45, 0)
	_add_faceted_rose_head(verts, faces_petals, faces_leaves, blossom_center, 0.58)
	
	# WRITE OBJ FILE
	var f := FileAccess.open(obj_path, FileAccess.WRITE)
	f.store_line("# Faceted Origami Rose")
	for v in verts:
		f.store_line("v %.4f %.4f %.4f" % [v.x, v.y, v.z])
		
	f.store_line("g Stem")
	for tri in faces_stem:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
		
	f.store_line("g Leaves")
	for tri in faces_leaves:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
		
	f.store_line("g Petals")
	for tri in faces_petals:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
		
	f.close()
	print("Faceted Rose OBJ successfully generated with %d vertices!" % verts.size())
	quit()

func next_i_idx(arr: Array[int], i: int) -> int:
	return arr[(i + 1) % arr.size()]

func _add_diamond_leaf(verts: Array[Vector3], faces: Array[PackedInt32Array], base_pos: Vector3, branch_dir: Vector3, length: float) -> void:
	var tip := base_pos + branch_dir.normalized() * length
	var side_dir := branch_dir.cross(Vector3.UP).normalized() * (length * 0.42)
	var mid := base_pos + branch_dir.normalized() * (length * 0.45)
	var left := mid + side_dir - Vector3(0, length * 0.08, 0)
	var right := mid - side_dir - Vector3(0, length * 0.08, 0)
	var spine_high := mid + Vector3(0, length * 0.06, 0)
	
	var i_base := add_v(verts, base_pos)
	var i_tip := add_v(verts, tip)
	var i_left := add_v(verts, left)
	var i_right := add_v(verts, right)
	var i_mid := add_v(verts, spine_high)
	
	# 4 Facets with central spine fold
	faces.append(PackedInt32Array([i_base, i_left, i_mid]))
	faces.append(PackedInt32Array([i_base, i_mid, i_right]))
	faces.append(PackedInt32Array([i_mid, i_left, i_tip]))
	faces.append(PackedInt32Array([i_mid, i_tip, i_right]))

func _add_branch(verts: Array[Vector3], faces: Array[PackedInt32Array], p1: Vector3, p2: Vector3, r: float) -> void:
	var dir := (p2 - p1).normalized()
	var side := dir.cross(Vector3.UP).normalized() * r
	var up := side.cross(dir).normalized() * r
	
	var r1 := [
		add_v(verts, p1 + side),
		add_v(verts, p1 + up),
		add_v(verts, p1 - side),
		add_v(verts, p1 - up)
	]
	var r2 := [
		add_v(verts, p2 + side),
		add_v(verts, p2 + up),
		add_v(verts, p2 - side),
		add_v(verts, p2 - up)
	]
	for i in range(4):
		var ni := (i + 1) % 4
		faces.append(PackedInt32Array([r1[i], r1[ni], r2[ni]]))
		faces.append(PackedInt32Array([r1[i], r2[ni], r2[i]]))

func _add_faceted_bud(verts: Array[Vector3], faces_p: Array[PackedInt32Array], faces_l: Array[PackedInt32Array], center: Vector3, size: float) -> void:
	# Calyx sepals
	var calyx_tip := center - Vector3(0, size * 0.5, 0)
	var i_calyx := add_v(verts, calyx_tip)
	var sep_r: Array[int] = []
	for i in range(4):
		var a := float(i) * TAU / 4.0
		var p := center + Vector3(cos(a) * size * 0.4, 0, sin(a) * size * 0.4)
		sep_r.append(add_v(verts, p))
	for i in range(4):
		var ni := (i + 1) % 4
		faces_l.append(PackedInt32Array([i_calyx, sep_r[i], sep_r[ni]]))
		
	# Spiral bud petals
	var bud_tip := center + Vector3(0, size * 0.8, 0)
	var i_bud_tip := add_v(verts, bud_tip)
	for i in range(4):
		var ni := (i + 1) % 4
		faces_p.append(PackedInt32Array([sep_r[i], i_bud_tip, sep_r[ni]]))

func _add_faceted_rose_head(verts: Array[Vector3], faces_p: Array[PackedInt32Array], faces_l: Array[PackedInt32Array], center: Vector3, scale: float) -> void:
	# 1. Calyx (Sepals underneath bloom)
	var sep_bot := center - Vector3(0, scale * 0.28, 0)
	var i_sep_bot := add_v(verts, sep_bot)
	for i in range(5):
		var a := float(i) * TAU / 5.0
		var sep_tip := center + Vector3(cos(a) * scale * 0.75, -scale * 0.08, sin(a) * scale * 0.75)
		var a_left := a - 0.25
		var a_right := a + 0.25
		var sep_base_l := center + Vector3(cos(a_left) * scale * 0.35, -scale * 0.2, sin(a_left) * scale * 0.35)
		var sep_base_r := center + Vector3(cos(a_right) * scale * 0.35, -scale * 0.2, sin(a_right) * scale * 0.35)
		
		var i_tip := add_v(verts, sep_tip)
		var i_bl := add_v(verts, sep_base_l)
		var i_br := add_v(verts, sep_base_r)
		faces_l.append(PackedInt32Array([i_sep_bot, i_bl, i_tip]))
		faces_l.append(PackedInt32Array([i_sep_bot, i_tip, i_br]))

	# 2. Outer Ring of Flared Faceted Petals (6 petals, angled outward)
	_build_petal_ring(verts, faces_p, center, 6, scale * 0.9, scale * 0.42, 0.15, 0.6)
	
	# 3. Middle Ring of Angled Petals (5 petals, rotated offset)
	_build_petal_ring(verts, faces_p, center + Vector3(0, scale * 0.12, 0), 5, scale * 0.65, scale * 0.46, 0.45, 0.5)
	
	# 4. Inner Spiral Core (Kawasaki origami swirl)
	_build_inner_spiral(verts, faces_p, center + Vector3(0, scale * 0.22, 0), scale * 0.42)

func _build_petal_ring(verts: Array[Vector3], faces: Array[PackedInt32Array], center: Vector3, count: int, radius: float, height: float, rot_offset: float, flare: float) -> void:
	for i in range(count):
		var a_mid := float(i) * TAU / float(count) + rot_offset
		var a_l := a_mid - (TAU / float(count)) * 0.55
		var a_r := a_mid + (TAU / float(count)) * 0.55
		
		# Base points (near center)
		var b_l := center + Vector3(cos(a_l) * radius * 0.45, -height * 0.3, sin(a_l) * radius * 0.45)
		var b_r := center + Vector3(cos(a_r) * radius * 0.45, -height * 0.3, sin(a_r) * radius * 0.45)
		
		# Top flared rim corners (sharp origami corners like in reference!)
		var t_mid := center + Vector3(cos(a_mid) * radius * (1.0 + flare * 0.2), height * 0.75, sin(a_mid) * radius * (1.0 + flare * 0.2))
		var t_l := center + Vector3(cos(a_l) * radius, height * 0.45, sin(a_l) * radius)
		var t_r := center + Vector3(cos(a_r) * radius, height * 0.45, sin(a_r) * radius)
		
		var ib_l := add_v(verts, b_l)
		var ib_r := add_v(verts, b_r)
		var it_m := add_v(verts, t_mid)
		var it_l := add_v(verts, t_l)
		var it_r := add_v(verts, t_r)
		
		# 3 triangular facets per petal
		faces.append(PackedInt32Array([ib_l, ib_r, it_m]))
		faces.append(PackedInt32Array([ib_l, it_m, it_l]))
		faces.append(PackedInt32Array([ib_r, it_r, it_m]))

func _build_inner_spiral(verts: Array[Vector3], faces: Array[PackedInt32Array], center: Vector3, size: float) -> void:
	var spiral_center := center + Vector3(0, size * 0.25, 0)
	var i_sc := add_v(verts, spiral_center)
	var pts: Array[int] = []
	for i in range(5):
		var a := float(i) * TAU / 5.0
		var r := size * (0.3 + float(i) * 0.1)
		var p := center + Vector3(cos(a) * r, size * 0.45, sin(a) * r)
		pts.append(add_v(verts, p))
	for i in range(5):
		var ni := (i + 1) % 5
		faces.append(PackedInt32Array([i_sc, pts[i], pts[ni]]))

func add_v(verts: Array[Vector3], v: Vector3) -> int:
	verts.append(v)
	return verts.size()
