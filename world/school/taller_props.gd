@tool
extends Node2D
## Arte provisional del taller de robótica (anexo del laboratorio, detrás de la puerta de vidrio), dibujado por código
## hasta que Ariel lo dibuje: pared de bloques gris azulado, un tablero perforado con herramientas, estantes con
## piezas y kits de robots, carteles de la actividad («Condicionales · Ciclos · Funciones»), lámparas colgantes y
## piso de cemento pulido con marcas de seguridad. La puerta de vidrio al laboratorio va a la izquierda.

const WALL := Color("4a5464")
const WALL_LINE := Color("3e4756")
const FLOOR := Color("6a6e78")
const OUTLINE := Color("1a1e28")
const CYAN := Color("3ef2ff")
const YELLOW := Color("f2c14e")

@export var width := 960.0
@export var floor_y := 304.0

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)


func _paint(c: VectorCanvas, t: float) -> void:
	var f := floor_y
	# Pared de bloques.
	c.draw_rect(Rect2(0, 0, width, f), WALL)
	var row := 0
	var y := 20.0
	while y < f:
		c.draw_line(Vector2(0, y), Vector2(width, y), WALL_LINE, 1.0)
		var x := 0.0 if row % 2 == 0 else 24.0
		while x < width:
			c.draw_line(Vector2(x, y), Vector2(x, y + 20), WALL_LINE, 1.0)
			x += 48.0
		y += 20.0
		row += 1
	c.draw_rect(Rect2(0, 0, width, 18), WALL.darkened(0.3))
	# Piso de cemento con franja de seguridad.
	c.draw_rect(Rect2(0, f, width, 60), FLOOR)
	var stripe := 0.0
	while stripe < width:
		c.draw_rect(Rect2(stripe, f + 2, 14, 4), YELLOW if int(stripe / 14.0) % 2 == 0 else OUTLINE)
		stripe += 14.0
	# Lámparas colgantes.
	for lamp_x in [200.0, 480.0, 760.0]:
		c.draw_line(Vector2(lamp_x, 18), Vector2(lamp_x, 46), Color("2a2e38"), 1.5)
		c.shape(PackedVector2Array([Vector2(lamp_x - 14, 56), Vector2(lamp_x - 6, 46), Vector2(lamp_x + 6, 46), Vector2(lamp_x + 14, 56)]),
			Color("3a3f4a"), OUTLINE, 0.6)
		c.glow(Vector2(lamp_x, 62), 26.0, Color(1, 0.95, 0.8, 0.12))
	# Puerta de vidrio al laboratorio (izquierda).
	c.draw_rect(Rect2(36, f - 100, 50, 100), Color("2a3040"))
	c.gradient_rect(Rect2(40, f - 96, 42, 96), Color(0.5, 0.8, 1.0, 0.45), Color(0.3, 0.55, 0.8, 0.35))
	c.draw_line(Vector2(61, f - 96), Vector2(61, f), Color("2a3040"), 2.0)
	# Cartel de la actividad.
	var banner := Rect2(330, 70, 300, 46)
	c.draw_rect(banner.grow(2), OUTLINE)
	c.draw_rect(banner, Color("1f3a6a"))
	c.crisp_text(banner.position + Vector2(0, 18), "ACTIVIDAD DE ROBÓTICA · DÉCIMO", 9, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, banner.size.x)
	c.crisp_text(banner.position + Vector2(0, 36), "CONDICIONALES  ·  CICLOS  ·  FUNCIONES", 8, CYAN, HORIZONTAL_ALIGNMENT_CENTER, banner.size.x)
	# Tablero perforado con herramientas.
	var board := Rect2(110, 80, 150, 90)
	c.draw_rect(board, Color("a88a60"))
	var hx := board.position.x + 8
	while hx < board.end.x:
		var hy := board.position.y + 8
		while hy < board.end.y:
			c.draw_circle(Vector2(hx, hy), 1.2, Color("7a6040"))
			hy += 10.0
		hx += 10.0
	c.draw_line(board.position + Vector2(20, 14), board.position + Vector2(20, 60), Color("3a3f4a"), 3.0)  # Destornillador
	c.draw_rect(Rect2(board.position + Vector2(14, 10), Vector2(12, 14)), Color("c0504d"))
	c.draw_line(board.position + Vector2(52, 16), board.position + Vector2(72, 56), Color("8a94a8"), 3.0)  # Llave
	c.draw_circle(board.position + Vector2(52, 16), 5.0, Color("8a94a8"))
	c.draw_arc(board.position + Vector2(110, 40), 16.0, 0.0, TAU, 20, Color("3a3f4a"), 3.0)  # Rollo de cable
	c.draw_rect(Rect2(board.position + Vector2(90, 64), Vector2(40, 16)), Color("4f81bd"))  # Multímetro
	c.draw_rect(Rect2(board.position + Vector2(94, 67), Vector2(14, 8)), Color("9bd0e8"))
	# Estantes con piezas y kits.
	for shelf_y in [150.0, 196.0]:
		c.draw_rect(Rect2(800, shelf_y, 130, 5), Color("6a4a32"))
	var colors: Array[Color] = [Color("c0504d"), Color("4f81bd"), Color("9bbb59"), YELLOW]
	for k in 5:
		c.draw_rect(Rect2(806 + k * 24, 132, 18, 18), colors[k % 4].darkened(0.1))
		c.draw_rect(Rect2(810 + k * 24, 178, 14, 18), colors[(k + 2) % 4].darkened(0.2))
	c.draw_circle(Vector2(900, 120), 8.0, Color("8a94a8"))  # Una rueda de robot
	c.draw_circle(Vector2(900, 120), 3.0, Color("3a3f4a"))
	# Pantalla de la red del taller (con un led que parpadea).
	c.draw_rect(Rect2(660, 140, 40, 26), Color("101824"))
	c.draw_circle(Vector2(694, 160), 2.0, CYAN if fmod(t, 1.0) < 0.5 else Color("204050"))
