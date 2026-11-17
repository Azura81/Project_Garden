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
	print("Garden assets regenerated with fence, watering can, and flower pot.")
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

func _add_vert(verts: Array[Vector3], v: Vector3) -> int:
	verts.append(v)
	return verts.size()
