class_name MaskIcon
extends Control
## Una vida de Kai en el HUD: el Núcleo de integridad (concepto de Ariel en
## docs/arte/referencias/vidas_concepto.webp). Un cristal lila con un núcleo de energía.
## amount: 1 = completo, 0.5 = dañado (la mitad derecha rota y apagada), 0 = vacío.
## Al perder integridad hace un glitch (copias magenta/cian, barras, temblor) y luego cambia de
## estado; al recuperarla destella. Con "reducir efectos glitch" el glitch es corto y suave.

const PALE := Color("e4dbff")
const DEEP := Color("5b2fe0")
const BRIGHT := Color("a47cff")
const CORE := Color("fbf8ff")
const BROKEN := Color("3d3170")
const EMPTY_FILL := Color("17132b")
const EMPTY_EDGE := Color("40366a")
const GLOW := Color("8a5cff")
const MAGENTA := Color("ff3db8")
const CYAN := Color("3ef2ff")
const GLITCH_TIME := 0.45

## Silueta del cristal en unidades (se escala al tamaño del ícono).
const SHAPE: Array[Vector2] = [
	Vector2(0, -1), Vector2(0.42, -0.4), Vector2(0.62, -0.05), Vector2(0.4, 0.42),
	Vector2(0, 1), Vector2(-0.4, 0.42), Vector2(-0.62, -0.05), Vector2(-0.42, -0.4),
]

var _amount := 1.0
var amount: float:
	get:
		return _amount
	set(value):
		value = snappedf(clampf(value, 0.0, 1.0), 0.5)
		if is_equal_approx(value, _amount):
			return
		var lost := value < _amount
		_previous = _amount
		_amount = value
		if lost:
			_start_glitch()
		else:
			_start_gain()
		queue_redraw()
## Compatibilidad: verdadero si queda algo de integridad.
var filled: bool:
	get:
		return amount > 0.0
	set(value):
		amount = 1.0 if value else 0.0

var _previous := 1.0
var _glitch := 0.0
var _flash := 0.0
var _time := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(38, 46)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	if _glitch > 0.0:
		_glitch = maxf(_glitch - delta, 0.0)
		queue_redraw()
	elif amount > 0.0:
		# El núcleo late suave.
		queue_redraw()


## Cambia el estado sin animación (al entrar a una sala).
func set_amount_instant(value: float) -> void:
	_previous = snappedf(clampf(value, 0.0, 1.0), 0.5)
	_amount = _previous
	_glitch = 0.0
	_flash = 0.0
	scale = Vector2.ONE
	queue_redraw()


func _start_glitch() -> void:
	var reduced := GameSettings.reduce_glitch
	_glitch = GLITCH_TIME * (0.4 if reduced else 1.0)
	set_process(true)


func _start_gain() -> void:
	_flash = 1.0
	pivot_offset = size / 2.0
	scale = Vector2(1.3, 1.3)
	var tween := create_tween().set_parallel()
	tween.tween_method(func(v: float) -> void:
		_flash = v
		queue_redraw(), 1.0, 0.0, 0.3)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var center := size / 2.0
	var half := Vector2(size.x * 0.5, size.y * 0.47)
	if _glitch > 0.0:
		_draw_glitch(center, half)
		return
	if amount >= 1.0:
		_draw_full(center, half)
	elif amount > 0.0:
		_draw_half(center, half)
	else:
		_draw_empty(center, half)
	if _flash > 0.0:
		draw_colored_polygon(_shape(center, half, 1.0), Color(1, 1, 1, _flash * 0.8))


func _draw_full(center: Vector2, half: Vector2) -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	_draw_glow(center, 1.0 + 0.15 * pulse)
	draw_colored_polygon(_shape(center, half, 1.0), PALE)
	draw_colored_polygon(_shape(center, half, 0.7), DEEP)
	draw_colored_polygon(_shape(center, half, 0.46), BRIGHT)
	_draw_facets(center, half, Color(PALE, 0.45))
	_draw_core(center, 1.0 + 0.2 * pulse)
	var edge := _shape(center, half, 1.0)
	edge.append(edge[0])
	draw_polyline(edge, Color.WHITE, 1.5, true)


## Dañado: la mitad izquierda sigue entera; la derecha está rota, apagada y con astillas sueltas.
func _draw_half(center: Vector2, half: Vector2) -> void:
	_draw_glow(center, 0.55)
	var outer := _shape(center, half, 1.0)
	draw_colored_polygon(outer, PALE.darkened(0.15))
	draw_colored_polygon(_shape(center, half, 0.7), DEEP.darkened(0.2))
	draw_colored_polygon(_shape(center, half, 0.46), BRIGHT.darkened(0.25))
	# Mitad derecha rota.
	var right := PackedVector2Array([center + Vector2(0, -half.y)])
	for i in range(1, 4):
		right.append(outer[i])
	right.append(center + Vector2(0, half.y))
	draw_colored_polygon(right, BROKEN)
	# Grieta en zigzag por el medio y otra hacia el borde.
	var crack := PackedVector2Array([center + Vector2(0, -half.y), center + Vector2(2, -half.y * 0.45),
		center + Vector2(-1, -half.y * 0.05), center + Vector2(3, half.y * 0.4), center + Vector2(0, half.y)])
	draw_polyline(crack, Color("0d0a1a"), 2.0)
	draw_polyline(PackedVector2Array([center + Vector2(2, -half.y * 0.2), center + Vector2(half.x * 0.5, -half.y * 0.1),
		center + Vector2(half.x * 0.7, half.y * 0.1)]), Color(PALE, 0.35), 1.0)
	# Astillas que se desprenden.
	var drift := sin(_time * 2.0) * 1.0
	for shard in [[Vector2(half.x + 4, -4), 3.0], [Vector2(half.x + 2, 6), 2.0]]:
		var p: Vector2 = center + shard[0] + Vector2(drift, 0)
		var r: float = shard[1]
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r)]), Color(BRIGHT, 0.7))
	_draw_facets(center, half, Color(PALE, 0.3), true)
	var edge := outer.duplicate()
	edge.append(edge[0])
	draw_polyline(edge, Color(PALE, 0.55), 1.5, true)
	_draw_core(center + Vector2(-1, 0), 0.6)


func _draw_empty(center: Vector2, half: Vector2) -> void:
	var outer := _shape(center, half, 1.0)
	draw_colored_polygon(outer, EMPTY_FILL)
	outer.append(outer[0])
	draw_polyline(outer, EMPTY_EDGE, 1.5, true)
	var inner := _shape(center, half, 0.5)
	inner.append(inner[0])
	draw_polyline(inner, Color(EMPTY_EDGE, 0.6), 1.0, true)


## Glitch al perder integridad: el estado anterior tiembla, se separa en magenta y cian,
## y lo cruzan barras de interferencia. Al final se mezcla con el estado nuevo.
func _draw_glitch(center: Vector2, half: Vector2) -> void:
	var t := 1.0 - _glitch / GLITCH_TIME
	var strength := 0.3 if GameSettings.reduce_glitch else 1.0
	var shake := Vector2(randf_range(-3.0, 3.0), randf_range(-1.0, 1.0)) * strength
	var shape := _shape(center + shake, half, 1.0)
	_draw_glow(center, 1.2 * (1.0 - t))
	_draw_offset(shape, Vector2(-3, 0) * strength, Color(MAGENTA, 0.6))
	_draw_offset(shape, Vector2(3, 0) * strength, Color(CYAN, 0.5))
	if t < 0.55 or randf() < 0.5:
		if _previous >= 1.0:
			_draw_full(center + shake, half)
		else:
			_draw_half(center + shake, half)
	else:
		if amount > 0.0:
			_draw_half(center + shake, half)
		else:
			_draw_empty(center + shake, half)
	# Barras de interferencia.
	for i in int(5 * strength) + 1:
		var y := randf_range(-half.y, half.y)
		var w := randf_range(half.x * 0.6, half.x * 2.6)
		var x := randf_range(-half.x * 1.4, half.x * 0.4)
		var color: Color = [Color.WHITE, BRIGHT, MAGENTA, CYAN].pick_random()
		draw_rect(Rect2(center + Vector2(x, y), Vector2(w, randf_range(1.0, 3.0))), Color(color, 0.85))


func _draw_offset(shape: PackedVector2Array, offset: Vector2, color: Color) -> void:
	var moved := PackedVector2Array()
	for p in shape:
		moved.append(p + offset)
	draw_colored_polygon(moved, color)


func _draw_glow(center: Vector2, intensity: float) -> void:
	for i in 4:
		draw_circle(center, size.x * (0.35 + i * 0.12), Color(GLOW, 0.07 * intensity))


## Líneas de las caras del cristal (del centro a cada vértice).
func _draw_facets(center: Vector2, half: Vector2, color: Color, left_only := false) -> void:
	var outer := _shape(center, half, 1.0)
	for i in outer.size():
		if left_only and outer[i].x > center.x + 0.5:
			continue
		draw_line(center, outer[i], color, 1.0)


## Núcleo: estrella de cuatro puntas blanca con brillo.
func _draw_core(center: Vector2, intensity: float) -> void:
	draw_circle(center, 5.0 * intensity, Color(CORE, 0.25))
	var a := 6.0 * intensity
	var b := 2.0
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -a), center + Vector2(b, -b), center + Vector2(a, 0),
		center + Vector2(b, b), center + Vector2(0, a), center + Vector2(-b, b), center + Vector2(-a, 0), center + Vector2(-b, -b)]), CORE)


func _shape(center: Vector2, half: Vector2, scale_factor: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for p in SHAPE:
		points.append(center + Vector2(p.x * half.x, p.y * half.y) * scale_factor)
	return points
