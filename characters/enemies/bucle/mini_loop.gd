class_name MiniLoop
extends HitboxComponent
## Mini anillo de Bucle: un anillo chico que viaja en línea recta. Lo usan la Recursión (el anillo grande se
## divide y los chicos vuelven hacia Bucle) y las Copias del proceso (cada clon tira uno hacia Kai). Antes de
## salir parpadea y marca su camino (telegraph segundos, sin daño). Corre con el tiempo de las amenazas.

const COLOR := Color("ff8a5c")
const RADIUS := 7.0

var direction := Vector2.RIGHT
var speed := 130.0
## Distancia que recorre antes de desaparecer.
var travel := 200.0
var telegraph := 0.4
var color := COLOR

var _time := 0.0
var _moved := 0.0


func _init() -> void:
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0
	threat_type = &"logica"
	knockback_force = 120.0
	active = false
	add_to_group(&"boss_attack")


func _ready() -> void:
	super()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS - 1.0
	shape.shape = circle
	add_child(shape)
	z_index = 4


func is_live() -> bool:
	return _time >= telegraph


func _physics_process(real_delta: float) -> void:
	var delta := CombatClock.scaled(real_delta)  # El Dominio Nulo lo ralentiza.
	_time += delta
	queue_redraw()
	if _time < telegraph:
		return
	active = true
	var step := speed * delta
	position += direction * step
	_moved += step
	if _moved >= travel:
		queue_free()


func _draw() -> void:
	var spin := _time * 9.0
	if _time < telegraph:
		# Aviso: parpadea y marca por dónde va a pasar.
		var blink := 0.3 + 0.45 * float(int(_time / 0.07) % 2)
		var d := 12.0
		while d < minf(travel, 150.0):
			draw_circle(direction * d, 1.3, Color(color, blink))
			d += 10.0
		draw_arc(Vector2.ZERO, RADIUS, spin, spin + TAU * 0.8, 12, Color(color, blink), 1.5)
		return
	draw_circle(Vector2.ZERO, RADIUS + 2.0, Color(color, 0.18))
	draw_arc(Vector2.ZERO, RADIUS, spin, spin + TAU * 0.8, 12, color, 2.5)
	draw_arc(Vector2.ZERO, RADIUS - 1.0, spin, spin + TAU * 0.8, 12, Color.WHITE, 1.0)
	draw_line(-direction * (RADIUS + 2.0), -direction * (RADIUS + 12.0), Color(color, 0.35), 3.0)
