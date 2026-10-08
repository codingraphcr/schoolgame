extends SceneTree
## Genera la plantilla de Kai por piezas (técnica de huesos pixelados) y las imágenes de la guía de arte.
## Diseño de referencia: Kai de Ariel (pelo plateado, chaqueta clara con cuello alto, mochila, ~40 px).
## Ejecutar: godot --headless --path . --script res://prototypes/estilos/huesos_pixelados/generar_plantilla_kai.gd
##
## Salidas:
##   assets/art/characters/kai/kai_piezas.png   → plantilla editable a tamaño real (redibújala encima)
##   assets/art/characters/kai/aegis.png        → acompañante flotante (no va en el esqueleto)
##   docs/arte/img/kai_piezas_guia.png          → piezas ampliadas con nombre, pivotes y ensamblado
##   docs/arte/img/paleta.png                   → paleta ampliada con códigos hexadecimales
##   assets/art/paleta.png / paleta.gpl         → paleta para programas de dibujo

const Sprites := preload("res://prototypes/estilos/pixel/generar_sprites.gd")

const PIECES_OUT := "res://assets/art/characters/kai/kai_piezas.png"
const AEGIS_OUT := "res://assets/art/characters/kai/aegis.png"
const GUIDE_OUT := "res://docs/arte/img/kai_piezas_guia.png"
const PALETTE_OUT := "res://docs/arte/img/paleta.png"

const PIVOT := Color("ff2a2a")
const JOINT := Color("ffe14d")
const BACKGROUND := Color("1b2033")
const LABEL := Color("c9d3ee")
const BACK_TINT := Color(0.72, 0.72, 0.82)  # Las extremidades de atrás reutilizan la pieza, más oscura.

## Piezas del esqueleto: tamaño del lienzo (incluye 1 px de margen para el contorno),
## pivote (punto de giro, se une a la pieza padre) y articulaciones (donde se unen las piezas hijas).
var pieces := {
	"cabeza": { "size": Vector2i(18, 18), "pivot": Vector2i(9, 16), "joints": { "flequillo": Vector2i(13, 7) } },
	"mechon": { "size": Vector2i(7, 9), "pivot": Vector2i(2, 1), "joints": {} },
	"torso": { "size": Vector2i(14, 16), "pivot": Vector2i(7, 14), "joints": { "cuello": Vector2i(7, 1), "hombro": Vector2i(7, 4), "espalda": Vector2i(3, 6) } },
	"mochila": { "size": Vector2i(10, 12), "pivot": Vector2i(6, 3), "joints": {} },
	"brazo": { "size": Vector2i(8, 11), "pivot": Vector2i(3, 2), "joints": { "codo": Vector2i(3, 8) } },
	"antebrazo": { "size": Vector2i(8, 10), "pivot": Vector2i(3, 2), "joints": { "mano": Vector2i(3, 8) } },
	"muslo": { "size": Vector2i(8, 11), "pivot": Vector2i(3, 2), "joints": { "rodilla": Vector2i(3, 8) } },
	"pierna": { "size": Vector2i(11, 12), "pivot": Vector2i(3, 2), "joints": {} },
	"arma": { "size": Vector2i(9, 22), "pivot": Vector2i(4, 17), "joints": {} },
}
## El Aegis flota junto a Kai: no lleva huesos, se anima por cuadros.
const AEGIS_SIZE := Vector2i(16, 16)

var images := {}
var aegis: PixelPainter


func _initialize() -> void:
	for piece_name: String in pieces:
		var size: Vector2i = pieces[piece_name].size
		var p := PixelPainter.new(size.x, size.y)
		call("_draw_" + piece_name, p)
		p.outline(Sprites.O)
		images[piece_name] = p
	aegis = PixelPainter.new(AEGIS_SIZE.x, AEGIS_SIZE.y)
	_draw_aegis(aegis)
	aegis.outline(Sprites.O)
	for path in [PIECES_OUT, GUIDE_OUT]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	_save_sheet()
	aegis.save(AEGIS_OUT)
	_save_guide()
	_save_palette()
	print("Plantilla de Kai generada.")
	quit()


# --- Piezas (mirando a la derecha) ---

func _draw_cabeza(p: PixelPainter) -> void:
	# Pelo plateado alborotado.
	p.ellipse(8.5, 7.5, 7.0, 6.0, Sprites.PLATA)
	p.line(4, 3, 2, 1, Sprites.PLATA)
	p.line(8, 2, 8, 1, Sprites.PLATA)
	p.line(12, 2, 14, 1, Sprites.PLATA)
	p.line(2, 7, 1, 5, Sprites.PLATA)
	p.rect(2, 6, 4, 7, Sprites.PLATA)
	p.rect(3, 10, 3, 3, Sprites.PLATA_D)
	p.rect(6, 3, 4, 1, Sprites.PLATA_L)
	p.px(11, 4, Sprites.PLATA_L)
	# Cara.
	p.ellipse(11.0, 10.5, 4.2, 4.5, Sprites.SKIN)
	p.rect(9, 6, 7, 2, Sprites.PLATA)  # Flequillo
	p.rect(14, 8, 1, 3, Sprites.PLATA)
	p.px(10, 8, Sprites.PLATA)
	p.px(12, 8, Sprites.PLATA_D)
	# Ojo violeta con brillo.
	p.rect(12, 9, 2, 1, Sprites.O)
	p.rect(12, 10, 2, 2, Sprites.VIOLETA)
	p.px(13, 10, Sprites.PLATA_L)
	p.px(8, 11, Sprites.SKIN_D)  # Oreja
	p.px(14, 13, Sprites.SKIN_D)
	p.rect(9, 14, 4, 1, Sprites.SKIN_D)
	p.rect(9, 15, 3, 2, Sprites.SKIN_D)  # Cuello


func _draw_mechon(p: PixelPainter) -> void:
	p.rect(2, 1, 2, 2, Sprites.PLATA)
	p.rect(2, 3, 2, 2, Sprites.PLATA)
	p.rect(3, 5, 2, 2, Sprites.PLATA_D)
	p.px(2, 1, Sprites.PLATA_L)


func _draw_torso(p: PixelPainter) -> void:
	p.rect(2, 2, 3, 3, Sprites.PLATA)  # Capucha detrás del cuello
	p.px(3, 3, Sprites.PLATA_D)
	p.rect(2, 4, 10, 9, Sprites.PLATA_L)  # Chaqueta
	p.rect(2, 4, 2, 9, Sprites.PLATA)
	p.rect(2, 10, 2, 3, Sprites.PLATA_D)
	p.rect(2, 12, 9, 2, Sprites.PLATA)
	p.rect(9, 4, 2, 8, Sprites.TELA)  # Camiseta oscura con luz
	p.px(9, 7, Sprites.AZUL_E)
	p.px(10, 8, Sprites.VIOLETA)
	p.rect(5, 1, 5, 3, Sprites.TELA)  # Cuello alto
	p.px(6, 2, Sprites.VIOLETA)
	p.rect(6, 9, 2, 1, Sprites.PLATA_D)


func _draw_mochila(p: PixelPainter) -> void:
	p.rect(2, 1, 5, 1, Sprites.TELA)
	p.rect(1, 2, 7, 9, Sprites.TELA)
	p.rect(1, 2, 1, 9, Sprites.N3)
	p.px(4, 5, Sprites.AZUL_L)  # Emblema luminoso
	p.px(3, 6, Sprites.VIOLETA)
	p.px(5, 6, Sprites.VIOLETA)
	p.px(4, 7, Sprites.AZUL_L)
	p.rect(7, 3, 2, 5, Sprites.N3)  # Correa


func _draw_brazo(p: PixelPainter) -> void:
	p.rect(2, 1, 4, 8, Sprites.PLATA_L)
	p.rect(2, 1, 1, 8, Sprites.PLATA)
	p.rect(2, 7, 4, 2, Sprites.PLATA_D)
	p.px(2, 1, Color.TRANSPARENT)
	p.px(5, 1, Color.TRANSPARENT)


func _draw_antebrazo(p: PixelPainter) -> void:
	p.rect(2, 1, 4, 3, Sprites.PLATA_L)
	p.rect(2, 1, 1, 3, Sprites.PLATA)
	p.rect(2, 4, 4, 5, Sprites.TELA)  # Guante
	p.px(4, 5, Sprites.AZUL_E)
	p.px(2, 8, Color.TRANSPARENT)
	p.px(5, 8, Color.TRANSPARENT)


func _draw_muslo(p: PixelPainter) -> void:
	p.rect(2, 1, 4, 8, Sprites.TELA)
	p.rect(5, 1, 1, 8, Sprites.N3)
	p.rect(3, 4, 2, 2, Sprites.N3)  # Bolsillo cargo
	p.px(3, 5, Sprites.VIOLETA_D)


func _draw_pierna(p: PixelPainter) -> void:
	p.rect(2, 1, 4, 6, Sprites.TELA)
	p.rect(5, 1, 1, 6, Sprites.N3)
	p.rect(2, 6, 4, 1, Sprites.N3)
	p.rect(2, 7, 7, 2, Sprites.N3)  # Zapatilla
	p.px(5, 7, Sprites.VIOLETA)
	p.px(7, 8, Sprites.AZUL_E)
	p.rect(2, 9, 7, 1, Sprites.PLATA_L)


## Arma provisional (Nullblade): cada nivel será una imagen distinta con el mismo pivote.
func _draw_arma(p: PixelPainter) -> void:
	p.px(4, 1, Sprites.PLATA_L)
	p.rect(3, 2, 3, 12, Sprites.PLATA_L)
	p.rect(4, 2, 1, 12, Sprites.PLATA)
	p.rect(5, 3, 1, 10, Sprites.AZUL_L)
	p.rect(1, 14, 7, 2, Sprites.VIOLETA_D)
	p.px(4, 14, Sprites.AZUL_E)
	p.rect(3, 16, 3, 4, Sprites.TELA)
	p.px(4, 20, Sprites.VIOLETA)


func _draw_aegis(p: PixelPainter) -> void:
	p.ellipse(7.5, 7.5, 6.0, 6.0, Sprites.TELA)
	p.ellipse(7.5, 7.5, 3.6, 3.6, Sprites.VIOLETA_D)
	p.ellipse(7.5, 7.5, 2.0, 2.0, Sprites.AZUL_L)
	p.px(4, 4, Sprites.N4)
	p.px(5, 3, Sprites.N4)


# --- Plantilla a tamaño real ---

func _save_sheet() -> void:
	var width := 0
	var height := 0
	for piece_name: String in pieces:
		var size: Vector2i = pieces[piece_name].size
		width += size.x + 2
		height = maxi(height, size.y)
	var sheet := PixelPainter.new(width, height)
	var x := 0
	for piece_name: String in pieces:
		sheet.paste(images[piece_name], x, 0)
		x += int(pieces[piece_name].size.x) + 2
	sheet.save(PIECES_OUT)


# --- Guía ampliada: piezas con nombre y pivotes + Kai ensamblado ---

func _save_guide() -> void:
	const CELL := Vector2i(44, 34)
	const COLUMNS := 5
	const SCALE := 5
	const ASSEMBLED_WIDTH := 56
	var guide := PixelPainter.new(CELL.x * COLUMNS + ASSEMBLED_WIDTH, CELL.y * 2 + 4)
	guide.rect(0, 0, guide.width, guide.height, BACKGROUND)
	var cells: Array[String] = []
	cells.assign(pieces.keys())
	cells.append("aegis")
	for i in cells.size():
		var piece_name := cells[i]
		var cell := Vector2i((i % COLUMNS) * CELL.x, (i / COLUMNS) * CELL.y + 2)
		var painter: PixelPainter = aegis if piece_name == "aegis" else images[piece_name]
		var origin := cell + Vector2i((CELL.x - painter.width) / 2, 23 - painter.height)
		guide.paste(painter, origin.x, origin.y)
		if piece_name != "aegis":
			var pivot: Vector2i = pieces[piece_name].pivot
			guide.px(origin.x + pivot.x, origin.y + pivot.y, PIVOT)
			for joint: String in pieces[piece_name].joints:
				var j: Vector2i = pieces[piece_name].joints[joint]
				guide.px(origin.x + j.x, origin.y + j.y, JOINT)
		var label := piece_name.to_upper()
		guide.text(cell.x + (CELL.x - label.length() * 4) / 2, cell.y + 25, label, LABEL)

	# Kai ensamblado: cada pivote coincide con la articulación de su pieza padre.
	var hip := Vector2i(CELL.x * COLUMNS + 26, 50)
	var torso_pivot: Vector2i = pieces.torso.pivot
	var torso_at := hip - torso_pivot
	var neck: Vector2i = torso_at + pieces.torso.joints.cuello
	var shoulder: Vector2i = torso_at + pieces.torso.joints.hombro
	var back: Vector2i = torso_at + pieces.torso.joints.espalda
	var head_pivot: Vector2i = pieces.cabeza.pivot
	var fringe: Vector2i = neck - head_pivot + pieces.cabeza.joints.flequillo
	var limb := Vector2i(0, 6)  # Distancia pivote → articulación en brazos y piernas
	_place(guide, "brazo", shoulder + Vector2i(-2, 0), BACK_TINT)
	_place(guide, "antebrazo", shoulder + Vector2i(-2, 0) + limb, BACK_TINT)
	_place(guide, "muslo", hip + Vector2i(-1, 0), BACK_TINT)
	_place(guide, "pierna", hip + Vector2i(-1, 0) + limb, BACK_TINT)
	_place(guide, "mochila", back)
	_place(guide, "muslo", hip + Vector2i(1, 0))
	_place(guide, "pierna", hip + Vector2i(1, 0) + limb)
	_place(guide, "torso", hip)
	_place(guide, "cabeza", neck)
	_place(guide, "mechon", fringe)
	_place(guide, "brazo", shoulder)
	_place(guide, "antebrazo", shoulder + limb)
	guide.text(CELL.x * COLUMNS + 8, CELL.y * 2 - 1, "ENSAMBLADO", LABEL)
	guide.image.resize(guide.width * SCALE, guide.height * SCALE, Image.INTERPOLATE_NEAREST)
	guide.save(GUIDE_OUT)


## Pega una pieza haciendo coincidir su pivote con `at`. `flip` la invierte verticalmente
## (el arma en reposo apunta hacia abajo).
func _place(guide: PixelPainter, piece_name: String, at: Vector2i, tint := Color.WHITE, flip := false) -> void:
	var source: PixelPainter = images[piece_name]
	var piece := PixelPainter.new(source.width, source.height)
	piece.image = source.image.duplicate()
	var pivot: Vector2i = pieces[piece_name].pivot
	if flip:
		piece.image.flip_y()
		pivot.y = source.height - 1 - pivot.y
	if tint != Color.WHITE:
		for y in piece.height:
			for x in piece.width:
				var c := piece.image.get_pixel(x, y)
				if c.a > 0.0:
					piece.image.set_pixel(x, y, Color(c.r * tint.r, c.g * tint.g, c.b * tint.b, c.a))
	guide.paste(piece, at.x - pivot.x, at.y - pivot.y)


# --- Paleta con códigos ---

func _save_palette() -> void:
	const COLUMNS := 5
	const CELL := Vector2i(34, 22)
	const SCALE := 4
	var colors: Array[Color] = Sprites.PALETTE
	var rows := ceili(colors.size() / float(COLUMNS))
	var p := PixelPainter.new(COLUMNS * CELL.x + 4, rows * CELL.y + 4)
	p.rect(0, 0, p.width, p.height, BACKGROUND)
	for i in colors.size():
		var cell := Vector2i(4 + (i % COLUMNS) * CELL.x, 4 + (i / COLUMNS) * CELL.y)
		p.rect(cell.x, cell.y, CELL.x - 6, 11, colors[i])
		p.frame(cell.x, cell.y, CELL.x - 6, 11, Sprites.O)
		p.text(cell.x, cell.y + 13, colors[i].to_html(false).to_upper(), LABEL)
	p.image.resize(p.width * SCALE, p.height * SCALE, Image.INTERPOLATE_NEAREST)
	p.save(PALETTE_OUT)

	# Paleta para importar en programas de dibujo: 1 píxel por color y formato GIMP (.gpl).
	var raw := PixelPainter.new(colors.size(), 1)
	for i in colors.size():
		raw.px(i, 0, colors[i])
	raw.save("res://assets/art/paleta.png")
	var gpl := FileAccess.open("res://assets/art/paleta.gpl", FileAccess.WRITE)
	gpl.store_line("GIMP Palette")
	gpl.store_line("Name: Escudo Escolar")
	gpl.store_line("Columns: 8")
	gpl.store_line("#")
	for c in colors:
		gpl.store_line("%3d %3d %3d\t%s" % [c.r8, c.g8, c.b8, c.to_html(false).to_upper()])
	gpl.close()
