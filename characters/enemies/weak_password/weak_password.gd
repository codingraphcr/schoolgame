class_name WeakPasswordEnemy
extends EnemyBase
## La «Contraseña débil» (prólogo, cuenta del profesor): un candado digital con «123456» en la
## pantalla. Se agacha avisando y salta hacia Kai. Con la mitad de la vida entra en «fuerza
## bruta»: avisa menos y salta más seguido y más lejos. Cada golpe suelta una contraseña débil
## real (123456, qwerty…) y al morir se deshace en números.
## Dibujo vectorial provisional (VectorCanvas) hasta que Ariel haga el suyo.

enum Phase { IDLE, TELEGRAPH, HOP }

## Contraseñas de las más usadas del mundo (lo que NO hay que usar).
const WEAK_PASSWORDS := ["123456", "qwerty", "password", "111111", "abc123", "123456789", "000000", "iloveyou"]
const MAG := Color("ff3ea5")
const DARK := Color("1a0f2e")
const SCREEN := Color("2b0d1f")

@export var hop_speed := 120.0
@export var hop_jump_speed := 250.0
@export var idle_time := 0.8
@export var telegraph_time := 0.45

var phase := Phase.IDLE
## Fuerza bruta: con la mitad de la vida o menos.
var brute_force := false

var _timer := 0.6
var _facing := -1
var _left_floor := false
var _canvas: VectorCanvas
var _popups := 0


func _init() -> void:
	display_name = "Contraseña débil"
	max_health = 6.0
	threat_type = &"credenciales"
	body_size = Vector2(22, 20)


func _ready() -> void:
	super()
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)


func _ai(delta: float) -> void:
	match phase:
		Phase.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if is_on_floor():
				_timer -= delta
				if _timer <= 0.0:
					phase = Phase.TELEGRAPH
					_timer = telegraph_time * (0.6 if brute_force else 1.0)
					_facing = direction_to_player()
		Phase.TELEGRAPH:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				var boost := 1.3 if brute_force else 1.0
				velocity = Vector2(_facing * hop_speed * boost, -hop_jump_speed)
				phase = Phase.HOP
				_left_floor = false
		Phase.HOP:
			if not is_on_floor():
				_left_floor = true
			elif _left_floor:
				phase = Phase.IDLE
				_timer = idle_time * (0.45 if brute_force else 1.0)


func _on_damaged(_hit: HitData) -> void:
	phase = Phase.IDLE
	_timer = 0.35
	_popup(WEAK_PASSWORDS[_popups % WEAK_PASSWORDS.size()], MAG)
	_popups += 1
	if not brute_force and health.current <= max_health / 2.0:
		brute_force = true
		_popup("¡FUERZA BRUTA!", Color("ffd84a"), Vector2(0, -44))


func _on_died() -> void:
	# Se deshace en los números de su contraseña.
	var digits := "123456"
	for i in digits.length():
		_popup(digits[i], MAG, Vector2((i - 2.5) * 7.0, -14.0), Vector2((i - 2.5) * 14.0, -30.0 - 6.0 * (i % 2)))


## Texto que sale flotando del enemigo (se agrega a la sala para que no desaparezca con él).
func _popup(text: String, color: Color, from := Vector2(0, -30), drift := Vector2(0, -24)) -> void:
	var label := Label.new()
	label.text = text
	label.scale = Vector2(0.5, 0.5)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	label.add_theme_constant_override("outline_size", 6)
	label.z_index = 20
	var parent := get_parent()
	if parent == null:
		return
	parent.add_child(label)
	label.global_position = global_position + from - Vector2(text.length() * 2.0, 0)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position", label.position + drift, 0.7).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)


func _paint(c: VectorCanvas, t: float) -> void:
	var squash := Vector2.ONE
	var shake := 0.0
	if phase == Phase.TELEGRAPH and not is_dead:
		squash = Vector2(1.15, 0.82)
		shake = sin(t * 60.0) * 1.0
	var w := body_size.x * squash.x
	var h := body_size.y * squash.y
	var body := Rect2(-w / 2.0 + shake, -h, w, h)
	var glow := MAG.lerp(Color("ffd84a"), 0.5) if brute_force else MAG
	c.glow(body.get_center(), 18.0, Color(glow, 0.2 + 0.1 * sin(t * 6.0)))
	# Arco del candado (abierto: es débil).
	var top := Vector2(shake, -h)
	c.draw_arc(top + Vector2(-2, 0), 7.0, PI, TAU - 0.5, 12, glow, 3.0, true)
	c.draw_line(top + Vector2(-9, 0), top + Vector2(-9, 2), glow, 3.0)
	# Cuerpo.
	c.gradient_box(body, 4.0, glow.lightened(0.15), glow.darkened(0.35), DARK, 1.2)
	# Pantalla con la contraseña.
	var screen := Rect2(body.position + Vector2(3, h * 0.42), Vector2(w - 6, h * 0.36))
	c.draw_rect(screen, SCREEN)
	c.crisp_text(screen.position + Vector2(0, screen.size.y - 1.5), "123456", 4, Color("ff9ccf"), HORIZONTAL_ALIGNMENT_CENTER, screen.size.x)
	# Ojos enojados que miran hacia Kai.
	var look := 1.5 * direction_to_player()
	for side in [-1, 1]:
		var eye := body.position + Vector2(w / 2.0 + side * 5.0 + look, h * 0.24)
		c.draw_rect(Rect2(eye - Vector2(1.5, 1.5), Vector2(3, 3)), Color.WHITE)
		c.draw_line(eye + Vector2(2.5 * side, -3.5), eye + Vector2(-2.5 * side, -2.0), DARK, 1.2)
