extends SceneTree
## Genera la plantilla de Kai por piezas (técnica de huesos pixelados) y las imágenes de la guía de arte.
## Ejecutar: godot --headless --path . --script res://prototypes/estilos/huesos_pixelados/generar_plantilla_kai.gd
##
## Salidas:
##   assets/art/characters/kai/kai_piezas.png   → plantilla editable a tamaño real (redibújala encima)
##   docs/arte/img/kai_piezas_guia.png          → piezas ampliadas con nombre, pivotes y ensamblado
##   docs/arte/img/paleta.png                   → paleta ampliada con códigos hexadecimales

const Sprites := preload("res://prototypes/estilos/pixel/generar_sprites.gd")

const PIECES_OUT := "res://assets/art/characters/kai/kai_piezas.png"
const GUIDE_OUT := "res://docs/arte/img/kai_piezas_guia.png"
const PALETTE_OUT := "res://docs/arte/img/paleta.png"

const PIVOT := Color("ff2a2a")
const JOINT := Color("ffe14d")
const BACKGROUND := Color("1b2033")
const LABEL := Color("c9d3ee")
const BACK_TINT := Color(0.72, 0.72, 0.82)  # Las extremidades de atrás reutilizan la pieza, más oscura.


## Definición de cada pieza: tamaño del lienzo (incluye 1 px de margen para el contorno),
## pivote (punto de giro, se une a la pieza padre) y articulaciones (donde se une la pieza hija).
var pieces := {
	"cabeza": { "size": Vector2i(16, 16), "pivot": Vector2i(8, 14), "joints": {} },
	"torso": { "size": Vector2i(12, 14), "pivot": Vector2i(6, 12), "joints": { "cuello": Vector2i(6, 1), "hombro": Vector2i(6, 3) } },
	"brazo": { "size": Vector2i(7, 9), "pivot": Vector2i(3, 2), "joints": { "codo": Vector2i(3, 7) } },
	"antebrazo": { "size": Vector2i(7, 9), "pivot": Vector2i(3, 2), "joints": {} },
	"muslo": { "size": Vector2i(7, 9), "pivot": Vector2i(3, 2), "joints": { "rodilla": Vector2i(3, 7) } },
	"pierna": { "size": Vector2i(9, 10), "pivot": Vector2i(3, 2), "joints": {} },
	"bufanda": { "size": Vector2i(11, 5), "pivot": Vector2i(5, 2), "joints": {} },
	"cola": { "size": Vector2i(6, 4), "pivot": Vector2i(4, 2), "joints": {} },
}
var images := {}


func _initialize() -> void:
	for piece_name: String in pieces:
		var size: Vector2i = pieces[piece_name].size
		var p := PixelPainter.new(size.x, size.y)
		call("_draw_" + piece_name, p)
		p.outline(Sprites.O)
		images[piece_name] = p
	for path in [PIECES_OUT, GUIDE_OUT]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	_save_sheet()
	_save_guide()
	_save_palette()
	print("Plantilla de Kai generada.")
	quit()


# --- Piezas (mirando a la derecha) ---

func _draw_cabeza(p: PixelPainter) -> void:
	p.ellipse(7.5, 7.0, 6.0, 5.0, Sprites.HAIR)
	p.rect(2, 6, 4, 6, Sprites.HAIR)
	p.ellipse(9.5, 9.2, 4.0, 4.3, Sprites.SKIN)
	p.rect(8, 5, 6, 1, Sprites.HAIR)
	p.rect(12, 6, 2, 1, Sprites.HAIR)
	p.rect(5, 3, 4, 1, Sprites.HAIR_L)
	p.rect(7, 13, 5, 1, Sprites.SKIN_D)
	p.rect(11, 8, 1, 2, Sprites.O)
	p.px(12, 11, Sprites.SKIN_D)
	p.rect(4, 2, 7, 1, Sprites.CYAN_D)
	p.rect(3, 7, 3, 4, Sprites.MET_D)
	p.px(4, 8, Sprites.MET)
	p.line(6, 11, 10, 12, Sprites.MET)
	p.px(11, 12, Sprites.CYAN)


func _draw_torso(p: PixelPainter) -> void:
	p.rect(1, 0, 3, 3, Sprites.HOOD_D)  # Capucha recogida
	p.px(2, 0, Sprites.HOOD)
	p.rect(3, 1, 6, 1, Sprites.HOOD)
	p.rect(2, 2, 8, 9, Sprites.HOOD)
	p.rect(2, 2, 2, 9, Sprites.HOOD_D)
	p.rect(9, 2, 1, 7, Sprites.HOOD_L)
	p.rect(5, 8, 4, 1, Sprites.HOOD_D)
	p.rect(2, 11, 8, 2, Sprites.HOOD_D)


func _draw_brazo(p: PixelPainter) -> void:
	p.rect(2, 1, 3, 7, Sprites.HOOD)
	p.rect(2, 1, 1, 7, Sprites.HOOD_D)
	p.px(4, 1, Sprites.HOOD_L)


func _draw_antebrazo(p: PixelPainter) -> void:
	p.rect(2, 1, 3, 5, Sprites.HOOD)
	p.rect(2, 1, 1, 5, Sprites.HOOD_D)
	p.rect(2, 6, 3, 2, Sprites.SKIN)
	p.px(2, 7, Sprites.SKIN_D)


func _draw_muslo(p: PixelPainter) -> void:
	p.rect(2, 1, 3, 7, Sprites.PANTS)
	p.rect(2, 1, 1, 7, Sprites.PANTS.darkened(0.25))


func _draw_pierna(p: PixelPainter) -> void:
	p.rect(2, 1, 3, 6, Sprites.PANTS)
	p.rect(2, 1, 1, 6, Sprites.PANTS.darkened(0.25))
	p.rect(2, 7, 6, 2, Sprites.SHOE)
	p.px(6, 7, Sprites.MET)


func _draw_bufanda(p: PixelPainter) -> void:
	p.rect(1, 1, 9, 3, Sprites.CYAN_M)
	p.rect(2, 1, 6, 1, Sprites.CYAN)


func _draw_cola(p: PixelPainter) -> void:
	p.rect(1, 1, 4, 2, Sprites.CYAN_M)
	p.px(2, 1, Sprites.CYAN)


# --- Plantilla a tamaño real ---

func _save_sheet() -> void:
	var x := 0
	var widths := 0
	for piece_name: String in pieces:
		widths += int(pieces[piece_name].size.x) + 2
	var sheet := PixelPainter.new(widths, 16)
	for piece_name: String in pieces:
		sheet.paste(images[piece_name], x, 0)
		x += int(pieces[piece_name].size.x) + 2
	sheet.save(PIECES_OUT)


# --- Guía ampliada: piezas con nombre y pivotes + Kai ensamblado ---

func _save_guide() -> void:
	const CELL := Vector2i(44, 28)
	const COLUMNS := 4
	const SCALE := 6
	var assembled_width := 46
	var guide := PixelPainter.new(CELL.x * COLUMNS + assembled_width, CELL.y * 2 + 4)
	guide.rect(0, 0, guide.width, guide.height, BACKGROUND)
	var i := 0
	for piece_name: String in pieces:
		var data: Dictionary = pieces[piece_name]
		var cell := Vector2i((i % COLUMNS) * CELL.x, (i / COLUMNS) * CELL.y + 2)
		var size: Vector2i = data.size
		var pivot: Vector2i = data.pivot
		var origin := cell + Vector2i((CELL.x - size.x) / 2, 16 - size.y)
		guide.paste(images[piece_name], origin.x, origin.y)
		guide.px(origin.x + pivot.x, origin.y + pivot.y, PIVOT)
		for joint: String in data.joints:
			var j: Vector2i = data.joints[joint]
			guide.px(origin.x + j.x, origin.y + j.y, JOINT)
		var label := piece_name.to_upper()
		guide.text(cell.x + (CELL.x - label.length() * 4) / 2, cell.y + 19, label, LABEL)
		i += 1
	# Kai ensamblado (los pivotes de cada pieza coinciden con las articulaciones del padre).
	var hip := Vector2i(CELL.x * COLUMNS + 22, 40)
	var torso_pivot: Vector2i = pieces.torso.pivot
	var torso_at := hip - torso_pivot
	var neck: Vector2i = torso_at + pieces.torso.joints.cuello
	var shoulder: Vector2i = torso_at + pieces.torso.joints.hombro
	_place(guide, "brazo", shoulder + Vector2i(-1, 0), BACK_TINT)
	_place(guide, "antebrazo", shoulder + Vector2i(-1, 5), BACK_TINT)
	_place(guide, "muslo", hip + Vector2i(-1, 0), BACK_TINT)
	_place(guide, "pierna", hip + Vector2i(-1, 5), BACK_TINT)
	_place(guide, "muslo", hip + Vector2i(1, 0))
	_place(guide, "pierna", hip + Vector2i(1, 5))
	_place(guide, "cola", neck + Vector2i(-3, 2))
	_place(guide, "torso", hip)
	_place(guide, "bufanda", neck + Vector2i(0, 1))
	_place(guide, "cabeza", neck)
	_place(guide, "brazo", shoulder)
	_place(guide, "antebrazo", shoulder + Vector2i(0, 5))
	guide.text(CELL.x * COLUMNS + 3, CELL.y * 2 - 2, "ENSAMBLADO", LABEL)
	guide.image.resize(guide.width * SCALE, guide.height * SCALE, Image.INTERPOLATE_NEAREST)
	guide.save(GUIDE_OUT)


## Pega una pieza haciendo coincidir su pivote con `at`.
func _place(guide: PixelPainter, piece_name: String, at: Vector2i, tint := Color.WHITE) -> void:
	var source: PixelPainter = images[piece_name]
	var piece := source
	if tint != Color.WHITE:
		piece = PixelPainter.new(source.width, source.height)
		piece.image = source.image.duplicate()
		for y in piece.height:
			for x in piece.width:
				var c := piece.image.get_pixel(x, y)
				if c.a > 0.0:
					piece.image.set_pixel(x, y, Color(c.r * tint.r, c.g * tint.g, c.b * tint.b, c.a))
	var pivot: Vector2i = pieces[piece_name].pivot
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
