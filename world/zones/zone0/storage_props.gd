@tool
extends Node2D
## Arte provisional del depósito del colegio (sala opcional del generador, M4), dibujado por código
## hasta que Ariel lo dibuje: cajas apiladas (las de arriba sirven de plataforma: deben coincidir con
## Collisions/Box*), un estante con rollos de cable, monitores viejos y la puerta. Se ve también en el
## editor.

const CARDBOARD := Color("8a6a44")
const CARDBOARD_DARK := Color("5e4630")
const METAL := Color("4a5470")
const DOOR := Color("5a4030")

## Cajas (rectángulo completo).
@export var boxes: Array[Rect2] = []
@export var rack := Rect2(420, 180, 120, 124)
@export var door_x := 16.0
@export var floor_y := 304.0

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	add_child(_canvas)


func _paint(c: VectorCanvas, _t: float) -> void:
	# Estante metálico con cables y monitores viejos.
	c.draw_rect(Rect2(rack.position.x, rack.position.y, 4, rack.size.y), METAL)
	c.draw_rect(Rect2(rack.end.x - 4, rack.position.y, 4, rack.size.y), METAL)
	for k in 3:
		var y := rack.position.y + 20 + k * 40.0
		c.draw_rect(Rect2(rack.position.x, y, rack.size.x, 3), METAL)
		for i in 3:
			var center := Vector2(rack.position.x + 22 + i * 38, y - 9)
			if k == 1:
				c.gradient_box(Rect2(center - Vector2(13, 10), Vector2(26, 19)), 2.0, Color("3a4152"), Color("252b38"))
			else:
				c.draw_arc(center, 8.0, 0.0, TAU, 14, Color("2e8a6a") if (i + k) % 2 == 0 else Color("c8a040"), 3.0)
	for box in boxes:
		c.gradient_box(box, 1.0, CARDBOARD, CARDBOARD_DARK)
		c.draw_line(Vector2(box.get_center().x, box.position.y), Vector2(box.get_center().x, box.position.y + 10), Color("c8b080"), 3.0)
	var rect := Rect2(door_x - 14, floor_y - 64, 28, 64)
	c.draw_rect(rect.grow(2), CARDBOARD_DARK.darkened(0.3))
	c.gradient_rect(rect, DOOR.lightened(0.1), DOOR)
	c.draw_circle(Vector2(door_x + 8, floor_y - 32), 2.0, Color("d8c060"))
