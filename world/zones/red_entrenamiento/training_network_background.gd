@tool
extends Node2D
## Fondo de la red de entrenamiento del colegio (la persecución digital del Capítulo 1), dibujado por
## código hasta que Ariel lo dibuje: un vacío azul oscuro con cuadrícula, torres de datos a lo lejos,
## cables de luz y los carteles de cada tramo. Casi todo es fijo; solo los datos que suben se mueven.

const SKY_TOP := Color("040816")
const SKY_BOTTOM := Color("0c1430")
const GRID := Color(0.24, 0.6, 1.0, 0.07)
const TOWER := Color("101c3a")
const TOWER_EDGE := Color(0.24, 0.95, 1.0, 0.18)
const SIGN := Color("3ef2ff")

@export var area := Rect2(0, 0, 4800, 360)
## Carteles: x → texto (arriba, a lo lejos).
@export var signs: Dictionary = {}

var _time := 0.0
## Los datos que suben se dibujan aparte: el resto del fondo no se redibuja en cada cuadro.
var _rain: Node2D


func _ready() -> void:
	z_index = -10
	_rain = Node2D.new()
	_rain.draw.connect(_draw_rain)
	add_child(_rain)
	set_process(not Engine.is_editor_hint())


func _process(delta: float) -> void:
	_time += delta
	_rain.queue_redraw()


func _draw() -> void:
	var steps := 12
	for i in steps:
		var band := Rect2(area.position.x, area.position.y + area.size.y * i / steps, area.size.x, area.size.y / steps + 1.0)
		draw_rect(band, SKY_TOP.lerp(SKY_BOTTOM, float(i) / steps))
	var x := area.position.x
	while x < area.end.x:
		draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), GRID, 1.0)
		x += 32.0
	var y := area.position.y
	while y < area.end.y:
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), GRID, 1.0)
		y += 32.0
	# Torres de datos a lo lejos (siempre iguales: dependen de la posición).
	var tx := area.position.x + 20.0
	var k := 0
	while tx < area.end.x:
		var h := 80.0 + float((k * 53) % 140)
		var w := 30.0 + float((k * 17) % 26)
		var tower := Rect2(tx, area.end.y - 60.0 - h, w, h)
		draw_rect(tower, TOWER)
		draw_rect(tower, TOWER_EDGE, false, 1.0)
		for r in int(h / 14.0):
			if (r + k) % 3 != 0:
				draw_rect(Rect2(tx + 5, tower.position.y + 6 + r * 14.0, w - 10, 3), Color(0.24, 0.95, 1.0, 0.07))
		tx += w + 40.0 + float((k * 29) % 70)
		k += 1
	var font := ThemeDB.fallback_font
	for sign_x: float in signs:
		draw_string(font, Vector2(sign_x, area.position.y + 44.0), String(signs[sign_x]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(SIGN, 0.55))


func _draw_rain() -> void:
	for i in int(area.size.x / 90.0):
		var px := area.position.x + i * 90.0 + float((i * 37) % 60)
		var py := area.end.y - fmod(_time * (18.0 + (i % 5) * 6.0) + i * 41.0, area.size.y)
		_rain.draw_rect(Rect2(px, py, 2, 6), Color(0.24, 0.95, 1.0, 0.25))
