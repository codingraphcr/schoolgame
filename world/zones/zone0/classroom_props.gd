@tool
extends Node2D
## Arte provisional de un aula del colegio (sala opcional del generador, M4), dibujado por código
## hasta que Ariel la dibuje: la pizarra, el escritorio del profesor, filas de pupitres, el reloj, una
## ventana y las puertas de los costados. Se ve también en el editor. Con computers, cada pupitre tiene
## una computadora de práctica (la Sala 3 del Capítulo 1); glitching las hace fallar (parpadean).

const WOOD := Color("6a4a32")
const WOOD_DARK := Color("3e2a1c")
const BOARD := Color("1f3a2e")
const METAL := Color("4a5470")
const DOOR := Color("5a4030")

@export var board := Rect2(200, 150, 220, 80)
@export var board_text := "REDES 101"
@export var teacher_desk := Rect2(470, 276, 70, 28)
## Centro (x) de cada pupitre.
@export var desks: Array[float] = [90.0, 150.0, 260.0, 320.0, 380.0]
@export var window := Rect2(40, 110, 110, 80)
## Puertas dibujadas (x del centro).
@export var doors: Array[float] = [16.0, 624.0]
@export var floor_y := 304.0
## Una computadora de práctica en cada pupitre.
@export var computers := false:
	set(value):
		computers = value
		if _canvas:
			_canvas.queue_redraw()
## Las computadoras fallan: las pantallas parpadean (lo pide la historia).
var glitching := false:
	set(value):
		glitching = value
		if _canvas:
			_canvas.animated = value
			_canvas.queue_redraw()

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	add_child(_canvas)


func _paint(c: VectorCanvas, t: float) -> void:
	c.draw_rect(window.grow(4), METAL)
	c.gradient_rect(window, Color("5a8ac8"), Color("3a6aa8"))
	c.draw_line(Vector2(window.get_center().x, window.position.y), Vector2(window.get_center().x, window.end.y), METAL, 2.0)
	c.draw_rect(board.grow(5), WOOD_DARK)
	c.draw_rect(board, BOARD)
	c.crisp_text(Vector2(board.position.x, board.position.y + 24), board_text, 12, Color(0.9, 0.95, 0.9), HORIZONTAL_ALIGNMENT_CENTER, board.size.x)
	# Un diagrama de red escrito con tiza.
	var chalk := Color(0.85, 0.9, 0.85, 0.8)
	var nodes := [board.position + Vector2(40, 52), board.position + Vector2(110, 40), board.position + Vector2(180, 56)]
	for i in nodes.size() - 1:
		c.draw_line(nodes[i], nodes[i + 1], chalk, 1.0)
	for n: Vector2 in nodes:
		c.draw_rect(Rect2(n - Vector2(6, 4), Vector2(12, 8)), chalk, false, 1.0)
	# Reloj.
	c.draw_circle(Vector2(450, 120), 10, Color("d8dce8"))
	c.draw_line(Vector2(450, 120), Vector2(450, 113), Color("20242e"), 1.5)
	c.draw_line(Vector2(450, 120), Vector2(455, 122), Color("20242e"), 1.5)
	c.gradient_box(teacher_desk, 1.0, WOOD, WOOD_DARK)
	for x in desks:
		c.gradient_box(Rect2(x - 16, floor_y - 20, 32, 4), 1.0, WOOD, WOOD_DARK)
		c.draw_line(Vector2(x - 13, floor_y - 16), Vector2(x - 13, floor_y), METAL, 2.0)
		c.draw_line(Vector2(x + 12, floor_y - 16), Vector2(x + 12, floor_y), METAL, 2.0)
		c.draw_rect(Rect2(x + 18, floor_y - 12, 10, 3), METAL)
		c.draw_rect(Rect2(x + 26, floor_y - 24, 2, 24), METAL)
		if computers:
			_paint_computer(c, x, t)
	for x in doors:
		_paint_door(c, x)


## Monitor sobre el pupitre (centro x). Si fallan, la pantalla parpadea entre magenta y estática.
func _paint_computer(c: VectorCanvas, x: float, t: float) -> void:
	var top := floor_y - 20
	c.draw_rect(Rect2(x - 2, top - 4, 4, 4), METAL)
	var monitor := Rect2(x - 11, top - 18, 22, 14)
	c.draw_rect(monitor.grow(1), Color("20242e"))
	var screen := Color("3a7ab8")
	if glitching:
		var flash := sin(t * 23.0 + x * 0.37) > 0.2
		screen = Color("ff3ea5") if flash else Color("2a1030")
	c.draw_rect(monitor.grow(-1), screen)
	if not glitching:
		for k in 3:
			c.draw_rect(Rect2(monitor.position.x + 3, monitor.position.y + 3 + k * 3, 10 - k * 3, 1), Color(0.85, 0.95, 1.0, 0.6))


func _paint_door(c: VectorCanvas, x: float) -> void:
	var rect := Rect2(x - 14, floor_y - 64, 28, 64)
	c.draw_rect(rect.grow(2), WOOD_DARK)
	c.gradient_rect(rect, DOOR.lightened(0.1), DOOR)
	c.draw_rect(Rect2(rect.position.x + 6, rect.position.y + 8, 16, 14), Color("8ab4e8"))
	c.draw_circle(Vector2(x + (8 if x < 320 else -8), floor_y - 32), 2.0, Color("d8c060"))
