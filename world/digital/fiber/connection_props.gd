@tool
extends Node2D
## Arte provisional de una conexión dañada de la red del colegio (Capítulo 3, la conexión del equipo 7): un túnel de
## datos oscuro, con conductos por donde corren paquetes y rastros oscuros (lo que daña los archivos) que van y vienen.
## Al fondo, abajo, un conducto que se pierde (por ahí cae Kai). Dibujado por código hasta que Ariel lo dibuje.

const DARK := Color("0a0818")
const TUNNEL := Color("140f2a")
const LINE := Color("2a2550")
const CYAN := Color("3ef2ff")
const RED := Color("ff4a6a")

@export var width := 1280.0
@export var floor_y := 304.0
## Dónde está el hueco del conducto (x de inicio y ancho), sin piso.
@export var pit := Vector2(1000, 180)

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)


func _paint(c: VectorCanvas, t: float) -> void:
	c.gradient_rect(Rect2(0, 0, width, 420), TUNNEL, DARK)
	# Conductos horizontales con paquetes y rastros oscuros.
	for row in 5:
		var y := 40.0 + row * 48.0
		c.draw_line(Vector2(0, y), Vector2(width, y), LINE, 2.0)
		for k in 6:
			var x := fmod(t * (60.0 + row * 12.0) + k * 230.0 + row * 70.0, width + 40.0) - 20.0
			c.draw_circle(Vector2(x, y), 2.5, Color(CYAN, 0.6))
		for k in 2:
			var x := fmod(-t * 40.0 + k * 520.0 + row * 150.0, width + 60.0)
			if x < 0:
				x += width + 60.0
			c.draw_circle(Vector2(x, y), 6.0, Color(0.1, 0.02, 0.12, 0.95))
			c.draw_arc(Vector2(x, y), 6.0, 0.0, TAU, 12, Color(RED, 0.7), 1.2)
	# Columnas de datos.
	var cx := 120.0
	while cx < width:
		c.draw_line(Vector2(cx, 0), Vector2(cx, floor_y), Color(LINE, 0.6), 1.0)
		cx += 160.0
	# El conducto del fondo: un pozo que se pierde hacia abajo.
	var mouth := Rect2(pit.x, floor_y - 4, pit.y, 120)
	c.gradient_rect(mouth, Color(0.05, 0.03, 0.1), Color(0, 0, 0))
	for k in 6:
		var y := floor_y + fmod(t * 80.0 + k * 20.0, 110.0)
		c.draw_line(Vector2(pit.x + 10, y), Vector2(pit.x + pit.y - 10, y), Color(CYAN, 0.12), 1.0)
	c.crisp_text(Vector2(pit.x, floor_y - 120), "CONDUCTO SIN RUTA", 8, Color(RED, 0.8), HORIZONTAL_ALIGNMENT_CENTER, pit.y)
