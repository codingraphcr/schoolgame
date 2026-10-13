@tool
extends Node2D
## Arte provisional del cuarto viejo (H5), dibujado por código hasta que Ariel lo dibuje: una mesa
## vieja (donde está el Grimorio), un servidor apagado (delante, la Nullblade), monitores rotos,
## sillas y telarañas. Casi todo queda a oscuras: se distingue con la Visión Digital.
## Las posiciones se ajustan en el Inspector. Se ve también en el editor.

const METAL := Color("2c3446")
const METAL_DARK := Color("1a2030")
const WOOD := Color("4a3a2c")
const WEB := Color(0.85, 0.88, 1.0, 0.3)

@export var desk := Rect2(440, 278, 60, 26)
@export var rack := Rect2(584, 214, 52, 90)
@export var monitors: Array[Vector2] = [Vector2(452, 278), Vector2(680, 304)]
@export var chairs: Array[float] = [400.0, 520.0]
@export var webs: Array[Vector2] = [Vector2(0, 48), Vector2(400, 48)]
@export var floor_y := 304.0

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	add_child(_canvas)


func _paint(c: VectorCanvas, _t: float) -> void:
	# Mesa.
	c.gradient_box(Rect2(desk.position, Vector2(desk.size.x, 4)), 1.0, WOOD, WOOD.darkened(0.3))
	c.draw_rect(Rect2(desk.position + Vector2(3, 4), Vector2(3, desk.size.y - 4)), WOOD.darkened(0.3))
	c.draw_rect(Rect2(desk.end.x - 6, desk.position.y + 4, 3, desk.size.y - 4), WOOD.darkened(0.3))
	# Servidor apagado.
	c.gradient_box(rack, 2.0, METAL, METAL_DARK)
	for i in 6:
		var y := rack.position.y + 8 + i * 13
		c.draw_rect(Rect2(rack.position.x + 6, y, rack.size.x - 12, 8), Color("141a26"))
		c.draw_rect(Rect2(rack.end.x - 12, y + 3, 2, 2), Color("3a2020"))
	for pos in monitors:
		_paint_monitor(c, pos)
	for x in chairs:
		var color := Color("333a4e")
		c.draw_rect(Rect2(x - 9, floor_y - 16, 18, 3), color)
		c.draw_rect(Rect2(x - 9, floor_y - 30, 3, 17), color)
		c.draw_line(Vector2(x - 8, floor_y - 13), Vector2(x - 8, floor_y), color, 2.0)
		c.draw_line(Vector2(x + 7, floor_y - 13), Vector2(x + 7, floor_y), color, 2.0)
	for corner in webs:
		for i in 4:
			c.draw_arc(corner, 8.0 + i * 7.0, 0.0, PI / 2.0, 8, WEB, 0.6, true)
		for a in [0.15, 0.55, 0.95, 1.35]:
			c.draw_line(corner, corner + Vector2.from_angle(a) * 32.0, WEB, 0.6, true)


## Monitor viejo de tubo, con la pantalla rajada. pos = centro de la base.
func _paint_monitor(c: VectorCanvas, pos: Vector2) -> void:
	var box := Rect2(pos + Vector2(-12, -22), Vector2(24, 20))
	c.gradient_box(box, 2.0, Color("3a4152"), Color("252b38"))
	var screen := box.grow(-3)
	c.draw_rect(screen, Color("0b0f18"))
	c.draw_polyline(PackedVector2Array([screen.position + Vector2(4, 1), screen.position + Vector2(8, 7), screen.position + Vector2(6, 12)]), Color(0.5, 0.6, 0.75, 0.5), 0.8)
	c.draw_rect(Rect2(pos + Vector2(-5, -2), Vector2(10, 2)), Color("252b38"))
