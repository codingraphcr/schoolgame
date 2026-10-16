extends SceneTree
## Fondos en el pixel art del juego (el estilo de assets/art/pixel: colores planos de la paleta, contorno oscuro de
## 1 px, un punto del dibujo = un punto del mundo), con lo que muestran las imágenes de Ariel de cada cuarto:
##   - pasillo_segundo.png: las salas 7, 8 y 9 (docs/arte/referencias/pasillo_segundo_fondo.webp).
##   - taller.png: el taller de robótica con sus tres estaciones (taller_fondo.webp).
##   - cuarto_viejo.png: el laboratorio viejo del club de ciencias (cuarto_viejo_fondo_vacio.webp).
## Y los objetos del taller que se mueven con sus anomalías (assets/art/props/taller/: robot, brazo y la puerta de
## la bodega) y los obstáculos del cuarto viejo (assets/art/props/cuarto_viejo/: el armario caído y el piso
## corrupto, como los de Ariel), al doble (se dibujan a la mitad).
## Reusa los sprites que ya existen (casilleros, puertas, ventanas, diarios murales, reloj y lámparas).
## Ejecutar: godot --headless --path . --script res://tools/art/pintar_fondos.gd

const S := preload("res://tools/art/generar_sprites.gd")
const OUT := "res://assets/art/backgrounds/"
const PROPS := "res://assets/art/props/taller/"
const PIXEL := "res://assets/art/pixel/"
const H := 400
const FLOOR := 304
## Colores que la paleta no tiene (plantas, pizarrón, franja de seguridad).
const LEAF_D := Color("1d4d33")
const LEAF := Color("2f7a4a")
const LEAF_L := Color("4fae6a")
const BOARD_D := Color("17302f")
const BOARD := Color("1f3d3b")
const YELLOW := Color("f2c14e")
## La soda y el patio (colores cálidos: crema, azulejos, madera, la fachada y el pasto).
const CREAM := Color("c9ad7c")
const CREAM_D := Color("a88f62")
const TILE := Color("d6d0c2")
const TILE_D := Color("ada594")
const FACADE := Color("bfae8c")
const FACADE_D := Color("8f8064")
const CONCRETE := Color("9a968c")
const CONCRETE_D := Color("6e6a62")
const RED_SIGN := Color("a8243a")
const CR_BLUE := Color("1f3f9f")
const BOOKS: Array[Color] =[Color("a8384a"), Color("2f7383"), Color("4a5f96"), Color("b8ab8c"), Color("ffb347"), Color("7b4fe0"), Color("4fa3ac")]

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	rng.seed = 11
	_taller_props()
	_cuarto_viejo_props()
	_pasillo()
	_taller()
	_cuarto_viejo()
	_soda()
	_patio()
	quit()


## La soda (comedor): pared crema con azulejos abajo, la puerta del comedor, la pizarra del menú (donde está el
## objeto Menú), mesas con bancos, la repisa con la radio, el mostrador con la vitrina, la refri, ventanas, una
## planta y la puerta al patio (derecha) con su cartel.
func _soda() -> void:
	var w := 640
	var p := PixelPainter.new(w, H)
	p.rect(0, 0, w, FLOOR, CREAM)
	for i in w / 4:
		p.px(rng.randi_range(0, w - 1), rng.randi_range(40, 230), CREAM_D)
	# Azulejos hasta media pared.
	p.rect(0, 232, w, FLOOR - 232, TILE)
	for y in range(236, FLOOR, 8):
		p.rect(0, y, w, 1, TILE_D)
	for x in range(0, w, 8):
		p.rect(x, 232, 1, FLOOR - 232, TILE_D)
	p.rect(0, 230, w, 2, CREAM_D)
	p.rect(0, 232, w, 1, S.O)
	_ceiling(p, w, false)
	for x in [140, 330, 560]:
		_hanging_lamp(p, x)
	for x in [240, 450]:
		_fan(p, x)
	_wood_door(p, 30, "COMEDOR")
	_menu_board(p, 135, 146)
	_table_benches(p, 110)
	_shelf_radio(p, 250, 176)
	_counter(p, 200, 220)
	_fridge(p, 498)
	_day_window(p, 516, 150)
	_plant(p, 444)
	_table_benches(p, 556)
	_wood_door(p, 612, "PATIO")
	_floor_warm(p, w)
	_save(p, OUT + "soda.png")


## El patio: la fachada del colegio (dos pisos de ventanas) con el cielo transparente (lo pinta el patio según la
## hora), la puerta de la soda a la izquierda, el almendro, bancas y jardineras, el mural de ciberseguridad (donde
## está el objeto Mural), el bebedero, el asta con la bandera, el techito del tablón (el tablón lo dibuja el juego)
## y la entrada con escaleras a la derecha, con faroles.
func _patio() -> void:
	var w := 1500
	var p := PixelPainter.new(w, H)
	# La soda: un edificio bajo a la izquierda.
	_facade(p, 0, 92, 196)
	_wood_door(p, 40, "SODA", RED_SIGN)
	# El colegio: dos pisos.
	_facade(p, 92, 1340, 56)
	for x in range(130, 1300, 92):
		if x > 540 and x < 830:
			continue
		_school_window(p, x, 78)
		if not (x > 1180 and x < 1340):
			_school_window(p, x, 168)
	_mural(p, 690, 160)
	# La entrada: un bloque bajo con el portón y las escaleras.
	_facade(p, 1340, w, 196)
	_entrance(p, 1400)
	_street_lamp(p, 1356)
	_street_lamp(p, 1446)
	# Árboles, jardineras, bancas, el bebedero, la bandera y el techito del tablón.
	_tree(p, 315, 70)
	_tree(p, 1490, 52)
	for x in [10, 150, 420, 860, 960, 1300, 1462]:
		_planter(p, x, 46)
	_bench(p, 200, 60)
	_bench(p, 470, 60)
	_bench(p, 900, 60)
	_fountain(p, 1051)
	_flag(p, 1150)
	_kiosk(p, 1265)
	_trash(p, 1328)
	_ground(p, w)
	_save(p, OUT + "patio.png")


# --- Cuartos ---

func _pasillo() -> void:
	var w := 1900
	var p := PixelPainter.new(w, H)
	_wall_panels(p, w, S.N2, S.N1, S.N3)
	_wainscot(p, w, 262)
	_ceiling(p, w, false)
	for x in [160, 520, 900, 1260, 1640]:
		_lamp(p, x, 30, 54)
	for x in [760, 1580]:
		_vent(p, x, 66)
	for x in [300, 640, 1110, 1430, 1700]:
		_pipe_down(p, x, 56, 140)
	# Ventanas, bancas, plantas, casilleros, puertas y lo de la pared (como en la imagen de Ariel).
	_window2(p, 46, 150)
	_bench(p, 40, 92)
	_plant(p, 140)
	_lockers(p, 162, 4)
	_door(p, 420, "SALA 7")
	_switch(p, 446, 236)
	_trash(p, 456)
	_banner(p, 480, 164)
	_paste(p, "board.png", 530, 190)
	_bench(p, 482, 90)
	_bookshelf(p, 598, 38, 64)
	_lockers(p, 660, 4)
	_papers(p, 740, 220)
	_door(p, 980, "SALA 8")
	_extinguisher(p, 1008)
	_paste(p, "board.png", 1024, 194)
	_bench(p, 1030, 84)
	_lockers(p, 1130, 4)
	_window2(p, 1260, 150)
	_plant(p, 1350)
	_papers(p, 1440, 226)
	_door(p, 1500, "SALA 9")
	_switch(p, 1526, 236)
	_lockers(p, 1534, 4)
	_trash(p, 1606)
	_bookshelf(p, 1632, 38, 64)
	_window2(p, 1710, 150)
	_bench(p, 1712, 92)
	_plant(p, 1830)
	_floor(p, w, false)
	_save(p, OUT + "pasillo_segundo.png")


func _taller() -> void:
	var w := 1120
	var p := PixelPainter.new(w, H)
	_wall_bricks(p, w)
	_ceiling(p, w, true)
	for x in [210, 470, 870]:
		_tube_lamp(p, x, 52)
	_vent(p, 40, 64)
	_vent(p, 756, 58)
	_pipe_down(p, 100, 44, 230)
	_pipe_down(p, 1006, 44, 200)
	# La puerta al laboratorio (como un ascensor), el estandarte y los papeles.
	_elevator(p, 61)
	_electric_box(p, 14, 230)
	_banner(p, 120, 150)
	_papers(p, 108, 222)
	# CONDICIONALES: estantes arriba y su mesa.
	_wall_shelves(p, 360, 120, 150)
	_station(p, 420, 0)
	# CICLOS: el tablero de herramientas arriba.
	_pegboard(p, 590, 116, 130, 84)
	_station(p, 660, 1)
	# La terminal del taller (la anomalía del mensaje escribe en su pantalla).
	_terminal(p, 753)
	# FUNCIONES: estantes arriba.
	_wall_shelves(p, 780, 120, 150)
	_station(p, 837, 2)
	_blueprint(p, 908, 128)
	_paste(p, "clock.png", 1040, 104)
	_warning_box(p, 1090, 100)
	_bodega(p, 990)
	_metal_shelf(p, 1030, 168)
	_floor(p, w, true)
	_save(p, OUT + "taller.png")


func _cuarto_viejo() -> void:
	var w := 720
	var p := PixelPainter.new(w, H)
	_wall_panels(p, w, S.N1, Color("0d1328"), S.N2)
	_wainscot(p, w, 270)
	_ceiling(p, w, true)
	_tube_lamp(p, 522, 92)
	_pipe_down(p, 20, 44, 300)
	_pipe_down(p, 262, 44, 180)
	_pipe_down(p, 690, 44, 200)
	# La puerta (la salida) con su luz, una escalera y cajas.
	_old_door(p, 61)
	_ladder(p, 4)
	_box(p, 104, 14, 12, S.WOOD)
	_box(p, 108, 10, 8, S.WOOD_L, FLOOR - 12)
	_stool(p, 136)
	# La vitrina con frascos sobre su mueble, el reloj, los casilleros y la estantería.
	_glass_cabinet(p, 166, 146)
	_big_clock(p, 320, 170)
	_lockers(p, 280, 2)
	_bookshelf(p, 357, 50, 116)
	_papers(p, 292, 196)
	_papers(p, 418, 206)
	# El pizarrón, la mesa del centro (ahí está el Grimorio) y la de la derecha (ahí aparece la Nullblade).
	_chalkboard(p, 456, 152, 157, 94)
	_table(p, 330, 151, 269, true)
	_table(p, 513, 103, 257, false)
	_server_box(p, 646, 224)
	_desk(p, 604, 116, 272)
	_floor(p, w, false)
	_save(p, OUT + "cuarto_viejo.png")


## Los obstáculos del cuarto viejo (al doble), como los dibujó Ariel: el armario caído (un estante volcado con libros,
## escombros, papeles y el lado roto corrompido en magenta: su cuerpo coincide con el choque, 84 × 38) y el piso
## corrupto (baldosas rotas con grietas magenta, cuadraditos y rayos de datos: la losa mide 100).
func _cuarto_viejo_props() -> void:
	var dir := "res://assets/art/props/cuarto_viejo/"
	var cab := PixelPainter.new(110, 52)
	# El cuerpo (x 13-96, y 10-48): marco de metal, la puerta de un lado y tres huecos con libros.
	cab.polygon(PackedVector2Array([Vector2(13, 13), Vector2(96, 9), Vector2(97, 47), Vector2(14, 48)]), S.N4)
	cab.polygon(PackedVector2Array([Vector2(13, 13), Vector2(96, 9), Vector2(96, 12), Vector2(13, 16)]), S.MET)
	cab.rect(16, 18, 20, 27, S.N5)
	cab.frame(16, 18, 20, 27, S.N3)
	cab.rect(19, 22, 7, 7, S.PAPER_D)
	cab.rect(31, 30, 2, 5, S.MET_L)
	for k in 3:
		var hx := 39 + k * 19
		cab.rect(hx, 17, 17, 28, S.N1)
		cab.rect(hx, 31, 17, 2, S.N4)
		for b in 4:
			var bh := rng.randi_range(8, 12)
			cab.rect(hx + 2 + b * 4, 31 - bh, 3, bh, BOOKS[(k * 4 + b) % BOOKS.size()])
		cab.rect(hx + 2, 41, 12, 3, BOOKS[(k + 3) % BOOKS.size()])
		cab.rect(hx + 3, 38, 8, 3, BOOKS[(k + 5) % BOOKS.size()])
	cab.rect(58, 36, 8, 6, S.WOOD_L)
	# Escombros, unas piezas encima y papeles en el piso.
	for chunk in [Rect2i(2, 40, 9, 8), Rect2i(6, 34, 6, 6), Rect2i(0, 46, 6, 5), Rect2i(98, 40, 8, 9), Rect2i(103, 46, 6, 5),
			Rect2i(26, 5, 10, 6), Rect2i(70, 3, 7, 6)]:
		cab.rect(chunk.position.x, chunk.position.y, chunk.size.x, chunk.size.y, S.N4)
		cab.rect(chunk.position.x, chunk.position.y, chunk.size.x, 1, S.N5)
	cab.outline(S.O)
	for paper in [Vector2i(26, 48), Vector2i(44, 49), Vector2i(60, 48)]:
		cab.rect(paper.x, paper.y, 9, 3, S.PAPER)
		cab.rect(paper.x, paper.y + 2, 9, 1, S.PAPER_D)
	# El lado roto, corrompido: píxeles magenta y cuadraditos que se desprenden.
	for i in 110:
		var gx := rng.randi_range(86, 102)
		var gy := rng.randi_range(9, 50)
		cab.px(gx, gy, [S.MAG, S.MAG, Color("ff9ad5"), S.MAG_D][rng.randi_range(0, 3)])
	for sq in [Vector2i(102, 14), Vector2i(105, 24), Vector2i(101, 32)]:
		cab.frame(sq.x, sq.y, 4, 4, S.MAG)
	_save2(cab, dir + "armario_caido.png")
	var floor := PixelPainter.new(106, 31)
	# La losa (x 3-103, y 19-30): baldosas oscuras rotas con grietas que brillan.
	floor.rect(3, 19, 100, 11, S.N2)
	floor.rect(3, 19, 100, 1, S.N4)
	for x in range(3, 103, 16):
		floor.rect(x, 20, 1, 10, S.N1)
	floor.rect(3, 25, 100, 1, S.N1)
	floor.outline(S.O)
	for crack in 9:
		var x := rng.randi_range(6, 96)
		var y := 20
		while y < 30:
			floor.px(x, y, Color("ff9ad5") if y < 24 else S.MAG)
			floor.px(x + 1, y, S.MAG_D)
			x += rng.randi_range(-1, 1)
			y += 1
	for i in 40:
		floor.px(rng.randi_range(4, 102), rng.randi_range(19, 29), S.MAG_D)
	floor.rect(3, 19, 100, 1, S.MAG)
	for i in 30:
		floor.px(rng.randi_range(4, 102), 18, Color(S.MAG, 0.6))
	# Rayos de datos y cuadraditos que suben.
	for i in 12:
		var x := rng.randi_range(5, 100)
		var top := rng.randi_range(2, 14)
		floor.rect(x, top, 1, 19 - top, S.MAG_D)
		floor.px(x, top, S.MAG)
	for i in 9:
		var x := rng.randi_range(4, 98)
		var y := rng.randi_range(2, 14)
		floor.frame(x, y, 4, 4, S.MAG)
	_save2(floor, dir + "piso_corrupto.png")


## Lo que se mueve con las anomalías del taller (al doble): el robot con la caja, el brazo y la puerta de la bodega.
func _taller_props() -> void:
	var robot := PixelPainter.new(26, 26)
	robot.rect(2, 12, 22, 10, S.MET)
	robot.rect(2, 12, 22, 2, S.MET_L)
	robot.rect(4, 15, 4, 3, S.CYAN)
	robot.ellipse(7, 22, 3.5, 3.5, S.N1)
	robot.ellipse(19, 22, 3.5, 3.5, S.N1)
	robot.rect(7, 2, 12, 10, S.WOOD_L)
	robot.rect(7, 2, 12, 2, YELLOW)
	robot.rect(12, 2, 2, 10, S.WOOD)
	robot.outline(S.O)
	_save2(robot, PROPS + "robot.png")
	var arm := PixelPainter.new(40, 32)
	arm.rect(4, 26, 16, 6, S.MET_D)
	arm.rect(8, 22, 8, 4, S.MET)
	arm.line(12, 22, 26, 10, S.MET_L, 3)
	arm.line(26, 10, 34, 14, S.MET_L, 3)
	arm.ellipse(26, 10, 2.5, 2.5, S.MET_D)
	arm.ellipse(35, 15, 3, 3, YELLOW)
	arm.outline(S.O)
	_save2(arm, PROPS + "brazo.png")
	var door := PixelPainter.new(46, 88)
	door.rect(0, 0, 46, 88, S.N4)
	door.rect(2, 2, 42, 86, S.N3)
	door.rect(4, 4, 38, 38, S.N4)
	door.rect(4, 46, 38, 38, S.N4)
	door.rect(30, 14, 6, 18, S.N1)
	door.rect(31, 15, 4, 16, S.CYAN_D)
	door.rect(34, 52, 4, 8, S.MET_L)
	door.frame(0, 0, 46, 88, S.O)
	_save2(door, PROPS + "puerta_bodega.png")


# --- Pared, techo y piso ---

## Pared de paneles: color base, junta oscura cada 64 px con su borde claro y motas.
func _wall_panels(p: PixelPainter, w: int, base: Color, dark: Color, light: Color) -> void:
	p.rect(0, 0, w, FLOOR, base)
	for x in range(0, w, 64):
		p.rect(x, 0, 1, FLOOR, dark)
		p.rect(x + 1, 0, 1, FLOOR, light)
	for i in w / 6:
		p.px(rng.randi_range(0, w - 1), rng.randi_range(48, FLOOR - 1), light if i % 3 == 0 else dark)


## Pared de bloques (el taller).
func _wall_bricks(p: PixelPainter, w: int) -> void:
	p.rect(0, 0, w, FLOOR, S.N2)
	for row in range(44, FLOOR, 10):
		p.rect(0, row, w, 1, S.N1)
		var shift := 0 if (row / 10) % 2 == 0 else 12
		for x in range(shift, w, 24):
			p.rect(x, row, 1, 10, S.N1)
			if rng.randf() < 0.3:
				p.rect(x + 2, row + 2, rng.randi_range(4, 12), 1, S.N3)


## Zócalo alto: la parte de abajo de la pared, más oscura, con su borde.
func _wainscot(p: PixelPainter, w: int, top: int) -> void:
	p.rect(0, top, w, FLOOR - top, S.N1)
	p.rect(0, top, w, 2, S.N3)
	p.rect(0, top + 2, w, 1, S.O)
	for x in range(0, w, 32):
		p.rect(x, top + 3, 1, FLOOR - top - 3, Color("0d1328"))


## El techo: una viga con un caño a lo largo (y cables colgando, si cables).
func _ceiling(p: PixelPainter, w: int, cables: bool) -> void:
	p.rect(0, 0, w, 40, S.N1)
	p.rect(0, 40, w, 4, S.MET_D)
	p.rect(0, 40, w, 1, S.MET)
	p.rect(0, 44, w, 1, S.O)
	p.rect(0, 30, w, 3, S.MET_D)
	p.rect(0, 30, w, 1, S.MET)
	for x in range(40, w, 96):
		p.rect(x, 28, 3, 7, S.MET)
	if cables:
		for k in w / 70:
			var x0 := rng.randi_range(0, w - 60)
			var x1 := x0 + rng.randi_range(30, 80)
			var sag := rng.randi_range(6, 18)
			for x in range(x0, x1):
				var t := float(x - x0) / (x1 - x0)
				p.px(x, 34 + int(sin(t * PI) * sag), S.O)


## El piso: la cara de arriba con su borde (como las baldosas del juego) y el relleno de abajo (con franja de
## seguridad amarilla y negra en el taller).
func _floor(p: PixelPainter, w: int, hazard: bool) -> void:
	p.rect(0, FLOOR - 4, w, 4, S.N1)
	p.rect(0, FLOOR - 4, w, 1, S.O)
	p.rect(0, FLOOR, w, 1, S.N5)
	p.rect(0, FLOOR + 1, w, 3, S.N4)
	p.rect(0, FLOOR + 2, w, 1, S.CYAN_D)
	p.rect(0, FLOOR + 4, w, 1, S.O)
	p.rect(0, FLOOR + 5, w, H - FLOOR - 5, S.N2)
	for x in range(0, w, 32):
		p.rect(x, FLOOR + 5, 1, 12, S.N1)
	p.rect(0, FLOOR + 17, w, 1, S.N1)
	p.rect(0, FLOOR + 18, w, H - FLOOR - 18, S.N1)
	if hazard:
		for x in range(0, w, 20):
			p.rect(x, FLOOR + 1, 10, 3, YELLOW)


# --- Objetos ---

func _paste(p: PixelPainter, file: String, x: int, y: int) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(PIXEL + file))
	image.convert(Image.FORMAT_RGBA8)
	p.image.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(x, y))


## Pinta un objeto en su propio lienzo, le pone el contorno y lo pega.
func _sprite(p: PixelPainter, x: int, y: int, w: int, h: int, painter: Callable) -> void:
	var s := PixelPainter.new(w + 2, h + 2)
	painter.call(s)
	s.outline(S.O)
	p.paste(s, x - 1, y - 1)


func _lamp(p: PixelPainter, x: int, width: int, y: int) -> void:
	_light_cone(p, x, y + 6, y + 120, width / 2, width / 2 + 34)
	p.rect(x - 1, 44, 2, y - 44, S.O)
	_sprite(p, x - width / 2, y, width, 6, func(s: PixelPainter) -> void:
		s.rect(1, 1, width, 3, S.MET_D)
		s.rect(2, 4, width - 2, 2, Color("d8e4ff"))
		s.rect(2, 5, width - 2, 1, Color("8fb4ff")))


## La lámpara de tubo larga del taller y del cuarto viejo.
func _tube_lamp(p: PixelPainter, x: int, y: int) -> void:
	_lamp(p, x, 64, y)


## Luz de una lámpara sobre la pared: un trapecio de puntos más claros (en damero, como el pixel art).
func _light_cone(p: PixelPainter, x: int, top: int, bottom: int, half_top: int, half_bottom: int) -> void:
	for y in range(top, bottom):
		var t := float(y - top) / (bottom - top)
		var half := int(lerpf(half_top, half_bottom, t))
		for xx in range(x - half, x + half):
			var fade := 1.0 - t
			if (xx + y) % 2 == 0 and (xx * 7 + y * 3) % 5 < int(fade * 4.0):
				var c := p.get_px(xx, y)
				p.px(xx, y, c.lightened(0.12))


func _vent(p: PixelPainter, x: int, y: int) -> void:
	_sprite(p, x, y, 20, 12, func(s: PixelPainter) -> void:
		s.rect(1, 1, 20, 12, S.MET_D)
		for k in 4:
			s.rect(3, 3 + k * 2, 16, 1, S.O))


func _pipe_down(p: PixelPainter, x: int, top: int, bottom: int) -> void:
	p.rect(x, top, 3, bottom - top, S.MET_D)
	p.rect(x, top, 1, bottom - top, S.MET)
	p.rect(x + 3, top, 1, bottom - top, S.O)
	p.rect(x - 2, bottom - 6, 7, 6, S.MET_D)
	p.frame(x - 2, bottom - 6, 7, 6, S.O)


func _switch(p: PixelPainter, x: int, y: int) -> void:
	p.rect(x, y, 5, 7, S.MET)
	p.frame(x, y, 5, 7, S.O)
	p.px(x + 2, y + 3, S.O)


func _electric_box(p: PixelPainter, x: int, y: int) -> void:
	p.rect(x, y, 12, 18, S.N4)
	p.frame(x, y, 12, 18, S.O)
	p.rect(x + 3, y + 4, 6, 3, S.CYAN_D)
	p.rect(x + 3, y + 10, 6, 1, S.MET)


## Ventana grande de cuatro vidrios (de noche: estrellas y luces de la ciudad), como las de la imagen de Ariel.
func _window2(p: PixelPainter, x: int, y: int) -> void:
	_sprite(p, x, y, 84, 56, func(s: PixelPainter) -> void:
		s.rect(1, 1, 84, 56, S.MET_D)
		for k in 2:
			var gx := 4 + k * 41
			s.rect(gx, 4, 37, 50, S.N1)
			s.rect(gx, 4, 37, 2, S.N2)
			# La ciudad de noche: edificios con ventanas encendidas y estrellas.
			var bx := gx
			while bx < gx + 37:
				var bw := rng.randi_range(5, 9)
				var bh := rng.randi_range(10, 24)
				s.rect(bx, 54 - bh, mini(bw, gx + 37 - bx), bh, S.N2)
				for ly in range(54 - bh + 3, 52, 4):
					if rng.randf() < 0.4:
						s.px(bx + rng.randi_range(1, maxi(bw - 2, 1)), ly, S.LED_A)
				bx += bw + 1
			for star in 5:
				s.px(gx + rng.randi_range(1, 35), rng.randi_range(7, 26), S.PAPER)
			s.rect(gx + 18, 4, 1, 50, S.MET_D)
			s.rect(gx, 28, 37, 1, S.MET_D)
		s.rect(1, 1, 84, 1, S.MET)
		s.rect(1, 56, 84, 2, S.MET_L))


func _lockers(p: PixelPainter, x: int, count: int) -> void:
	for k in count / 2:
		_paste(p, "lockers.png", x + k * 32, FLOOR - 40)
	# Cajas y libros encima.
	_box(p, x + 4, 10, 6, S.WOOD, FLOOR - 40)
	_box(p, x + 16, 8, 4, S.RED, FLOOR - 40)


func _door(p: PixelPainter, x: int, label: String) -> void:
	p.rect(x - 16, FLOOR - 52, 32, 52, S.MET_D)
	p.frame(x - 16, FLOOR - 52, 32, 52, S.O)
	_paste(p, "door.png", x - 14, FLOOR - 48)
	var sign_w := label.length() * 4 + 7
	var sx := x - sign_w / 2
	p.rect(sx, FLOOR - 68, sign_w, 11, S.TEAL_D)
	p.frame(sx, FLOOR - 68, sign_w, 11, S.CYAN_M)
	p.text(sx + 4, FLOOR - 65, label, S.CYAN)


func _bench(p: PixelPainter, x: int, w: int) -> void:
	_sprite(p, x, FLOOR - 16, w, 16, func(s: PixelPainter) -> void:
		s.rect(1, 1, w, 4, S.WOOD)
		s.rect(1, 1, w, 1, S.WOOD_L)
		s.rect(1, 5, w, 1, S.WOOD_D)
		for leg in [4, w - 5]:
			s.rect(leg, 6, 2, 10, S.MET_D))


func _plant(p: PixelPainter, x: int) -> void:
	_sprite(p, x - 10, FLOOR - 38, 20, 38, func(s: PixelPainter) -> void:
		s.rect(5, 28, 11, 11, S.MET_L)
		s.rect(5, 28, 11, 2, S.PAPER)
		for k in 7:
			var angle := -PI * 0.5 + (k - 3) * 0.42
			var tip := Vector2(10.5, 28) + Vector2.from_angle(angle) * 24.0
			s.line(10, 28, int(tip.x), int(tip.y), LEAF_D, 2)
			s.line(10, 27, int(tip.x), int(tip.y) + 1, LEAF if k % 2 == 0 else LEAF_L, 1))


func _bookshelf(p: PixelPainter, x: int, w: int, h: int) -> void:
	_sprite(p, x, FLOOR - h, w, h, func(s: PixelPainter) -> void:
		s.rect(1, 1, w, h, S.WOOD_D)
		s.rect(3, 3, w - 4, h - 4, Color("2a1a12"))
		var rows := maxi(int(h / 16.0), 2)
		var row_h := (h - 4) / rows
		for r in rows:
			var shelf_y := 3 + (r + 1) * row_h - 2
			s.rect(2, shelf_y, w - 2, 2, S.WOOD)
			var bx := 4
			while bx < w - 4:
				var bw := rng.randi_range(2, 4)
				var bh := rng.randi_range(row_h - 6, row_h - 3)
				s.rect(bx, shelf_y - bh, bw, bh, BOOKS[rng.randi_range(0, BOOKS.size() - 1)])
				bx += bw + 1
		s.rect(2, 1, w - 2, 1, S.WOOD_L))
	# Una planta encima.
	p.rect(x + w / 2 - 4, FLOOR - h - 5, 8, 5, LEAF)
	p.rect(x + w / 2 - 6, FLOOR - h - 3, 3, 3, LEAF_L)


func _trash(p: PixelPainter, x: int) -> void:
	_sprite(p, x, FLOOR - 16, 11, 16, func(s: PixelPainter) -> void:
		s.rect(1, 3, 11, 14, S.MET_D)
		s.rect(1, 1, 11, 2, S.MET)
		for k in 3:
			s.rect(3 + k * 3, 5, 1, 10, S.O))


func _extinguisher(p: PixelPainter, x: int) -> void:
	_sprite(p, x, FLOOR - 40, 7, 18, func(s: PixelPainter) -> void:
		s.rect(1, 4, 7, 15, S.RED)
		s.rect(2, 5, 1, 12, Color("d8566a"))
		s.rect(2, 1, 4, 3, S.O)
		s.rect(5, 2, 3, 1, S.O))


## Estandarte del Club de Ciencia (con el átomo).
func _banner(p: PixelPainter, x: int, y: int) -> void:
	p.line(x + 2, y - 4, x + 17, y - 9, S.MET, 1)
	p.line(x + 32, y - 4, x + 17, y - 9, S.MET, 1)
	_sprite(p, x, y, 34, 46, func(s: PixelPainter) -> void:
		s.polygon(PackedVector2Array([Vector2(1, 1), Vector2(35, 1), Vector2(35, 40), Vector2(18, 47), Vector2(1, 40)]), S.VIOLETA_D)
		s.rect(1, 1, 34, 2, S.VIOLETA)
		s.ellipse(18, 16, 9, 3.5, S.CYAN_D)
		s.ellipse(18, 16, 7.5, 2.2, S.VIOLETA_D)
		s.line(12, 10, 24, 22, S.CYAN_M, 1)
		s.line(24, 10, 12, 22, S.CYAN_M, 1)
		s.ellipse(18, 16, 2, 2, S.MAG)
		s.text(5, 27, "CLUB", S.PAPER)
		s.text(4, 34, "CIENCIA", S.PAPER_D))


## Papeles pegados en la pared.
func _papers(p: PixelPainter, x: int, y: int) -> void:
	for k in 2:
		var px0 := x + k * 14
		var py := y + (k % 2) * 6
		p.rect(px0, py, 11, 14, S.PAPER)
		p.rect(px0, py, 11, 1, S.PAPER_D)
		for line_y in range(py + 3, py + 13, 3):
			p.rect(px0 + 2, line_y, 7, 1, S.PAPER_D)
		p.frame(px0, py, 11, 14, S.O)


func _box(p: PixelPainter, x: int, w: int, h: int, color: Color, base := FLOOR) -> void:
	p.rect(x, base - h, w, h, color)
	p.rect(x, base - h, w, 1, color.lightened(0.2))
	p.rect(x + w / 2, base - h, 1, h, color.darkened(0.25))
	p.frame(x, base - h, w, h, S.O)


func _stool(p: PixelPainter, x: int) -> void:
	_sprite(p, x - 7, FLOOR - 18, 14, 18, func(s: PixelPainter) -> void:
		s.rect(1, 1, 14, 3, S.N4)
		s.rect(3, 4, 2, 15, S.MET_D)
		s.rect(11, 4, 2, 15, S.MET_D)
		s.rect(3, 12, 10, 1, S.MET_D))


## Una mesa de madera (con cosas encima: libros y un lapicero).
func _table(p: PixelPainter, x: int, w: int, top: int, stuff: bool) -> void:
	_sprite(p, x, top, w, FLOOR - top, func(s: PixelPainter) -> void:
		s.rect(1, 1, w, 5, S.N4)
		s.rect(1, 1, w, 1, S.N5)
		s.rect(1, 6, w, 1, S.N1)
		for leg in [4, w - 7]:
			s.rect(leg, 7, 3, FLOOR - top - 6, S.MET_D))
	if stuff:
		_box(p, x + 12, 14, 4, BOOKS[1], top)
		_box(p, x + 14, 12, 3, BOOKS[0], top - 4)
		_box(p, x + w - 30, 6, 7, S.MET, top)


## La mesa de una estación del taller: mesa de madera, banquitos, el cartel (sin texto: lo escribe la estación) y
## la vitrina con su máquina (0 clasificador, 1 cinta, 2 asistente).
func _station(p: PixelPainter, cx: int, kind: int) -> void:
	_stool(p, cx - 60)
	_stool(p, cx + 56)
	_sprite(p, cx - 73, FLOOR - 36, 146, 36, func(s: PixelPainter) -> void:
		s.rect(1, 1, 146, 5, S.WOOD)
		s.rect(1, 1, 146, 1, S.WOOD_L)
		s.rect(1, 6, 146, 1, S.WOOD_D)
		for leg in [6, 72, 139]:
			s.rect(leg, 7, 3, 30, S.WOOD_D))
	# Cartel.
	p.rect(cx - 41, FLOOR - 80, 82, 13, S.N1)
	p.frame(cx - 41, FLOOR - 80, 82, 13, S.MET)
	p.frame(cx - 42, FLOOR - 81, 84, 15, S.O)
	# Vitrina.
	var gx := cx - 31
	var gy := FLOOR - 64
	p.rect(gx, gy, 62, 28, Color("2c4f86"))
	p.rect(gx + 1, gy + 1, 60, 3, Color("4a74b8"))
	p.frame(gx, gy, 62, 28, S.AZUL_L)
	p.frame(gx - 1, gy - 1, 64, 30, S.O)
	match kind:
		0:
			for k in 3:
				p.rect(gx + 9 + k * 18, gy + 12, 9, 9, [S.AZUL_E, S.LED_G, S.AZUL_E][k])
				p.frame(gx + 9 + k * 18, gy + 12, 9, 9, S.O)
			p.rect(gx + 4, gy + 22, 54, 2, S.MET_D)
		1:
			p.rect(gx + 3, gy + 22, 56, 3, S.MET_D)
			for k in 3:
				p.rect(gx + 9 + k * 18, gy + 12, 9, 9, S.PAPER)
				p.frame(gx + 9 + k * 18, gy + 12, 9, 9, S.O)
		2:
			p.rect(gx + 14, gy + 9, 18, 14, S.MET)
			p.frame(gx + 14, gy + 9, 18, 14, S.O)
			p.rect(gx + 18, gy + 13, 3, 3, S.CYAN)
			p.rect(gx + 25, gy + 13, 3, 3, S.CYAN)
			p.line(gx + 32, gy + 15, gx + 44, gy + 9, S.MET_L, 2)
			p.rect(gx + 46, gy + 6, 8, 8, S.AZUL_L)
			p.rect(gx + 46, gy + 18, 8, 6, S.LED_G)
	if kind == 0:
		# Un brazo de adorno en la mesa de CONDICIONALES.
		p.rect(cx - 66, FLOOR - 42, 14, 6, S.MET_D)
		p.line(cx - 60, FLOOR - 42, cx - 50, FLOOR - 52, S.MET_L, 2)
		p.ellipse(cx - 49, FLOOR - 53, 2, 2, YELLOW)


func _pegboard(p: PixelPainter, x: int, y: int, w: int, h: int) -> void:
	_sprite(p, x, y, w, h, func(s: PixelPainter) -> void:
		s.rect(1, 1, w, h, S.CORK)
		s.frame(1, 1, w, h, S.CORK_D)
		for yy in range(6, h, 8):
			for xx in range(6, w, 8):
				s.px(xx, yy, S.CORK_D)
		# Martillo, llave, pinza, rollo de cable y un tester.
		s.rect(14, 12, 10, 7, S.RED)
		s.rect(18, 19, 3, 40, S.WOOD_D)
		s.rect(38, 12, 3, 44, S.MET_L)
		s.ellipse(39.5, 12, 4, 4, S.MET_L)
		s.ellipse(39.5, 12, 2, 2, S.CORK)
		s.line(56, 14, 62, 52, S.MET, 2)
		s.line(68, 14, 62, 52, S.MET, 2)
		s.ellipse(94, 30, 15, 15, S.O)
		s.ellipse(94, 30, 12, 12, S.CORK)
		s.rect(80, 58, 30, 18, S.N4)
		s.rect(84, 61, 14, 7, S.CYAN_D))


## Estantes de pared con cajas de colores (dos repisas).
func _wall_shelves(p: PixelPainter, x: int, w: int, top: int) -> void:
	for k in 2:
		var y := top + k * 34
		var bx := x + 4
		while bx < x + w - 14:
			var bw := rng.randi_range(9, 14)
			var bh := rng.randi_range(10, 18)
			_box(p, bx, bw, bh, BOOKS[rng.randi_range(0, BOOKS.size() - 1)], y)
			bx += bw + rng.randi_range(2, 6)
		p.rect(x, y, w, 3, S.WOOD)
		p.rect(x, y, w, 1, S.WOOD_L)
		p.frame(x - 1, y - 1, w + 2, 5, S.O)


func _blueprint(p: PixelPainter, x: int, y: int) -> void:
	_sprite(p, x, y, 58, 62, func(s: PixelPainter) -> void:
		s.rect(1, 1, 58, 62, S.N3)
		s.frame(1, 1, 58, 62, S.MET)
		s.frame(6, 6, 22, 30, S.CYAN_D)
		s.line(30, 50, 46, 14, S.CYAN_D, 1)
		s.ellipse(46, 14, 4, 4, S.CYAN_D)
		s.ellipse(46, 14, 2.5, 2.5, S.N3)
		for k in 4:
			s.rect(8, 42 + k * 4, 18, 1, S.CYAN_D)
		s.frame(32, 40, 22, 18, S.CYAN_D))


func _warning_box(p: PixelPainter, x: int, y: int) -> void:
	p.rect(x, y, 16, 20, S.N4)
	p.frame(x, y, 16, 20, S.O)
	p.polygon(PackedVector2Array([Vector2(x + 8, y + 4), Vector2(x + 14, y + 15), Vector2(x + 2, y + 15)]), YELLOW)
	p.rect(x + 7, y + 8, 2, 4, S.O)


## Terminal en un pie: el marco y la pantalla (vacía: la anomalía del mensaje escribe ahí).
func _terminal(p: PixelPainter, x: int) -> void:
	p.rect(x - 2, FLOOR - 59, 4, 59, S.MET_D)
	p.rect(x - 2, FLOOR - 59, 1, 59, S.MET)
	p.rect(x - 9, FLOOR - 3, 18, 3, S.MET_D)
	p.frame(x - 9, FLOOR - 3, 18, 3, S.O)
	p.rect(x - 29, FLOOR - 92, 58, 34, S.MET_D)
	p.rect(x - 27, FLOOR - 90, 54, 30, S.N1)
	p.frame(x - 29, FLOOR - 92, 58, 34, S.O)


## La puerta del laboratorio, como un ascensor, con la luz celeste arriba.
func _elevator(p: PixelPainter, x: int) -> void:
	p.rect(x - 24, FLOOR - 66, 48, 66, S.MET_D)
	p.frame(x - 24, FLOOR - 66, 48, 66, S.O)
	for side in [-1, 1]:
		var dx := x - 21 if side < 0 else x + 1
		p.rect(dx, FLOOR - 62, 20, 62, Color("3f6fb8"))
		p.rect(dx, FLOOR - 62, 20, 2, S.AZUL_L)
		p.frame(dx, FLOOR - 62, 20, 62, S.O)
	p.rect(x + 12, FLOOR - 50, 4, 20, S.N1)
	p.rect(x - 14, FLOOR - 76, 28, 5, S.CYAN)
	p.frame(x - 15, FLOOR - 77, 30, 7, S.O)


## La puerta de la bodega (en el fondo; la anomalía la abre por encima) con su cartel.
func _bodega(p: PixelPainter, x: int) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(PROPS + "puerta_bodega.png"))
	image.convert(Image.FORMAT_RGBA8)
	image.resize(image.get_width() / 2, image.get_height() / 2, Image.INTERPOLATE_NEAREST)
	p.image.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(x - 23, FLOOR - 88))
	p.text(x - 11, FLOOR - 97, "BODEGA", S.MET_L)


func _metal_shelf(p: PixelPainter, x: int, top: int) -> void:
	_sprite(p, x, top, 88, FLOOR - top, func(s: PixelPainter) -> void:
		s.rect(1, 1, 3, FLOOR - top, S.MET)
		s.rect(85, 1, 3, FLOOR - top, S.MET)
		for k in 4:
			var y := 2 + k * 34
			s.rect(1, y + 30, 87, 3, S.MET_D)
		for k in 4:
			var y := 2 + k * 34
			var bx := 6
			while bx < 80:
				var bw := rng.randi_range(6, 12)
				var bh := rng.randi_range(10, 24)
				s.rect(bx, y + 30 - bh, bw, bh, BOOKS[rng.randi_range(0, BOOKS.size() - 1)])
				bx += bw + rng.randi_range(1, 4))


func _old_door(p: PixelPainter, x: int) -> void:
	p.rect(x - 20, FLOOR - 64, 40, 64, S.MET_D)
	p.frame(x - 20, FLOOR - 64, 40, 64, S.O)
	p.rect(x - 16, FLOOR - 60, 32, 60, S.N3)
	p.frame(x - 16, FLOOR - 60, 32, 60, S.O)
	p.rect(x + 2, FLOOR - 52, 8, 24, S.N1)
	p.rect(x + 3, FLOOR - 51, 6, 22, S.CYAN_D)
	p.rect(x - 12, FLOOR - 30, 3, 6, S.MET_L)
	p.rect(x - 14, FLOOR - 76, 28, 6, S.CYAN)
	p.frame(x - 15, FLOOR - 77, 30, 8, S.O)
	_light_cone(p, x, FLOOR - 70, FLOOR - 30, 16, 26)


func _ladder(p: PixelPainter, x: int) -> void:
	p.line(x + 2, FLOOR, x + 10, FLOOR - 48, S.VIOLETA, 2)
	p.line(x + 22, FLOOR, x + 28, FLOOR - 48, S.VIOLETA, 2)
	for k in 5:
		var y := FLOOR - 8 - k * 9
		p.rect(x + 4 + k, y, 20, 2, S.VIOLETA_D)


## Vitrina de vidrio con frascos y un microscopio, sobre su mueble de cajones.
func _glass_cabinet(p: PixelPainter, x: int, top: int) -> void:
	_sprite(p, x, top, 86, 122, func(s: PixelPainter) -> void:
		s.rect(1, 1, 86, 84, S.N4)
		s.rect(3, 3, 40, 80, Color("1f3157"))
		s.rect(45, 3, 40, 80, Color("1f3157"))
		for shelf in [28, 55]:
			s.rect(3, shelf, 82, 2, S.N5)
		for k in 9:
			var bx := 6 + (k % 9) * 9
			var row := k % 3
			var by := 26 + row * 27 - 2
			s.rect(bx, by - 8, 5, 8, [S.CYAN_D, S.TEAL, S.PAPER_D][k % 3])
			s.rect(bx + 1, by - 10, 3, 2, S.MET_L)
		s.rect(1, 86, 86, 37, S.N3)
		s.rect(1, 86, 86, 2, S.N5)
		for k in 2:
			s.frame(4 + k * 42, 92, 38, 14, S.N1)
			s.rect(20 + k * 42, 98, 6, 2, S.MET_L))


func _big_clock(p: PixelPainter, x: int, y: int) -> void:
	p.ellipse(x, y, 13, 13, S.O)
	p.ellipse(x, y, 11.5, 11.5, S.PAPER)
	p.ellipse(x, y, 10, 10, Color("dcd2b8"))
	p.line(x, y, x, y - 7, S.O, 1)
	p.line(x, y, x + 5, y, S.O, 1)
	p.px(x, y, S.RED)


func _chalkboard(p: PixelPainter, x: int, y: int, w: int, h: int) -> void:
	_sprite(p, x, y, w, h, func(s: PixelPainter) -> void:
		s.rect(1, 1, w, h, S.WOOD_D)
		s.rect(4, 4, w - 6, h - 6, BOARD)
		var chalk := Color(S.PAPER_D, 0.7)
		for k in 5:
			var lx := 10 + k * 28
			s.rect(lx, 10, rng.randi_range(12, 22), 1, chalk)
			s.rect(lx, 14, rng.randi_range(8, 18), 1, chalk)
		s.ellipse(40, 50, 12, 12, chalk)
		s.ellipse(40, 50, 11, 11, BOARD)
		s.line(28, 50, 52, 50, chalk, 1)
		s.line(40, 38, 40, 62, chalk, 1)
		s.line(70, 70, 90, 40, chalk, 1)
		s.line(90, 40, 110, 70, chalk, 1)
		s.line(70, 70, 110, 70, chalk, 1)
		s.ellipse(130, 50, 9, 9, chalk)
		s.ellipse(130, 50, 8, 8, BOARD)
		s.rect(4, h - 2, w - 6, 2, S.WOOD))


func _server_box(p: PixelPainter, x: int, y: int) -> void:
	_sprite(p, x, y, 46, 48, func(s: PixelPainter) -> void:
		s.rect(1, 1, 46, 48, S.MET_D)
		for k in 5:
			s.rect(4, 4 + k * 9, 40, 6, S.MET)
			s.px(38, 6 + k * 9, S.LED_G if k % 2 == 0 else S.LED_A)
			s.px(40, 6 + k * 9, S.CYAN))


func _desk(p: PixelPainter, x: int, w: int, top: int) -> void:
	_sprite(p, x, top, w, FLOOR - top, func(s: PixelPainter) -> void:
		s.rect(1, 1, w, 5, S.N4)
		s.rect(1, 1, w, 1, S.N5)
		s.rect(w - 34, 7, 30, FLOOR - top - 6, S.N3)
		s.frame(w - 34, 9, 30, 10, S.N1)
		s.rect(4, 7, 3, FLOOR - top - 6, S.MET_D))


func _save(p: PixelPainter, path: String) -> void:
	p.image.save_png(ProjectSettings.globalize_path(path))
	print("%s (%dx%d)" % [path, p.width, p.height])


## Guarda al doble (los objetos del taller se dibujan a la mitad, como Kai).
func _save2(p: PixelPainter, path: String) -> void:
	var image := p.image.duplicate() as Image
	image.resize(p.width * 2, p.height * 2, Image.INTERPOLATE_NEAREST)
	image.save_png(ProjectSettings.globalize_path(path))
	print("%s (%dx%d)" % [path, image.get_width(), image.get_height()])


# --- La soda y el patio ---

## Lámpara colgante de luz cálida.
func _hanging_lamp(p: PixelPainter, x: int) -> void:
	p.rect(x, 44, 1, 14, S.O)
	_light_cone(p, x, 64, 150, 10, 30)
	_sprite(p, x - 12, 58, 24, 7, func(s: PixelPainter) -> void:
		s.polygon(PackedVector2Array([Vector2(5, 1), Vector2(20, 1), Vector2(25, 6), Vector2(1, 6)]), S.N1)
		s.rect(4, 6, 18, 2, S.PAPER))


## Abanico de techo.
func _fan(p: PixelPainter, x: int) -> void:
	p.rect(x, 44, 1, 8, S.O)
	p.rect(x - 16, 52, 33, 2, S.N2)
	p.rect(x - 3, 51, 7, 4, S.N1)
	p.frame(x - 16, 51, 33, 4, S.O)


## Puerta de madera con su cartel arriba.
func _wood_door(p: PixelPainter, x: int, label: String, sign_color := S.TEAL_D) -> void:
	p.rect(x - 17, FLOOR - 54, 34, 54, S.WOOD_D)
	p.frame(x - 17, FLOOR - 54, 34, 54, S.O)
	_paste(p, "door.png", x - 14, FLOOR - 48)
	var sign_w := label.length() * 4 + 7
	var sx := x - sign_w / 2
	p.rect(sx, FLOOR - 70, sign_w, 11, sign_color)
	p.frame(sx, FLOOR - 70, sign_w, 11, S.O)
	p.text(sx + 4, FLOOR - 67, label, S.PAPER)


## La pizarra del menú del día (con la fuente chiquita).
func _menu_board(p: PixelPainter, cx: int, top: int) -> void:
	var lines := ["MENU DEL DIA", "- CASADO", "- EMPANADA", "- GALLO PINTO", "- FRESCO DE CAS", "- ARROZ C LECHE"]
	_sprite(p, cx - 40, top, 80, 62, func(s: PixelPainter) -> void:
		s.rect(1, 1, 80, 62, S.WOOD_D)
		s.rect(3, 3, 76, 58, BOARD)
		for k in lines.size():
			s.text(6, 6 + k * 9, lines[k], YELLOW if k == 0 else S.PAPER))


## Una mesa con dos bancos (para comer).
func _table_benches(p: PixelPainter, cx: int) -> void:
	for side in [-1, 1]:
		_sprite(p, cx + side * 30 - 13, FLOOR - 12, 26, 12, func(s: PixelPainter) -> void:
			s.rect(1, 1, 26, 3, S.WOOD)
			s.rect(1, 1, 26, 1, S.WOOD_L)
			s.rect(3, 4, 2, 9, S.WOOD_D)
			s.rect(22, 4, 2, 9, S.WOOD_D))
	_sprite(p, cx - 26, FLOOR - 22, 52, 22, func(s: PixelPainter) -> void:
		s.rect(1, 1, 52, 4, S.WOOD)
		s.rect(1, 1, 52, 1, S.WOOD_L)
		s.rect(1, 5, 52, 1, S.WOOD_D)
		s.rect(8, 6, 3, 17, S.WOOD_D)
		s.rect(43, 6, 3, 17, S.WOOD_D))
	p.rect(cx - 6, FLOOR - 26, 5, 4, S.MET_L)
	p.rect(cx + 6, FLOOR - 25, 6, 3, S.PAPER)


## Repisa con la radio.
func _shelf_radio(p: PixelPainter, cx: int, y: int) -> void:
	p.rect(cx - 22, y, 44, 3, S.WOOD)
	p.frame(cx - 23, y - 1, 46, 5, S.O)
	_sprite(p, cx - 12, y - 13, 24, 13, func(s: PixelPainter) -> void:
		s.rect(1, 1, 24, 13, S.N3)
		s.ellipse(8, 8, 4.5, 4.5, S.N1)
		s.ellipse(8, 8, 2.5, 2.5, S.MET)
		s.rect(15, 4, 7, 3, S.LED_A)
		s.rect(15, 9, 7, 2, S.MET_L))
	p.line(cx + 8, y - 13, cx + 14, y - 22, S.MET_L, 1)


## El mostrador de madera con la vitrina (empanadas, pan, arroz con leche y botellas).
func _counter(p: PixelPainter, x: int, w: int) -> void:
	_sprite(p, x, FLOOR - 40, w, 40, func(s: PixelPainter) -> void:
		s.rect(1, 1, w, 40, S.WOOD_D)
		s.rect(1, 1, w, 4, S.WOOD)
		s.rect(1, 1, w, 1, S.WOOD_L)
		for k in range(10, w - 10, 40):
			s.frame(k, 9, 32, 26, S.WOOD))
	_sprite(p, x + 14, FLOOR - 66, w - 28, 26, func(s: PixelPainter) -> void:
		s.rect(1, 1, w - 28, 26, Color("8fb0d8"))
		s.rect(1, 1, w - 28, 2, S.AZUL_L)
		s.rect(1, 22, w - 28, 5, S.MET_D)
		for k in 6:
			s.ellipse(12 + k * 13, 17, 5, 4, Color("e8a050"))
			s.rect(9 + k * 13, 15, 6, 1, Color("c47a30"))
		for k in 5:
			s.rect(96 + k * 12, 12, 9, 10, S.PAPER)
			s.rect(96 + k * 12, 12, 9, 2, S.PAPER_D)
		for k in 4:
			s.rect(162 + k * 7, 8, 4, 14, [S.RED, S.LED_A, S.LED_G, S.AZUL_E][k]))


## La refri de refrescos (con luz).
func _fridge(p: PixelPainter, cx: int) -> void:
	_sprite(p, cx - 16, FLOOR - 66, 32, 66, func(s: PixelPainter) -> void:
		s.rect(1, 1, 32, 66, S.N2)
		s.rect(4, 4, 26, 48, Color("9ec4e8"))
		for row in 4:
			s.rect(4, 14 + row * 11, 26, 1, S.MET)
			for k in 4:
				s.rect(6 + k * 6, 6 + row * 11, 4, 8, [S.RED, S.LED_G, S.AZUL_E, S.LED_A][(row + k) % 4])
		s.rect(4, 55, 26, 8, S.N3)
		s.rect(27, 26, 2, 10, S.MET_L))


## El piso de la soda: baldosas oscuras cálidas con su borde.
func _floor_warm(p: PixelPainter, w: int) -> void:
	p.rect(0, FLOOR, w, 1, Color("8a7a6a"))
	p.rect(0, FLOOR + 1, w, 3, Color("6a5a4c"))
	p.rect(0, FLOOR + 4, w, 1, S.O)
	p.rect(0, FLOOR + 5, w, H - FLOOR - 5, Color("3e342e"))
	for x in range(0, w, 32):
		p.rect(x, FLOOR + 5, 1, 12, Color("2c2420"))
	p.rect(0, FLOOR + 17, w, H - FLOOR - 17, Color("2c2420"))


## Una fachada desde x0 hasta x1, con la cornisa arriba (top) y el zócalo abajo.
func _facade(p: PixelPainter, x0: int, x1: int, top: int) -> void:
	p.rect(x0, top, x1 - x0, FLOOR - top, FACADE)
	for i in (x1 - x0) / 5:
		p.px(rng.randi_range(x0, x1 - 1), rng.randi_range(top + 6, FLOOR - 1), FACADE_D)
	p.rect(x0, top, x1 - x0, 5, CONCRETE)
	p.rect(x0, top + 5, x1 - x0, 1, S.O)
	p.rect(x0, top - 1, x1 - x0, 1, S.O)
	p.rect(x0, FLOOR - 10, x1 - x0, 10, CONCRETE_D)
	p.rect(x0, FLOOR - 10, x1 - x0, 1, S.O)
	p.rect(x0, top, 1, FLOOR - top, S.O)
	p.rect(x1 - 1, top, 1, FLOOR - top, S.O)
	if top < 100:
		# La línea del piso de arriba.
		p.rect(x0, 148, x1 - x0, 4, CONCRETE)
		p.rect(x0, 152, x1 - x0, 1, S.O)


func _school_window(p: PixelPainter, x: int, y: int) -> void:
	_sprite(p, x, y, 48, 44, func(s: PixelPainter) -> void:
		s.rect(1, 1, 48, 44, S.MET_D)
		for k in 2:
			s.rect(4 + k * 22, 4, 20, 38, Color("5a7ab8"))
			s.rect(4 + k * 22, 4, 20, 14, Color("7a9ad0"))
			s.line(6 + k * 22, 30, 14 + k * 22, 22, Color("9ab8e8"), 1)
		s.rect(1, 44, 48, 2, CONCRETE))


## El mural de la especialidad: CIBERSEGURIDAD con un candado y un circuito.
func _mural(p: PixelPainter, cx: int, top: int) -> void:
	_sprite(p, cx - 64, top, 128, 86, func(s: PixelPainter) -> void:
		s.rect(1, 1, 128, 76, S.MET_D)
		s.rect(4, 4, 122, 70, S.N1)
		s.ellipse(31, 20, 10, 10, YELLOW)
		s.ellipse(31, 20, 6, 6, S.N1)
		s.rect(18, 22, 26, 22, YELLOW)
		s.rect(18, 22, 26, 3, Color("ffd97a"))
		s.rect(29, 30, 4, 8, S.O)
		for k in 4:
			s.rect(58, 18 + k * 9, 50, 2, S.CYAN_M)
			s.ellipse(58, 19 + k * 9, 2.5, 2.5, S.CYAN)
		s.text(10, 62, "CIBERSEGURIDAD", S.PAPER)
		s.rect(14, 78, 3, 9, S.MET_D)
		s.rect(113, 78, 3, 9, S.MET_D))


## La entrada: un portón oscuro con escaleras que suben, y el cartel ENTRADA.
func _entrance(p: PixelPainter, cx: int) -> void:
	p.rect(cx - 30, FLOOR - 78, 60, 78, CONCRETE_D)
	p.frame(cx - 30, FLOOR - 78, 60, 78, S.O)
	p.rect(cx - 26, FLOOR - 74, 52, 74, S.N1)
	for k in 8:
		var step_y := FLOOR - 6 - k * 8
		p.rect(cx - 26 + k * 4, step_y, 52 - k * 4, 2, S.N3)
	p.rect(cx + 8, FLOOR - 70, 2, 60, S.MET)
	p.rect(cx - 24, FLOOR - 92, 48, 11, S.N1)
	p.frame(cx - 24, FLOOR - 92, 48, 11, S.MET)
	p.text(cx - 13, FLOOR - 89, "ENTRADA", S.PAPER)


func _street_lamp(p: PixelPainter, x: int) -> void:
	p.rect(x - 1, FLOOR - 64, 3, 64, S.MET_D)
	p.rect(x - 4, FLOOR - 4, 9, 4, S.MET_D)
	p.frame(x - 4, FLOOR - 4, 9, 4, S.O)
	p.rect(x - 4, FLOOR - 72, 9, 8, S.PAPER)
	p.rect(x - 4, FLOOR - 74, 9, 2, S.MET_D)
	p.frame(x - 4, FLOOR - 74, 9, 10, S.O)


## Un árbol de copa redonda en capas.
func _tree(p: PixelPainter, cx: int, radius: int) -> void:
	_sprite(p, cx - radius, FLOOR - radius * 2 - 50, radius * 2, radius * 2 + 50, func(s: PixelPainter) -> void:
		s.rect(radius - 5, radius + 20, 10, radius + 32, S.WOOD_D)
		s.rect(radius - 5, radius + 20, 3, radius + 32, S.WOOD)
		for blob in [Vector3(radius, radius, radius * 0.9), Vector3(radius * 0.55, radius * 1.2, radius * 0.6),
				Vector3(radius * 1.45, radius * 1.2, radius * 0.6), Vector3(radius, radius * 0.6, radius * 0.6)]:
			s.ellipse(blob.x, blob.y, blob.z, blob.z * 0.9, LEAF_D)
		for blob in [Vector3(radius * 0.9, radius * 0.85, radius * 0.6), Vector3(radius * 0.6, radius * 1.05, radius * 0.4),
				Vector3(radius * 1.35, radius * 1.0, radius * 0.4)]:
			s.ellipse(blob.x, blob.y, blob.z, blob.z * 0.85, LEAF)
		for k in 14:
			s.px(rng.randi_range(radius / 2, radius * 3 / 2), rng.randi_range(radius / 3, radius), LEAF_L))


## Jardinera de madera con arbustos.
func _planter(p: PixelPainter, x: int, w: int) -> void:
	_sprite(p, x, FLOOR - 22, w, 22, func(s: PixelPainter) -> void:
		for k in 4:
			s.ellipse(6 + k * (w - 12) / 3.0, 9, 8, 7, LEAF_D)
			s.ellipse(6 + k * (w - 12) / 3.0, 8, 6, 5, LEAF)
		s.rect(1, 13, w, 10, S.WOOD_D)
		s.rect(1, 13, w, 2, S.WOOD))


func _fountain(p: PixelPainter, cx: int) -> void:
	_sprite(p, cx - 8, FLOOR - 30, 16, 30, func(s: PixelPainter) -> void:
		s.rect(1, 10, 16, 21, S.MET)
		s.rect(1, 10, 16, 3, S.MET_L)
		s.rect(3, 6, 12, 4, S.MET_D)
		s.rect(10, 2, 2, 4, S.MET_L))


## El asta con la bandera de Costa Rica (azul, blanco, rojo, blanco, azul).
func _flag(p: PixelPainter, x: int) -> void:
	p.rect(x - 1, FLOOR - 150, 3, 150, S.MET_L)
	p.rect(x + 2, FLOOR - 150, 1, 150, S.O)
	p.rect(x - 4, FLOOR - 4, 9, 4, CONCRETE_D)
	var colors := [CR_BLUE, S.PAPER, RED_SIGN, RED_SIGN, S.PAPER, CR_BLUE]
	for k in colors.size():
		p.rect(x + 3, FLOOR - 146 + k * 4, 44, 4, colors[k])
	p.frame(x + 3, FLOOR - 146, 44, 24, S.O)


## El techito sobre el tablón de anuncios (el tablón con sus papeles lo dibuja el juego).
func _kiosk(p: PixelPainter, cx: int) -> void:
	for side in [-1, 1]:
		p.rect(cx + side * 66 - 2, FLOOR - 118, 4, 118, S.WOOD_D)
		p.frame(cx + side * 66 - 2, FLOOR - 118, 4, 118, S.O)
	p.rect(cx - 74, FLOOR - 124, 148, 8, S.TEAL_D)
	p.rect(cx - 74, FLOOR - 124, 148, 2, S.TEAL)
	p.frame(cx - 74, FLOOR - 124, 148, 8, S.O)


## El piso del patio: cemento con su borde.
func _ground(p: PixelPainter, w: int) -> void:
	p.rect(0, FLOOR, w, 1, Color("c8c4b8"))
	p.rect(0, FLOOR + 1, w, 3, CONCRETE)
	p.rect(0, FLOOR + 4, w, 1, S.O)
	p.rect(0, FLOOR + 5, w, H - FLOOR - 5, CONCRETE_D)
	for x in range(0, w, 40):
		p.rect(x, FLOOR + 5, 1, 12, Color("57534c"))
	p.rect(0, FLOOR + 17, w, H - FLOOR - 17, Color("57534c"))


## Ventana grande de día (cielo celeste con nubes y copas de árboles), para la soda.
func _day_window(p: PixelPainter, x: int, y: int) -> void:
	_sprite(p, x, y, 84, 56, func(s: PixelPainter) -> void:
		s.rect(1, 1, 84, 56, S.MET_D)
		for k in 2:
			var gx := 4 + k * 41
			s.rect(gx, 4, 37, 50, Color("7aa8e0"))
			s.rect(gx, 4, 37, 16, Color("5a8ad0"))
			s.ellipse(gx + 10 + k * 8, 22, 9, 4, S.PAPER)
			s.ellipse(gx + 16 + k * 8, 20, 6, 4, S.PAPER)
			for tree in 4:
				s.ellipse(gx + 4 + tree * 10, 52, 7, 8, LEAF)
			s.rect(gx + 18, 4, 1, 50, S.MET_D)
			s.rect(gx, 28, 37, 1, S.MET_D)
		s.rect(1, 1, 84, 1, S.MET)
		s.rect(1, 56, 84, 2, S.MET_L))
