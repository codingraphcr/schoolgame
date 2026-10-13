@tool
extends Node2D
## Arte provisional de la biblioteca del colegio (M3), dibujado por código hasta que Ariel la dibuje:
## estanterías con libros de colores, mesas de lectura con lámparas, sillas, el mostrador con una
## computadora, una ventana grande y el cartel. Las estanterías bajas sirven de plataforma
## (Collisions/Shelf*: deben coincidir con shelves). Se ve también en el editor.

const WOOD := Color("6a4a32")
const WOOD_DARK := Color("3e2a1c")
const BOOKS := [Color("b8434a"), Color("3f7cc8"), Color("e0b040"), Color("4fa36a"), Color("8a5cc8"), Color("d07a3a"), Color("c8c8d8")]
const GLASS := Color("3a6aa8")
const SIGN := Color("1f6f5a")

## Estanterías (rectángulo completo; arriba = donde puede pararse Kai).
@export var shelves: Array[Rect2] = []
## Centro de cada mesa de lectura (x).
@export var tables: Array[float] = []
@export var counter := Rect2(820, 268, 96, 36)
@export var window := Rect2(330, 96, 150, 90)
@export var sign_center := Vector2(120, 80)
@export var floor_y := 304.0
## Puertas dibujadas (x del centro).
@export var doors: Array[float] = []

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	add_child(_canvas)


func _paint(c: VectorCanvas, _t: float) -> void:
	c.draw_rect(window.grow(4), WOOD_DARK)
	c.gradient_rect(window, GLASS.lightened(0.35), GLASS)
	for k in 3:
		var x := window.position.x + window.size.x * (k + 1) / 4.0
		c.draw_line(Vector2(x, window.position.y), Vector2(x, window.end.y), WOOD_DARK, 2.0)
	c.draw_line(Vector2(window.position.x, window.get_center().y), Vector2(window.end.x, window.get_center().y), WOOD_DARK, 2.0)
	for i in shelves.size():
		_paint_shelf(c, shelves[i], i)
	for x in tables:
		_paint_table(c, x)
	# Mostrador con la computadora de la biblioteca.
	c.gradient_box(counter, 1.0, WOOD, WOOD_DARK)
	var monitor := Rect2(counter.get_center().x - 14, counter.position.y - 22, 28, 20)
	c.gradient_box(monitor, 2.0, Color("3a4152"), Color("252b38"))
	c.draw_rect(monitor.grow(-3), Color("1d3a5a"))
	c.draw_rect(Rect2(monitor.get_center().x - 3, monitor.end.y, 6, 2), Color("252b38"))
	var box := Rect2(sign_center - Vector2(48, 9), Vector2(96, 18))
	c.draw_rect(box.grow(2), WOOD_DARK)
	c.draw_rect(box, SIGN)
	c.crisp_text(Vector2(box.position.x, box.end.y - 5), "BIBLIOTECA", 10, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	for x in doors:
		var door := Rect2(x - 14, floor_y - 64, 28, 64)
		c.draw_rect(door.grow(2), WOOD_DARK)
		c.gradient_rect(door, WOOD.lightened(0.1), WOOD)
		c.draw_rect(Rect2(door.position.x + 6, door.position.y + 8, 16, 14), Color("8ab4e8"))
		c.draw_circle(Vector2(x - 8, floor_y - 32), 2.0, Color("d8c060"))


func _paint_shelf(c: VectorCanvas, rect: Rect2, index: int) -> void:
	c.gradient_box(rect, 1.0, WOOD, WOOD_DARK)
	var rows := maxi(1, int((rect.size.y - 6) / 22.0))
	for r in rows:
		var y := rect.position.y + 5 + r * 22.0
		c.draw_rect(Rect2(rect.position.x + 4, y, rect.size.x - 8, 18), WOOD_DARK.darkened(0.3))
		var x := rect.position.x + 5
		var k := 0
		while x < rect.end.x - 8:
			var width := 4.0 + float((index * 7 + r * 3 + k * 5) % 4)
			var height := 12.0 + float((index * 5 + r * 11 + k * 3) % 6)
			c.draw_rect(Rect2(x, y + 18 - height, width, height), BOOKS[(index * 3 + r * 2 + k) % BOOKS.size()])
			x += width + 1.0
			k += 1


func _paint_table(c: VectorCanvas, x: float) -> void:
	c.gradient_box(Rect2(x - 30, floor_y - 22, 60, 5), 1.0, WOOD, WOOD_DARK)
	c.draw_rect(Rect2(x - 26, floor_y - 17, 3, 17), WOOD_DARK)
	c.draw_rect(Rect2(x + 23, floor_y - 17, 3, 17), WOOD_DARK)
	# Lámpara de lectura y un libro abierto.
	c.draw_line(Vector2(x - 12, floor_y - 22), Vector2(x - 12, floor_y - 36), Color("2c3446"), 2.0)
	c.shape(PackedVector2Array([Vector2(x - 20, floor_y - 34), Vector2(x - 4, floor_y - 34), Vector2(x - 8, floor_y - 42), Vector2(x - 16, floor_y - 42)]), Color("3f8a5a"))
	c.glow(Vector2(x - 12, floor_y - 30), 14.0, Color(1.0, 0.9, 0.6, 0.18))
	c.draw_rect(Rect2(x + 4, floor_y - 25, 14, 3), Color("e8e4d8"))
	for side in [-1, 1]:
		var chair_x: float = x + side * 42
		c.draw_rect(Rect2(chair_x - 8, floor_y - 14, 16, 3), Color("4a3a2c"))
		c.draw_rect(Rect2(chair_x + (6 if side > 0 else -9), floor_y - 28, 3, 15), Color("4a3a2c"))
		c.draw_line(Vector2(chair_x - 7, floor_y - 11), Vector2(chair_x - 7, floor_y), Color("4a3a2c"), 2.0)
		c.draw_line(Vector2(chair_x + 6, floor_y - 11), Vector2(chair_x + 6, floor_y), Color("4a3a2c"), 2.0)
