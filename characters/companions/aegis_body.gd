@tool
class_name AegisBody
extends Node2D
## El dibujo de Aegis (provisional, por código, hasta que Ariel lo dibuje): una esfera robótica pequeña, blanca y azul,
## con un único ojo expresivo de luz cian. Se expresa con parpadeos, inclinaciones y movimientos (no habla con la
## cara). Estados: DANADO (apagado, en el piso, el ojo titila), FLOTANDO (sube y baja suave) y SIGUIENDO (lo mueve
## AegisCompanion). look_dir: hacia dónde mira el ojo. El origen es el centro de la esfera.

enum Mood { DANADO, FLOTANDO }

const SHELL := Color("eef3fa")
const SHELL_DARK := Color("b8c4d6")
const BLUE := Color("3a7adf")
const CYAN := Color("3ef2ff")

@export var mood := Mood.FLOTANDO
@export var radius := 10.0
@export var look_dir := Vector2.RIGHT
## Inclinación (radianes) para expresar duda, curiosidad...
@export var tilt := 0.0
## 0 a 1: qué tan encendido está (dañado ≈ 0.2).
@export var power := 1.0

var _clock := 0.0
var _blink := 0.0
var _next_blink := 3.0


func _process(delta: float) -> void:
	_clock += delta
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.15
		_next_blink = randf_range(2.5, 5.0)
	_blink = maxf(_blink - delta, 0.0)
	queue_redraw()


## Parpadea ya (una reacción).
func blink() -> void:
	_blink = 0.15


func _draw() -> void:
	var bob := sin(_clock * 2.4) * 2.0 if mood == Mood.FLOTANDO else 0.0
	var center := Vector2(0, bob)
	draw_set_transform(Vector2.ZERO, tilt)
	if mood == Mood.FLOTANDO:
		draw_circle(center, radius + 5.0, Color(CYAN, 0.12 * power))
		draw_line(center + Vector2(-radius * 0.6, radius + 6.0), center + Vector2(radius * 0.6, radius + 6.0), Color(CYAN, 0.3 * power), 2.0)
	# Carcasa: blanca arriba, gris abajo, una franja azul.
	draw_circle(center, radius, SHELL_DARK)
	draw_circle(center + Vector2(0, -1.5), radius - 1.5, SHELL)
	draw_arc(center, radius - 0.5, 0.15 * PI, 0.85 * PI, 12, BLUE, 2.0)
	draw_arc(center, radius, 0.0, TAU, 24, Color("8a9ab8"), 1.0)
	# El ojo: un óvalo cian que mira hacia look_dir, parpadea y titila si está dañado.
	var eye_on := power
	if mood == Mood.DANADO and fmod(_clock, 1.3) < 0.25:
		eye_on *= 0.2
	var eye := center + look_dir.normalized() * radius * 0.28
	var height := 1.0 if _blink > 0.0 else radius * 0.42
	draw_circle(eye, radius * 0.48, Color("1a2438"))
	draw_set_transform(eye, tilt, Vector2(1.0, height / (radius * 0.42)))
	draw_circle(Vector2.ZERO, radius * 0.32, Color(CYAN, eye_on))
	draw_circle(Vector2(-radius * 0.1, -radius * 0.1), radius * 0.1, Color(1, 1, 1, 0.8 * eye_on))
	draw_set_transform(Vector2.ZERO, 0.0)
	if mood == Mood.DANADO:
		# Grietas y chispas.
		draw_line(center + Vector2(-radius * 0.5, -radius * 0.7), center + Vector2(-radius * 0.1, -radius * 0.2), Color("5a6474"), 1.0)
		if fmod(_clock, 0.9) < 0.12:
			draw_circle(center + Vector2(radius * 0.8, -radius * 0.6), 1.5, Color("ffd166"))
