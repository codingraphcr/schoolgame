class_name ConvergenceChamber
extends Node2D
## Cámara de convergencia: el fondo de la arena de Glitch y Chip, el dibujo de Ariel
## (docs/arte/referencias/camara_convergencia_fondo.webp, en pixel art con tools/art/generar_fondo_arena.gd
## → assets/art/backgrounds/camara_convergencia.png): columnas, la sala profunda, el piso y las tres
## plataformas (las de verdad están en el mismo lugar y no se dibujan) y el gran anillo con el rombo. El
## anillo empieza apagado; en la Fase 2 (Sincronización) se activa: se enciende, gira una corona de luces
## y baja un haz de luz.

const PINK := Color("ff4fb4")
const BLUE := Color("4fa8ff")
const VIOLET := Color("7a4fd0")
const DARK := Color("0a0718")

@export var texture: Texture2D = preload("res://assets/art/backgrounds/camara_convergencia.png")
## Dónde se dibuja el fondo (el piso del dibujo queda en y = 304, el de la arena).
@export var area := Rect2(0, -7, 640, 376)
## El anillo del dibujo (centro y radio, en la arena).
@export var ring_center := Vector2(321, 113)
@export var ring_radius := 76.0
## El anillo encendido (Fase 2 en adelante).
var active := false

var _time := 0.0
var _power := 0.0


func _process(delta: float) -> void:
	_time += delta
	_power = move_toward(_power, 1.0 if active else 0.0, delta * 0.8)
	queue_redraw()


func _draw() -> void:
	if texture:
		draw_texture_rect(texture, area, false)
	# Apagado: una banda oscura tapa el neón del anillo (se va al encenderse).
	var dim := 1.0 - _power
	if dim > 0.0:
		draw_arc(ring_center, ring_radius, 0.0, TAU, 72, Color(DARK, 0.72 * dim), 14.0)
		draw_circle(ring_center, 9.0, Color(DARK, 0.6 * dim))
	if _power <= 0.0:
		return
	# Encendido: brillo que late, una corona de luces que gira y el haz que baja a la arena.
	var pulse := 0.75 + 0.25 * sin(_time * 4.0)
	draw_arc(ring_center, ring_radius + 6.0, 0.0, TAU, 72, Color(VIOLET, 0.18 * _power * pulse), 10.0)
	var spin := _time * 1.2
	draw_arc(ring_center, ring_radius, spin, spin + PI, 40, Color(PINK, 0.5 * _power * pulse), 3.0)
	draw_arc(ring_center, ring_radius, spin + PI, spin + TAU, 40, Color(BLUE, 0.5 * _power * pulse), 3.0)
	for k in 12:
		var p := ring_center + Vector2.from_angle(spin * 0.5 + k * TAU / 12.0) * (ring_radius + 12.0)
		draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color(PINK if k % 2 == 0 else BLUE, 0.7 * _power))
	var beam := Rect2(ring_center.x - 9.0, ring_center.y + ring_radius - 6.0, 18.0, 304.0 - ring_center.y - ring_radius + 6.0)
	draw_rect(beam, Color(VIOLET, 0.14 * _power * pulse))
	draw_rect(beam.grow_individual(-6.0, 0.0, -6.0, 0.0), Color(Color.WHITE, 0.1 * _power))
	draw_circle(ring_center, 6.0, Color(BLUE.lerp(PINK, 0.5 + 0.5 * sin(_time * 3.0)), 0.6 * _power))
