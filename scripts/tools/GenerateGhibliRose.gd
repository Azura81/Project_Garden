extends SceneTree

## GenerateGhibliRose: Mathematisch exakte Fibonacci-Ghibli-Rose mit becherförmigen,
## überlappenden Petalen, tiefem Rubinrot, gezackten Wächter-Blättern, Dornen & Knospe.

func _init() -> void:
	print("Starte Neugenerierung der Ghibli-Rose (Fibonacci-Kelch & S-Kurve)...")
	var obj_content := generate_rose_obj()
	var file := FileAccess.open("res://assets/models/ghibli_rose.obj", FileAccess.WRITE)
	if file:
		file.store_string(obj_content)
		file.close()
		print("Erfolgreich gespeichert: res://assets/models/ghibli_rose.obj")
	else:
		printerr("Fehler beim Speichern von ghibli_rose.obj")
	quit(0)

class MeshBuilder:
	var verts: Array[Vector3] = []
	var normals: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	var faces: Array[Array] = []
	var group_commands: Array = []

	func set_group_and_material(g: String, m: String) -> void:
		group_commands.append({"face_index": faces.size(), "group": g, "mat": m})

	func add_vertex(p: Vector3, n: Vector3, uv: Vector2) -> int:
		verts.append(p)
		normals.append(n.normalized())
		uvs.append(uv)
		return verts.size()

	func add_quad(i1: int, i2: int, i3: int, i4: int) -> void:
		faces.append([[i1, i1, i1], [i2, i2, i2], [i3, i3, i3]])
		faces.append([[i1, i1, i1], [i3, i3, i3], [i4, i4, i4]])

	func add_tri(i1: int, i2: int, i3: int) -> void:
		faces.append([[i1, i1, i1], [i2, i2, i2], [i3, i3, i3]])

	func build_obj_string() -> String:
		var sb := PackedStringArray()
		sb.append("# Ghibli Rose 3D Model v2 (Fibonacci English Rose)\n\n")

		for v in verts:
			sb.append("v %.4f %.4f %.4f\n" % [v.x, v.y, v.z])
		sb.append("\n")

		for uv in uvs:
			sb.append("vt %.4f %.4f\n" % [uv.x, uv.y])
		sb.append("\n")

		for n in normals:
			sb.append("vn %.4f %.4f %.4f\n" % [n.x, n.y, n.z])
		sb.append("\n")

		var cmd_idx := 0
		for f_idx in range(faces.size()):
			while cmd_idx < group_commands.size() and f_idx == group_commands[cmd_idx]["face_index"]:
				var cmd: Dictionary = group_commands[cmd_idx]
				sb.append("\ng %s\nusemtl %s\n" % [cmd["group"], cmd["mat"]])
				cmd_idx += 1

			var f: Array = faces[f_idx]
			sb.append("f %d/%d/%d %d/%d/%d %d/%d/%d\n" % [
				f[0][0], f[0][1], f[0][2],
				f[1][0], f[1][1], f[1][2],
				f[2][0], f[2][1], f[2][2]
			])

		return "".join(sb)

func generate_rose_obj() -> String:
	var mb := MeshBuilder.new()

	# 1. Haupt-Stängel (Ausdrucksstarke S-Kurve mit stolzer Vorwärts-Neigung)
	mb.set_group_and_material("Stem", "mat_stem")
	var stem_spine: Array[Vector3] = []
	var stem_segments := 20
	for i in range(stem_segments + 1):
		var t := float(i) / float(stem_segments)
		# Kraftvolle, geschwungene S-Kurve
		var p0 := Vector3(0.0, 0.0, 0.0)
		var p1 := Vector3(0.14, 0.45, -0.12)
		var p2 := Vector3(-0.20, 0.92, 0.22)
		var p3 := Vector3(0.04, 1.38, 0.34)
		var u := 1.0 - t
		var pt := u * u * u * p0 + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * p3
		stem_spine.append(pt)

	_extrude_tube(mb, stem_spine, 0.058, 0.042, 10, Vector2(0, 0), Vector2(1, 1))

	# 2. Blütenboden (Receptacle / Hagebutte)
	var hip_center := stem_spine[-1]
	_generate_receptacle(mb, hip_center, 0.09, 0.12)

	# 3. Dornen (Thorns) entlang des Stängels
	mb.set_group_and_material("Thorns", "mat_thorns")
	var thorn_configs := [
		{"t": 0.20, "angle": 0.6, "len": 0.095, "down": 0.035},
		{"t": 0.35, "angle": 2.9, "len": 0.090, "down": 0.032},
		{"t": 0.52, "angle": 1.4, "len": 0.085, "down": 0.030},
		{"t": 0.68, "angle": 4.1, "len": 0.080, "down": 0.026},
		{"t": 0.85, "angle": 2.3, "len": 0.075, "down": 0.022}
	]
	for cfg in thorn_configs:
		var spine_idx := int(cfg["t"] * float(stem_segments))
		var pt: Vector3 = stem_spine[spine_idx]
		_generate_thorn(mb, pt, cfg["angle"], cfg["len"], cfg["down"])

	# 4. Wache, kräftige Rosenblätter (Pinnate Leaves)
	mb.set_group_and_material("Leaves", "mat_leaves")
	_generate_leaf_cluster(mb, stem_spine[6], Vector3(0.88, 0.18, 0.22).normalized(), 0.52)
	_generate_leaf_cluster(mb, stem_spine[11], Vector3(-0.85, 0.25, -0.30).normalized(), 0.48)
	_generate_leaf_cluster(mb, stem_spine[16], Vector3(0.70, 0.30, 0.65).normalized(), 0.44)

	# 5. Kelchblätter (Sepalen) unter dem Blütenkopf
	mb.set_group_and_material("Sepals", "mat_sepals")
	var flower_base := hip_center + Vector3(0.0, 0.07, 0.0)
	for i in range(5):
		var ang := float(i) * (2.0 * PI / 5.0) + 0.35
		_generate_sepal(mb, flower_base, ang, 0.28, 0.065)

	# 6. Der üppige, becherförmige Blütenkopf (Ghibli Cup-Rose)
	# Der Kopf neigt sich 15° nach vorne dem Betrachter entgegen
	mb.set_group_and_material("Petals", "mat_petals")
	var flower_origin := flower_base + Vector3(0.0, 0.04, 0.02)
	_generate_cupped_rose_bloom(mb, flower_origin)

	# 7. Seitenast mit Knospe (Side Bud)
	mb.set_group_and_material("SideStem", "mat_stem")
	var branch_start := stem_spine[8]
	var bud_spine: Array[Vector3] = []
	for i in range(12):
		var t := float(i) / 11.0
		var p0 := branch_start
		var p1 := branch_start + Vector3(-0.16, 0.2, -0.04)
		var p2 := branch_start + Vector3(-0.32, 0.45, -0.10)
		var p3 := branch_start + Vector3(-0.36, 0.62, -0.14)
		var u := 1.0 - t
		var pt := u * u * u * p0 + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * p3
		bud_spine.append(pt)
	_extrude_tube(mb, bud_spine, 0.034, 0.022, 6, Vector2(0, 0), Vector2(1, 1))

	# Knospe mit Kelchblättern
	var bud_tip := bud_spine[-1]
	_generate_bud(mb, bud_tip, Vector3(-0.25, 0.85, -0.12).normalized())

	return mb.build_obj_string()

# --- Geometrie-Konstruktion für die Ghibli-Blüte ---

func _generate_cupped_rose_bloom(mb: MeshBuilder, origin: Vector3) -> void:
	# Klassische englische Gartenrose (nach Vorbild des Gemini-Gemäldes):
	# Ein nach oben geöffneter, bauchiger Blütenkelch, der sich 24° nach vorne neigt,
	# sodass man direkt in die samtig geschichteten roten Petalen blickt.
	
	# Schicht 1 (Äußere Blütenblätter): 5 breite, nach außen geschwungene Schalen
	_generate_petal_layer(mb, origin, 5, 0.42, 0.52, 0.28, 0.18, 0.0)
	
	# Schicht 2 (Mittlerer Blütenkörper): 5 Petalen, versetzt angeordnet
	_generate_petal_layer(mb, origin + Vector3(0, 0.02, 0), 5, 0.31, 0.40, 0.32, 0.10, 0.65)
	
	# Schicht 3 (Innerer Kelch): 6 Petalen, dichter umschlungen
	_generate_petal_layer(mb, origin + Vector3(0, 0.04, 0), 6, 0.21, 0.28, 0.35, 0.04, 1.3)
	
	# Schicht 4 (Herz-Rosette): 6 Petalen, aufrechte Spirale
	_generate_petal_layer(mb, origin + Vector3(0, 0.06, 0), 6, 0.12, 0.18, 0.36, -0.02, 1.95)
	
	# Zentrales Blütenauge (dichte Spirale)
	_generate_inner_swirl(mb, origin + Vector3(0, 0.08, 0), 0.06, 0.34)

func _generate_petal_layer(mb: MeshBuilder, base_pos: Vector3, count: int, radius: float, width: float, height: float, curl_out: float, rot_offset: float) -> void:
	var rows := 6
	var cols := 6
	var tilt_rad := deg_to_rad(24.0) # 24 Grad nach vorne neigen dem Betrachter entgegen

	for i in range(count):
		var azimuth := float(i) * (2.0 * PI / float(count)) + rot_offset
		var rad_dir := Vector3(cos(azimuth), 0.0, sin(azimuth)).normalized()
		var tan_dir := Vector3(-sin(azimuth), 0.0, cos(azimuth)).normalized()

		var grid: Array[Array] = []

		for r in range(rows):
			var vt := float(r) / float(rows - 1) # 0.0 = Basis, 1.0 = Blattrand
			var row_indices: Array[int] = []

			# Echte Öffnung nach oben:
			# Basis ist kompakt (0.25 * r), weitet sich nach oben tulpen-/rosenförmig auf (1.1 * r)
			var radial_dist := radius * (0.25 + 0.65 * vt + 0.25 * sin(vt * PI * 0.5))
			if vt > 0.70:
				radial_dist += curl_out * pow((vt - 0.70) / 0.30, 1.6)

			var y_pos := base_pos.y + vt * height

			for c in range(cols):
				var ut := (float(c) / float(cols - 1)) - 0.5 # -0.5 bis +0.5
				
				# Schalenwölbung nach innen (Cup)
				var span_factor := 1.0 - pow(ut * 2.0, 2.0)
				var cup_depth := span_factor * 0.045
				
				# Gerundeter oberer Blattrand (Scallop)
				var scallop_drop := pow(ut * 2.0, 2.0) * (height * 0.12) * vt
				var cur_w := width * (0.35 + 0.65 * sin(vt * PI * 0.65 + 0.2))

				var local_p := Vector3(
					rad_dir.x * (radial_dist - cup_depth) + tan_dir.x * (ut * cur_w),
					vt * height - scallop_drop,
					rad_dir.z * (radial_dist - cup_depth) + tan_dir.z * (ut * cur_w)
				)

				# 24° Vorwärtsneigung anwenden
				var tilted_y := local_p.y * cos(tilt_rad) - local_p.z * sin(tilt_rad)
				var tilted_z := local_p.y * sin(tilt_rad) + local_p.z * cos(tilt_rad)

				var pt := Vector3(
					base_pos.x + local_p.x,
					base_pos.y + tilted_y,
					base_pos.z + tilted_z
				)

				var norm := (rad_dir * 0.7 + Vector3(0.0, 0.7, 0.0) + tan_dir * (ut * 0.5)).normalized()
				var tilted_norm_y := norm.y * cos(tilt_rad) - norm.z * sin(tilt_rad)
				var tilted_norm_z := norm.y * sin(tilt_rad) + norm.z * cos(tilt_rad)
				var final_norm := Vector3(norm.x, tilted_norm_y, tilted_norm_z).normalized()

				var uv := Vector2(ut + 0.5, vt)
				var idx := mb.add_vertex(pt, final_norm, uv)
				row_indices.append(idx)
			grid.append(row_indices)

		for r in range(rows - 1):
			for c in range(cols - 1):
				mb.add_quad(grid[r][c], grid[r + 1][c], grid[r + 1][c + 1], grid[r][c + 1])

func _generate_inner_swirl(mb: MeshBuilder, center: Vector3, radius: float, height: float) -> void:
	var segs := 10
	var rings := 5
	var prev_ring: Array[int] = []
	var tilt_rad := deg_to_rad(24.0)

	for r in range(rings):
		var vt := float(r) / float(rings - 1)
		var cur_r := radius * (0.4 + 0.6 * vt)
		var y := vt * height
		var ring: Array[int] = []

		for s in range(segs):
			var phi := float(s) * (2.0 * PI / float(segs)) + vt * 2.2
			var lx := cos(phi) * cur_r
			var lz := sin(phi) * cur_r
			var ly := y

			var tilted_y := ly * cos(tilt_rad) - lz * sin(tilt_rad)
			var tilted_z := ly * sin(tilt_rad) + lz * cos(tilt_rad)

			var pt := Vector3(center.x + lx, center.y + tilted_y, center.z + tilted_z)
			var norm := Vector3(cos(phi) * 0.5, 0.8, sin(phi) * 0.5).normalized()
			var idx := mb.add_vertex(pt, norm, Vector2(float(s) / float(segs), vt))
			ring.append(idx)

		if prev_ring.size() > 0:
			for s in range(segs):
				var s_next := (s + 1) % segs
				mb.add_quad(prev_ring[s], ring[s], ring[s_next], prev_ring[s_next])
		prev_ring = ring

# --- Hilfsfunktionen für Stängel, Sepalen, Blätter, Dornen ---

func _extrude_tube(mb: MeshBuilder, spine: Array[Vector3], r_start: float, r_end: float, radial_segs: int, uv_min: Vector2, uv_max: Vector2) -> void:
	var rings: Array[Array] = []
	for i in range(spine.size()):
		var t := float(i) / float(spine.size() - 1)
		var r := lerpf(r_start, r_end, t)
		var p: Vector3 = spine[i]

		var fwd: Vector3
		if i < spine.size() - 1:
			fwd = (spine[i + 1] - p).normalized()
		else:
			fwd = (p - spine[i - 1]).normalized()

		var up_ref := Vector3.UP if absf(fwd.y) < 0.9 else Vector3.FORWARD
		var right := fwd.cross(up_ref).normalized()
		var up := right.cross(fwd).normalized()

		var ring_indices: Array[int] = []
		for j in range(radial_segs):
			var phi := float(j) * (2.0 * PI / float(radial_segs))
			var norm := right * cos(phi) + up * sin(phi)
			var vpos := p + norm * r
			var uv := Vector2(
				lerpf(uv_min.x, uv_max.x, float(j) / float(radial_segs)),
				lerpf(uv_min.y, uv_max.y, t)
			)
			var idx := mb.add_vertex(vpos, norm, uv)
			ring_indices.append(idx)
		rings.append(ring_indices)

	for i in range(spine.size() - 1):
		var r1: Array = rings[i]
		var r2: Array = rings[i + 1]
		for j in range(radial_segs):
			var j_next := (j + 1) % radial_segs
			mb.add_quad(r1[j], r2[j], r2[j_next], r1[j_next])

func _generate_receptacle(mb: MeshBuilder, center: Vector3, radius: float, height: float) -> void:
	var lat_segs := 5
	var lon_segs := 10
	var prev_ring: Array[int] = []

	for lat in range(lat_segs + 1):
		var v_ratio := float(lat) / float(lat_segs)
		var theta := v_ratio * PI * 0.5
		var cur_y := center.y + v_ratio * height
		var cur_r := radius * sin(theta + 0.35)
		var cur_ring: Array[int] = []

		for lon in range(lon_segs):
			var phi := float(lon) * (2.0 * PI / float(lon_segs))
			var norm := Vector3(cos(phi) * sin(theta), -cos(theta), sin(phi) * sin(theta)).normalized()
			var vpos := Vector3(center.x + cos(phi) * cur_r, cur_y, center.z + sin(phi) * cur_r)
			var idx := mb.add_vertex(vpos, norm, Vector2(float(lon) / float(lon_segs), v_ratio))
			cur_ring.append(idx)

		if prev_ring.size() > 0:
			for lon in range(lon_segs):
				var lon_next := (lon + 1) % lon_segs
				mb.add_quad(prev_ring[lon], cur_ring[lon], cur_ring[lon_next], prev_ring[lon_next])
		prev_ring = cur_ring

func _generate_thorn(mb: MeshBuilder, stem_pt: Vector3, angle: float, length: float, hook_down: float) -> void:
	var out_dir := Vector3(cos(angle), 0.0, sin(angle)).normalized()
	var base_w := 0.042
	var base_h := 0.052
	var perp := out_dir.cross(Vector3.UP).normalized()

	var b_top := stem_pt + Vector3(0.0, base_h * 0.5, 0.0)
	var b_bot := stem_pt - Vector3(0.0, base_h * 0.5, 0.0)
	var b_l := stem_pt + perp * (base_w * 0.5)
	var b_r := stem_pt - perp * (base_w * 0.5)

	var tip := stem_pt + out_dir * length - Vector3(0.0, hook_down, 0.0)

	var iv_top := mb.add_vertex(b_top, Vector3.UP, Vector2(0.5, 1.0))
	var iv_bot := mb.add_vertex(b_bot, -Vector3.UP, Vector2(0.5, 0.0))
	var iv_l := mb.add_vertex(b_l, perp, Vector2(0.0, 0.5))
	var iv_r := mb.add_vertex(b_r, -perp, Vector2(1.0, 0.5))
	var iv_tip := mb.add_vertex(tip, out_dir - Vector3(0, 0.6, 0), Vector2(0.5, 0.5))

	mb.add_tri(iv_top, iv_l, iv_tip)
	mb.add_tri(iv_top, iv_tip, iv_r)
	mb.add_tri(iv_bot, iv_tip, iv_l)
	mb.add_tri(iv_bot, iv_r, iv_tip)

func _generate_sepal(mb: MeshBuilder, base: Vector3, angle: float, length: float, width: float) -> void:
	var dir := Vector3(cos(angle), -0.4, sin(angle)).normalized()
	var perp := dir.cross(Vector3.UP).normalized()
	var normal := dir.cross(perp).normalized()

	var b_l := base + perp * (width * 0.5)
	var b_r := base - perp * (width * 0.5)
	var m_l := base + dir * (length * 0.45) + perp * (width * 0.65) - Vector3(0, 0.03, 0)
	var m_r := base + dir * (length * 0.45) - perp * (width * 0.65) - Vector3(0, 0.03, 0)
	var tip := base + dir * length - Vector3(0, 0.14, 0)

	var i_bl := mb.add_vertex(b_l, normal, Vector2(0, 0))
	var i_br := mb.add_vertex(b_r, normal, Vector2(1, 0))
	var i_ml := mb.add_vertex(m_l, normal, Vector2(0, 0.5))
	var i_mr := mb.add_vertex(m_r, normal, Vector2(1, 0.5))
	var i_tip := mb.add_vertex(tip, normal, Vector2(0.5, 1.0))

	mb.add_quad(i_bl, i_ml, i_mr, i_br)
	mb.add_tri(i_ml, i_tip, i_mr)

func _generate_leaf_cluster(mb: MeshBuilder, origin: Vector3, direction: Vector3, length: float) -> void:
	var right := direction.cross(Vector3.UP).normalized()
	var up := right.cross(direction).normalized()

	var stem_end := origin + direction * (length * 0.38)
	_extrude_tube(mb, [origin, stem_end], 0.018, 0.012, 4, Vector2(0, 0), Vector2(1, 1))

	# 1. Haupt-Blatt an der Spitze
	_generate_single_leaflet(mb, stem_end, direction, right, 0.28, 0.16)

	# 2. Linkes Seitenblatt
	var side_dir_l := (direction * 0.65 - right * 0.75).normalized()
	var side_orig_l := origin + direction * (length * 0.22)
	_generate_single_leaflet(mb, side_orig_l, side_dir_l, side_dir_l.cross(up).normalized(), 0.22, 0.13)

	# 3. Rechtes Seitenblatt
	var side_dir_r := (direction * 0.65 + right * 0.75).normalized()
	var side_orig_r := origin + direction * (length * 0.22)
	_generate_single_leaflet(mb, side_orig_r, side_dir_r, side_dir_r.cross(up).normalized(), 0.22, 0.13)

func _generate_single_leaflet(mb: MeshBuilder, base: Vector3, fwd: Vector3, side: Vector3, len: float, w: float) -> void:
	var norm := fwd.cross(side).normalized()
	var p_base := base
	var p_m1_l := base + fwd * (len * 0.35) - side * (w * 0.5) + norm * 0.018
	var p_m1_r := base + fwd * (len * 0.35) + side * (w * 0.5) + norm * 0.018
	var p_m2_l := base + fwd * (len * 0.70) - side * (w * 0.42) - norm * 0.01
	var p_m2_r := base + fwd * (len * 0.70) + side * (w * 0.42) - norm * 0.01
	var p_tip := base + fwd * len - norm * 0.03

	var ib := mb.add_vertex(p_base, norm, Vector2(0.5, 0.0))
	var im1l := mb.add_vertex(p_m1_l, norm, Vector2(0.0, 0.35))
	var im1r := mb.add_vertex(p_m1_r, norm, Vector2(1.0, 0.35))
	var im2l := mb.add_vertex(p_m2_l, norm, Vector2(0.0, 0.7))
	var im2r := mb.add_vertex(p_m2_r, norm, Vector2(1.0, 0.7))
	var itip := mb.add_vertex(p_tip, norm, Vector2(0.5, 1.0))

	mb.add_quad(ib, im1l, im1r, ib)
	mb.add_quad(im1l, im2l, im2r, im1r)
	mb.add_tri(im2l, itip, im2r)

func _generate_bud(mb: MeshBuilder, tip_pos: Vector3, dir: Vector3) -> void:
	mb.set_group_and_material("Sepals", "mat_sepals")
	for i in range(4):
		var ang := float(i) * (2.0 * PI / 4.0)
		_generate_sepal(mb, tip_pos, ang, 0.16, 0.045)

	mb.set_group_and_material("Petals", "mat_petals")
	var up := Vector3.UP
	var right := dir.cross(up).normalized()
	up = right.cross(dir).normalized()
	var bud_len := 0.18
	var bud_r := 0.065

	var segs := 8
	var prev_ring: Array[int] = []
	for h in range(5):
		var vt := float(h) / 4.0
		var r := bud_r * sin(vt * PI * 0.7 + 0.3)
		var center := tip_pos + dir * (vt * bud_len)
		var ring: Array[int] = []
		for s in range(segs):
			var phi := float(s) * (2.0 * PI / float(segs)) + vt * 1.2
			var norm := (right * cos(phi) + up * sin(phi)).normalized()
			var pt := center + norm * r
			var idx := mb.add_vertex(pt, norm, Vector2(float(s) / float(segs), vt))
			ring.append(idx)
		if prev_ring.size() > 0:
			for s in range(segs):
				var s_next := (s + 1) % segs
				mb.add_quad(prev_ring[s], ring[s], ring[s_next], prev_ring[s_next])
		prev_ring = ring
