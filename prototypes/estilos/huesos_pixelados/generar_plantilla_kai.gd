extends SceneTree
## Genera la plantilla de Kai por piezas (técnica de huesos pixelados) y las imágenes de la guía de arte.
## Diseño: Kai de Ariel según su hoja de sprites (pelo blanco-lavanda medio largo, chaqueta blanca
## con capucha abierta sobre camiseta negra, guantes, pantalón holgado, zapatillas; ~44 px).
## Ejecutar: godot --headless --path . --script res://prototypes/estilos/huesos_pixelados/generar_plantilla_kai.gd
##
## Salidas:
##   assets/art/characters/kai/kai_piezas.png   → plantilla editable a tamaño real (redibújala encima)
##   assets/art/characters/kai/aegis.png        → acompañante flotante (no va en el esqueleto)
##   docs/arte/img/kai_piezas_guia.png          → piezas ampliadas con nombre, pivotes y ensamblado
##   docs/arte/img/paleta.png                   → paleta ampliada con códigos hexadecimales
##   assets/art/paleta.png / paleta.gpl         → paleta para programas de dibujo

const Sprites := preload("res://tools/art/generar_sprites.gd")

const PIECES_OUT := "res://assets/art/characters/kai/kai_piezas.png"
const AEGIS_OUT := "res://assets/art/characters/kai/aegis.png"
const GUIDE_OUT := "res://docs/arte/img/kai_piezas_guia.png"
const PALETTE_OUT := "res://docs/arte/img/paleta.png"

const PIVOT := Color("ff2a2a")
const JOINT := Color("ffe14d")
const BACKGROUND := Color("1b2033")
const LABEL := Color("c9d3ee")
const BACK_TINT := Color(0.72, 0.72, 0.82)  # Las extremidades de atrás reutilizan la pieza, más oscura.
## El Aegis flota junto a Kai: no lleva huesos, se anima por cuadros.
const AEGIS_SIZE := Vector2i(16, 16)

## Medidas de las piezas (compartidas con el esqueleto): ver characters/player/kai/kai_piezas.gd.
var pieces := KaiPiezas.PIECES

## Letras de los mapas de píxeles → colores de la paleta ("." = transparente).
var ink := {
	"o": Sprites.O, "W": Sprites.PLATA_L, "H": Sprites.PLATA, "D": Sprites.PLATA_D, "V": Sprites.VIOLETA_D,
	"S": Sprites.SKIN, "s": Sprites.SKIN_D, "E": Sprites.VIOLETA, "e": Sprites.VIOLETA_D,
	"C": Sprites.TELA, "c": Sprites.N3, "U": Sprites.VIOLETA, "B": Sprites.AZUL_E, "A": Sprites.AZUL_L,
}

## Piezas dibujadas píxel a píxel, mirando a la derecha. El contorno exterior se agrega solo.
const MAPS := {
	# Pelo voluminoso en puntas, flequillo sobre los ojos y ojo grande violeta.
	"cabeza": [
		"................",
		"......W..W......",
		"...W..WH.HW..W..",
		"...HWWHHWHHW.HH.",
		"..HHHWHHHHHWWHH.",
		".DHHHHHHHHHHHHH.",
		".DHHHHHHHHWHHHH.",
		".DHHHHHHHHHHHHH.",
		".DDHHHHHHSHHSHH.",
		".VDHHHHSSSooooH.",
		".VDDHHHSSSEEWoH.",
		".VDDHHSSSSeEESS.",
		"..VDDHSSSSSSSsS.",
		"..VDDHsSSSSSS...",
		"...VDHssSSS.....",
		"......sss.......",
	],
	# Melena de atrás: cae por la nuca hasta los hombros (medio larga).
	"pelo_atras": [
		"..........",
		"..DHHHHH..",
		".DDHHHHH..",
		".VDHHHHH..",
		".VDDHHHH..",
		"..VDHHH...",
		"..VDDH....",
		"...VD.....",
		"...V......",
		"..........",
	],
	"mechon_frente": [
		".....",
		".HW..",
		".HH..",
		"..H..",
		"..H..",
		"..D..",
		".....",
	],
	"mechon_atras": [
		"......",
		".WH...",
		"..HH..",
		"...HH.",
		"......",
	],
	# Chaqueta blanca con capucha, abierta sobre la camiseta negra con emblema violeta.
	"torso": [
		"................",
		"......CCCC......",
		"...HHHCCCCC.....",
		"..HWHHCcUCCW....",
		"..HHWWWWWCCWW...",
		"..DHWWWWWCBCWW..",
		"..DHWWWWWCCCWW..",
		"..DHWWWWWCUCWW..",
		"..DHWWWHWCCCWW..",
		"..DHWWWWWCCCWW..",
		"..DHWWWWWCCCWW..",
		"..DDHWWWWCCCW...",
		"..DDHWWWWCCCW...",
		"..DDHHHHHCCCH...",
		"...DDHHHHCCCH...",
		"....CCCCCCCC....",
		"................",
	],
	# Faldón trasero de la chaqueta (se balancea).
	"faldon": [
		"............",
		".DHHHHHH....",
		".DHHHHHH....",
		".DDHHHHH....",
		"..DDHHH.....",
		"...DD.......",
		"............",
	],
	"mochila": [
		"...........",
		"...CCCCC...",
		"..CCCCCCC..",
		".cCCCCCCCc.",
		".cCCCCCCCc.",
		".cCCCACCCc.",
		".cCCUCUCCc.",
		".cCCCACCCc.",
		".cCCCCCCCc.",
		".cCCCCCCCc.",
		"..cCCCCCc..",
		"...ccccc...",
		"...........",
	],
	# Manga abullonada.
	"brazo": [
		".........",
		"..HWWW...",
		".HWWWWW..",
		".HWWWWW..",
		".DHWWWW..",
		".DHWWWW..",
		".DHWWWH..",
		"..DHWWH..",
		"..DHHHD..",
		"..DDHHD..",
		"...DD....",
		".........",
	],
	# Puño de la manga y guante negro sin dedos.
	"antebrazo": [
		"........",
		".DHWW...",
		".DHWW...",
		".DHHW...",
		".CCCC...",
		".CcBC...",
		".CCCC...",
		".SCCS...",
		"..SS....",
		"........",
	],
	# Pantalón holgado con correa violeta.
	"muslo": [
		".........",
		".CCCCC...",
		".CCCCcc..",
		".CCCCcc..",
		".CCUCCc..",
		".CcCCCc..",
		".CCCCCc..",
		".CCCCcc..",
		".CCCCcc..",
		"..CCCc...",
		"..CCCC...",
		".........",
	],
	# Pantalón y zapatilla gruesa con suela blanca.
	"pierna": [
		"............",
		"..CCCc......",
		"..CCCc......",
		"..CCCc......",
		"..CCCc......",
		"..CCCc......",
		"..cCCC......",
		"..cCCC......",
		".CCUCCC.....",
		".CCCCBCC....",
		".CCCCCCCC...",
		".WWWWWWWW...",
		"............",
	],
	# Nullblade (primer nivel): hoja violeta con núcleo luminoso.
	"arma": [
		".........",
		"....A....",
		"...UAU...",
		"...UAU...",
		"...UAU...",
		"...UAU...",
		"...UAU...",
		"...UAU...",
		"...UAU...",
		"...UAU...",
		"...UAU...",
		"...UAU...",
		"...UAU...",
		"...UAU...",
		"...UAU...",
		"...UAU...",
		".VVVVVVV.",
		"..VUBUV..",
		"...CCC...",
		"...CcC...",
		"...CCC...",
		"...CCC...",
		"....U....",
		".........",
	],
}

var images := {}
var aegis: PixelPainter


func _initialize() -> void:
	for piece_name: String in pieces:
		var size: Vector2i = pieces[piece_name].size
		var p := PixelPainter.new(size.x, size.y)
		_paint_map(p, piece_name)
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


## Pinta el mapa de una pieza y avisa si no coincide con su tamaño.
func _paint_map(p: PixelPainter, piece_name: String) -> void:
	var rows: Array = MAPS[piece_name]
	var size: Vector2i = pieces[piece_name].size
	if rows.size() != size.y:
		push_error("%s: el mapa tiene %d filas y la pieza mide %d" % [piece_name, rows.size(), size.y])
	for y in rows.size():
		var row: String = rows[y]
		if row.length() != size.x:
			push_error("%s, fila %d: %d columnas en vez de %d" % [piece_name, y, row.length(), size.x])
		for x in row.length():
			if ink.has(row[x]):
				p.px(x, y, ink[row[x]])


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
		width += size.x + KaiPiezas.GAP
		height = maxi(height, size.y)
	var sheet := PixelPainter.new(width, height)
	for piece_name: String in pieces:
		var region := KaiPiezas.region(piece_name)
		sheet.paste(images[piece_name], region.position.x, 0)
	sheet.save(PIECES_OUT)


# --- Guía ampliada: piezas con nombre y pivotes + Kai ensamblado ---

func _save_guide() -> void:
	const CELL := Vector2i(62, 36)
	const COLUMNS := 5
	const SCALE := 5
	const ASSEMBLED_WIDTH := 64
	var names: Array[String] = []
	names.assign(pieces.keys())
	names.append("aegis")
	var rows := ceili(names.size() / float(COLUMNS))
	var guide := PixelPainter.new(CELL.x * COLUMNS + ASSEMBLED_WIDTH, CELL.y * rows + 4)
	guide.rect(0, 0, guide.width, guide.height, BACKGROUND)
	for i in names.size():
		var piece_name := names[i]
		var cell := Vector2i((i % COLUMNS) * CELL.x, (i / COLUMNS) * CELL.y + 2)
		var painter: PixelPainter = aegis if piece_name == "aegis" else images[piece_name]
		var origin := cell + Vector2i((CELL.x - painter.width) / 2, 25 - painter.height)
		guide.paste(painter, origin.x, origin.y)
		if piece_name != "aegis":
			var pivot: Vector2i = pieces[piece_name].pivot
			guide.px(origin.x + pivot.x, origin.y + pivot.y, PIVOT)
			for joint: String in pieces[piece_name].joints:
				var j: Vector2i = pieces[piece_name].joints[joint]
				guide.px(origin.x + j.x, origin.y + j.y, JOINT)
		var label := piece_name.to_upper().replace("_", " ")
		guide.text(cell.x + (CELL.x - label.length() * 4) / 2, cell.y + 27, label, LABEL)

	# Kai ensamblado: recorre el esqueleto y pega cada pieza en la posición de su hueso.
	var feet := Vector2(CELL.x * COLUMNS + ASSEMBLED_WIDTH / 2, CELL.y * rows - 10)
	var positions := { "": feet }
	var placed: Array = []
	for entry: Dictionary in KaiPiezas.RIG:
		var pos: Vector2 = positions[entry.parent] + KaiPiezas.bone_offset(entry)
		positions[entry.bone] = pos
		if entry.has("piece") and not entry.get("weapon", false):
			placed.append([entry.get("z", 0), entry.piece, pos, entry.get("back", false)])
	placed.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for item: Array in placed:
		_place(guide, item[1], Vector2i(item[2].round()), BACK_TINT if item[3] else Color.WHITE)
	guide.text(CELL.x * COLUMNS + 12, CELL.y * rows - 4, "ENSAMBLADO", LABEL)
	guide.image.resize(guide.width * SCALE, guide.height * SCALE, Image.INTERPOLATE_NEAREST)
	guide.save(GUIDE_OUT)


## Pega una pieza haciendo coincidir su pivote con `at`.
func _place(guide: PixelPainter, piece_name: String, at: Vector2i, tint := Color.WHITE) -> void:
	var source: PixelPainter = images[piece_name]
	var piece := PixelPainter.new(source.width, source.height)
	piece.image = source.image.duplicate()
	if tint != Color.WHITE:
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
	gpl.store_line("Name: Nullveil")
	gpl.store_line("Columns: 8")
	gpl.store_line("#")
	for c in colors:
		gpl.store_line("%3d %3d %3d\t%s" % [c.r8, c.g8, c.b8, c.to_html(false).to_upper()])
	gpl.close()
