class_name IterationBeam
extends HitboxComponent
## Iteración de Bucle: un rayo vertical (de arriba de la sala al suelo) que la barre de un lado al otro, con un
## hueco por donde se pasa. El hueco está a la altura de algo que se pisa (el suelo, las plataformas de los
## costados o el puente y los pilares); si gap_second es distinto, el hueco cambia de altura a mitad de
## camino. Antes de salir marca el borde de donde sale y el camino del hueco (telegraph segundos, sin daño),
## y mientras barre, el camino que le falta. Corre con el tiempo de las amenazas (el Dominio lo frena).

const COLOR := Color("ffb347")
const WIDTH := 8.0
## Distancia (px) en la que el hueco sube o baja a mitad de camino.
const BLEND := 36.0

## x de donde sale y adonde llega (direction sale de ahí).
var from_x := 0.0
var to_x := 640.0
var speed := 210.0
var telegraph := 0.6
## y de arriba del rayo y del suelo.
var top_y := 0.0
var floor_y := 304.0
## y del centro del hueco en la primera mitad del barrido y en la segunda (iguales = no cambia).
var gap_first := 280.0
var gap_second := 280.0
var gap_size := 50.0

var _time := 0.0
var _top: CollisionShape2D
var _bottom: CollisionShape2D


func _init() -> void:
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0
	threat_type = &"logica"
	knockback_force = 150.0
	active = false
	add_to_group(&"boss_attack")


func _ready() -> void:
	super()
	_top = _make_shape()
	_bottom = _make_shape()
	z_index = 4
	_update_shapes()


func is_live() -> bool:
	return _time >= telegraph


func direction() -> float:
	return 1.0 if to_x >= from_x else -1.0


## Centro del hueco (y) cuando el rayo pasa por x.
func gap_at(x: float) -> float:
	var progress := (x - from_x) / (to_x - from_x)
	var blend := BLEND / absf(to_x - from_x)
	return lerpf(gap_first, gap_second, clampf((progress - 0.5) / blend + 0.5, 0.0, 1.0))


func _physics_process(real_delta: float) -> void:
	var delta := CombatClock.scaled(real_delta)  # El Dominio Nulo lo ralentiza.
	_time += delta
	queue_redraw()
	if _time < telegraph:
		return
	if not active:
		active = true
		Sfx.play(&"boss_charge", 1.5, -8.0)
	position.x += direction() * speed * delta
	if (position.x - to_x) * direction() >= 0.0:
		queue_free()
		return
	_update_shapes()


func _update_shapes() -> void:
	var gap := gap_at(position.x)
	var gap_top := gap - gap_size / 2.0
	var gap_bottom := gap + gap_size / 2.0
	_set_rect(_top, top_y, gap_top)
	_set_rect(_bottom, gap_bottom, floor_y)
	_top.disabled = not active
	_bottom.disabled = not active or gap_bottom >= floor_y


func _make_shape() -> CollisionShape2D:
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	add_child(shape)
	return shape


func _set_rect(shape: CollisionShape2D, from_y: float, to_y: float) -> void:
	var height := maxf(to_y - from_y, 1.0)
	(shape.shape as RectangleShape2D).size = Vector2(WIDTH - 2.0, height)
	shape.position = Vector2(0, from_y + height / 2.0 - position.y)


func _draw() -> void:
	var dir := direction()
	if _time < telegraph:
		# Aviso: el borde de donde sale, y el camino del hueco (por ahí hay que estar cuando pase).
		var blink := 0.3 + 0.4 * float(int(_time / 0.08) % 2)
		draw_line(Vector2(0, top_y), Vector2(0, floor_y), Color(COLOR, blink), 3.0)
		_draw_corridor(0.25 + blink * 0.6)
		draw_line(Vector2(dir * 6.0, floor_y - 8.0), Vector2(dir * 30.0, floor_y - 8.0), Color(COLOR, blink), 2.0)
		draw_line(Vector2(dir * 30.0, floor_y - 8.0), Vector2(dir * 24.0, floor_y - 13.0), Color(COLOR, blink), 2.0)
		draw_line(Vector2(dir * 30.0, floor_y - 8.0), Vector2(dir * 24.0, floor_y - 3.0), Color(COLOR, blink), 2.0)
		return
	# Lo que le falta barrer (el hueco, tenue) y el rayo, con su hueco.
	_draw_corridor(0.3)
	var gap := gap_at(position.x)
	var gap_top := gap - gap_size / 2.0
	var gap_bottom := gap + gap_size / 2.0
	for part in [Vector2(top_y, gap_top), Vector2(gap_bottom, floor_y)]:
		if part.y - part.x < 1.0:
			continue
		var rect := Rect2(Vector2(-WIDTH / 2.0, part.x), Vector2(WIDTH, part.y - part.x))
		draw_rect(rect.grow(2.0), Color(COLOR, 0.25))
		draw_rect(rect, Color(COLOR, 0.85))
		draw_line(Vector2(0, part.x), Vector2(0, part.y), Color.WHITE, 1.5)
	# Los bordes del hueco brillan.
	for y in [gap_top, gap_bottom]:
		if y < floor_y:
			draw_line(Vector2(-WIDTH, y), Vector2(WIDTH, y), Color.WHITE, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(-14, top_y + 52.0), "for i", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(COLOR, 0.8))


## El camino del hueco, desde donde está el rayo hasta donde llega (en coordenadas del rayo): una franja
## clara con los bordes punteados.
func _draw_corridor(alpha: float) -> void:
	var left := to_x - position.x
	var step := 6.0 * signf(left)
	var x := 0.0
	var k := 0
	while absf(x) < absf(left):
		var gap := gap_at(position.x + x)
		var from := minf(x, x + step)
		draw_rect(Rect2(Vector2(from, gap - gap_size / 2.0), Vector2(absf(step), gap_size)), Color(Color.WHITE, alpha * 0.25))
		if k % 2 == 0:
			for y in [gap - gap_size / 2.0, gap + gap_size / 2.0]:
				draw_line(Vector2(from, y), Vector2(from + absf(step), y), Color(Color.WHITE, alpha), 1.0)
		x += step
		k += 1
