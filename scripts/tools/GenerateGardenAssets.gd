@tool
extends SceneTree

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/models")
	_generate_golden_sprout()
	_generate_mini_sprout()
	_generate_rustic_beam()
	_generate_river_stones()
	_generate_picket_fence()
	_generate_watering_can()
	_generate_flower_pot()
	_generate_grass_tuft()
	_generate_garden_bush()
	_generate_detailed_tree()
	_generate_mushroom_cluster()
	_generate_wildflower()
	print("Garden assets regenerated with grass tufts, bushes, detailed trees, mushrooms, and wildflowers.")
	quit()

# -------------------------------------------------------------
# 1. GOLDEN SPROUT
# -------------------------------------------------------------
func _generate_golden_sprout() -> void:
	var path := "res://assets/models/golden_sprout.obj"
	var verts: Array[Vector3] = []
	var faces_stem: Array[PackedInt32Array] = []
	var faces_leaves: Array[PackedInt32Array] = []
	var faces_bud: Array[PackedInt32Array] = []
	
	var stem_spine: Array[Vector3] = [
		Vector3(0, 0, 0),
		Vector3(0.06, 0.45, 0.03),
		Vector3(-0.04, 0.95, -0.02),
		Vector3(0.03, 1.45, 0.04),
		Vector3(0.0, 1.85, 0.0)
	]
	var stem_radii := [0.12, 0.10, 0.085, 0.07, 0.055]
	var prev_ring: Array[int] = []
	for p_idx in range(stem_spine.size()):
		var center := stem_spine[p_idx]
		var r: float = stem_radii[p_idx]
		var curr_ring: Array[int] = []
		for i in range(6):
			var a := float(i) * TAU / 6.0
			verts.append(center + Vector3(cos(a) * r, 0, sin(a) * r))
			curr_ring.append(verts.size())
		if p_idx > 0:
			for i in range(6):
				var n_i := (i + 1) % 6
				faces_stem.append(PackedInt32Array([prev_ring[i], curr_ring[i], curr_ring[n_i]]))
				faces_stem.append(PackedInt32Array([prev_ring[i], curr_ring[n_i], prev_ring[n_i]]))
		prev_ring = curr_ring
		
	_add_sculpted_sprout_leaf(verts, faces_leaves, stem_spine[2], Vector3(-1.1, 0.35, 0.3), 1.15, 0.55)
	_add_sculpted_sprout_leaf(verts, faces_leaves, stem_spine[2], Vector3(1.15, 0.38, -0.25), 1.2, 0.58)
	
	_add_sculpted_sprout_leaf(verts, faces_leaves, stem_spine[3], Vector3(0.45, 0.65, 0.4), 0.75, 0.35)
	_add_sculpted_sprout_leaf(verts, faces_leaves, stem_spine[3], Vector3(-0.5, 0.68, -0.35), 0.78, 0.36)
	_add_sculpted_sprout_leaf(verts, faces_leaves, stem_spine[3], Vector3(-0.25, 0.62, 0.5), 0.7, 0.32)

	var bud_center := Vector3(0.0, 2.05, 0.0)
	_add_faceted_crystal_bud(verts, faces_bud, bud_center, 0.52)

	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_line("# Golden Sprout Core")
	for v in verts:
		f.store_line("v %.4f %.4f %.4f" % [v.x, v.y, v.z])
	
	f.store_line("g Stem")
	f.store_line("usemtl SproutStem")
	for tri in faces_stem:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
		
	f.store_line("g Leaves")
	f.store_line("usemtl SproutLeaf")
	for tri in faces_leaves:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
		
	f.store_line("g Bud")
	f.store_line("usemtl SproutBud")
	for tri in faces_bud:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.close()

func _add_sculpted_sprout_leaf(verts: Array[Vector3], faces: Array[PackedInt32Array], base_pos: Vector3, dir: Vector3, length: float, width: float) -> void:
	var tip_dir := dir.normalized()
	var side_dir := tip_dir.cross(Vector3.UP).normalized()
	if side_dir.length_squared() < 0.1:
		side_dir = tip_dir.cross(Vector3.FORWARD).normalized()
	var up_dir := side_dir.cross(tip_dir).normalized()
	
	var p0 := base_pos
	var p_quarter := base_pos + tip_dir * (length * 0.35) + up_dir * (length * 0.25)
	var p_half := base_pos + tip_dir * (length * 0.7) + up_dir * (length * 0.22)
	var p_tip := base_pos + tip_dir * length - up_dir * (length * 0.08)
	
	var l_mid := p_quarter + side_dir * (width * 0.55)
	var r_mid := p_quarter - side_dir * (width * 0.55)
	var l_broad := p_half + side_dir * (width * 0.42)
	var r_broad := p_half - side_dir * (width * 0.42)
	
	var i0 := _add_vert(verts, p0)
	var i_q := _add_vert(verts, p_quarter + up_dir * (width * 0.12))
	var i_h := _add_vert(verts, p_half + up_dir * (width * 0.08))
	var i_tip := _add_vert(verts, p_tip)
	
	var i_lm := _add_vert(verts, l_mid)
	var i_rm := _add_vert(verts, r_mid)
	var i_lb := _add_vert(verts, l_broad)
	var i_rb := _add_vert(verts, r_broad)
	
	faces.append(PackedInt32Array([i0, i_lm, i_q]))
	faces.append(PackedInt32Array([i0, i_q, i_rm]))
	faces.append(PackedInt32Array([i_q, i_lm, i_lb]))
	faces.append(PackedInt32Array([i_q, i_lb, i_h]))
	faces.append(PackedInt32Array([i_q, i_h, i_rb]))
	faces.append(PackedInt32Array([i_q, i_rb, i_rm]))
	faces.append(PackedInt32Array([i_h, i_lb, i_tip]))
	faces.append(PackedInt32Array([i_h, i_tip, i_rb]))
	
	faces.append(PackedInt32Array([i0, i_q, i_lm]))
	faces.append(PackedInt32Array([i0, i_rm, i_q]))
	faces.append(PackedInt32Array([i_q, i_lb, i_lm]))
	faces.append(PackedInt32Array([i_q, i_h, i_lb]))
	faces.append(PackedInt32Array([i_q, i_rb, i_h]))
	faces.append(PackedInt32Array([i_q, i_rm, i_rb]))
	faces.append(PackedInt32Array([i_h, i_tip, i_lb]))
	faces.append(PackedInt32Array([i_h, i_rb, i_tip]))

func _add_faceted_crystal_bud(verts: Array[Vector3], faces: Array[PackedInt32Array], center: Vector3, size: float) -> void:
	var top := center + Vector3(0, size * 0.95, 0)
	var bot := center - Vector3(0, size * 0.65, 0)
	var itop := _add_vert(verts, top)
	var ibot := _add_vert(verts, bot)
	
	var ring: Array[int] = []
	for i in range(6):
		var a := float(i) * TAU / 6.0
		var pos := center + Vector3(cos(a) * size * 0.55, sin(a * 2.0) * size * 0.1, sin(a) * size * 0.55)
		ring.append(_add_vert(verts, pos))
		
	for i in range(6):
		var ni := (i + 1) % 6
		faces.append(PackedInt32Array([itop, ring[ni], ring[i]]))
		faces.append(PackedInt32Array([ibot, ring[i], ring[ni]]))

# -------------------------------------------------------------
# 2. MINI SPROUT
# -------------------------------------------------------------
func _generate_mini_sprout() -> void:
	var path := "res://assets/models/mini_sprout.obj"
	var verts: Array[Vector3] = []
	var faces: Array[PackedInt32Array] = []
	
	var base := Vector3(0, 0, 0)
	var top := Vector3(0, 0.32, 0)
	var r := 0.035
	var b_ring: Array[int] = []
	var t_ring: Array[int] = []
	for i in range(5):
		var a := float(i) * TAU / 5.0
		b_ring.append(_add_vert(verts, base + Vector3(cos(a) * r, 0, sin(a) * r)))
		t_ring.append(_add_vert(verts, top + Vector3(cos(a) * (r * 0.7), 0, sin(a) * (r * 0.7))))
	for i in range(5):
		var ni := (i + 1) % 5
		faces.append(PackedInt32Array([b_ring[i], t_ring[i], t_ring[ni]]))
		faces.append(PackedInt32Array([b_ring[i], t_ring[ni], b_ring[ni]]))
		
	_add_sculpted_sprout_leaf(verts, faces, top, Vector3(-0.28, 0.18, 0.06), 0.32, 0.18)
	_add_sculpted_sprout_leaf(verts, faces, top, Vector3(0.28, 0.20, -0.06), 0.32, 0.18)
	
	var ipip := _add_vert(verts, top + Vector3(0, 0.1, 0))
	for i in range(5):
		var ni := (i + 1) % 5
		faces.append(PackedInt32Array([ipip, t_ring[ni], t_ring[i]]))
		
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_line("# Mini Sprout Indicator")
	for v in verts:
		f.store_line("v %.4f %.4f %.4f" % [v.x, v.y, v.z])
	f.store_line("g MiniSprout")
	f.store_line("usemtl MiniSproutMat")
	for tri in faces:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.close()

# -------------------------------------------------------------
# 3. RUSTIC WOODEN BEAM
# -------------------------------------------------------------
func _generate_rustic_beam() -> void:
	var path := "res://assets/models/rustic_beam.obj"
	var verts: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	var faces: Array[PackedInt32Array] = []
	
	var w: float = 0.20
	var h: float = 0.30
	var c: float = 0.04
	var profile: Array[Vector2] = [
		Vector2(-w + c, -h),
		Vector2(w - c, -h),
		Vector2(w, -h + c),
		Vector2(w, h - c),
		Vector2(w - c, h),
		Vector2(-w + c, h),
		Vector2(-w, h - c),
		Vector2(-w, -h + c)
	]
	
	var x_coords := [-2.0, -1.0, 0.0, 1.0, 2.0]
	var rings: Array[Array] = []
	
	for s_idx in range(x_coords.size()):
		var x: float = x_coords[s_idx]
		var ring: Array[int] = []
		var wobble_y := sin(x * 1.5) * 0.012
		var wobble_z := cos(x * 1.8) * 0.01
		for p in profile:
			verts.append(Vector3(x, p.y + wobble_y + h, p.x + wobble_z))
			uvs.append(Vector2((x + 2.0) * 0.5, (p.y + h) * 1.2))
			ring.append(verts.size())
		rings.append(ring)
		
	for s in range(rings.size() - 1):
		var r1: Array = rings[s]
		var r2: Array = rings[s + 1]
		for i in range(profile.size()):
			var ni := (i + 1) % profile.size()
			faces.append(PackedInt32Array([r1[i], r2[i], r2[ni]]))
			faces.append(PackedInt32Array([r1[i], r2[ni], r1[ni]]))
			
	var end_left := _add_vert(verts, Vector3(-2.0, h, 0))
	uvs.append(Vector2(0, 0))
	for i in range(profile.size()):
		var ni := (i + 1) % profile.size()
		faces.append(PackedInt32Array([end_left, rings[0][i], rings[0][ni]]))
		
	var end_right := _add_vert(verts, Vector3(2.0, h, 0))
	uvs.append(Vector2(1, 1))
	for i in range(profile.size()):
		var ni := (i + 1) % profile.size()
		faces.append(PackedInt32Array([end_right, rings[rings.size() - 1][ni], rings[rings.size() - 1][i]]))
		
	for peg_x in [-1.5, 1.5]:
		var peg_center := Vector3(peg_x, h * 2.0 + 0.02, 0.0)
		var p_top := _add_vert(verts, peg_center + Vector3(0, 0.045, 0))
		uvs.append(Vector2(0.5, 0.5))
		var peg_ring: Array[int] = []
		for i in range(6):
			var a := float(i) * TAU / 6.0
			var pv := peg_center + Vector3(cos(a) * 0.04, 0, sin(a) * 0.04)
			peg_ring.append(_add_vert(verts, pv))
			uvs.append(Vector2(0.5 + cos(a) * 0.1, 0.5 + sin(a) * 0.1))
		for i in range(6):
			var ni := (i + 1) % 6
			faces.append(PackedInt32Array([p_top, peg_ring[ni], peg_ring[i]]))
			
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_line("# Rustic Garden Beam")
	for i in range(verts.size()):
		f.store_line("v %.4f %.4f %.4f" % [verts[i].x, verts[i].y, verts[i].z])
	for uv in uvs:
		f.store_line("vt %.4f %.4f" % [uv.x, uv.y])
	f.store_line("g RusticBeam")
	f.store_line("usemtl BeamWoodMat")
	for tri in faces:
		f.store_line("f %d/%d %d/%d %d/%d" % [tri[0], tri[0], tri[1], tri[1], tri[2], tri[2]])
	f.close()

# -------------------------------------------------------------
# 4. RIVER STONES
# -------------------------------------------------------------
func _generate_river_stones() -> void:
	var path := "res://assets/models/river_stones.obj"
	var verts: Array[Vector3] = []
	var faces: Array[PackedInt32Array] = []
	
	var stones := [
		{"pos": Vector3(0.0, 0.26, 0.0), "scale": Vector3(0.55, 0.32, 0.48), "rot": 0.3},
		{"pos": Vector3(0.42, 0.18, 0.22), "scale": Vector3(0.40, 0.22, 0.36), "rot": 1.2},
		{"pos": Vector3(-0.38, 0.16, 0.20), "scale": Vector3(0.36, 0.20, 0.42), "rot": 2.4},
		{"pos": Vector3(0.06, 0.44, 0.06), "scale": Vector3(0.32, 0.18, 0.30), "rot": 0.8}
	]
	
	for s in stones:
		_add_faceted_stone(verts, faces, s.pos, s.scale, s.rot)
		
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_line("# River Stones Cluster")
	for v in verts:
		f.store_line("v %.4f %.4f %.4f" % [v.x, v.y, v.z])
	f.store_line("g RiverStones")
	f.store_line("usemtl StoneMat")
	for tri in faces:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.close()

func _add_faceted_stone(verts: Array[Vector3], faces: Array[PackedInt32Array], center: Vector3, size: Vector3, rot_y: float) -> void:
	var top := center + Vector3(0, size.y, 0)
	var bot := center - Vector3(0, size.y * 0.8, 0)
	var itop := _add_vert(verts, top)
	var ibot := _add_vert(verts, bot)
	
	var r_upper: Array[int] = []
	var r_lower: Array[int] = []
	for i in range(8):
		var a := float(i) * TAU / 8.0 + rot_y
		var jitter := 1.0 + sin(a * 3.0) * 0.12
		var px := cos(a) * size.x * jitter
		var pz := sin(a) * size.z * jitter
		r_upper.append(_add_vert(verts, center + Vector3(px * 0.85, size.y * 0.45, pz * 0.85)))
		r_lower.append(_add_vert(verts, center + Vector3(px, -size.y * 0.15, pz)))
		
	for i in range(8):
		var ni := (i + 1) % 8
		faces.append(PackedInt32Array([itop, r_upper[ni], r_upper[i]]))
		faces.append(PackedInt32Array([r_upper[i], r_upper[ni], r_lower[ni]]))
		faces.append(PackedInt32Array([r_upper[i], r_lower[ni], r_lower[i]]))
		faces.append(PackedInt32Array([ibot, r_lower[i], r_lower[ni]]))

# -------------------------------------------------------------
# 5. PICKET FENCE SEGMENT (4m wide, charming cottage fence)
# -------------------------------------------------------------
func _generate_picket_fence() -> void:
	var path := "res://assets/models/picket_fence.obj"
	var verts: Array[Vector3] = []
	var faces: Array[PackedInt32Array] = []
	
	# Sturdy square post at x = 2.0 (height 2.0m, width 0.22m)
	_add_box(verts, faces, Vector3(2.0, 0.9, 0), Vector3(0.24, 1.8, 0.24))
	# Post pyramid cap
	_add_pyramid_cap(verts, faces, Vector3(2.0, 1.8, 0), 0.28, 0.2)
	
	# Two horizontal rails spanning from x = -2.0 to x = +2.0
	_add_box(verts, faces, Vector3(0, 0.55, 0), Vector3(4.0, 0.14, 0.08))
	_add_box(verts, faces, Vector3(0, 1.25, 0), Vector3(4.0, 0.14, 0.08))
	
	# 7 vertical pickets with pointed tips
	# spacing: -1.75, -1.25, -0.75, -0.25, 0.25, 0.75, 1.25, 1.75
	var picket_xs := [-1.75, -1.25, -0.75, -0.25, 0.25, 0.75, 1.25, 1.75]
	for px in picket_xs:
		var picket_w := 0.22
		var picket_t := 0.04
		var picket_h := 1.5
		_add_box(verts, faces, Vector3(px, picket_h * 0.5, 0.06), Vector3(picket_w, picket_h, picket_t))
		# Pointed top triangle
		_add_picket_tip(verts, faces, Vector3(px, picket_h, 0.06), picket_w, picket_t, 0.25)
		
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_line("# Picket Fence Segment")
	for v in verts:
		f.store_line("v %.4f %.4f %.4f" % [v.x, v.y, v.z])
	f.store_line("g PicketFence")
	f.store_line("usemtl FenceWoodMat")
	for tri in faces:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.close()

func _add_box(verts: Array[Vector3], faces: Array[PackedInt32Array], center: Vector3, size: Vector3) -> void:
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5
	
	var v := [
		center + Vector3(-hx, -hy, -hz), # 0
		center + Vector3(hx, -hy, -hz),  # 1
		center + Vector3(hx, hy, -hz),   # 2
		center + Vector3(-hx, hy, -hz),  # 3
		center + Vector3(-hx, -hy, hz),  # 4
		center + Vector3(hx, -hy, hz),   # 5
		center + Vector3(hx, hy, hz),    # 6
		center + Vector3(-hx, hy, hz)    # 7
	]
	var idx: Array[int] = []
	for p in v:
		idx.append(_add_vert(verts, p))
		
	# Front (+Z): 4, 5, 6, 7
	faces.append(PackedInt32Array([idx[4], idx[5], idx[6]]))
	faces.append(PackedInt32Array([idx[4], idx[6], idx[7]]))
	# Back (-Z): 1, 0, 3, 2
	faces.append(PackedInt32Array([idx[1], idx[0], idx[3]]))
	faces.append(PackedInt32Array([idx[1], idx[3], idx[2]]))
	# Top (+Y): 3, 2, 6, 7
	faces.append(PackedInt32Array([idx[3], idx[2], idx[6]]))
	faces.append(PackedInt32Array([idx[3], idx[6], idx[7]]))
	# Bottom (-Y): 0, 1, 5, 4
	faces.append(PackedInt32Array([idx[0], idx[4], idx[5]]))
	faces.append(PackedInt32Array([idx[0], idx[5], idx[1]]))
	# Right (+X): 1, 2, 6, 5
	faces.append(PackedInt32Array([idx[1], idx[2], idx[6]]))
	faces.append(PackedInt32Array([idx[1], idx[6], idx[5]]))
	# Left (-X): 0, 4, 7, 3
	faces.append(PackedInt32Array([idx[0], idx[7], idx[3]]))
	faces.append(PackedInt32Array([idx[0], idx[4], idx[7]]))

func _add_pyramid_cap(verts: Array[Vector3], faces: Array[PackedInt32Array], base_center: Vector3, width: float, height: float) -> void:
	var hw := width * 0.5
	var apex := _add_vert(verts, base_center + Vector3(0, height, 0))
	var c0 := _add_vert(verts, base_center + Vector3(-hw, 0, -hw))
	var c1 := _add_vert(verts, base_center + Vector3(hw, 0, -hw))
	var c2 := _add_vert(verts, base_center + Vector3(hw, 0, hw))
	var c3 := _add_vert(verts, base_center + Vector3(-hw, 0, hw))
	
	faces.append(PackedInt32Array([apex, c1, c0]))
	faces.append(PackedInt32Array([apex, c2, c1]))
	faces.append(PackedInt32Array([apex, c3, c2]))
	faces.append(PackedInt32Array([apex, c0, c3]))

func _add_picket_tip(verts: Array[Vector3], faces: Array[PackedInt32Array], base_center: Vector3, width: float, depth: float, height: float) -> void:
	var hw := width * 0.5
	var hd := depth * 0.5
	var tip_front := _add_vert(verts, base_center + Vector3(0, height, hd))
	var tip_back := _add_vert(verts, base_center + Vector3(0, height, -hd))
	var blf := _add_vert(verts, base_center + Vector3(-hw, 0, hd))
	var brf := _add_vert(verts, base_center + Vector3(hw, 0, hd))
	var blb := _add_vert(verts, base_center + Vector3(-hw, 0, -hd))
	var brb := _add_vert(verts, base_center + Vector3(hw, 0, -hd))
	
	# Front triangle
	faces.append(PackedInt32Array([blf, brf, tip_front]))
	# Back triangle
	faces.append(PackedInt32Array([brb, blb, tip_back]))
	# Left slope
	faces.append(PackedInt32Array([blb, blf, tip_front]))
	faces.append(PackedInt32Array([blb, tip_front, tip_back]))
	# Right slope
	faces.append(PackedInt32Array([brf, brb, tip_back]))
	faces.append(PackedInt32Array([brf, tip_back, tip_front]))

# -------------------------------------------------------------
# 6. WATERING CAN (Giant prop emphasizing shrunk-down perspective)
# -------------------------------------------------------------
func _generate_watering_can() -> void:
	var path := "res://assets/models/watering_can.obj"
	var verts: Array[Vector3] = []
	var faces_body: Array[PackedInt32Array] = []
	var faces_handle: Array[PackedInt32Array] = []
	
	# Can body: 8-sided tapered cylinder, radius ~1.2m, height ~2.4m
	var h := 2.4
	var r_bot := 1.1
	var r_top := 0.85
	var b_ring: Array[int] = []
	var t_ring: Array[int] = []
	for i in range(8):
		var a := float(i) * TAU / 8.0
		b_ring.append(_add_vert(verts, Vector3(cos(a) * r_bot, 0, sin(a) * r_bot)))
		t_ring.append(_add_vert(verts, Vector3(cos(a) * r_top, h, sin(a) * r_top)))
	for i in range(8):
		var ni := (i + 1) % 8
		faces_body.append(PackedInt32Array([b_ring[i], t_ring[i], t_ring[ni]]))
		faces_body.append(PackedInt32Array([b_ring[i], t_ring[ni], b_ring[ni]]))
		
	# Top lid (recessed)
	var top_center := _add_vert(verts, Vector3(0, h * 0.95, 0))
	for i in range(8):
		var ni := (i + 1) % 8
		faces_body.append(PackedInt32Array([top_center, t_ring[ni], t_ring[i]]))
		
	# Spout: angled tube extending out to the front-right
	var spout_base := Vector3(0.7, 0.4, 0)
	var spout_tip := Vector3(2.6, 2.8, 0)
	var sr_base := 0.28
	var sr_tip := 0.16
	var s_b_ring: Array[int] = []
	var s_t_ring: Array[int] = []
	for i in range(6):
		var a := float(i) * TAU / 6.0
		s_b_ring.append(_add_vert(verts, spout_base + Vector3(0, cos(a) * sr_base, sin(a) * sr_base)))
		s_t_ring.append(_add_vert(verts, spout_tip + Vector3(0, cos(a) * sr_tip, sin(a) * sr_tip)))
	for i in range(6):
		var ni := (i + 1) % 6
		faces_body.append(PackedInt32Array([s_b_ring[i], s_t_ring[i], s_t_ring[ni]]))
		faces_body.append(PackedInt32Array([s_b_ring[i], s_t_ring[ni], s_b_ring[ni]]))
		
	# Rose (sprinkler disc at spout tip)
	var rose_center := spout_tip + Vector3(0.2, 0.1, 0)
	var rose_top := _add_vert(verts, rose_center + Vector3(0.12, 0.12, 0))
	var rose_ring: Array[int] = []
	for i in range(8):
		var a := float(i) * TAU / 8.0
		rose_ring.append(_add_vert(verts, rose_center + Vector3(-0.05 + cos(a) * 0.42, sin(a) * 0.42, 0)))
	for i in range(8):
		var ni := (i + 1) % 8
		faces_body.append(PackedInt32Array([rose_top, rose_ring[ni], rose_ring[i]]))
		
	# Overhead arched handle
	var handle_pts: Array[Vector3] = [
		Vector3(0.4, h, 0),
		Vector3(0.2, h + 0.8, 0),
		Vector3(-0.5, h + 0.9, 0),
		Vector3(-1.1, h + 0.4, 0),
		Vector3(-1.1, 0.6, 0)
	]
	var h_rad := 0.08
	var prev_h_ring: Array[int] = []
	for p_idx in range(handle_pts.size()):
		var cp := handle_pts[p_idx]
		var cur_ring: Array[int] = []
		for i in range(5):
			var a := float(i) * TAU / 5.0
			cur_ring.append(_add_vert(verts, cp + Vector3(0, cos(a) * h_rad, sin(a) * h_rad)))
		if p_idx > 0:
			for i in range(5):
				var ni := (i + 1) % 5
				faces_handle.append(PackedInt32Array([prev_h_ring[i], cur_ring[i], cur_ring[ni]]))
				faces_handle.append(PackedInt32Array([prev_h_ring[i], cur_ring[ni], prev_h_ring[ni]]))
		prev_h_ring = cur_ring
		
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_line("# Garden Watering Can")
	for v in verts:
		f.store_line("v %.4f %.4f %.4f" % [v.x, v.y, v.z])
	f.store_line("g CanBody")
	f.store_line("usemtl CanBodyMat")
	for tri in faces_body:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.store_line("g CanHandle")
	f.store_line("usemtl CanHandleMat")
	for tri in faces_handle:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.close()

# -------------------------------------------------------------
# 7. FLOWER POT (Terracotta pot prop)
# -------------------------------------------------------------
func _generate_flower_pot() -> void:
	var path := "res://assets/models/flower_pot.obj"
	var verts: Array[Vector3] = []
	var faces_pot: Array[PackedInt32Array] = []
	var faces_soil: Array[PackedInt32Array] = []
	
	var r_base := 0.7
	var r_rim_bot := 1.05
	var r_rim_top := 1.15
	var h_pot := 1.4
	var h_rim := 0.35
	
	var ring_b: Array[int] = []
	var ring_m: Array[int] = []
	var ring_r_b: Array[int] = []
	var ring_r_t: Array[int] = []
	for i in range(8):
		var a := float(i) * TAU / 8.0
		ring_b.append(_add_vert(verts, Vector3(cos(a) * r_base, 0, sin(a) * r_base)))
		ring_m.append(_add_vert(verts, Vector3(cos(a) * r_rim_bot, h_pot - h_rim, sin(a) * r_rim_bot)))
		ring_r_b.append(_add_vert(verts, Vector3(cos(a) * r_rim_top, h_pot - h_rim, sin(a) * r_rim_top)))
		ring_r_t.append(_add_vert(verts, Vector3(cos(a) * r_rim_top, h_pot, sin(a) * r_rim_top)))
		
	for i in range(8):
		var ni := (i + 1) % 8
		# Base to rim under
		faces_pot.append(PackedInt32Array([ring_b[i], ring_m[i], ring_m[ni]]))
		faces_pot.append(PackedInt32Array([ring_b[i], ring_m[ni], ring_b[ni]]))
		# Rim overhang
		faces_pot.append(PackedInt32Array([ring_m[i], ring_r_b[i], ring_r_b[ni]]))
		faces_pot.append(PackedInt32Array([ring_m[i], ring_r_b[ni], ring_m[ni]]))
		# Rim outer face
		faces_pot.append(PackedInt32Array([ring_r_b[i], ring_r_t[i], ring_r_t[ni]]))
		faces_pot.append(PackedInt32Array([ring_r_b[i], ring_r_t[ni], ring_r_b[ni]]))
		
	# Soil inside
	var soil_center := _add_vert(verts, Vector3(0, h_pot - 0.12, 0))
	for i in range(8):
		var ni := (i + 1) % 8
		faces_soil.append(PackedInt32Array([soil_center, ring_r_t[ni], ring_r_t[i]]))
		
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_line("# Terracotta Flower Pot")
	for v in verts:
		f.store_line("v %.4f %.4f %.4f" % [v.x, v.y, v.z])
	f.store_line("g Pot")
	f.store_line("usemtl PotMat")
	for tri in faces_pot:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.store_line("g Soil")
	f.store_line("usemtl SoilMat")
	for tri in faces_soil:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.close()

# -------------------------------------------------------------
# 8. GRASS TUFT (Stylized faceted tall garden grass)
# -------------------------------------------------------------
func _generate_grass_tuft() -> void:
	var path := "res://assets/models/grass_tuft.obj"
	var verts: Array[Vector3] = []
	var faces: Array[PackedInt32Array] = []
	
	var blade_defs := [
		{"a": 0.2, "h": 1.1, "curve": 0.45, "w": 0.14},
		{"a": 0.9, "h": 0.85, "curve": 0.38, "w": 0.12},
		{"a": 1.6, "h": 1.25, "curve": 0.52, "w": 0.15},
		{"a": 2.3, "h": 0.95, "curve": 0.42, "w": 0.13},
		{"a": 3.0, "h": 1.15, "curve": 0.48, "w": 0.14},
		{"a": 3.7, "h": 0.78, "curve": 0.35, "w": 0.11},
		{"a": 4.4, "h": 1.05, "curve": 0.46, "w": 0.13},
		{"a": 5.1, "h": 0.9, "curve": 0.4, "w": 0.12},
		{"a": 5.8, "h": 1.2, "curve": 0.5, "w": 0.15}
	]
	
	for bd in blade_defs:
		var angle: float = bd.a
		var h: float = bd.h
		var curve: float = bd.curve
		var w: float = bd.w
		
		var dir := Vector3(cos(angle), 0, sin(angle))
		var side := dir.cross(Vector3.UP).normalized()
		
		var root_pos := dir * 0.08
		var mid_pos := root_pos + dir * (curve * 0.5) + Vector3(0, h * 0.55, 0)
		var tip_pos := root_pos + dir * curve + Vector3(0, h * 0.88, 0)
		
		var r_l := _add_vert(verts, root_pos + side * (w * 0.4))
		var r_r := _add_vert(verts, root_pos - side * (w * 0.4))
		var m_spine := _add_vert(verts, mid_pos + dir * (w * 0.15))
		var m_l := _add_vert(verts, mid_pos + side * (w * 0.5))
		var m_r := _add_vert(verts, mid_pos - side * (w * 0.5))
		var tip := _add_vert(verts, tip_pos)
		
		# Front faces
		faces.append(PackedInt32Array([r_l, m_l, m_spine]))
		faces.append(PackedInt32Array([r_l, m_spine, r_r]))
		faces.append(PackedInt32Array([r_r, m_spine, m_r]))
		faces.append(PackedInt32Array([m_l, tip, m_spine]))
		faces.append(PackedInt32Array([m_spine, tip, m_r]))
		
		# Back faces
		faces.append(PackedInt32Array([r_l, m_spine, m_l]))
		faces.append(PackedInt32Array([r_l, r_r, m_spine]))
		faces.append(PackedInt32Array([r_r, m_r, m_spine]))
		faces.append(PackedInt32Array([m_l, m_spine, tip]))
		faces.append(PackedInt32Array([m_spine, m_r, tip]))
		
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_line("# Tall Grass Tuft")
	for v in verts:
		f.store_line("v %.4f %.4f %.4f" % [v.x, v.y, v.z])
	f.store_line("g Grass")
	f.store_line("usemtl GrassMat")
	for tri in faces:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.close()

# -------------------------------------------------------------
# 9. GARDEN BUSH (Faceted leafy shrub)
# -------------------------------------------------------------
func _generate_garden_bush() -> void:
	var path := "res://assets/models/garden_bush.obj"
	var verts: Array[Vector3] = []
	var faces: Array[PackedInt32Array] = []
	
	var lobes := [
		{"pos": Vector3(0, 0.75, 0), "size": Vector3(0.9, 0.75, 0.85), "rot": 0.2},
		{"pos": Vector3(0.55, 0.55, 0.35), "size": Vector3(0.75, 0.65, 0.7), "rot": 1.1},
		{"pos": Vector3(-0.6, 0.5, 0.25), "size": Vector3(0.7, 0.6, 0.75), "rot": 2.2},
		{"pos": Vector3(0.1, 0.45, -0.65), "size": Vector3(0.75, 0.6, 0.7), "rot": 3.4},
		{"pos": Vector3(-0.15, 1.15, -0.1), "size": Vector3(0.65, 0.55, 0.6), "rot": 0.7}
	]
	
	for l in lobes:
		_add_faceted_stone(verts, faces, l.pos, l.size, l.rot)
		
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_line("# Garden Bush")
	for v in verts:
		f.store_line("v %.4f %.4f %.4f" % [v.x, v.y, v.z])
	f.store_line("g Bush")
	f.store_line("usemtl BushFoliageMat")
	for tri in faces:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.close()

# -------------------------------------------------------------
# 10. DETAILED BRANCHING TREE TRUNK
# -------------------------------------------------------------
func _generate_detailed_tree() -> void:
	var path := "res://assets/models/detailed_tree.obj"
	var verts: Array[Vector3] = []
	var faces: Array[PackedInt32Array] = []
	
	# Main trunk spine: from ground up to branching point at y=5.5
	var spine: Array[Vector3] = [
		Vector3(0, 0, 0),
		Vector3(0.15, 1.8, -0.1),
		Vector3(-0.1, 3.6, 0.15),
		Vector3(0.05, 5.5, 0.0)
	]
	var radii := [1.25, 0.95, 0.75, 0.62]
	var prev_ring: Array[int] = []
	for p_idx in range(spine.size()):
		var cp := spine[p_idx]
		var r: float = radii[p_idx]
		var cur_ring: Array[int] = []
		for i in range(8):
			var a := float(i) * TAU / 8.0
			var root_flare: float = 1.0
			if p_idx == 0 and (i % 2 == 0):
				root_flare = 1.35 # root buttresses at ground
			verts.append(cp + Vector3(cos(a) * r * root_flare, 0, sin(a) * r * root_flare))
			cur_ring.append(verts.size())
		if p_idx > 0:
			for i in range(8):
				var ni := (i + 1) % 8
				faces.append(PackedInt32Array([prev_ring[i], cur_ring[i], cur_ring[ni]]))
				faces.append(PackedInt32Array([prev_ring[i], cur_ring[ni], prev_ring[ni]]))
		prev_ring = cur_ring
		
	# 3 Branches extending outward from spine[3]
	_add_tree_limb(verts, faces, spine[3], Vector3(-2.6, 3.8, 1.4), 0.38, 0.18)
	_add_tree_limb(verts, faces, spine[3], Vector3(2.8, 4.2, -1.2), 0.42, 0.2)
	_add_tree_limb(verts, faces, spine[3], Vector3(0.5, 4.8, 2.2), 0.36, 0.16)
	
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_line("# Detailed Branching Tree")
	for v in verts:
		f.store_line("v %.4f %.4f %.4f" % [v.x, v.y, v.z])
	f.store_line("g TreeTrunk")
	f.store_line("usemtl TreeTrunkMat")
	for tri in faces:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.close()

func _add_tree_limb(verts: Array[Vector3], faces: Array[PackedInt32Array], start_pos: Vector3, offset: Vector3, r_start: float, r_end: float) -> void:
	var end_pos := start_pos + offset
	var dir := offset.normalized()
	var side := dir.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.1:
		side = dir.cross(Vector3.FORWARD).normalized()
	var up := side.cross(dir).normalized()
	
	var b_ring: Array[int] = []
	var t_ring: Array[int] = []
	for i in range(6):
		var a := float(i) * TAU / 6.0
		var cos_a := cos(a)
		var sin_a := sin(a)
		b_ring.append(_add_vert(verts, start_pos + (side * cos_a + up * sin_a) * r_start))
		t_ring.append(_add_vert(verts, end_pos + (side * cos_a + up * sin_a) * r_end))
	for i in range(6):
		var ni := (i + 1) % 6
		faces.append(PackedInt32Array([b_ring[i], t_ring[i], t_ring[ni]]))
		faces.append(PackedInt32Array([b_ring[i], t_ring[ni], b_ring[ni]]))

func _add_vert(verts: Array[Vector3], v: Vector3) -> int:
	verts.append(v)
	return verts.size()

# -------------------------------------------------------------
# 11. MUSHROOM CLUSTER (Capped Toadstools with Toon Facets)
# -------------------------------------------------------------
func _generate_mushroom_cluster() -> void:
	var path := "res://assets/models/mushroom_cluster.obj"
	var verts: Array[Vector3] = []
	var faces_cap: Array[PackedInt32Array] = []
	var faces_stem: Array[PackedInt32Array] = []
	
	# Shroom 1: Large primary toadstool
	_add_single_mushroom(verts, faces_stem, faces_cap, Vector3(0, 0, 0), 0.52, 0.44, Vector3(0.04, 0.0, 0.02))
	# Shroom 2: Medium companion shroom
	_add_single_mushroom(verts, faces_stem, faces_cap, Vector3(0.32, 0, 0.16), 0.38, 0.32, Vector3(0.08, 0.0, 0.05))
	# Shroom 3: Small cute button shroom
	_add_single_mushroom(verts, faces_stem, faces_cap, Vector3(-0.25, 0, 0.22), 0.24, 0.22, Vector3(-0.04, 0.0, 0.03))

	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_line("# Stylized Mushroom Cluster")
	for v in verts:
		f.store_line("v %.4f %.4f %.4f" % [v.x, v.y, v.z])
	f.store_line("g Cap")
	f.store_line("usemtl MushroomCap")
	for tri in faces_cap:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.store_line("g Stem")
	f.store_line("usemtl MushroomStem")
	for tri in faces_stem:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.close()

func _add_single_mushroom(verts: Array[Vector3], faces_stem: Array[PackedInt32Array], faces_cap: Array[PackedInt32Array], base_pos: Vector3, total_height: float, cap_radius: float, tilt: Vector3) -> void:
	# Stem: 4 rings of 6 segments
	var stem_h := total_height * 0.72
	var stem_radii := [cap_radius * 0.28, cap_radius * 0.22, cap_radius * 0.20, cap_radius * 0.24]
	var stem_spine: Array[Vector3] = [
		base_pos,
		base_pos + Vector3(0, stem_h * 0.33, 0) + tilt * 0.3,
		base_pos + Vector3(0, stem_h * 0.66, 0) + tilt * 0.7,
		base_pos + Vector3(0, stem_h, 0) + tilt
	]
	
	var prev_ring: Array[int] = []
	for p_idx in range(4):
		var cp := stem_spine[p_idx]
		var r: float = stem_radii[p_idx]
		var cur_ring: Array[int] = []
		for i in range(6):
			var a := float(i) * TAU / 6.0
			cur_ring.append(_add_vert(verts, cp + Vector3(cos(a) * r, 0, sin(a) * r)))
		if p_idx > 0:
			for i in range(6):
				var ni := (i + 1) % 6
				faces_stem.append(PackedInt32Array([prev_ring[i], cur_ring[i], cur_ring[ni]]))
				faces_stem.append(PackedInt32Array([prev_ring[i], cur_ring[ni], prev_ring[ni]]))
		prev_ring = cur_ring
		
	# Cap: Dome with 8 segments, underside undercut rim, bulbous waist, and rounded top
	var cap_center := stem_spine[3]
	var cap_rim_y := cap_center.y - total_height * 0.08
	var cap_mid_y := cap_center.y + total_height * 0.16
	var cap_tip_y := cap_center.y + total_height * 0.38
	
	var rim_ring: Array[int] = []
	var mid_ring: Array[int] = []
	
	# Inner rim / underside
	for i in range(8):
		var a := float(i) * TAU / 8.0
		var r_rim := cap_radius * 0.95
		rim_ring.append(_add_vert(verts, Vector3(cap_center.x + cos(a) * r_rim, cap_rim_y, cap_center.z + sin(a) * r_rim)))
		
	# Mid bulbous ring
	for i in range(8):
		var a := float(i) * TAU / 8.0
		var r_mid := cap_radius
		mid_ring.append(_add_vert(verts, Vector3(cap_center.x + cos(a) * r_mid, cap_mid_y, cap_center.z + sin(a) * r_mid)))

	# Tip
	var tip_idx := _add_vert(verts, Vector3(cap_center.x, cap_tip_y, cap_center.z))

	# Connect stem top to inner cap rim (underside / gills)
	for i in range(8):
		var ni := (i + 1) % 8
		# Outer rim to mid ring
		faces_cap.append(PackedInt32Array([rim_ring[i], mid_ring[i], mid_ring[ni]]))
		faces_cap.append(PackedInt32Array([rim_ring[i], mid_ring[ni], rim_ring[ni]]))
		# Mid ring to tip
		faces_cap.append(PackedInt32Array([mid_ring[i], tip_idx, mid_ring[ni]]))
		# Underside face to stem top
		faces_cap.append(PackedInt32Array([rim_ring[i], rim_ring[ni], prev_ring[i % 6]]))

# -------------------------------------------------------------
# 12. WILDFLOWER CLUSTER (Dandelions & Field Daisies)
# -------------------------------------------------------------
func _generate_wildflower() -> void:
	var path := "res://assets/models/wildflower_cluster.obj"
	var verts: Array[Vector3] = []
	var faces_stem: Array[PackedInt32Array] = []
	var faces_puff: Array[PackedInt32Array] = []
	var faces_petals: Array[PackedInt32Array] = []
	var faces_center: Array[PackedInt32Array] = []

	# 1. Dandelion Puffball Stem & Head
	var puff_head := _add_curved_flower_stem(verts, faces_stem, Vector3(0, 0, 0), Vector3(0.04, 0.65, 0.02), 0.028, 0.018)
	_add_puffball_sphere(verts, faces_puff, puff_head, 0.18)

	# 2. Open Daisy Stem & Head
	var daisy_head := _add_curved_flower_stem(verts, faces_stem, Vector3(0.18, 0, 0.12), Vector3(0.24, 0.52, 0.15), 0.024, 0.015)
	_add_daisy_flower(verts, faces_petals, faces_center, daisy_head, Vector3(0.2, 0.95, 0.2).normalized(), 0.16)

	# 3. Small Budding Wildflower
	var small_head := _add_curved_flower_stem(verts, faces_stem, Vector3(-0.16, 0, 0.08), Vector3(-0.22, 0.38, 0.12), 0.022, 0.014)
	_add_daisy_flower(verts, faces_petals, faces_center, small_head, Vector3(-0.3, 0.9, 0.2).normalized(), 0.11)

	# 4. Basal Serrated Leaves
	_add_serrated_ground_leaf(verts, faces_stem, Vector3(0, 0, 0), Vector3(-0.32, 0.05, 0.15), 0.35, 0.09)
	_add_serrated_ground_leaf(verts, faces_stem, Vector3(0, 0, 0), Vector3(0.28, 0.05, -0.2), 0.32, 0.085)
	_add_serrated_ground_leaf(verts, faces_stem, Vector3(0, 0, 0), Vector3(-0.1, 0.04, -0.28), 0.3, 0.08)

	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_line("# Painterly Wildflower Cluster")
	for v in verts:
		f.store_line("v %.4f %.4f %.4f" % [v.x, v.y, v.z])
	f.store_line("g FlowerStem")
	f.store_line("usemtl FlowerStemMat")
	for tri in faces_stem:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.store_line("g DandelionPuff")
	f.store_line("usemtl DandelionPuffMat")
	for tri in faces_puff:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.store_line("g DaisyPetal")
	f.store_line("usemtl DaisyPetalMat")
	for tri in faces_petals:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.store_line("g DaisyCenter")
	f.store_line("usemtl DaisyCenterMat")
	for tri in faces_center:
		f.store_line("f %d %d %d" % [tri[0], tri[1], tri[2]])
	f.close()

func _add_curved_flower_stem(verts: Array[Vector3], faces: Array[PackedInt32Array], base_pos: Vector3, top_pos: Vector3, r_base: float, r_top: float) -> Vector3:
	var mid1 := base_pos.lerp(top_pos, 0.33) + Vector3(0.03, 0, 0.02)
	var mid2 := base_pos.lerp(top_pos, 0.66) - Vector3(0.02, 0, 0.03)
	var spine := [base_pos, mid1, mid2, top_pos]
	var prev_ring: Array[int] = []
	for p in range(4):
		var cp: Vector3 = spine[p]
		var r := lerpf(r_base, r_top, float(p) / 3.0)
		var ring: Array[int] = []
		for i in range(5):
			var a := float(i) * TAU / 5.0
			ring.append(_add_vert(verts, cp + Vector3(cos(a) * r, 0, sin(a) * r)))
		if p > 0:
			for i in range(5):
				var ni := (i + 1) % 5
				faces.append(PackedInt32Array([prev_ring[i], ring[i], ring[ni]]))
				faces.append(PackedInt32Array([prev_ring[i], ring[ni], prev_ring[ni]]))
		prev_ring = ring
	return top_pos

func _add_puffball_sphere(verts: Array[Vector3], faces: Array[PackedInt32Array], center: Vector3, radius: float) -> void:
	# Low-poly faceted puffball (3 latitude rings, 8 segments)
	var rings: Array[Array] = []
	for lat in range(1, 4):
		var phi := float(lat) * PI / 4.0
		var ring: Array[int] = []
		for lon in range(8):
			var theta := float(lon) * TAU / 8.0
			var r_fac := 1.0 + (float((lon + lat) % 3) - 1.0) * 0.08 # faceted fuzz
			var offset := Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta)) * radius * r_fac
			ring.append(_add_vert(verts, center + offset))
		rings.append(ring)
	var top_pt := _add_vert(verts, center + Vector3(0, radius, 0))
	var bot_pt := _add_vert(verts, center - Vector3(0, radius, 0))
	for i in range(8):
		var ni := (i + 1) % 8
		faces.append(PackedInt32Array([top_pt, (rings[0] as Array)[ni], (rings[0] as Array)[i]]))
		faces.append(PackedInt32Array([bot_pt, (rings[2] as Array)[i], (rings[2] as Array)[ni]]))
	for r in range(2):
		var r1: Array = rings[r]
		var r2: Array = rings[r + 1]
		for i in range(8):
			var ni := (i + 1) % 8
			faces.append(PackedInt32Array([r1[ni], r2[i], r1[i]]))
			faces.append(PackedInt32Array([r1[ni], r2[ni], r2[i]]))

func _add_daisy_flower(verts: Array[Vector3], faces_petals: Array[PackedInt32Array], faces_center: Array[PackedInt32Array], pos: Vector3, normal: Vector3, radius: float) -> void:
	var tangent := normal.cross(Vector3.UP).normalized()
	if tangent.length_squared() < 0.1:
		tangent = normal.cross(Vector3.RIGHT).normalized()
	var binormal := normal.cross(tangent).normalized()

	# Center dome
	var center_pt := _add_vert(verts, pos + normal * 0.03)
	var center_ring: Array[int] = []
	var cr := radius * 0.35
	for i in range(6):
		var a := float(i) * TAU / 6.0
		center_ring.append(_add_vert(verts, pos + (tangent * cos(a) + binormal * sin(a)) * cr))
	for i in range(6):
		var ni := (i + 1) % 6
		faces_center.append(PackedInt32Array([center_pt, center_ring[i], center_ring[ni]]))

	# 8 Radiating white/cream petals
	for p in range(8):
		var a := float(p) * TAU / 8.0
		var dir := tangent * cos(a) + binormal * sin(a)
		var perp := tangent * -sin(a) + binormal * cos(a)
		var b_l := _add_vert(verts, pos + dir * cr - perp * (cr * 0.3))
		var b_r := _add_vert(verts, pos + dir * cr + perp * (cr * 0.3))
		var tip := _add_vert(verts, pos + dir * radius + normal * 0.015)
		faces_petals.append(PackedInt32Array([b_l, tip, b_r]))

func _add_serrated_ground_leaf(verts: Array[Vector3], faces: Array[PackedInt32Array], base_pos: Vector3, tip_offset: Vector3, length: float, width: float) -> void:
	var dir := tip_offset.normalized()
	var side := dir.cross(Vector3.UP).normalized()
	var steps := 3
	var prev_l := _add_vert(verts, base_pos)
	var prev_r := prev_l
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var cp := base_pos + dir * (length * t) + Vector3(0, sin(t * PI) * 0.04, 0)
		var w := sin(t * PI) * width * 0.5
		if i == steps:
			var tip := _add_vert(verts, cp)
			faces.append(PackedInt32Array([prev_l, tip, prev_r]))
		else:
			var l := _add_vert(verts, cp - side * w)
			var r := _add_vert(verts, cp + side * w)
			faces.append(PackedInt32Array([prev_l, l, r]))
			faces.append(PackedInt32Array([prev_l, r, prev_r]))
			prev_l = l
			prev_r = r


