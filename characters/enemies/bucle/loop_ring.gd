class_name LoopRing
extends HitboxComponent
## Ciclo circular de Bucle: un anillo de energía que se expande desde él, con dos huecos opuestos que
## giran despacio (por ahí se pasa). Antes de salir, un anillo fino marca dónde estarán los huecos
## (telegraph segundos, sin daño).
## Colisión igual a lo dibujado: cada cuadro busca el punto del anillo que cae dentro del Hurtbox de Kai
## (si lo hay y no está en un hueco) y pone ahí su forma de choque; si no, la forma queda apagada.

const COLOR := Color("ff8a5c")
const MAX_RADIUS := 470.0

var speed := 150.0
var width := 10.0
## Tamaño de cada hueco (grados) y cuánto giran por segundo.
var gap := 80.0
var spin := 30.0
## Ángulo del primer hueco al salir (grados; el otro está enfrente).
var gap_angle := 0.0
var telegraph := 0.6

var radius := 14.0
var _time := 0.0
var _shape: CollisionShape2D


func _init() -> void:
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0
	threat_type = &"logica"
	knockback_force = 150.0
	active = false
	add_to_group(&"boss_attack")


func _ready() -> void:
	super()
	_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 2.0
	_shape.shape = circle
	_shape.disabled = true
	add_child(_shape)
	z_index = 4


func is_live() -> bool:
	return _time >= telegraph


## Si el ángulo (radianes, desde el centro) cae en uno de los dos huecos.
func in_gap(angle: float) -> bool:
	var first := deg_to_rad(gap_angle + spin * _time)
	for center in [first, first + PI]:
		if absf(angle_difference(angle, center)) <= deg_to_rad(gap) / 2.0:
			return true
	return false


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time < telegraph:
		return
	active = true
	radius += speed * delta
	if radius >= MAX_RADIUS:
		queue_free()
		return
	_place_shape()


## Pone la forma de choque en un punto del anillo dentro del Hurtbox de Kai (o la apaga).
func _place_shape() -> void:
	_shape.disabled = true
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return
	var hurt := player.get_node_or_null("Hurtbox/CollisionShape2D") as CollisionShape2D
	if hurt == null:
		return
	var half := (hurt.shape as RectangleShape2D).size / 2.0
	var box := Rect2(hurt.global_position - half, half * 2.0)
	var center := global_position
	var closest := Vector2(clampf(center.x, box.position.x, box.end.x), clampf(center.y, box.position.y, box.end.y))
	var farthest := Vector2(box.position.x if center.x > box.get_center().x else box.end.x,
		box.position.y if center.y > box.get_center().y else box.end.y)
	var near := closest.distance_to(center)
	var far := farthest.distance_to(center)
	var inner := radius - width / 2.0
	var outer := radius + width / 2.0
	if near > outer or far < inner:
		return
	# Un punto del anillo dentro de la caja: entre el punto más cercano y el más lejano.
	var target := clampf(radius, near, far)
	var low := 0.0
	var high := 1.0
	for i in 12:
		var mid := (low + high) / 2.0
		if closest.lerp(farthest, mid).distance_to(center) < target:
			low = mid
		else:
			high = mid
	var point := closest.lerp(farthest, (low + high) / 2.0)
	if in_gap((point - center).angle()):
		return
	_shape.global_position = point
	_shape.disabled = false


func _draw() -> void:
	var first := deg_to_rad(gap_angle + spin * _time)
	if _time < telegraph:
		# Aviso: anillo fino que late y los huecos marcados con rayos.
		var blink := 0.35 + 0.35 * float(int(_time / 0.08) % 2)
		_draw_ring(26.0, 2.0, Color(COLOR, blink), first)
		for center in [first, first + PI]:
			draw_line(Vector2.from_angle(center) * 30.0, Vector2.from_angle(center) * 70.0, Color(Color.WHITE, blink), 1.5)
		return
	_draw_ring(radius, width, Color(COLOR, 0.85), first)
	_draw_ring(radius, 1.5, Color.WHITE, first)


## El anillo en arcos, sin los dos huecos.
func _draw_ring(r: float, w: float, color: Color, first: float) -> void:
	var half_gap := deg_to_rad(gap) / 2.0
	for center in [first, first + PI]:
		var from: float = center + half_gap
		var to: float = center + PI - half_gap
		draw_arc(Vector2.ZERO, r, from, to, maxi(16, int(r / 4.0)), color, w)
