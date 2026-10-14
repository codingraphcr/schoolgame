@tool
class_name CorruptEmitter
extends Node2D
## Nodo corrupto de la persecución digital (Capítulo 1): dispara datos corruptos (DataShot) cada
## interval segundos, siempre con aviso (el disparo parpadea warning segundos antes de salir). Dos
## patrones:
## - SHOOT: dispara en line recta (direction) desde su lugar: hay que saltarlo o esquivarlo.
## - RAIN: lluvia desde arriba, en una franja de rain_width a lo ancho (cae en lugares que van rotando).
## Solo dispara si Kai está cerca (active_range) y la persecución está corriendo (no en las zonas
## seguras ni mientras responde una pregunta). Todo con la física.

enum Pattern { SHOOT, RAIN }

const MAGENTA := Color("ff3ea5")
const VIOLET := Color("8a3eff")

@export var pattern := Pattern.SHOOT:
	set(value):
		pattern = value
		queue_redraw()
@export var direction := Vector2.LEFT
@export var interval := 2.2
## Retraso del primer disparo (para que varios nodos no disparen a la vez).
@export var offset := 0.0
@export var speed := 150.0
@export var warning := 0.45
@export var active_range := 560.0
@export var rain_width := 160.0:
	set(value):
		rain_width = value
		queue_redraw()
## La persecución: solo dispara mientras corre un tramo.
@export var chase: DigitalChaseController

var shots_fired := 0
var _timer := 0.0
var _time := 0.0


func _ready() -> void:
	_timer = -offset


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if Engine.is_editor_hint() or not is_firing():
		return
	_timer += delta
	if _timer >= interval:
		_timer = 0.0
		fire()


## Si ahora está disparando (Kai cerca y el tramo corriendo).
func is_firing() -> bool:
	if chase and (not chase.running or chase.paused):
		return false
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	return player != null and absf(player.global_position.x - global_position.x) <= active_range


func fire() -> void:
	shots_fired += 1
	if pattern == Pattern.SHOOT:
		BossAttacks.shot(get_parent(), global_position, direction.normalized() * speed, 9.0, warning)
	else:
		# Lugares que van rotando a lo ancho de la franja (siempre iguales: se pueden aprender).
		var slots := [0.15, 0.65, 0.35, 0.9, 0.5]
		var x: float = global_position.x - rain_width / 2.0 + rain_width * float(slots[shots_fired % slots.size()])
		BossAttacks.shot(get_parent(), Vector2(x, global_position.y), Vector2.DOWN * speed, 8.0, warning)


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 5.0)
	if pattern == Pattern.SHOOT:
		draw_circle(Vector2.ZERO, 12.0 + pulse * 2.0, Color(MAGENTA, 0.18))
		var points := PackedVector2Array([Vector2(0, -9), Vector2(8, 0), Vector2(0, 9), Vector2(-8, 0)])
		draw_colored_polygon(points, Color(0.15, 0.02, 0.12))
		draw_polyline(points + PackedVector2Array([points[0]]), MAGENTA, 1.5)
		draw_line(Vector2.ZERO, direction.normalized() * 14.0, Color(MAGENTA, 0.8), 2.0)
	else:
		# Una nube de datos corruptos arriba.
		var cloud := Rect2(-rain_width / 2.0, -10, rain_width, 12)
		draw_rect(cloud, Color(VIOLET, 0.18 + 0.08 * pulse))
		for k in int(rain_width / 12.0):
			var x := cloud.position.x + 6.0 + k * 12.0
			draw_rect(Rect2(x, -8 + sin(_time * 4.0 + k) * 2.0, 4, 4), Color(MAGENTA, 0.6))
