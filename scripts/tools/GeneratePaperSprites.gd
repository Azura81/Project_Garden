extends SceneTree

## GeneratePaperSprites: Generiert saubere, hochauflösende 2.5D-Aquarell-Sprites
## (Rose, Schnecke, Keimling, Käfer, Pusteblume, 1st-Person-Cockpit & Aquarell-Papiertextur)

func _init() -> void:
	print("Starte Generierung der 2.5D Paper-Mario Aquarell-Sprites...")

	generate_watercolor_paper_texture()
	generate_rose_sprite()
	generate_golden_seedling_sprite()
	generate_dandelion_sprite()
	generate_snail_sprite()
	generate_beetle_sprite()
	generate_rose_cockpit_overlay()

	print("Alle Sprites erfolgreich in res://assets/sprites/ generiert!")
	quit(0)

# --- 1. Aquarell-Papiertextur (Nahtlos, körnig, cold-press) ---

func generate_watercolor_paper_texture() -> void:
	var size := 1024
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 42
	noise.frequency = 0.035
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.6

	var fine_noise := FastNoiseLite.new()
	fine_noise.seed = 1337
	fine_noise.frequency = 0.15
	fine_noise.fractal_octaves = 3

	for y in range(size):
		for x in range(size):
			var n1 := noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
			var n2 := fine_noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
			var grain := (n1 * 0.7 + n2 * 0.3)
			
			# Cremefarbenes warmes Büttenpapier (#FDFBF7 mit Fasern)
			var base_r := 0.96 + (grain - 0.5) * 0.06
			var base_g := 0.94 + (grain - 0.5) * 0.06
			var base_b := 0.90 + (grain - 0.5) * 0.05
			img.set_pixel(x, y, Color(base_r, base_g, base_b, 1.0))

	img.save_png("res://assets/textures/watercolor_paper.png")
	print("Gespeichert: res://assets/textures/watercolor_paper.png")

# --- 2. Rose Sprite (Aquarell-Pappaufsteller nach Referenz) ---

func generate_rose_sprite() -> void:
	var w := 512
	var h := 512
	var img := Image.create(w, h, true, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Zeichne Rosen-Busch mit 3 Stängeln, Knospe, Blättern und prachtvoller Hauptblüte
	# A. Stängel (geschwungen, dunkelgrün mit Tusche-Kontur)
	_draw_bezier_stem(img, Vector2(256, 500), Vector2(240, 360), Vector2(210, 220), Vector2(220, 160), 12.0, Color(0.31, 0.42, 0.23), Color(0.17, 0.13, 0.09))
	_draw_bezier_stem(img, Vector2(256, 450), Vector2(170, 380), Vector2(140, 300), Vector2(130, 240), 9.0, Color(0.31, 0.42, 0.23), Color(0.17, 0.13, 0.09))
	_draw_bezier_stem(img, Vector2(256, 430), Vector2(330, 370), Vector2(370, 310), Vector2(360, 260), 8.0, Color(0.31, 0.42, 0.23), Color(0.17, 0.13, 0.09))

	# B. Dornen
	_draw_thorn_2d(img, Vector2(245, 410), Vector2(-1, 0.3), 16.0, Color(0.55, 0.25, 0.18))
	_draw_thorn_2d(img, Vector2(228, 300), Vector2(1, 0.4), 14.0, Color(0.55, 0.25, 0.18))
	_draw_thorn_2d(img, Vector2(155, 340), Vector2(-1, 0.35), 12.0, Color(0.55, 0.25, 0.18))

	# C. Gezackte Rosenblätter
	_draw_watercolor_leaf(img, Vector2(180, 330), Vector2(-0.8, -0.4), 48.0, 26.0, Color(0.49, 0.61, 0.37))
	_draw_watercolor_leaf(img, Vector2(290, 320), Vector2(0.85, -0.3), 46.0, 24.0, Color(0.49, 0.61, 0.37))
	_draw_watercolor_leaf(img, Vector2(195, 230), Vector2(-0.7, -0.6), 40.0, 22.0, Color(0.45, 0.58, 0.33))
	_draw_watercolor_leaf(img, Vector2(275, 220), Vector2(0.75, -0.5), 42.0, 23.0, Color(0.45, 0.58, 0.33))

	# D. Seiten-Knospe links (halb geöffnet)
	_draw_rosebud_2d(img, Vector2(130, 230), 28.0, Color(0.79, 0.29, 0.29), Color(0.31, 0.42, 0.23))

	# E. Zweite Blüte rechts
	_draw_rose_blossom_2d(img, Vector2(360, 250), 42.0, Color(0.79, 0.29, 0.29))

	# F. Große, prächtige Hauptblüte (Zentrum)
	_draw_rose_blossom_2d(img, Vector2(220, 150), 68.0, Color(0.79, 0.29, 0.29))

	# G. Weicher weißer Pop-Up-Papierrand (Paper Cutout Border)
	var final_img := _apply_paper_cutout_border(img, 3)

	final_img.save_png("res://assets/sprites/plants/rose_idle.png")
	print("Gespeichert: res://assets/sprites/plants/rose_idle.png")

# --- 3. Golden Sprout (Keimling mit magischem Schein) ---

func generate_golden_seedling_sprite() -> void:
	var w := 512
	var h := 512
	var img := Image.create(w, h, true, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Leuchtender Erdhügel an der Basis
	_draw_watercolor_disc(img, Vector2(256, 440), 90.0, 35.0, Color(0.55, 0.38, 0.22, 0.95), Color(0.17, 0.13, 0.09))
	_draw_watercolor_disc(img, Vector2(256, 435), 75.0, 28.0, Color(0.78, 0.64, 0.48, 0.9), Color(0.17, 0.13, 0.09))

	# Magischer Goldener Keimling (#F5D061 mit Glow)
	# Stängel
	_draw_bezier_stem(img, Vector2(256, 430), Vector2(256, 340), Vector2(256, 280), Vector2(256, 250), 16.0, Color(0.96, 0.82, 0.38), Color(0.72, 0.52, 0.12))

	# Zwei herzförmig geschwungene goldene Keimblätter
	_draw_golden_leaf(img, Vector2(256, 250), Vector2(-0.85, -0.52), 85.0, 48.0)
	_draw_golden_leaf(img, Vector2(256, 250), Vector2(0.85, -0.52), 85.0, 48.0)

	# Zentraler Austrieb
	_draw_golden_leaf(img, Vector2(256, 240), Vector2(0.0, -1.0), 55.0, 26.0)

	# Magische Glitzerpartikel rundherum
	_draw_sparkle(img, Vector2(170, 180), 14.0, Color(1.0, 0.95, 0.7))
	_draw_sparkle(img, Vector2(340, 190), 16.0, Color(1.0, 0.95, 0.7))
	_draw_sparkle(img, Vector2(210, 120), 12.0, Color(1.0, 0.95, 0.7))
	_draw_sparkle(img, Vector2(305, 110), 15.0, Color(1.0, 0.95, 0.7))

	var final_img := _apply_paper_cutout_border(img, 3)
	final_img.save_png("res://assets/sprites/plants/golden_seedling.png")
	print("Gespeichert: res://assets/sprites/plants/golden_seedling.png")

# --- 4. Dandelion Sprite (Pusteblume nach Referenz) ---

func generate_dandelion_sprite() -> void:
	var w := 512
	var h := 512
	var img := Image.create(w, h, true, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Gezackte Rosettenblätter an der Basis
	for a in [-0.85, -0.4, 0.0, 0.4, 0.85]:
		var dir := Vector2(sin(a), -cos(a) * 0.45).normalized()
		_draw_watercolor_leaf(img, Vector2(256, 460), dir, 80.0, 28.0, Color(0.42, 0.58, 0.28))

	# 3 Stängel zu den Samenbällen
	_draw_bezier_stem(img, Vector2(256, 460), Vector2(240, 350), Vector2(200, 260), Vector2(180, 210), 8.0, Color(0.45, 0.58, 0.32), Color(0.17, 0.13, 0.09))
	_draw_bezier_stem(img, Vector2(256, 460), Vector2(260, 320), Vector2(260, 220), Vector2(260, 150), 9.0, Color(0.45, 0.58, 0.32), Color(0.17, 0.13, 0.09))
	_draw_bezier_stem(img, Vector2(256, 460), Vector2(275, 350), Vector2(320, 270), Vector2(340, 220), 8.0, Color(0.45, 0.58, 0.32), Color(0.17, 0.13, 0.09))

	# 3 Flauschige weiße Pusteblumen-Kugeln
	_draw_dandelion_globe(img, Vector2(180, 210), 45.0)
	_draw_dandelion_globe(img, Vector2(340, 220), 45.0)
	_draw_dandelion_globe(img, Vector2(260, 150), 56.0)

	var final_img := _apply_paper_cutout_border(img, 3)
	final_img.save_png("res://assets/sprites/plants/dandelion_idle.png")
	print("Gespeichert: res://assets/sprites/plants/dandelion_idle.png")

# --- 5. Garden Snail Sprite (Niedliche Schnecke nach Referenz) ---

func generate_snail_sprite() -> void:
	var w := 512
	var h := 512
	var img := Image.create(w, h, true, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Schneckenfuß / Körper (Kriecht nach rechts, wiegende Wellen)
	var body_col := Color(0.88, 0.85, 0.75)
	var body_shadow := Color(0.72, 0.68, 0.56)
	var ink_col := Color(0.17, 0.13, 0.09)

	# Welliger Fuß unten (von x=80 bis x=410, y=380 bis 430)
	_draw_watercolor_capsule(img, Vector2(110, 410), Vector2(390, 405), 32.0, body_col, ink_col)

	# Kopf & Hals (ragt rechts nach oben x=380, y=340)
	_draw_watercolor_capsule(img, Vector2(350, 400), Vector2(400, 330), 28.0, body_col, ink_col)

	# Zwei Fühler mit runden Knopfaugen
	_draw_bezier_stem(img, Vector2(395, 320), Vector2(410, 290), Vector2(420, 260), Vector2(430, 230), 5.0, body_col, ink_col)
	_draw_bezier_stem(img, Vector2(385, 320), Vector2(395, 285), Vector2(400, 255), Vector2(405, 225), 5.0, body_col, ink_col)
	# Augen
	_draw_watercolor_disc(img, Vector2(430, 225), 9.0, 9.0, ink_col, ink_col)
	_draw_watercolor_disc(img, Vector2(405, 220), 9.0, 9.0, ink_col, ink_col)
	_draw_watercolor_disc(img, Vector2(432, 223), 3.0, 3.0, Color.WHITE, Color.WHITE)
	_draw_watercolor_disc(img, Vector2(407, 218), 3.0, 3.0, Color.WHITE, Color.WHITE)

	# Bauchiges Schneckenhaus (Karamellbraun mit spiralförmigen Rillen)
	var shell_center := Vector2(245, 330)
	var shell_r := 95.0
	var shell_col := Color(0.78, 0.58, 0.36)
	var shell_dark := Color(0.55, 0.38, 0.22)
	_draw_watercolor_disc(img, shell_center, shell_r, shell_r * 0.9, shell_col, ink_col)
	# Innere Spiralwindungen
	_draw_watercolor_disc(img, shell_center + Vector2(15, -5), shell_r * 0.72, shell_r * 0.65, shell_dark, ink_col)
	_draw_watercolor_disc(img, shell_center + Vector2(25, -10), shell_r * 0.45, shell_r * 0.40, shell_col, ink_col)
	_draw_watercolor_disc(img, shell_center + Vector2(30, -12), shell_r * 0.20, shell_r * 0.18, shell_dark, ink_col)

	var final_img := _apply_paper_cutout_border(img, 3)
	final_img.save_png("res://assets/sprites/enemies/snail_walk.png")
	print("Gespeichert: res://assets/sprites/enemies/snail_walk.png")

# --- 6. Beetle Sprite (Schmuckkäfer nach Referenz) ---

func generate_beetle_sprite() -> void:
	var w := 384
	var h := 384
	var img := Image.create(w, h, true, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var ink := Color(0.17, 0.13, 0.09)
	var beetle_col := Color(0.58, 0.22, 0.48) # Purpur/Käfer
	var wing_line := Color(0.35, 0.12, 0.30)

	# 6 kleine Beinchen
	for side in [-1.0, 1.0]:
		for y_off in [-30.0, 0.0, 30.0]:
			var b1 := Vector2(192 + side * 40.0, 192 + y_off)
			var b2 := Vector2(192 + side * 90.0, 192 + y_off + 15.0)
			var b3 := Vector2(192 + side * 115.0, 192 + y_off + 35.0)
			_draw_line_2d(img, b1, b2, 5.0, ink)
			_draw_line_2d(img, b2, b3, 4.0, ink)

	# Ovaler Rumpf / Flügeldecken
	_draw_watercolor_disc(img, Vector2(192, 205), 62.0, 78.0, beetle_col, ink)
	_draw_line_2d(img, Vector2(192, 130), Vector2(192, 280), 3.0, ink)

	# Kopf & Fühler
	_draw_watercolor_disc(img, Vector2(192, 120), 32.0, 24.0, ink, ink)
	_draw_line_2d(img, Vector2(180, 110), Vector2(160, 75), 3.5, ink)
	_draw_line_2d(img, Vector2(204, 110), Vector2(224, 75), 3.5, ink)

	var final_img := _apply_paper_cutout_border(img, 3)
	final_img.save_png("res://assets/sprites/enemies/beetle_walk.png")
	print("Gespeichert: res://assets/sprites/enemies/beetle_walk.png")

# --- 7. Rose Cockpit Overlay (1st-Person-Sicht aus der Blüte) ---

func generate_rose_cockpit_overlay() -> void:
	var w := 1920
	var h := 1080
	var img := Image.create(w, h, true, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Zeichne sanft geschwungene rote Rosenblätter entlang der 4 Ränder und Ecken
	# Oben, unten, links und rechts ragen Blütenblätter ins Bild, Mitte bleibt frei
	var petal_red := Color(0.79, 0.29, 0.29, 0.92)
	var petal_dark := Color(0.48, 0.12, 0.16, 0.95)
	var ink := Color(0.22, 0.05, 0.08, 0.9)

	# Ecken: Große, weiche Rosenblätter
	_draw_curved_petal_2d(img, Vector2(0, 0), Vector2(450, 320), petal_red, petal_dark, ink)
	_draw_curved_petal_2d(img, Vector2(w, 0), Vector2(w - 450, 320), petal_red, petal_dark, ink)
	_draw_curved_petal_2d(img, Vector2(0, h), Vector2(400, h - 280), petal_red, petal_dark, ink)
	_draw_curved_petal_2d(img, Vector2(w, h), Vector2(w - 400, h - 280), petal_red, petal_dark, ink)

	# Oberer und unterer Rand
	_draw_curved_petal_2d(img, Vector2(w * 0.35, 0), Vector2(w * 0.5, 180), petal_red, petal_dark, ink)
	_draw_curved_petal_2d(img, Vector2(w * 0.65, 0), Vector2(w * 0.5, 180), petal_red, petal_dark, ink)
	_draw_curved_petal_2d(img, Vector2(w * 0.5, h), Vector2(w * 0.5, h - 160), petal_red, petal_dark, ink)

	# Zarte grüne Kelchblattspitzen links und rechts unten
	_draw_curved_petal_2d(img, Vector2(60, h - 40), Vector2(260, h - 180), Color(0.38, 0.52, 0.25, 0.9), Color(0.22, 0.34, 0.14, 0.9), ink)
	_draw_curved_petal_2d(img, Vector2(w - 60, h - 40), Vector2(w - 260, h - 180), Color(0.38, 0.52, 0.25, 0.9), Color(0.22, 0.34, 0.14, 0.9), ink)

	img.save_png("res://assets/sprites/cockpits/rose_cockpit.png")
	print("Gespeichert: res://assets/sprites/cockpits/rose_cockpit.png")

# --- Zeichen-Hilfsfunktionen für 2D-Aquarell ---

func _draw_watercolor_disc(img: Image, center: Vector2, rx: float, ry: float, col: Color, outline_col: Color) -> void:
	var min_x := clampi(int(center.x - rx - 3), 0, img.get_width() - 1)
	var max_x := clampi(int(center.x + rx + 3), 0, img.get_width() - 1)
	var min_y := clampi(int(center.y - ry - 3), 0, img.get_height() - 1)
	var max_y := clampi(int(center.y + ry + 3), 0, img.get_height() - 1)

	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var dx := (float(x) - center.x) / rx
			var dy := (float(y) - center.y) / ry
			var d_sq := dx * dx + dy * dy
			if d_sq <= 1.0:
				var edge := 1.0 - sqrt(d_sq)
				var c := col
				if edge < 0.12:
					c = outline_col
				img.set_pixel(x, y, c)

func _draw_watercolor_capsule(img: Image, p1: Vector2, p2: Vector2, radius: float, col: Color, outline_col: Color) -> void:
	var segs := int(p1.distance_to(p2) / (radius * 0.4)) + 2
	for i in range(segs):
		var t := float(i) / float(segs - 1)
		var pt := p1.lerp(p2, t)
		_draw_watercolor_disc(img, pt, radius, radius, col, outline_col)

func _draw_line_2d(img: Image, p1: Vector2, p2: Vector2, width: float, col: Color) -> void:
	var steps := int(p1.distance_to(p2) / 2.0) + 1
	var r := width * 0.5
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var pt := p1.lerp(p2, t)
		_draw_watercolor_disc(img, pt, r, r, col, col)

func _draw_bezier_stem(img: Image, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, width: float, col: Color, outl: Color) -> void:
	var steps := 40
	var prev := p0
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var u := 1.0 - t
		var pt := u * u * u * p0 + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * p3
		var cur_w := lerpf(width, width * 0.65, t)
		_draw_watercolor_capsule(img, prev, pt, cur_w * 0.5, col, outl)
		prev = pt

func _draw_thorn_2d(img: Image, base: Vector2, dir: Vector2, length: float, col: Color) -> void:
	var tip := base + dir.normalized() * length + Vector2(0, length * 0.4)
	_draw_watercolor_capsule(img, base, tip, 3.5, col, Color(0.2, 0.1, 0.05))

func _draw_watercolor_leaf(img: Image, base: Vector2, dir: Vector2, len: float, w: float, col: Color) -> void:
	var norm := dir.normalized()
	var perp := Vector2(-norm.y, norm.x)
	var steps := 16
	for i in range(steps):
		var t := float(i) / float(steps - 1)
		var pt := base + norm * (t * len)
		var cur_w := sin(t * PI) * (w * 0.5)
		_draw_watercolor_disc(img, pt, maxf(cur_w, 2.0), maxf(cur_w * 0.75, 2.0), col, Color(0.17, 0.13, 0.09))

func _draw_rose_blossom_2d(img: Image, center: Vector2, radius: float, base_col: Color) -> void:
	# Schichtweise überlappende Rosen-Petalen
	var dark := Color(base_col.r * 0.6, base_col.g * 0.15, base_col.b * 0.2)
	var mid := base_col
	var light := Color(base_col.r * 1.15, base_col.g * 1.25, base_col.b * 1.15)
	var outl := Color(0.2, 0.04, 0.08)

	# 1. Äußerer Kelch
	_draw_watercolor_disc(img, center, radius, radius * 0.82, dark, outl)

	# 2. Äußere Petalen-Blätter
	for a in range(5):
		var ang := float(a) * (2.0 * PI / 5.0)
		var off := Vector2(cos(ang), sin(ang)) * (radius * 0.55)
		_draw_watercolor_disc(img, center + off, radius * 0.5, radius * 0.42, mid, outl)

	# 3. Mittlere Spiralschicht
	for a in range(6):
		var ang := float(a) * (2.0 * PI / 6.0) + 0.5
		var off := Vector2(cos(ang), sin(ang)) * (radius * 0.32)
		_draw_watercolor_disc(img, center + off, radius * 0.38, radius * 0.32, light, outl)

	# 4. Herz-Rosette (dichtes Zentrum)
	_draw_watercolor_disc(img, center, radius * 0.28, radius * 0.24, dark, outl)
	_draw_watercolor_disc(img, center + Vector2(2, -2), radius * 0.14, radius * 0.12, light, outl)

func _draw_rosebud_2d(img: Image, center: Vector2, radius: float, red_col: Color, green_col: Color) -> void:
	var outl := Color(0.17, 0.13, 0.09)
	# Rote Knospe
	_draw_watercolor_disc(img, center, radius * 0.7, radius * 0.95, red_col, outl)
	# 3 Grüne Hüllblätter
	_draw_watercolor_disc(img, center + Vector2(-radius * 0.4, radius * 0.2), radius * 0.4, radius * 0.7, green_col, outl)
	_draw_watercolor_disc(img, center + Vector2(radius * 0.4, radius * 0.2), radius * 0.4, radius * 0.7, green_col, outl)
	_draw_watercolor_disc(img, center + Vector2(0, radius * 0.4), radius * 0.5, radius * 0.6, green_col, outl)

func _draw_golden_leaf(img: Image, base: Vector2, dir: Vector2, len: float, w: float) -> void:
	var norm := dir.normalized()
	var steps := 20
	var col := Color(0.96, 0.82, 0.38)
	var glow := Color(1.0, 0.94, 0.65)
	var outl := Color(0.72, 0.52, 0.12)
	for i in range(steps):
		var t := float(i) / float(steps - 1)
		var pt := base + norm * (t * len)
		var cur_w := sin(t * PI) * (w * 0.5)
		_draw_watercolor_disc(img, pt, maxf(cur_w, 3.0), maxf(cur_w * 0.85, 3.0), col if t < 0.6 else glow, outl)

func _draw_dandelion_globe(img: Image, center: Vector2, radius: float) -> void:
	var col := Color(0.96, 0.96, 0.94, 0.88)
	var center_col := Color(0.68, 0.62, 0.48)
	var outl := Color(0.2, 0.16, 0.12)
	_draw_watercolor_disc(img, center, radius, radius, col, Color(0.85, 0.85, 0.82, 0.9))
	_draw_watercolor_disc(img, center, radius * 0.25, radius * 0.25, center_col, outl)

func _draw_sparkle(img: Image, center: Vector2, radius: float, col: Color) -> void:
	_draw_watercolor_disc(img, center, radius, radius * 0.35, col, col)
	_draw_watercolor_disc(img, center, radius * 0.35, radius, col, col)

func _draw_curved_petal_2d(img: Image, from_pt: Vector2, to_pt: Vector2, col: Color, dark: Color, outl: Color) -> void:
	var dist := from_pt.distance_to(to_pt)
	var steps := int(dist / 14.0) + 2
	for i in range(steps):
		var t := float(i) / float(steps - 1)
		var pt := from_pt.lerp(to_pt, t)
		var r := sin(t * PI) * 90.0 + 35.0
		_draw_watercolor_disc(img, pt, r, r * 0.65, col if t > 0.4 else dark, outl)

func _apply_paper_cutout_border(src: Image, border_width: int) -> Image:
	# Erzeugt die typische weiße Paper-Mario-Schnittkante um das Sprite
	var w := src.get_width()
	var h := src.get_height()
	var out := Image.create(w, h, true, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))

	# 1. Weißer Rand auf Pixeln mit Nachbarschaft
	var border_col := Color(0.98, 0.97, 0.95, 0.95)
	for y in range(h):
		for x in range(w):
			if src.get_pixel(x, y).a > 0.05:
				for dy in range(-border_width, border_width + 1):
					for dx in range(-border_width, border_width + 1):
						var nx := x + dx
						var ny := y + dy
						if nx >= 0 and nx < w and ny >= 0 and ny < h:
							if out.get_pixel(nx, ny).a < 0.5:
								out.set_pixel(nx, ny, border_col)

	# 2. Original-Grafik darüberblenden
	for y in range(h):
		for x in range(w):
			var c := src.get_pixel(x, y)
			if c.a > 0.05:
				out.set_pixel(x, y, c)

	return out
