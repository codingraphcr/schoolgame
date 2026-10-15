@tool
extends Node2D
## Arte provisional del pasillo del segundo piso (Capítulo 1), dibujado por código hasta que Ariel lo
## dibuje: la pared con zócalo, el piso, ventanas, casilleros, puertas de aulas con su cartel, diarios
## murales, afiches y lámparas. Es largo: ahí Chip y Glitch tiran estanterías y cajas. Se ve también en
## el editor.

const WALL := Color("1c2440")
const WALL_DARK := Color("141a30")
const SKIRTING := Color("2c3658")
const FLOOR := Color("2a3150")
const FLOOR_LINE := Color("3c4670")
const GLASS := Color("2a4a7a")
const FRAME := Color("4a5470")
const LOCKER := Color("3a6c8a")
const LOCKER_DARK := Color("2a4c66")
const DOOR := Color("5a4030")
const SIGN := Color("1f6f5a")
const CORK := Color("8a6a40")
const PAPERS: Array[Color] = [Color("e8e4d8"), Color("f2c14e"), Color("9bd0e8"), Color("f0a0b0")]

@export var width := 1900.0:
	set(value):
		width = value
		if _canvas:
			_canvas.queue_redraw()
@export var floor_y := 304.0
## Ventanas (rectángulos), casilleros (x de inicio, cantidad) y puertas de aulas (x del centro → texto).
@export var windows: Array[Rect2] = []
@export var lockers: Array[Vector2] = []
@export var doors: Dictionary = {}
@export var boards: Array[Rect2] = []
## Afiches: centro → texto.
@export var posters: Dictionary = {}

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	add_child(_canvas)


func _paint(c: VectorCanvas, _t: float) -> void:
	c.draw_rect(Rect2(0, 0, width, floor_y), WALL)
	c.draw_rect(Rect2(0, 0, width, 40), WALL_DARK)
	c.draw_rect(Rect2(0, floor_y - 14, width, 14), SKIRTING)
	c.draw_rect(Rect2(0, floor_y, width, 60), FLOOR)
	var x := 0.0
	while x < width:
		c.draw_line(Vector2(x, floor_y), Vector2(x, floor_y + 60), FLOOR_LINE, 1.0)
		x += 48.0
	# Lámparas del techo.
	x = 80.0
	while x < width:
		c.draw_rect(Rect2(x - 18, 40, 36, 4), Color("d8e4ff"))
		c.draw_rect(Rect2(x - 22, 44, 44, 28), Color(0.85, 0.9, 1.0, 0.04))
		x += 240.0
	for window in windows:
		c.draw_rect(window.grow(3), FRAME)
		c.gradient_rect(window, Color("3a5a9a"), GLASS)
		c.draw_line(Vector2(window.get_center().x, window.position.y), Vector2(window.get_center().x, window.end.y), FRAME, 2.0)
	for data in lockers:
		for k in int(data.y):
			var rect := Rect2(Vector2(data.x + k * 18.0, floor_y - 62), Vector2(16, 48))
			c.draw_rect(rect, LOCKER_DARK)
			c.draw_rect(rect.grow(-1), LOCKER)
			for slot in 3:
				c.draw_line(rect.position + Vector2(4, 6 + slot * 3), rect.position + Vector2(12, 6 + slot * 3), LOCKER_DARK, 1.0)
			c.draw_rect(Rect2(rect.position + Vector2(12, 24), Vector2(2, 4)), Color("c8d0e8"))
	for door_x: float in doors:
		var rect := Rect2(Vector2(door_x - 14, floor_y - 62), Vector2(28, 48))
		c.draw_rect(rect.grow(2), Color("3e2a1c"))
		c.gradient_rect(rect, DOOR.lightened(0.1), DOOR)
		c.draw_rect(Rect2(rect.position + Vector2(6, 6), Vector2(16, 12)), Color("8ab4e8"))
		c.draw_circle(rect.position + Vector2(22, 26), 1.6, Color("d8c060"))
		var sign_rect := Rect2(Vector2(door_x - 22, floor_y - 78), Vector2(44, 11))
		c.draw_rect(sign_rect, SIGN)
		c.crisp_text(sign_rect.position + Vector2(0, 9), String(doors[door_x]), 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, sign_rect.size.x)
	for board in boards:
		c.draw_rect(board.grow(2), Color("4a3420"))
		c.draw_rect(board, CORK)
		for k in 5:
			var paper := Rect2(board.position + Vector2(4 + (k % 3) * (board.size.x / 3.0), 4 + floorf(k / 3.0) * (board.size.y / 2.0)), Vector2(12, 10))
			c.draw_rect(paper, PAPERS[k % PAPERS.size()])
	for center: Vector2 in posters:
		var poster_width := maxf(52.0, String(posters[center]).length() * 3.4 + 8.0)
		var rect := Rect2(center - Vector2(poster_width / 2.0, 16), Vector2(poster_width, 32))
		c.draw_rect(rect, Color("2f6fb8"))
		c.crisp_text(rect.position + Vector2(0, 19), String(posters[center]), 7, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
