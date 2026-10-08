extends SceneTree
## Genera el pixel art provisional del juego (estilo D de Ariel) como archivos PNG editables.
## Ejecutar: godot --headless --path . --script res://tools/art/generar_sprites.gd
## Ojo: sobrescribe los PNG de assets/art/pixel/ (si se retocaron a mano, se pierden los cambios).
## Los PNG resultantes se pueden abrir y retocar en Pixelorama, Aseprite o LibreSprite.

const OUT := "res://assets/art/pixel/"

# --- Paleta (también se exporta como paleta.png) ---
const O := Color("0a0d1c")       # Contorno
const N1 := Color("121a33")      # Azules noche, de oscuro a claro
const N2 := Color("1b2647")
const N3 := Color("26355e")
const N4 := Color("34477a")
const N5 := Color("4a5f96")
const WOOD_D := Color("5a3826")  # Madera (puertas, marcos)
const WOOD := Color("8a5a3a")
const WOOD_L := Color("b9824f")
const TEAL_D := Color("1e4f5c")  # Casilleros
const TEAL := Color("2f7383")
const TEAL_L := Color("4fa3ac")
const PAPER := Color("e9dfc6")   # Papel, carteles
const PAPER_D := Color("b8ab8c")
const CORK := Color("9a6a42")
const CORK_D := Color("7a4f30")
const RED := Color("a8384a")
const SKIN := Color("f0c39a")
const SKIN_D := Color("c98d6b")
const HAIR := Color("2a2233")
const HAIR_L := Color("4a3d58")
const HOOD := Color("e0913a")    # Sudadera de Kai
const HOOD_D := Color("a85d24")
const HOOD_L := Color("ffc070")
const PANTS := Color("2c3555")
const SHOE := Color("16161f")
const MET_D := Color("3a4462")   # Metal (racks, bandejas)
const MET := Color("5a6788")
const MET_L := Color("8b98b8")
const CYAN := Color("3ef2ff")    # Red sana
const CYAN_M := Color("1fa5c4")
const CYAN_D := Color("146a8a")
const MAG := Color("ff3ea5")     # Amenazas
const MAG_D := Color("9c1f6e")
const LED_G := Color("59ff9c")
const LED_A := Color("ffb347")
const LED_R := Color("ff4d4d")
# Kai (diseño de Ariel): pelo plateado, chaqueta clara, ropa oscura y poder violeta-azul.
const PLATA_D := Color("8e8aa8")
const PLATA := Color("c9c6e0")
const PLATA_L := Color("eeedf7")
const TELA := Color("23243a")
const VIOLETA_D := Color("3a2a6e")
const VIOLETA := Color("7b4fe0")
const AZUL_E := Color("3b8ff0")
const AZUL_L := Color("8fd3ff")

const PALETTE: Array[Color] = [
	O, N1, N2, N3, N4, N5, WOOD_D, WOOD, WOOD_L, TEAL_D, TEAL, TEAL_L, PAPER, PAPER_D,
	CORK, CORK_D, RED, SKIN, SKIN_D, HAIR, HAIR_L, HOOD, HOOD_D, HOOD_L, PANTS, SHOE,
	MET_D, MET, MET_L, CYAN, CYAN_M, CYAN_D, MAG, MAG_D, LED_G, LED_A, LED_R,
	PLATA_D, PLATA, PLATA_L, TELA, VIOLETA_D, VIOLETA, AZUL_E, AZUL_L,
]

const KAI_W := 24
const KAI_H := 36


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_save_palette()
	_save_kai()
	_save_phish_lure()
	_save_tiles()
	_save_props()
	print("Sprites generados en ", OUT)
	quit()


# =====================================================================
# Kai, el personaje
# =====================================================================

func _save_kai() -> void:
	var idle: Array[Dictionary] = []
	for k in 4:
		idle.append({ "bob": [0, 0, 1, 1][k], "scarf": k * PI / 2.0 })
	var run: Array[Dictionary] = []
	for k in 8:
		var t := k / 8.0 * TAU
		var s := sin(t)
		run.append({
			"bob": 1 if absf(s) > 0.7 else 0,
			"lean": 1,
			"front_foot": Vector2i(roundi(4.0 * s), roundi(maxf(0.0, cos(t)) * 3.0)),
			"back_foot": Vector2i(roundi(-4.0 * s), roundi(maxf(0.0, -cos(t)) * 3.0)),
			"front_hand": Vector2i(roundi(-3.0 * s), -1 if s < 0.0 else 0),
			"back_hand": Vector2i(roundi(3.0 * s), -1 if s > 0.0 else 0),
			"scarf": t * 2.0,
			"droop": 0.15,
		})
	var jump: Array[Dictionary] = [
		{ "front_foot": Vector2i(2, 4), "back_foot": Vector2i(-2, 1), "front_hand": Vector2i(2, -5), "back_hand": Vector2i(-2, -4), "scarf": 0.0, "droop": 0.6 },
		{ "front_foot": Vector2i(3, 5), "back_foot": Vector2i(-1, 2), "front_hand": Vector2i(2, -6), "back_hand": Vector2i(-1, -5), "scarf": 1.5, "droop": 0.6 },
	]
	var fall: Array[Dictionary] = [
		{ "front_foot": Vector2i(1, 1), "back_foot": Vector2i(-1, 0), "front_hand": Vector2i(3, -3), "back_hand": Vector2i(-3, -3), "scarf": 0.0, "droop": -0.5 },
		{ "front_foot": Vector2i(2, 2), "back_foot": Vector2i(-1, 1), "front_hand": Vector2i(3, -4), "back_hand": Vector2i(-3, -4), "scarf": 1.8, "droop": -0.6 },
	]
	# Dash: cuerpo inclinado, brazos atrás, bufanda horizontal.
	var dash: Array[Dictionary] = [
		{ "bob": 1, "lean": 2, "front_foot": Vector2i(3, 2), "back_foot": Vector2i(-5, 1), "front_hand": Vector2i(-3, -1), "back_hand": Vector2i(-4, -1), "scarf": 0.0, "droop": -0.15 },
		{ "bob": 1, "lean": 2, "front_foot": Vector2i(3, 3), "back_foot": Vector2i(-5, 2), "front_hand": Vector2i(-3, 0), "back_hand": Vector2i(-4, 0), "scarf": 1.6, "droop": -0.2 },
	]
	# Deslizamiento en pared: la espalda contra la pared (a la izquierda) y una mano apoyada.
	var wall: Array[Dictionary] = [
		{ "lean": -1, "front_foot": Vector2i(2, 2), "back_foot": Vector2i(-3, 1), "front_hand": Vector2i(2, -1), "back_hand": Vector2i(-5, -5), "scarf": 0.0, "droop": -0.3 },
		{ "lean": -1, "front_foot": Vector2i(2, 3), "back_foot": Vector2i(-3, 1), "front_hand": Vector2i(2, -2), "back_hand": Vector2i(-5, -5), "scarf": 1.2, "droop": -0.35 },
	]
	_save_strip("kai_dash.png", dash)
	_save_strip("kai_wall.png", wall)
	_save_strip("kai_idle.png", idle)
	_save_strip("kai_run.png", run)
	_save_strip("kai_jump.png", jump)
	_save_strip("kai_fall.png", fall)


func _save_strip(file: String, poses: Array[Dictionary]) -> void:
	var sheet := PixelPainter.new(KAI_W * poses.size(), KAI_H)
	for i in poses.size():
		var f := PixelPainter.new(KAI_W, KAI_H)
		_paint_kai(f, poses[i])
		f.outline(O)
		sheet.paste(f, i * KAI_W, 0)
	sheet.save(OUT + file)


func _paint_kai(p: PixelPainter, pose: Dictionary) -> void:
	var bob: int = pose.get("bob", 0)
	var lean: int = pose.get("lean", 0)
	var front_foot: Vector2i = pose.get("front_foot", Vector2i(1, 0))
	var back_foot: Vector2i = pose.get("back_foot", Vector2i(-1, 0))
	var front_hand: Vector2i = pose.get("front_hand", Vector2i(1, 0))
	var back_hand: Vector2i = pose.get("back_hand", Vector2i(-1, 0))
	var scarf_phase: float = pose.get("scarf", 0.0)
	var droop: float = pose.get("droop", 0.7)  # Cuánto cae la bufanda (negativo = se eleva)
	var hip_y := 25 + bob
	var ux := lean  # Desplazamiento del torso al inclinarse

	# Bufanda: cola (detrás de todo).
	for i in 7:
		var x := 9 + ux - i - 1
		var y := 16 + bob + roundi(sin(scarf_phase + i * 0.9) * 0.8 + droop * i)
		p.rect(x, y, 1, 2 if i < 5 else 1, CYAN_M)
		if i % 2 == 0:
			p.px(x, y, CYAN)

	# Pierna trasera y brazo trasero (más oscuros).
	_leg(p, 10, hip_y, back_foot, PANTS.darkened(0.25))
	p.line(10 + ux, 18 + bob, 10 + ux + back_hand.x, 23 + bob + back_hand.y, HOOD_D, 2)
	p.rect(10 + ux + back_hand.x - 1, 23 + bob + back_hand.y, 2, 2, SKIN_D)

	# Pierna delantera.
	_leg(p, 12, hip_y, front_foot, PANTS)

	# Torso: sudadera.
	p.rect(9 + ux, 16 + bob, 6, 1, HOOD)
	p.rect(8 + ux, 17 + bob, 8, 8, HOOD)
	p.rect(8 + ux, 17 + bob, 2, 8, HOOD_D)
	p.rect(15 + ux, 17 + bob, 1, 6, HOOD_L)
	p.rect(8 + ux, 25 + bob, 8, 2, HOOD_D)
	p.rect(11 + ux, 22 + bob, 4, 1, HOOD_D)
	p.rect(7 + ux, 15 + bob, 3, 3, HOOD_D)  # Capucha recogida
	p.px(8 + ux, 15 + bob, HOOD)

	# Cabeza.
	var hy := bob
	p.ellipse(12.5 + ux, 7.5 + hy, 6.0, 4.2, HAIR)
	p.rect(7 + ux, 7 + hy, 4, 7, HAIR)
	p.ellipse(14.5 + ux, 11.2 + hy, 4.0, 4.2, SKIN)
	p.rect(13 + ux, 7 + hy, 6, 1, HAIR)  # Flequillo
	p.rect(17 + ux, 8 + hy, 2, 1, HAIR)
	p.rect(10 + ux, 4 + hy, 4, 1, HAIR_L)
	p.rect(12 + ux, 15 + hy, 5, 1, SKIN_D)  # Sombra del mentón
	p.rect(16 + ux, 10 + hy, 1, 2, O)  # Ojo
	p.px(17 + ux, 13 + hy, SKIN_D)

	# Auriculares con micrófono.
	p.rect(9 + ux, 3 + hy, 7, 1, CYAN_D)
	p.rect(9 + ux, 9 + hy, 3, 4, MET_D)
	p.px(10 + ux, 10 + hy, MET)
	p.line(11 + ux, 13 + hy, 15 + ux, 14 + hy, MET)
	p.px(16 + ux, 14 + hy, CYAN)

	# Bufanda: vuelta al cuello.
	p.rect(10 + ux, 15 + bob, 6, 2, CYAN_M)
	p.rect(11 + ux, 15 + bob, 4, 1, CYAN)

	# Brazo delantero.
	p.line(13 + ux, 18 + bob, 13 + ux + front_hand.x, 23 + bob + front_hand.y, HOOD, 2)
	p.rect(13 + ux + front_hand.x - 1, 23 + bob + front_hand.y, 2, 2, SKIN)


func _leg(p: PixelPainter, hip_x: int, hip_y: int, foot: Vector2i, color: Color) -> void:
	var foot_x := hip_x + foot.x
	var foot_y := 33 - foot.y
	p.line(hip_x, hip_y, foot_x, foot_y, color, 2)
	p.rect(foot_x - 1, foot_y + 1, 4, 2, SHOE)


# =====================================================================
# Amenaza: "El Anzuelo" (phishing). Un correo colgado de un anzuelo.
# =====================================================================

func _save_phish_lure() -> void:
	const W := 32
	const FRAMES := 6
	var sheet := PixelPainter.new(W * FRAMES, W)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in FRAMES:
		var p := PixelPainter.new(W, W)
		var b: int = [0, 0, 1, 1, 1, 0][k]
		# Sedal y anzuelo.
		p.line(16, 0, 16, 8 + b, MET_L)
		p.px(16, 9 + b, MET_L)
		p.rect(13, 10 + b, 3, 1, MET_L)
		p.px(13, 9 + b, MET_L)
		p.px(14, 8 + b, MET)
		# Sobre.
		p.rect(8, 11 + b, 17, 12, PAPER)
		p.rect(8, 22 + b, 17, 1, PAPER_D)
		p.rect(24, 11 + b, 1, 12, PAPER_D)
		p.line(8, 11 + b, 16, 17 + b, PAPER_D)
		p.line(24, 11 + b, 16, 17 + b, PAPER_D)
		p.rect(15, 16 + b, 3, 3, MAG)
		p.px(16, 17 + b, MAG_D)
		# Ojos que brillan bajo la solapa.
		var eye := MAG if k != 3 else MAG_D
		p.rect(11, 19 + b, 2, 1, eye)
		p.rect(20, 19 + b, 2, 1, eye)
		# Goteo de corrupción.
		for drip in [Vector2i(10, 2 + k % 3), Vector2i(14, 3 + (k + 1) % 3), Vector2i(21, 2 + (k + 2) % 3)]:
			p.rect(drip.x, 23 + b, 1, drip.y, MAG_D)
			p.px(drip.x, 23 + b + drip.y, MAG)
		# Fallo visual: una franja desplazada en algunos cuadros.
		if k == 2 or k == 4:
			var band := p.image.get_region(Rect2i(6, 13 + b, 22, 3))
			p.rect(6, 13 + b, 22, 3, Color.TRANSPARENT)
			p.image.blend_rect(band, Rect2i(0, 0, 22, 3), Vector2i(8 if k == 2 else 4, 13 + b))
		p.outline(O)
		for i in 5:
			p.px(rng.randi_range(4, 27), rng.randi_range(8, 28), MAG if i % 2 == 0 else CYAN)
		sheet.paste(p, k * W, 0)
	sheet.save(OUT + "phish_lure.png")


# =====================================================================
# Tiles de 16×16 (una fila: ver TILE_* en muestra_pixel.gd)
# =====================================================================

func _save_tiles() -> void:
	var sheet := PixelPainter.new(16 * 10, 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var t: PixelPainter

	# 0: suelo (cara superior + borde).
	t = PixelPainter.new(16, 16)
	t.rect(0, 0, 16, 1, N5)
	t.rect(0, 1, 16, 3, N4)
	t.rect(0, 4, 16, 1, O)
	t.rect(0, 5, 16, 11, N2)
	t.rect(15, 5, 1, 11, N1)
	t.rect(0, 2, 16, 1, CYAN_D)
	for i in 3:
		t.px(rng.randi_range(0, 15), rng.randi_range(6, 15), N3)
	sheet.paste(t, 0, 0)

	# 1: relleno bajo el suelo.
	t = PixelPainter.new(16, 16)
	t.rect(0, 0, 16, 16, N1)
	for i in 4:
		t.px(rng.randi_range(0, 15), rng.randi_range(0, 15), N2)
	sheet.paste(t, 16, 0)

	# 2: pared del pasillo.
	t = PixelPainter.new(16, 16)
	t.rect(0, 0, 16, 16, N2)
	t.rect(0, 0, 1, 16, N1)
	for i in 6:
		t.px(rng.randi_range(1, 15), rng.randi_range(0, 15), N3 if i % 2 == 0 else N1)
	sheet.paste(t, 32, 0)

	# 3: pared tecnológica con pistas de circuito.
	t = PixelPainter.new(16, 16)
	t.rect(0, 0, 16, 16, N1)
	t.rect(0, 5, 10, 1, CYAN_D)
	t.rect(9, 5, 1, 7, CYAN_D)
	t.rect(9, 12, 7, 1, CYAN_D)
	t.px(9, 12, CYAN_M)
	t.px(3, 5, CYAN_M)
	t.rect(0, 0, 16, 1, N2)
	sheet.paste(t, 48, 0)

	# 4: zócalo (pared con franja inferior de casilleros).
	t = PixelPainter.new(16, 16)
	t.rect(0, 0, 16, 16, N2)
	t.rect(0, 10, 16, 6, TEAL_D)
	t.rect(0, 10, 16, 1, TEAL)
	t.rect(0, 0, 1, 10, N1)
	sheet.paste(t, 64, 0)

	# 5: techo con bandeja de cables.
	t = PixelPainter.new(16, 16)
	t.rect(0, 0, 16, 10, N1)
	t.rect(0, 10, 16, 1, O)
	t.rect(0, 11, 16, 3, MET_D)
	t.rect(0, 11, 16, 1, MET)
	t.px(4, 12, LED_G)
	t.rect(0, 14, 16, 1, CYAN_D)
	t.rect(0, 15, 16, 1, MAG_D)
	sheet.paste(t, 80, 0)

	# 6: cables horizontales (transparente).
	t = PixelPainter.new(16, 16)
	t.rect(0, 6, 16, 1, CYAN_D)
	t.rect(0, 8, 16, 1, MAG_D)
	t.rect(0, 10, 16, 1, LED_A.darkened(0.5))
	t.rect(7, 5, 2, 7, MET)
	sheet.paste(t, 96, 0)

	# 7: suelo corrupto (la amenaza "rompe" la cuadrícula).
	t = PixelPainter.new(16, 16)
	t.rect(0, 0, 16, 1, MAG)
	t.rect(0, 1, 16, 3, N4)
	t.rect(0, 4, 16, 1, O)
	t.rect(0, 5, 16, 11, N2)
	t.rect(3, 1, 5, 2, MAG_D)
	t.rect(10, 2, 4, 1, MAG)
	for i in 8:
		t.px(rng.randi_range(0, 15), rng.randi_range(5, 15), MAG_D if i % 3 else MAG)
	sheet.paste(t, 112, 0)

	# 8: moldura a media altura del pasillo.
	t = PixelPainter.new(16, 16)
	t.rect(0, 0, 16, 16, N2)
	t.rect(0, 0, 1, 16, N1)
	t.rect(0, 6, 16, 1, O)
	t.rect(0, 7, 16, 3, N4)
	t.rect(0, 7, 16, 1, N5)
	t.rect(0, 10, 16, 1, O)
	sheet.paste(t, 128, 0)

	# 9: pared tecnológica lisa (alterna con la de circuitos).
	t = PixelPainter.new(16, 16)
	t.rect(0, 0, 16, 16, N1)
	t.rect(0, 0, 16, 1, N2)
	t.px(rng.randi_range(2, 13), rng.randi_range(3, 12), CYAN_D)
	sheet.paste(t, 144, 0)

	sheet.save(OUT + "tiles.png")


# =====================================================================
# Objetos del escenario
# =====================================================================

func _save_props() -> void:
	_save_lockers()
	_save_door()
	_save_window()
	_save_board()
	_save_server_rack()
	_save_router()
	_save_sign("sign_lab.png", "LABORATORIO")
	_save_sign("sign_sala.png", "SALA 3")
	_save_decor()
	_save_lab_door()
	var packet := PixelPainter.new(5, 3)
	packet.rect(0, 0, 5, 3, CYAN_M)
	packet.rect(1, 1, 3, 1, CYAN)
	packet.save(OUT + "packet.png")
	var bad := PixelPainter.new(5, 3)
	bad.rect(0, 0, 5, 3, MAG_D)
	bad.rect(1, 1, 3, 1, MAG)
	bad.save(OUT + "packet_bad.png")


func _save_lockers() -> void:
	var sheet := PixelPainter.new(32, 40)
	for v in 2:
		var p := PixelPainter.new(16, 40)
		p.rect(0, 0, 16, 40, O)
		p.rect(1, 1, 14, 38, TEAL)
		p.rect(1, 1, 1, 38, TEAL_L)
		p.rect(14, 1, 1, 38, TEAL_D)
		p.rect(1, 1, 14, 1, TEAL_L)
		for row in [4, 6, 8]:
			p.rect(4, row, 8, 1, TEAL_D)
		p.rect(5, 12, 5, 3, PAPER_D)
		p.px(7, 13, O)
		p.rect(11, 19, 1, 4, MET_L)
		p.rect(1, 36, 14, 3, TEAL_D)
		if v == 1:
			p.rect(4, 25, 4, 4, MAG_D)  # Calcomanía
			p.rect(5, 26, 2, 2, MAG)
			p.rect(9, 28, 3, 3, CYAN_M)
		sheet.paste(p, v * 16, 0)
	sheet.save(OUT + "lockers.png")


func _save_door() -> void:
	var p := PixelPainter.new(28, 48)
	p.rect(0, 0, 28, 48, O)
	p.rect(1, 1, 26, 47, WOOD_D)
	p.rect(4, 4, 20, 44, WOOD)
	p.rect(4, 4, 1, 44, WOOD_L)
	p.rect(7, 8, 14, 12, O)
	p.rect(8, 9, 12, 10, CYAN_D)
	p.rect(8, 9, 12, 3, CYAN_M)
	p.line(10, 17, 15, 10, CYAN)
	p.rect(7, 26, 14, 1, WOOD_D)
	p.rect(7, 36, 14, 1, WOOD_D)
	p.rect(20, 28, 2, 3, MET_L)
	p.save(OUT + "door.png")


func _save_window() -> void:
	var p := PixelPainter.new(40, 28)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	p.rect(0, 0, 40, 28, MET_D)
	p.rect(2, 2, 36, 23, N1)
	for i in 10:
		p.px(rng.randi_range(3, 36), rng.randi_range(3, 12), PAPER)
	var x := 2
	while x < 38:
		var w := rng.randi_range(4, 7)
		var h := rng.randi_range(5, 13)
		p.rect(x, 25 - h, w, h, N2 if rng.randf() < 0.5 else N3)
		for i in 3:
			p.px(rng.randi_range(x, x + w - 1), rng.randi_range(26 - h, 23), LED_A if i % 2 == 0 else CYAN_M)
		x += w
	p.rect(19, 2, 2, 23, MET_D)
	p.rect(0, 25, 40, 3, MET_L)
	p.rect(0, 27, 40, 1, MET)
	p.save(OUT + "window.png")


func _save_board() -> void:
	var p := PixelPainter.new(36, 24)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	p.rect(0, 0, 36, 24, O)
	p.rect(1, 1, 34, 22, WOOD_D)
	p.rect(3, 3, 30, 18, CORK)
	for i in 14:
		p.px(rng.randi_range(3, 32), rng.randi_range(3, 20), CORK_D)
	p.rect(5, 5, 8, 7, PAPER)
	for row in [7, 9]:
		p.rect(6, row, 6, 1, PAPER_D)
	p.rect(14, 10, 7, 8, PAPER_D)
	p.rect(15, 12, 5, 1, WOOD)
	p.rect(23, 4, 8, 12, MAG_D)  # Afiche: "¡Cuidado con el phishing!"
	p.frame(23, 4, 8, 12, MAG)
	p.rect(26, 6, 2, 5, PAPER)
	p.rect(26, 12, 2, 2, PAPER)
	p.px(9, 5, RED)
	p.px(17, 10, CYAN)
	p.save(OUT + "board.png")


func _save_server_rack() -> void:
	const W := 28
	const H := 64
	var sheet := PixelPainter.new(W * 4, H)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for k in 4:
		var p := PixelPainter.new(W, H)
		p.rect(0, 0, W, H, O)
		p.rect(1, 1, W - 2, H - 3, MET_D)
		p.rect(3, 3, W - 6, H - 7, N1)
		p.rect(1, 1, 1, H - 3, MET)
		for u in 7:
			var y := 4 + u * 8
			p.rect(4, y, 20, 6, MET)
			p.rect(4, y, 20, 1, MET_L)
			for vx in range(6, 15, 2):
				p.px(vx, y + 3, MET_D)
			for led in 3:
				var roll := rng.randf()
				var color := LED_G if roll < 0.55 else (LED_A if roll < 0.75 else MET_D)
				if u == 5 and led == 2 and k % 2 == 0:
					color = LED_R
				p.px(17 + led * 2, y + 2, color)
		p.rect(2, H - 2, 4, 2, O)
		p.rect(W - 6, H - 2, 4, 2, O)
		sheet.paste(p, k * W, 0)
	sheet.save(OUT + "server_rack.png")


func _save_router() -> void:
	var router := PixelPainter.new(18, 12)
	router.rect(1, 6, 16, 6, MET_D)
	router.rect(1, 6, 16, 1, MET)
	router.line(4, 0, 4, 6, MET_L)
	router.line(13, 0, 13, 6, MET_L)
	router.px(4, 0, CYAN)
	router.px(13, 0, CYAN)
	for i in 4:
		router.px(5 + i * 2, 9, LED_G if i < 3 else CYAN)
	router.outline(O)
	router.save(OUT + "router.png")

	# Ondas de Wi-Fi: 3 cuadros, cada uno con un arco más.
	var waves := PixelPainter.new(30 * 3, 18)
	for k in 3:
		var p := PixelPainter.new(30, 18)
		for r in k + 1:
			var radius := 5.0 + r * 5.0
			var color := CYAN if r == k else CYAN_M
			for a in range(-140, -39, 4):
				var angle := deg_to_rad(a)
				p.px(roundi(15 + cos(angle) * radius), roundi(17 + sin(angle) * radius), color)
		waves.paste(p, k * 30, 0)
	waves.save(OUT + "wifi_waves.png")


func _save_sign(file: String, text: String) -> void:
	var w := text.length() * 4 + 7
	var p := PixelPainter.new(w, 13)
	p.rect(0, 0, w, 13, Color(CYAN_D, 0.55))
	p.frame(0, 0, w, 13, CYAN_M)
	for y in range(2, 12, 2):
		p.rect(1, y, w - 2, 1, Color(CYAN_D, 0.35))
	p.text(4, 4, text, CYAN)
	p.save(OUT + file)


func _save_palette() -> void:
	const SIZE := 8
	const COLUMNS := 8
	var rows := ceili(PALETTE.size() / float(COLUMNS))
	var p := PixelPainter.new(COLUMNS * SIZE, rows * SIZE)
	for i in PALETTE.size():
		p.rect((i % COLUMNS) * SIZE, (i / COLUMNS) * SIZE, SIZE, SIZE, PALETTE[i])
	p.save(OUT + "paleta.png")


func _save_decor() -> void:
	# Lámpara de techo.
	var lamp := PixelPainter.new(20, 5)
	lamp.rect(0, 0, 20, 3, MET_D)
	lamp.rect(2, 3, 16, 2, PAPER)
	lamp.rect(4, 3, 12, 1, Color.WHITE)
	lamp.outline(O)
	lamp.save(OUT + "lamp.png")

	# Reloj de pared.
	var clock := PixelPainter.new(13, 13)
	clock.ellipse(6.5, 6.5, 6.5, 6.5, O)
	clock.ellipse(6.5, 6.5, 5.5, 5.5, PAPER)
	clock.rect(6, 3, 1, 4, O)
	clock.rect(6, 6, 3, 1, O)
	clock.px(6, 1, RED)
	clock.save(OUT + "clock.png")

	# Banderines de la feria de ciencias.
	var flags := PixelPainter.new(72, 10)
	flags.line(0, 1, 71, 1, PAPER_D)
	var colors: Array[Color] = [CYAN_M, HOOD, TEAL_L, MAG_D, LED_A]
	for i in 9:
		var x := 2 + i * 8
		var c := colors[i % colors.size()]
		for row in 6:
			flags.rect(x + row / 2, 2 + row, 6 - row, 1, c)
	flags.save(OUT + "pennants.png")

	# Canaleta vertical con cables (se repite verticalmente).
	var conduit := PixelPainter.new(7, 16)
	conduit.rect(0, 0, 7, 16, MET_D)
	conduit.rect(0, 0, 1, 16, MET)
	conduit.rect(2, 0, 1, 16, CYAN_D)
	conduit.rect(4, 0, 1, 16, MAG_D)
	conduit.rect(6, 0, 1, 16, O)
	conduit.rect(0, 7, 7, 2, MET)
	conduit.save(OUT + "conduit.png")


func _save_lab_door() -> void:
	var p := PixelPainter.new(30, 48)
	p.rect(0, 0, 30, 48, O)
	p.rect(1, 1, 28, 47, CYAN_D)
	p.rect(3, 3, 24, 45, Color(CYAN_M, 0.35))
	p.rect(3, 3, 24, 8, Color(CYAN_M, 0.5))
	p.rect(14, 3, 2, 45, Color(CYAN, 0.5))
	p.line(6, 40, 11, 10, Color(1, 1, 1, 0.25))
	p.save(OUT + "lab_door.png")
