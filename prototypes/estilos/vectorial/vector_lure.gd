extends VectorCanvas
## El Anzuelo en estilo vectorial, dibujado alrededor de su origen (centro del sobre).
## Lo usan las muestras E (huesos pixelados) y F (personajes vectoriales).

const PAPER := Color("e9dfc6")
const PAPER_D := Color("b8ab8c")
const MET_L := Color("8b98b8")
const CYAN := Color("3ef2ff")
const MAG := Color("ff3ea5")


func _init() -> void:
	painter = _paint
	animated = true


func _paint(c: VectorCanvas, t: float) -> void:
	# Anzuelo.
	c.draw_line(Vector2(0, -15), Vector2(0, -8), MET_L, 1.1, true)
	c.draw_arc(Vector2(-2.2, -8), 2.2, 0.0, PI, 10, MET_L, 1.1, true)
	c.draw_line(Vector2(-4.4, -8), Vector2(-3.6, -10), MET_L, 1.0, true)
	# Tentáculos de corrupción.
	for i in 3:
		var root := Vector2(-6 + i * 6, 6)
		var points := PackedVector2Array()
		for k in 7:
			points.append(root + Vector2(sin(t * 3.0 + i * 2.0 + k * 0.7) * 1.6, k * 1.6))
		for k in points.size() - 1:
			c.draw_line(points[k], points[k + 1], Color(MAG, 1.0 - k / 7.0), lerpf(1.6, 0.4, k / 6.0), true)
	# Sobre.
	var envelope := Rect2(Vector2(-9, -6), Vector2(18, 12))
	c.gradient_box(envelope, 1.5, PAPER, PAPER_D)
	c.draw_polyline(PackedVector2Array([envelope.position + Vector2(0.5, 0.5), Vector2(0, 0.5), Vector2(envelope.end.x - 0.5, envelope.position.y + 0.5)]),
		PAPER_D.darkened(0.2), 0.8, true)
	c.draw_circle(Vector2(0, 0.5), 1.8, MAG)
	var blink := 0.3 if fmod(t, 3.0) < 0.12 else 1.0
	for side in [-1, 1]:
		var eye := Vector2(side * 4.5, 3.2)
		c.draw_line(eye - Vector2(1.2, 0), eye + Vector2(1.2, 0), Color(MAG, blink), 1.0, true)
	# Fallo visual intermitente.
	if int(t * 6.0) % 5 == 0:
		c.draw_rect(Rect2(envelope.position + Vector2(3, 3), Vector2(18, 2)), Color(PAPER, 0.85))
		c.draw_rect(Rect2(envelope.position + Vector2(-2, 7), Vector2(14, 1)), Color(CYAN, 0.8))
		c.draw_rect(Rect2(envelope.position + Vector2(5, 4.5), Vector2(10, 1)), Color(MAG, 0.9))
