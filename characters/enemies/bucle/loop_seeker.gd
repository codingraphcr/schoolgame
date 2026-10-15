class_name LoopSeeker
extends HitboxComponent
## Proceso huérfano de Bucle: una esfera que, después de un aviso (telegraph, quieta y parpadeando), persigue
## a Kai un rato (life) girando de a poco (turn_rate): se esquiva cambiando de dirección o con el dash. Se
## deshace al tocar a Kai, al terminar su vida o al salir de la arena. Corre con la física.

const COLOR := Color("9dff6a")
const RADIUS := 7.0

var telegraph := 0.6
var speed := 115.0
## Radianes por segundo que puede girar (más bajo = más fácil de esquivar).
var turn_rate := 2.2
var life := 2.8
var arena := Rect2(0, 0, 640, 360)
var target: Node2D

var _time := 0.0
var _heading := Vector2.DOWN


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
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	z_index = 4
	hit_dealt.connect(func(_hurtbox: Node2D, _hit: HitData) -> void: _pop())


func is_live() -> bool:
	return _time >= telegraph


func _physics_process(real_delta: float) -> void:
	var delta := CombatClock.scaled(real_delta)
	_time += delta
	queue_redraw()
	if _time < telegraph:
		return
	active = true
	if is_instance_valid(target):
		var wanted := (target.global_position + Vector2(0, -20) - global_position).normalized()
		var angle := _heading.angle_to(wanted)
		_heading = _heading.rotated(clampf(angle, -turn_rate * delta, turn_rate * delta))
	global_position += _heading * speed * delta
	if _time >= telegraph + life or not arena.grow(24.0).has_point(global_position):
		_pop()


func _pop() -> void:
	if is_queued_for_deletion():
		return
	PixelBurst.spawn(get_parent(), global_position, [COLOR, Color.WHITE], 6, 60.0, Vector2(10, 10), 0.3)
	queue_free()


func _draw() -> void:
	if _time < telegraph:
		var blink := 0.3 + 0.5 * float(int(_time / 0.08) % 2)
		draw_arc(Vector2.ZERO, RADIUS + 6.0 - _time / telegraph * 6.0, 0, TAU, 20, Color(COLOR, blink), 2.0)
		draw_circle(Vector2.ZERO, 3.0, Color(COLOR, blink))
		return
	draw_circle(Vector2.ZERO, RADIUS + 4.0, Color(COLOR, 0.2))
	draw_circle(Vector2.ZERO, RADIUS, Color(COLOR, 0.85))
	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
	draw_line(Vector2.ZERO, -_heading * 14.0, Color(COLOR, 0.4), 3.0)
