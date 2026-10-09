@tool
class_name DialogueFrameArt
extends Control
## Dibuja la caja de diálogo al estilo Hades: marco doble del color del personaje, fondo claro
## como papel y esquinas con detalles de circuito. La caja está inclinada: el lado del retrato
## es más bajo (mirrored = el retrato está a la derecha).

## Color del marco (el del personaje que habla).
@export var accent := Color(0.243, 0.949, 1.0):
	set(value):
		accent = value
		queue_redraw()
@export var mirrored := false:
	set(value):
		mirrored = value
		queue_redraw()
## Cuánto más bajo es el lado del retrato, en píxeles (0 = caja recta, como en la hoja de Ariel).
@export var tilt := 0.0:
	set(value):
		tilt = value
		queue_redraw()

const PAPER_TOP := Color(0.95, 0.94, 0.91)
const PAPER_BOTTOM := Color(0.85, 0.85, 0.83)
const INK := Color(0.07, 0.07, 0.1)


func _ready() -> void:
	resized.connect(queue_redraw)


## Esquinas de la caja: arriba-izq, arriba-der, abajo-der, abajo-izq.
func outline() -> PackedVector2Array:
	var w := size.x
	var h := size.y
	var points := PackedVector2Array([Vector2(0, tilt), Vector2(w, 0), Vector2(w, h), Vector2(0, h - 3)])
	if mirrored:
		points = PackedVector2Array([Vector2(0, 0), Vector2(w, tilt), Vector2(w, h - 3), Vector2(0, h)])
	return points


func _draw() -> void:
	var base := outline()
	var dark := accent.darkened(0.72)
	# Sombra.
	var shadow := PackedVector2Array()
	for point in base:
		shadow.append(point + Vector2(7, 9))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.5))
	# Marco: oscuro, línea de color, oscuro y el papel.
	draw_colored_polygon(base, dark)
	draw_colored_polygon(_inset(base, 4.0), accent)
	draw_colored_polygon(_inset(base, 8.0), dark.darkened(0.3))
	var paper := _inset(base, 11.0)
	var shades := PackedColorArray()
	for point in paper:
		shades.append(PAPER_TOP.lerp(PAPER_BOTTOM, clampf(point.y / size.y, 0.0, 1.0)))
	draw_polygon(paper, shades)
	# Rayones suaves del papel.
	var scratch := Color(INK, 0.05)
	draw_line(Vector2(size.x * 0.18, size.y * 0.78), Vector2(size.x * 0.42, size.y * 0.35), scratch, 2.0)
	draw_line(Vector2(size.x * 0.63, size.y * 0.9), Vector2(size.x * 0.8, size.y * 0.55), scratch, 1.5)
	# Línea fina interior.
	var inner := _inset(base, 17.0)
	inner.append(inner[0])
	draw_polyline(inner, Color(accent.darkened(0.25), 0.55), 1.5, true)
	# Esquinas: corchete de color y rombo.
	for i in base.size():
		var corner := base[i]
		var to_next := (base[(i + 1) % base.size()] - corner).normalized()
		var to_prev := (base[(i + base.size() - 1) % base.size()] - corner).normalized()
		draw_line(corner, corner + to_next * 34.0, accent, 4.0)
		draw_line(corner, corner + to_prev * 34.0, accent, 4.0)
		_draw_diamond(corner, 7.0, accent, dark)
	_draw_flourish(base[0] if mirrored else base[1], -1.0 if mirrored else 1.0, -1.0)
	_draw_flourish(base[2] if mirrored else base[3], 1.0 if mirrored else -1.0, 1.0)


## Adorno por fuera de una esquina (como los dorados de Hades, pero con terminales de circuito).
## out_x / out_y: hacia dónde queda el exterior de esa esquina (1 o -1).
func _draw_flourish(corner: Vector2, out_x: float, out_y: float) -> void:
	var gap := 8.0
	var elbow := corner + Vector2(out_x * gap, out_y * gap)
	var points := PackedVector2Array([elbow + Vector2(-out_x * 90.0, 0), elbow, elbow + Vector2(0, -out_y * 46.0)])
	draw_polyline(points, accent, 2.5)
	draw_line(elbow + Vector2(-out_x * 90.0, out_y * 5.0), elbow + Vector2(-out_x * 30.0, out_y * 5.0), Color(accent, 0.6), 1.5)
	for end in [points[0], points[2]]:
		draw_circle(end, 4.0, accent)
		draw_circle(end, 1.8, accent.darkened(0.72))


func _draw_diamond(center: Vector2, radius: float, fill: Color, border: Color) -> void:
	var points := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0)])
	draw_colored_polygon(points, border)
	draw_colored_polygon(_inset(points, 2.0), fill)


func _inset(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var result := Geometry2D.offset_polygon(points, -amount, Geometry2D.JOIN_MITER)
	return result[0] if not result.is_empty() else points
