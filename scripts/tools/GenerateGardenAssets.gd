@tool
extends SceneTree

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/models")
	_generate_golden_sprout()
	_generate_mini_sprout()
	_generate_rustic_beam()
	_generate_river_stones()
	print("Garden assets regenerated with outward-facing normals and enhanced geometry.")
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
	
	# Stem: curved 6-sided stalk with natural taper
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
				# Outward winding (counter-clockwise viewed from outside)
				faces_stem.append(PackedInt32Array([prev_ring[i], curr_ring[i], curr_ring[n_i]]))
				faces_stem.append(PackedInt32Array([prev_ring[i], curr_ring[n_i], prev_ring[n_i]]))
		prev_ring = curr_ring
		
	# 2 Large Cotyledon Leaves (lush, sweeping wings)
	_add_sculpted_sprout_leaf(verts, faces_leaves, stem_spine[2], Vector3(-1.1, 0.35, 0.3), 1.15, 0.55)
	_add_sculpted_sprout_leaf(verts, faces_leaves, stem_spine[2], Vector3(1.15, 0.38, -0.25), 1.2, 0.58)
	
	# 3 Upright Crown Leaves cradling the core crystal bud
	_add_sculpted_sprout_leaf(verts, faces_leaves, stem_spine[3], Vector3(0.45, 0.65, 0.4), 0.75, 0.35)
	_add_sculpted_sprout_leaf(verts, faces_leaves, stem_spine[3], Vector3(-0.5, 0.68, -0.35), 0.78, 0.36)
	_add_sculpted_sprout_leaf(verts, faces_leaves, stem_spine[3], Vector3(-0.25, 0.62, 0.5), 0.7, 0.32)

	# Glowing Crystal Bud at apex
	var bud_center := Vector3(0.0, 2.05, 0.0)
	_add_faceted_crystal_bud(verts, faces_bud, bud_center, 0.52)

	# Write OBJ
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
	
	# Spine nodes
	var p0 := base_pos
	var p_quarter := base_pos + tip_dir * (length * 0.35) + up_dir * (length * 0.25)
	var p_half := base_pos + tip_dir * (length * 0.7) + up_dir * (length * 0.22)
	var p_tip := base_pos + tip_dir * length - up_dir * (length * 0.08) # gentle droop at tip
	
	# Outer wing vertices
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
	
	# Top faces (outward facing)
	faces.append(PackedInt32Array([i0, i_lm, i_q]))
	faces.append(PackedInt32Array([i0, i_q, i_rm]))
	faces.append(PackedInt32Array([i_q, i_lm, i_lb]))
	faces.append(PackedInt32Array([i_q, i_lb, i_h]))
	faces.append(PackedInt32Array([i_q, i_h, i_rb]))
	faces.append(PackedInt32Array([i_q, i_rb, i_rm]))
	faces.append(PackedInt32Array([i_h, i_lb, i_tip]))
	faces.append(PackedInt32Array([i_h, i_tip, i_rb]))
	
	# Bottom faces (two-sided)
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
		
	# Cotyledons
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
		
	# Wooden dowels/pegs
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
		# Outward winding normals!
		faces.append(PackedInt32Array([itop, r_upper[ni], r_upper[i]]))
		faces.append(PackedInt32Array([r_upper[i], r_upper[ni], r_lower[ni]]))
		faces.append(PackedInt32Array([r_upper[i], r_lower[ni], r_lower[i]]))
		faces.append(PackedInt32Array([ibot, r_lower[i], r_lower[ni]]))

func _add_vert(verts: Array[Vector3], v: Vector3) -> int:
	verts.append(v)
	return verts.size()
