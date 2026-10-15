@tool
extends Node2D
## Arte provisional de la casa de Kai (dibujado por código hasta que Ariel la dibuje): de izquierda a
## derecha, la puerta de la calle y el recibidor (percheros, zapatos, fotos), la sala (sofá, ventana,
## lámpara, tele), el comedor y la cocina (con la refri llena de imanes) y el pasillito con la puerta del
## cuarto de Kai y las marcas de su estatura en el marco. Luz cálida; por la ventana se ve el momento del
## día (DayPhase). Una casa de barrio, sencilla: no una mansión.

const WALL := Color("e8d4b0")
const WALL_SHADE := Color("d4bc94")
const STRIPE := Color(0.0, 0.0, 0.0, 0.035)
const CEILING := Color("c8b08a")
const BASEBOARD := Color("8a6440")
const FLOOR := Color("9a6a42")
const FLOOR_DARK := Color("7e5434")
const WOOD := Color("7a5236")
const WOOD_DARK := Color("4a3020")
const OUTLINE := Color("2a1a10")
const TILE := Color("d8e4e8")
const TILE_LINE := Color("b8c8d0")

@export var width := 1040.0
@export var floor_y := 304.0
## En el editor: qué momento del día mostrar (en el juego lo dice la historia).
@export var preview_phase := DayPhase.Phase.TARDE

var _canvas: VectorCanvas
var _phase := DayPhase.Phase.TARDE


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_phase = preview_phase
	elif has_node("/root/GameState"):
		_phase = DayPhase.current(get_node("/root/GameState"))


func _paint(c: VectorCanvas, t: float) -> void:
	var f := floor_y
	# Pared con papel de rayas suaves, cielo raso, zócalo y piso de madera.
	c.draw_rect(Rect2(0, 0, width, f), WALL)
	var x := 0.0
	while x < width:
		c.draw_rect(Rect2(x, 30, 10, f - 30), STRIPE)
		x += 24.0
	c.draw_rect(Rect2(0, 0, width, 30), CEILING)
	c.draw_rect(Rect2(0, 28, width, 3), WALL_SHADE)
	c.draw_rect(Rect2(0, f - 10, width, 10), BASEBOARD)
	c.gradient_rect(Rect2(0, f, width, 60), FLOOR, FLOOR_DARK)
	x = 0.0
	while x < width:
		c.draw_line(Vector2(x, f), Vector2(x, f + 60), OUTLINE * Color(1, 1, 1, 0.25), 1.0)
		x += 56.0
	_entrance(c, f)
	_living_room(c, f, t)
	_dining(c, f)
	_kitchen(c, f, t)
	_hallway(c, f)


func _entrance(c: VectorCanvas, f: float) -> void:
	# Puerta de la calle (con su vidrio) y alfombra de entrada.
	c.draw_rect(Rect2(10, f - 96, 44, 96), WOOD_DARK)
	c.gradient_rect(Rect2(14, f - 92, 36, 92), Color("8a5a36"), Color("6a4228"))
	c.draw_rect(Rect2(22, f - 84, 20, 26), _sky_bottom().lerp(Color.WHITE, 0.2))
	c.draw_circle(Vector2(44, f - 46), 2.0, Color("d8c060"))
	c.draw_rect(Rect2(8, f - 2, 52, 4), Color("6a5a8a"))
	# Perchero con una jacket y la mochila de reserva.
	c.draw_rect(Rect2(70, f - 120, 36, 4), WOOD)
	for k in 3:
		c.draw_rect(Rect2(74 + k * 12, f - 118, 3, 8), WOOD_DARK)
	c.draw_rect(Rect2(72, f - 112, 12, 34), Color("3a6c8a"))
	c.draw_rect(Rect2(96, f - 110, 10, 22), Color("8a4a6a"))
	# Zapatera con zapatos.
	c.draw_rect(Rect2(70, f - 24, 56, 24), WOOD)
	c.draw_rect(Rect2(72, f - 22, 52, 9), WOOD_DARK)
	for k in 4:
		c.draw_rect(Rect2(76 + k * 12, f - 12, 9, 5), [Color("2a2a3a"), Color("c04040"), Color("e8e8f0"), Color("6a4a32")][k])
	# Fotos de la familia (se examinan).
	var frames: Array[Rect2] = [Rect2(140, 150, 26, 32), Rect2(172, 140, 36, 26), Rect2(172, 172, 22, 22), Rect2(200, 172, 18, 24)]
	for rect in frames:
		c.draw_rect(rect.grow(2), WOOD_DARK)
		c.draw_rect(rect, Color("f6d8a8"))
		c.draw_circle(rect.get_center() + Vector2(-3, -2), rect.size.y * 0.16, Color("e0b090"))
		c.draw_circle(rect.get_center() + Vector2(4, -1), rect.size.y * 0.16, Color("e0b090"))
		c.draw_rect(Rect2(rect.get_center() + Vector2(-7, 3), Vector2(14, rect.size.y * 0.3)), Color("6a8ab8"))


func _living_room(c: VectorCanvas, f: float, t: float) -> void:
	# Ventana con cortinas: afuera, el cielo del momento del día.
	var window := Rect2(290, 110, 96, 80)
	c.draw_rect(window.grow(4), Color("f4f0e4"))
	c.gradient_rect(window, _sky_top(), _sky_bottom())
	if _phase == DayPhase.Phase.NOCHE:
		for k in 5:
			c.draw_circle(window.position + Vector2(12 + k * 17, 14 + (k % 2) * 16), 1.0, Color(1, 1, 1, 0.7))
	else:
		# Techos del barrio y un árbol.
		c.draw_rect(Rect2(window.position + Vector2(0, 54), Vector2(40, 26)), Color("b86a4a").darkened(0.15))
		c.draw_rect(Rect2(window.position + Vector2(56, 46), Vector2(40, 34)), Color("8aa0b8").darkened(0.15))
		c.draw_circle(window.position + Vector2(48, 50), 16.0, Color("4a7a3a"))
	c.draw_line(Vector2(window.get_center().x, window.position.y), Vector2(window.get_center().x, window.end.y), Color("f4f0e4"), 3.0)
	c.draw_line(Vector2(window.position.x, window.get_center().y), Vector2(window.end.x, window.get_center().y), Color("f4f0e4"), 3.0)
	var sway := sin(t * 0.8) * 2.0
	c.shape(PackedVector2Array([Vector2(280, 100), Vector2(304, 100), Vector2(300 + sway, 204), Vector2(276, 204)]), Color("c86a5a"))
	c.shape(PackedVector2Array([Vector2(372, 100), Vector2(396, 100), Vector2(400, 204), Vector2(376 + sway, 204)]), Color("c86a5a"))
	c.draw_rect(Rect2(272, 98, 132, 4), WOOD_DARK)
	# Alfombra, sofá con cojines.
	c.draw_rect(Rect2(250, f - 2, 280, 6), Color("8a4a5a"))
	c.gradient_box(Rect2(254, f - 46, 140, 30), 6.0, Color("5a7a9a"), Color("3e5a78"))
	c.gradient_box(Rect2(250, f - 62, 148, 26), 6.0, Color("6a8aaa"), Color("4e6a88"))
	c.draw_rect(Rect2(258, f - 16, 6, 16), WOOD_DARK)
	c.draw_rect(Rect2(384, f - 16, 6, 16), WOOD_DARK)
	c.gradient_box(Rect2(266, f - 58, 22, 18), 4.0, Color("f2c14e"), Color("d8a030"))
	c.gradient_box(Rect2(360, f - 58, 22, 18), 4.0, Color("e87a6a"), Color("c85a4a"))
	# Lámpara de pie con su luz cálida.
	c.draw_rect(Rect2(418, f - 110, 3, 110), Color("3a3a3a"))
	c.draw_rect(Rect2(410, f - 2, 19, 3), Color("3a3a3a"))
	c.shape(PackedVector2Array([Vector2(406, f - 110), Vector2(434, f - 110), Vector2(428, f - 132), Vector2(412, f - 132)]), Color("f4e0b0"))
	c.glow(Vector2(420, f - 116), 70.0, Color(1.0, 0.8, 0.45, 0.22 if _phase == DayPhase.Phase.NOCHE else 0.1))
	# Mueble de la tele y la tele (de noche, encendida).
	c.draw_rect(Rect2(446, f - 34, 92, 34), WOOD)
	c.draw_rect(Rect2(450, f - 30, 40, 26), WOOD_DARK)
	c.draw_rect(Rect2(494, f - 30, 40, 26), WOOD_DARK)
	c.draw_rect(Rect2(456, f - 90, 76, 52), Color("1a1a22"))
	var screen := Rect2(460, f - 86, 68, 44)
	if _phase == DayPhase.Phase.NOCHE:
		var flick := 0.85 + 0.15 * sin(t * 7.0) * sin(t * 2.3)
		c.gradient_rect(screen, Color(0.35, 0.55, 0.85) * flick, Color(0.25, 0.4, 0.6) * flick)
		c.glow(screen.get_center(), 60.0, Color(0.4, 0.6, 1.0, 0.12))
	else:
		c.draw_rect(screen, Color("22262e"))
		c.draw_line(screen.position + Vector2(6, 6), screen.position + Vector2(20, 18), Color(1, 1, 1, 0.08), 3.0)
	c.draw_rect(Rect2(490, f - 38, 8, 4), Color("1a1a22"))
	# Planta.
	c.draw_rect(Rect2(548, f - 20, 16, 20), Color("b86a4a"))
	for k in 5:
		c.draw_circle(Vector2(550 + k * 3, f - 26 - (k % 3) * 8), 7.0, Color("4a8a3a").darkened(k * 0.05))


func _dining(c: VectorCanvas, f: float) -> void:
	# Lámpara colgante sobre la mesa, mesa y tres sillas (la de Kai, la de mamá y la de papá).
	c.draw_line(Vector2(640, 30), Vector2(640, 120), Color("3a3a3a"), 1.5)
	c.shape(PackedVector2Array([Vector2(624, 132), Vector2(656, 132), Vector2(648, 118), Vector2(632, 118)]), Color("d89a4a"))
	c.glow(Vector2(640, 140), 80.0, Color(1.0, 0.78, 0.4, 0.25 if _phase == DayPhase.Phase.NOCHE else 0.08))
	for k in 3:
		var sx := 590.0 + k * 42.0
		c.draw_rect(Rect2(sx, f - 52, 4, 52), WOOD_DARK)
		c.draw_rect(Rect2(sx, f - 26, 20, 4), WOOD)
		c.draw_rect(Rect2(sx + 16, f - 26, 4, 26), WOOD_DARK)
	c.draw_rect(Rect2(586, f - 40, 112, 6), WOOD)
	c.draw_rect(Rect2(592, f - 34, 6, 34), WOOD_DARK)
	c.draw_rect(Rect2(686, f - 34, 6, 34), WOOD_DARK)
	c.draw_rect(Rect2(600, f - 44, 96, 4), Color("f4f0e4"))  # Mantel
	c.draw_circle(Vector2(624, f - 46), 4.0, Color("e8e4d8"))  # Platos
	c.draw_circle(Vector2(664, f - 46), 4.0, Color("e8e4d8"))
	c.draw_rect(Rect2(642, f - 52, 6, 8), Color("c04a3a"))  # Taza


func _kitchen(c: VectorCanvas, f: float, t: float) -> void:
	# Azulejos, gabinetes de arriba, ventana sobre el fregadero, mueble con fregadero y cocina, refri.
	c.draw_rect(Rect2(722, f - 120, 200, 76), TILE)
	var x := 722.0
	while x < 922.0:
		c.draw_line(Vector2(x, f - 120), Vector2(x, f - 44), TILE_LINE, 1.0)
		x += 12.0
	var y := f - 120
	while y < f - 44:
		c.draw_line(Vector2(722, y), Vector2(922, y), TILE_LINE, 1.0)
		y += 12.0
	var window := Rect2(744, f - 112, 48, 36)
	c.draw_rect(window.grow(3), Color("f4f0e4"))
	c.gradient_rect(window, _sky_top(), _sky_bottom())
	for k in 3:
		c.draw_rect(Rect2(730 + k * 50, 70, 46, 40), WOOD)
		c.draw_rect(Rect2(733 + k * 50, 73, 40, 34), Color("8a6040"))
		c.draw_circle(Vector2(770 + k * 50, 100), 1.5, Color("d8c060"))
	c.draw_rect(Rect2(726, f - 44, 156, 44), Color("e8e0d0"))
	c.draw_rect(Rect2(726, f - 46, 156, 5), Color("6a6a72"))
	for k in 3:
		c.draw_rect(Rect2(732 + k * 50, f - 36, 42, 30), Color("d8d0c0"))
		c.draw_circle(Vector2(753 + k * 50, f - 30), 1.5, Color("6a6a72"))
	c.draw_rect(Rect2(752, f - 50, 30, 4), Color("a8b0b8"))  # Fregadero
	c.draw_rect(Rect2(764, f - 62, 3, 14), Color("a8b0b8"))
	# Cocina con una olla (vapor si hay alguien cocinando: de tarde y de mañana).
	c.draw_rect(Rect2(820, f - 50, 40, 4), Color("2a2a32"))
	c.draw_rect(Rect2(826, f - 62, 26, 12), Color("8a8a96"))
	if _phase != DayPhase.Phase.NOCHE:
		for k in 3:
			var rise := fmod(t * 14.0 + k * 9.0, 28.0)
			c.draw_circle(Vector2(839 + sin(t * 2.0 + k) * 3.0, f - 66 - rise), 3.0 + rise * 0.1, Color(1, 1, 1, 0.3 * (1.0 - rise / 28.0)))
	# Refri con imanes y el dibujo de Kai de chiquito.
	c.gradient_box(Rect2(886, f - 120, 40, 120), 4.0, Color("f0f0f4"), Color("d0d4dc"))
	c.draw_line(Vector2(886, f - 78), Vector2(926, f - 78), Color("b0b4bc"), 1.5)
	c.draw_rect(Rect2(920, f - 110, 2, 20), Color("8a8e96"))
	c.draw_rect(Rect2(892, f - 112, 18, 14), Color("fff8e8"))
	c.draw_circle(Vector2(898, f - 106), 3.0, Color("3ef2ff"))
	c.draw_circle(Vector2(905, f - 104), 2.0, Color("f2c14e"))
	for k in 3:
		c.draw_circle(Vector2(894 + k * 9, f - 66 + (k % 2) * 6), 2.5, [Color("c0504d"), Color("4f81bd"), Color("9bbb59")][k])


func _hallway(c: VectorCanvas, f: float) -> void:
	# Marco de la puerta con las marcas de estatura de Kai y la puerta de su cuarto (a la derecha).
	c.draw_rect(Rect2(952, f - 110, 8, 110), Color("f4f0e4"))
	for k in 6:
		var mark_y := f - 30 - k * 13.0
		c.draw_line(Vector2(952, mark_y), Vector2(962, mark_y), Color("3a5a8a"), 1.5)
	c.draw_rect(Rect2(988, f - 100, 40, 100), WOOD_DARK)
	c.gradient_rect(Rect2(992, f - 96, 32, 96), Color("9a6a42"), Color("7a5232"))
	c.draw_circle(Vector2(996, f - 48), 2.0, Color("d8c060"))
	c.draw_rect(Rect2(998, f - 86, 20, 12), Color("3ef2ff").darkened(0.2))  # Cartelito «KAI»
	c.crisp_text(Vector2(998, f - 77), "KAI", 7, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 20)



func _sky_top() -> Color:
	return DayPhase.sky_top(_phase)


func _sky_bottom() -> Color:
	return DayPhase.sky_bottom(_phase)
