class_name VectorCanvas
extends Node2D
## Nodo que se dibuja con una función (painter) y utilidades de dibujo vectorial:
## formas redondeadas, degradados, contornos suaves y halos de luz.

## Función que dibuja: func(canvas: VectorCanvas, time: float)
var painter: Callable
## Si es true, se redibuja cada cuadro (objetos animados).
var animated := false:
	set(value):
		animated = value
		set_process(value)
var time := 0.0


func _ready() -> void:
	set_process(animated)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	if painter.is_valid():
		painter.call(self, time)


# --- Utilidades ---

const OUTLINE := Color(0.03, 0.04, 0.09)


## Puntos de un rectángulo con esquinas redondeadas.
static func rounded_rect(rect: Rect2, radius: float, segments := 4) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var points := PackedVector2Array()
	var corners: Array[Vector2] = [
		Vector2(rect.end.x - r, rect.position.y + r),
		Vector2(rect.end.x - r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.position.y + r),
	]
	for c in 4:
		var start := -PI / 2.0 + c * PI / 2.0
		for s in segments + 1:
			var angle := start + (PI / 2.0) * s / segments
			points.append(corners[c] + Vector2(cos(angle), sin(angle)) * r)
	return points


## Polígono relleno con contorno antialiasado.
func shape(points: PackedVector2Array, fill: Color, outline := OUTLINE, width := 0.8) -> void:
	draw_colored_polygon(points, fill)
	if width > 0.0:
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, outline, width, true)


## Rectángulo redondeado con degradado vertical y contorno.
func gradient_box(rect: Rect2, radius: float, top: Color, bottom: Color, outline := OUTLINE, width := 0.8) -> void:
	var points := rounded_rect(rect, radius)
	var colors := PackedColorArray()
	for p in points:
		colors.append(top.lerp(bottom, clampf((p.y - rect.position.y) / rect.size.y, 0.0, 1.0)))
	draw_polygon(points, colors)
	if width > 0.0:
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, outline, width, true)


## Rectángulo con degradado vertical, sin contorno (fondos).
func gradient_rect(rect: Rect2, top: Color, bottom: Color) -> void:
	draw_polygon(
		PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


## Halo de luz suave.
func glow(center: Vector2, radius: float, color: Color, steps := 8) -> void:
	var c := color
	c.a = color.a / steps
	for i in steps:
		draw_circle(center, radius * (1.0 - float(i) / steps), c)


## Curva cuadrática (para cables que cuelgan).
static func sag_curve(from: Vector2, to: Vector2, sag: float, segments := 16) -> PackedVector2Array:
	var points := PackedVector2Array()
	var control := (from + to) * 0.5 + Vector2(0, sag * 2.0)
	for i in segments + 1:
		var t := float(i) / segments
		points.append(from.lerp(control, t).lerp(control.lerp(to, t), t))
	return points


## Texto nítido aunque la cámara tenga zoom ×2 (se dibuja al doble de resolución).
func crisp_text(pos: Vector2, text: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_CENTER, width := -1.0) -> void:
	draw_set_transform(pos, 0.0, Vector2(0.5, 0.5))
	draw_string(ThemeDB.fallback_font, Vector2.ZERO, text, align, width * 2.0 if width > 0.0 else -1.0, size * 2, color)
	draw_set_transform(Vector2.ZERO)
