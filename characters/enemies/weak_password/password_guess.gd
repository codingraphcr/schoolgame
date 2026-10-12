class_name PasswordGuess
extends HitboxComponent
## Un «intento» de la «Contraseña débil»: una contraseña débil real (qwerty, 123456…) que sale
## disparada a ras del suelo. Así se ve un ataque de fuerza bruta: probar contraseña tras contraseña.
## Hay que saltarla. Quita medio cristal (golpe enemigo) y desaparece sola.
## Uso: PasswordGuess.throw(sala, posición, dirección, "qwerty")

const MAG := Color("ff3ea5")
const DARK := Color("1a0f2e")
const SPEED := 150.0
const LIFETIME := 3.2
## Aviso antes de salir disparado (parpadea en su lugar).
const WARNING := 0.25

var text := "123456"
var direction := 1
var _time := 0.0
var _canvas: VectorCanvas


static func throw(parent: Node, at: Vector2, dir: int, guess: String) -> PasswordGuess:
	var shot := PasswordGuess.new()
	shot.text = guess
	shot.direction = 1 if dir >= 0 else -1
	parent.add_child(shot)
	shot.global_position = at
	return shot


func _init() -> void:
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0
	damage = 1.0
	threat_type = &"credenciales"
	knockback_force = 140.0
	active = false


func _ready() -> void:
	super()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(maxf(text.length() * 4.0 + 6.0, 18.0), 9.0)
	shape.shape = rect
	add_child(shape)
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)
	z_index = 5


func _physics_process(delta: float) -> void:
	_time += delta
	if _time < WARNING:
		return
	active = true
	global_position.x += direction * SPEED * delta
	if _time >= LIFETIME:
		queue_free()


func _paint(c: VectorCanvas, t: float) -> void:
	var w := maxf(text.length() * 4.0 + 6.0, 18.0)
	var box := Rect2(-w / 2.0, -5.0, w, 10.0)
	var warning := _time < WARNING and fmod(t, 0.1) < 0.05
	c.glow(Vector2.ZERO, w * 0.6, Color(MAG, 0.25))
	c.gradient_box(box, 2.0, MAG.lightened(0.25) if not warning else Color.WHITE, MAG.darkened(0.3), DARK, 1.0)
	c.crisp_text(Vector2(box.position.x, 2.5), text, 4, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, w)
	# Estela de velocidad.
	if _time >= WARNING:
		for i in 3:
			var x := -direction * (w / 2.0 + 3.0 + i * 4.0)
			c.draw_line(Vector2(x, -2 + i * 2), Vector2(x - direction * 4.0, -2 + i * 2), Color(MAG, 0.5 - i * 0.15), 1.0)
