@tool
extends Node2D
## Arte provisional de las escaleras del colegio (M3), dibujado por código hasta que Ariel lo dibuje:
## los descansos (las plataformas donde se para Kai), los tramos de escalera entre ellos, la baranda,
## una ventana por piso y los carteles de cada piso. Las posiciones se ajustan en el Inspector y
## deben coincidir con las colisiones (Collisions/Landing*). Se ve también en el editor.

const CONCRETE := Color("5a6274")
const CONCRETE_DARK := Color("3a4152")
const RAIL := Color("8a96b8")
const GLASS := Color("2a4a7a")
const SIGN := Color("1f6f5a")

## Descansos de la escalera (rectángulos de las plataformas, arriba = donde pisa Kai).
@export var landings: Array[Rect2] = []
## Ventanas (una por piso).
@export var windows: Array[Rect2] = []
## Carteles: posición (centro) → texto.
@export var signs: Dictionary = {}

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	add_child(_canvas)


func _paint(c: VectorCanvas, _t: float) -> void:
	for window in windows:
		c.draw_rect(window.grow(3), CONCRETE_DARK)
		c.gradient_rect(window, GLASS.lightened(0.2), GLASS)
		c.draw_line(Vector2(window.get_center().x, window.position.y), Vector2(window.get_center().x, window.end.y), CONCRETE_DARK, 2.0)
		c.draw_line(Vector2(window.position.x, window.get_center().y), Vector2(window.end.x, window.get_center().y), CONCRETE_DARK, 2.0)
	# Tramos: de cada descanso al siguiente, una franja de escalones en diagonal.
	for i in landings.size() - 1:
		_paint_flight(c, landings[i], landings[i + 1])
	for landing in landings:
		c.gradient_box(landing, 1.0, CONCRETE, CONCRETE_DARK)
		c.draw_line(landing.position + Vector2(0, -14), Vector2(landing.end.x, landing.position.y - 14), RAIL, 1.0)
		for k in int(landing.size.x / 24.0) + 1:
			var x := minf(landing.position.x + k * 24.0, landing.end.x)
			c.draw_line(Vector2(x, landing.position.y - 14), Vector2(x, landing.position.y), RAIL, 1.0)
	for pos: Vector2 in signs:
		var text := String(signs[pos])
		var box := Rect2(pos - Vector2(text.length() * 3.0 + 6, 7), Vector2(text.length() * 6.0 + 12, 14))
		c.draw_rect(box, SIGN)
		c.crisp_text(Vector2(box.position.x, box.end.y - 4), text, 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, box.size.x)


## Escalones entre dos descansos (solo dibujo: Kai sube saltando de descanso en descanso).
func _paint_flight(c: VectorCanvas, from: Rect2, to: Rect2) -> void:
	var start := Vector2(from.end.x if to.position.x > from.position.x else from.position.x, from.position.y)
	var finish := Vector2(to.position.x if to.position.x > from.position.x else to.end.x, to.position.y)
	var steps := 6
	for k in steps:
		var a := start.lerp(finish, float(k) / steps)
		var b := start.lerp(finish, float(k + 1) / steps)
		c.draw_rect(Rect2(Vector2(minf(a.x, b.x), b.y), Vector2(absf(b.x - a.x) + 1.0, a.y - b.y + 4.0)), CONCRETE_DARK.darkened(0.2))
	c.draw_line(start + Vector2(0, -14), finish + Vector2(0, -14), RAIL, 1.0)
