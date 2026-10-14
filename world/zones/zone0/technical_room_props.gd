@tool
extends Node2D
## Arte provisional del cuarto técnico del colegio (Capítulo 1), dibujado por código hasta que Ariel
## lo dibuje: racks de servidores con luces que parpadean, bandejas de cables, el aire acondicionado,
## el servidor del sistema de entrenamiento (en rojo mientras Chip y Glitch andan sueltos) con su
## monitor, un extintor, la puerta y el cartel «SOLO PERSONAL AUTORIZADO». Se ve también en el editor.

const METAL := Color("2c3446")
const METAL_DARK := Color("1a2030")
const LED_OK := Color("3ef28a")
const LED_BUSY := Color("3ef2ff")
const LED_ALERT := Color("ff4a5a")
const SIGN := Color("c8a040")
const DOOR := Color("4a5470")

## Racks comunes (rectángulo completo).
@export var racks: Array[Rect2] = []
## El servidor del sistema de entrenamiento.
@export var training_server := Rect2(330, 196, 70, 108)
## Centro de su monitor (ahí va la conexión de la Inmersión Digital).
@export var monitor_center := Vector2(470, 252)
## Si el servidor de entrenamiento está fallando (luces rojas y la pantalla con error).
@export var alert := true
@export var door_x := 624.0
@export var floor_y := 304.0

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)


func _paint(c: VectorCanvas, t: float) -> void:
	# Bandeja de cables en el techo y cables que bajan a los racks.
	c.draw_rect(Rect2(0, 70, door_x - 20, 6), METAL)
	for i in racks.size():
		var x := racks[i].get_center().x
		c.draw_line(Vector2(x - 6, 76), Vector2(x - 6, racks[i].position.y), Color("1f6f5a"), 2.0)
		c.draw_line(Vector2(x + 4, 76), Vector2(x + 4, racks[i].position.y), Color("6a4ab8"), 2.0)
	# Aire acondicionado.
	var ac := Rect2(40, 96, 90, 34)
	c.gradient_box(ac, 2.0, Color("c8ccd8"), Color("8a90a0"))
	for k in 6:
		c.draw_line(Vector2(ac.position.x + 8, ac.position.y + 8 + k * 4), Vector2(ac.end.x - 8, ac.position.y + 8 + k * 4), Color("6a7080"), 1.0)
	for i in racks.size():
		_paint_rack(c, racks[i], t, i, false)
	_paint_rack(c, training_server, t, 99, alert)
	var sign := Rect2(training_server.position.x - 10, training_server.position.y - 34, 96, 22)
	c.draw_rect(sign, Color("101626"))
	c.crisp_text(Vector2(sign.position.x, sign.position.y + 9), "SISTEMA DE", 6, Color(0.85, 0.9, 1), HORIZONTAL_ALIGNMENT_CENTER, sign.size.x)
	c.crisp_text(Vector2(sign.position.x, sign.position.y + 18), "ENTRENAMIENTO", 6, Color(0.85, 0.9, 1), HORIZONTAL_ALIGNMENT_CENTER, sign.size.x)
	_paint_monitor(c, t)
	# Extintor.
	c.gradient_box(Rect2(560, floor_y - 30, 12, 30), 3.0, Color("e04040"), Color("a02020"))
	c.draw_rect(Rect2(563, floor_y - 36, 6, 6), Color("2c2c2c"))
	# Puerta y cartel.
	var door := Rect2(door_x - 14, floor_y - 64, 28, 64)
	c.draw_rect(door.grow(2), METAL_DARK)
	c.gradient_rect(door, DOOR.lightened(0.1), DOOR)
	c.draw_circle(Vector2(door_x - 8, floor_y - 32), 2.0, Color("d8c060"))
	var warning := Rect2(door_x - 74, floor_y - 108, 64, 30)
	c.draw_rect(warning, SIGN)
	c.crisp_text(Vector2(warning.position.x, warning.position.y + 11), "SOLO PERSONAL", 5, Color("201a10"), HORIZONTAL_ALIGNMENT_CENTER, warning.size.x)
	c.crisp_text(Vector2(warning.position.x, warning.position.y + 22), "AUTORIZADO", 5, Color("201a10"), HORIZONTAL_ALIGNMENT_CENTER, warning.size.x)


func _paint_rack(c: VectorCanvas, rack: Rect2, t: float, seed_value: int, failing: bool) -> void:
	c.gradient_box(rack, 2.0, METAL, METAL_DARK)
	var rows := int((rack.size.y - 8) / 12.0)
	for r in rows:
		var y := rack.position.y + 5 + r * 12.0
		c.draw_rect(Rect2(rack.position.x + 5, y, rack.size.x - 10, 8), Color("141a26"))
		for k in 3:
			var blink := sin(t * (2.0 + float((seed_value * 7 + r * 3 + k) % 5)) + r + k) > 0.2
			var color := LED_ALERT if failing else (LED_OK if k == 0 else LED_BUSY)
			if failing and fmod(t * 3.0 + r * 0.3, 1.0) < 0.5:
				color = Color(color, 0.3)
			elif not failing and not blink:
				color = Color(color, 0.25)
			c.draw_rect(Rect2(rack.end.x - 10 - k * 5, y + 3, 2, 2), color)


## Monitor del servidor de entrenamiento: con error mientras está en alerta.
func _paint_monitor(c: VectorCanvas, t: float) -> void:
	var screen := Rect2(monitor_center - Vector2(22, 15), Vector2(44, 30))
	c.draw_rect(Rect2(monitor_center.x - 3, screen.end.y, 6, floor_y - screen.end.y - 26), METAL)
	c.gradient_box(Rect2(monitor_center.x - 30, floor_y - 26, 60, 26), 1.0, Color("4a3a2c"), Color("2e241c"))
	c.draw_rect(screen.grow(3), Color("252b38"))
	if alert:
		var flicker := 0.7 + 0.3 * sin(t * 9.0)
		c.draw_rect(screen, Color(0.35 * flicker, 0.04, 0.08))
		c.crisp_text(Vector2(screen.position.x, screen.position.y + 13), "ERROR", 7, Color(1, 0.6, 0.6), HORIZONTAL_ALIGNMENT_CENTER, screen.size.x)
		c.crisp_text(Vector2(screen.position.x, screen.position.y + 23), "0x0C1G", 5, Color(1, 0.5, 0.5, 0.8), HORIZONTAL_ALIGNMENT_CENTER, screen.size.x)
	else:
		c.draw_rect(screen, Color("1d3a5a"))
