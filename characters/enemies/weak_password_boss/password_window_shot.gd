class_name PasswordWindowShot
extends PasswordGuess
## Proyectil del jefe «Contraseña débil» (hoja de Ariel, "3. Proyectiles": dispara ventanas de
## contraseñas en línea recta o en arco). Una ventana con borde de neón rosa que brilla, con una
## contraseña común (qwerty, 123456…) o un candado; va un poco inclinada y deja líneas de estela.
## En arco sube y cae (hay que leer dónde aterriza). Quita medio cristal y desaparece sola.
## Uso: PasswordWindowShot.fire(sala, posición, dirección, "qwerty", en_arco, candado)

const NEON := Color("ff3ec8")
const NEON_LIGHT := Color("ff9ae8")
const FILL := Color("1a0626")
const FLY_SPEED := 165.0
const ARC_SPEED := 120.0
const ARC_LIFT := 230.0
const GRAVITY := 380.0

var arc := false
var lock := false
var _velocity := Vector2.ZERO
var _trail: Array[Vector2] = []
var _size := Vector2(34, 14)


static func fire(parent: Node, at: Vector2, dir: int, guess: String, in_arc := false, with_lock := false) -> PasswordWindowShot:
	var shot := PasswordWindowShot.new()
	shot.text = guess
	shot.direction = 1 if dir >= 0 else -1
	shot.arc = in_arc
	shot.lock = with_lock
	parent.add_child(shot)
	shot.global_position = at
	return shot


func _ready() -> void:
	_size = Vector2(18, 16) if lock else Vector2(maxf(text.length() * 4.5 + 10.0, 24.0), 13.0)
	super()
	# La zona de golpe del tamaño de la ventana.
	for child in get_children():
		if child is CollisionShape2D:
			var rect := RectangleShape2D.new()
			rect.size = _size - Vector2(2, 2)
			(child as CollisionShape2D).shape = rect
	_velocity = Vector2(direction * (ARC_SPEED if arc else FLY_SPEED), -ARC_LIFT if arc else 0.0)


func _physics_process(delta: float) -> void:
	_time += delta
	if _time < WARNING:
		return
	active = true
	if arc:
		_velocity.y += GRAVITY * delta
	global_position += _velocity * delta
	_trail.append(global_position)
	if _trail.size() > 6:
		_trail.remove_at(0)
	if _time >= LIFETIME or global_position.y > 2000.0:
		queue_free()


func _paint(c: VectorCanvas, t: float) -> void:
	var warning := _time < WARNING and fmod(t, 0.1) < 0.05
	# Estela: líneas punteadas detrás (en coordenadas de la ventana).
	if _time >= WARNING:
		for i in range(1, _trail.size()):
			var k := float(i) / _trail.size()
			var from := _trail[i - 1] - global_position
			var to := _trail[i] - global_position
			for y: float in [-3.0, 3.0]:
				var a := from + Vector2(0, y)
				var b := to + Vector2(0, y)
				c.draw_line(a, a.lerp(b, 0.55), Color(NEON, 0.45 * k), 1.0)
	# Inclinada: un poco hacia donde va (en arco, sigue la curva).
	var tilt := -0.08 * direction
	if arc:
		# El ángulo de la curva, sin dar vuelta la ventana cuando va a la izquierda.
		var heading := _velocity if direction > 0 else -_velocity
		tilt = clampf(heading.angle(), -0.6, 0.6)
	c.draw_set_transform(Vector2.ZERO, tilt, Vector2.ONE)
	var rect := Rect2(-_size / 2.0, _size)
	c.glow(Vector2.ZERO, _size.x * 0.8, Color(NEON, 0.22 + 0.08 * sin(t * 12.0)))
	c.draw_rect(rect, FILL)
	var edge := Color.WHITE if warning else NEON
	c.draw_rect(rect, edge, false, 1.5)
	c.draw_rect(rect.grow(-2.0), Color(NEON, 0.35), false, 1.0)
	if lock:
		var center := Vector2(0, 1)
		c.draw_arc(center + Vector2(0, -3), 3.0, PI, TAU, 10, NEON_LIGHT, 1.5)
		c.draw_rect(Rect2(center + Vector2(-4, -3), Vector2(8, 6)), NEON_LIGHT)
		c.draw_rect(Rect2(center + Vector2(-0.5, -1), Vector2(1, 3)), FILL)
	else:
		c.crisp_text(Vector2(rect.position.x, 3.0), text, 5, NEON_LIGHT, HORIZONTAL_ALIGNMENT_CENTER, _size.x)
	c.draw_set_transform(Vector2.ZERO)
