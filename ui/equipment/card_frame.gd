@tool
extends Control
## Marco de la tarjeta de equipamiento: fondo violeta oscuro, borde lila con brillo, esquinas
## marcadas, un rombo a cada lado y la línea con rombo que separa el nombre de la descripción.

const BACK := Color(0.04, 0.02, 0.09, 0.95)
const EDGE := Color("8f6bff")
const EDGE_LIGHT := Color("cdbcff")
const GLOW := Color(0.55, 0.38, 1.0, 0.35)

## Altura (desde arriba) de la línea separadora.
@export var separator_y := 395.0:
	set(value):
		separator_y = value
		queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	for i in 3:
		draw_rect(rect.grow(4 + i * 4), Color(GLOW, GLOW.a / (i + 1)), false, 4.0)
	draw_rect(rect, BACK)
	draw_rect(rect, EDGE, false, 2.0)
	draw_rect(rect.grow(-6), Color(EDGE, 0.25), false, 1.0)
	# Esquinas.
	var arm := 34.0
	for corner in [Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]:
		var dx := 1.0 if corner.x == 0.0 else -1.0
		var dy := 1.0 if corner.y == 0.0 else -1.0
		draw_line(corner, corner + Vector2(arm * dx, 0), EDGE_LIGHT, 4.0)
		draw_line(corner, corner + Vector2(0, arm * dy), EDGE_LIGHT, 4.0)
	# Rombos a los costados.
	for x in [0.0, size.x]:
		_diamond(Vector2(x, size.y * 0.5), 7.0)
	# Separador.
	var middle := size.x * 0.5
	draw_line(Vector2(60, separator_y), Vector2(middle - 14, separator_y), Color(EDGE, 0.7), 1.0)
	draw_line(Vector2(middle + 14, separator_y), Vector2(size.x - 60, separator_y), Color(EDGE, 0.7), 1.0)
	_diamond(Vector2(middle, separator_y), 6.0)


func _diamond(center: Vector2, radius: float) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0),
		center + Vector2(0, radius), center + Vector2(-radius, 0)]), EDGE_LIGHT)
	var inner := radius * 0.45
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -inner), center + Vector2(inner, 0),
		center + Vector2(0, inner), center + Vector2(-inner, 0)]), BACK)
