class_name ConvergenceChamber
extends Node2D
## Cámara de convergencia: el fondo de la arena de Glitch y Chip (hoja de Ariel, «Escenario»). Columnas
## a los costados, luces rosas y azules y un gran anillo con un rombo en el centro. En la Fase 2
## (Sincronización) el anillo se activa: gira, se enciende mitad rosa y mitad azul y baja un haz de luz.
## Es hijo del fondo de la sala: se dibuja sobre la red de entrenamiento y detrás de todo lo demás.

const PINK := Color("ff4fb4")
const BLUE := Color("4fa8ff")
const VIOLET := Color("7a4fd0")
const DARK := Color("120a24")

## Tamaño de la arena (en píxeles del mundo).
@export var area := Rect2(0, 0, 640, 360)
@export var ring_center := Vector2(320, 120)
@export var ring_radius := 86.0
## El anillo encendido (Fase 2 en adelante).
var active := false

var _time := 0.0
var _power := 0.0


func _process(delta: float) -> void:
	_time += delta
	_power = move_toward(_power, 1.0 if active else 0.0, delta * 0.8)
	queue_redraw()


func _draw() -> void:
	# Columnas a los costados, con luces que suben.
	for column: Vector2 in [Vector2(70, 46), Vector2(570, 46)]:
		var rect := Rect2(column.x - column.y / 2.0, area.position.y + 40.0, column.y, area.size.y - 96.0)
		draw_rect(rect, Color(DARK, 0.85))
		draw_rect(rect, Color(VIOLET, 0.5), false, 1.0)
		var light := PINK if column.x < 320.0 else BLUE
		for k in 4:
			var y := rect.end.y - fposmod(_time * 24.0 + k * 50.0, rect.size.y)
			draw_rect(Rect2(rect.position.x + 6, y, rect.size.x - 12, 2), Color(light, 0.25 + 0.35 * _power))
		draw_line(Vector2(rect.get_center().x, rect.position.y), Vector2(rect.get_center().x, rect.end.y), Color(light, 0.2 + 0.4 * _power), 1.0)
	# El anillo: apagado es un aro violeta tenue; encendido gira, mitad rosa y mitad azul.
	var spin := _time * (0.2 + 0.8 * _power)
	draw_arc(ring_center, ring_radius, 0.0, TAU, 64, Color(VIOLET, 0.35), 2.0)
	if _power > 0.0:
		draw_circle(ring_center, ring_radius + 14.0, Color(VIOLET, 0.06 * _power))
		draw_arc(ring_center, ring_radius, spin, spin + PI, 40, Color(PINK, 0.85 * _power), 3.0)
		draw_arc(ring_center, ring_radius, spin + PI, spin + TAU, 40, Color(BLUE, 0.85 * _power), 3.0)
		# Haz de luz que baja del anillo a la arena.
		var beam := Rect2(ring_center.x - 10.0, ring_center.y + 20.0, 20.0, area.end.y - ring_center.y - 76.0)
		draw_rect(beam, Color(VIOLET, 0.12 * _power))
		draw_rect(beam.grow_individual(-7.0, 0.0, -7.0, 0.0), Color(Color.WHITE, 0.08 * _power))
	for k in 12:
		var angle := spin * 0.5 + k * TAU / 12.0
		var p := ring_center + Vector2.from_angle(angle) * (ring_radius + 10.0)
		draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color(PINK if k % 2 == 0 else BLUE, 0.25 + 0.6 * _power))
	# El rombo del centro.
	var size := 18.0 + 3.0 * sin(_time * 2.0) * _power
	var diamond := PackedVector2Array([ring_center + Vector2(0, -size), ring_center + Vector2(size, 0), ring_center + Vector2(0, size), ring_center + Vector2(-size, 0)])
	draw_colored_polygon(diamond, Color(DARK, 0.9))
	draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color(VIOLET.lerp(Color.WHITE, 0.4 * _power), 0.6 + 0.4 * _power), 1.5)
	draw_circle(ring_center, 3.0 + 2.0 * _power, Color(PINK.lerp(BLUE, 0.5 + 0.5 * sin(_time * 3.0)), 0.5 + 0.5 * _power))
