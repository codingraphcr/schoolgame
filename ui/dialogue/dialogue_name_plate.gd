@tool
class_name DialogueNamePlate
extends PanelContainer
## Placa con el nombre y el título al estilo Hades: oscura, inclinada, con bordes del color del
## personaje y un emblema hexagonal (como los escudos de vida) del lado del retrato.
## mirrored = el retrato está a la derecha (el emblema va a la derecha).

@export var accent := Color(0.243, 0.949, 1.0):
	set(value):
		accent = value
		queue_redraw()
@export var mirrored := false:
	set(value):
		mirrored = value
		_update_margins()
		queue_redraw()

const SKEW := 14.0
const EMBLEM_SPACE := 46.0
const PLATE_TOP := Color(0.13, 0.13, 0.16)
const PLATE_BOTTOM := Color(0.06, 0.06, 0.08)


func _ready() -> void:
	resized.connect(queue_redraw)
	_update_margins()


func _update_margins() -> void:
	var style := StyleBoxEmpty.new()
	style.content_margin_top = 8.0
	style.content_margin_bottom = 10.0
	style.content_margin_left = 30.0 if mirrored else EMBLEM_SPACE + 10.0
	style.content_margin_right = EMBLEM_SPACE + 10.0 if mirrored else 34.0
	add_theme_stylebox_override(&"panel", style)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var dark := accent.darkened(0.72)
	# Placa inclinada (paralelogramo), con un borde grueso de color detrás que hace de canto.
	var plate := PackedVector2Array([Vector2(SKEW, 0), Vector2(w, 0), Vector2(w - SKEW, h), Vector2(0, h)])
	if mirrored:
		plate = PackedVector2Array([Vector2(0, 0), Vector2(w - SKEW, 0), Vector2(w, h), Vector2(SKEW, h)])
	var edge := PackedVector2Array()
	for point in plate:
		edge.append(point + Vector2(-5 if mirrored else 5, 5))
	draw_colored_polygon(edge, dark)
	draw_polygon(plate, PackedColorArray([PLATE_TOP, PLATE_TOP, PLATE_BOTTOM, PLATE_BOTTOM]))
	# Borde fino de color alrededor, más grueso arriba y en el lado de afuera.
	var outline := plate.duplicate()
	outline.append(plate[0])
	draw_polyline(outline, accent, 2.0)
	draw_line(plate[0], plate[1], accent, 3.0)
	if mirrored:
		draw_line(plate[0], plate[3], accent, 3.0)
	else:
		draw_line(plate[1], plate[2], accent, 3.0)
	# Terminal de circuito en la punta de afuera (como en la hoja de Ariel).
	var tip := plate[3] if mirrored else plate[2]
	var away := -1.0 if mirrored else 1.0
	var trace := PackedVector2Array([tip + Vector2(away * 4.0, -6.0), tip + Vector2(away * 14.0, -6.0), tip + Vector2(away * 22.0, 2.0)])
	draw_polyline(trace, accent, 2.0)
	draw_circle(trace[2], 3.5, accent)
	draw_circle(trace[2], 1.5, PLATE_BOTTOM)
	# Emblema hexagonal.
	var center := Vector2(w - EMBLEM_SPACE * 0.5 - 4.0, h * 0.5) if mirrored else Vector2(EMBLEM_SPACE * 0.5 + 4.0, h * 0.5)
	var radius := minf(h * 0.62, 30.0)
	draw_colored_polygon(_hexagon(center + Vector2(0, 3), radius), Color(0, 0, 0, 0.5))
	draw_colored_polygon(_hexagon(center, radius), accent)
	draw_colored_polygon(_hexagon(center, radius - 4.0), PLATE_BOTTOM)
	draw_colored_polygon(_hexagon(center, radius * 0.42), accent)
	draw_colored_polygon(_hexagon(center, radius * 0.42 - 3.0), dark)


func _hexagon(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 6:
		var angle := TAU * i / 6.0 - PI / 2.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points
