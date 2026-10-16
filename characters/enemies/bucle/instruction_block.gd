class_name InstructionBlock
extends HitboxComponent
## Lluvia de instrucciones de Bucle: un bloque de código que cae desde arriba. Antes de caer marca su
## carril en el suelo telegraph segundos (aviso, sin daño). Al llegar al suelo se rompe; con el
## Desbordamiento (stay_time > 0) se queda apilado ahí stay_time segundos, todavía dañando: sube el suelo y
## obliga a usar las plataformas (parpadea antes de romperse).

const HEIGHT := 18.0
const COLOR := Color("ffd166")
const OVERFLOW := Color("ff6b51")
const TEXTS: PackedStringArray = ["repetir()", "i = i + 1", "mientras", "otra vez", "tarea()"]

var width := 56.0
var fall_speed := 300.0
var telegraph := 0.6
## y donde se apoya (el suelo o el bloque apilado de abajo).
var floor_y := 304.0
var text := "repetir()"
## Desbordamiento: segundos que queda apilado al llegar (0 = se rompe al llegar) y su carril.
var stay_time := 0.0
var lane := -1

var _time := 0.0
var _stay_left := 0.0
var _landed := false


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
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width - 6.0, HEIGHT)
	shape.shape = rect
	add_child(shape)
	z_index = 4


func is_live() -> bool:
	return _time >= telegraph


## Si quedó apilado en el suelo (Desbordamiento).
func is_landed() -> bool:
	return _landed


func _physics_process(real_delta: float) -> void:
	var delta := CombatClock.scaled(real_delta)  # El Dominio Nulo lo ralentiza.
	_time += delta
	queue_redraw()
	if _time < telegraph:
		return
	active = true
	if _landed:
		_stay_left -= delta
		if _stay_left <= 0.0:
			_break()
		return
	position.y += fall_speed * delta
	if position.y + HEIGHT / 2.0 >= floor_y:
		if stay_time <= 0.0:
			_break()
			return
		position.y = floor_y - HEIGHT / 2.0
		_landed = true
		_stay_left = stay_time
		PixelBurst.spawn(get_parent(), Vector2(position.x, floor_y - 2.0), [OVERFLOW, COLOR], 6, 50.0, Vector2(width, 4), 0.3)


func _break() -> void:
	PixelBurst.spawn(get_parent(), Vector2(position.x, floor_y - 4.0), [COLOR, Color.WHITE], 8, 70.0, Vector2(width, 6), 0.4)
	queue_free()


func _draw() -> void:
	var box := Rect2(Vector2(-width / 2.0, -HEIGHT / 2.0), Vector2(width, HEIGHT))
	if _time < telegraph:
		# Aviso: el carril se marca en el suelo y el bloque espera arriba, transparente.
		var blink := 0.3 + 0.4 * float(int(_time / 0.08) % 2)
		var ground := floor_y - position.y
		draw_rect(Rect2(Vector2(-width / 2.0, ground - 4.0), Vector2(width, 4.0)), Color(COLOR, blink))
		draw_rect(Rect2(Vector2(-width / 2.0, HEIGHT / 2.0), Vector2(width, ground - HEIGHT / 2.0)), Color(COLOR, 0.06))
		draw_rect(box, Color(COLOR, 0.3), false, 1.0)
		return
	var edge := COLOR
	if _landed:
		# Desbordado: rojo, chispas arriba (daña al tocarlo) y parpadea antes de romperse.
		edge = OVERFLOW
		if _stay_left < 0.6 and int(_stay_left / 0.08) % 2 == 0:
			edge = Color(OVERFLOW, 0.35)
		var t := _time * 6.0
		for k in 3:
			var x := -width / 2.0 + fmod(t * 7.0 + k * width / 3.0, width)
			draw_line(Vector2(x, -HEIGHT / 2.0), Vector2(x + 2.0, -HEIGHT / 2.0 - 3.0 - 2.0 * sin(t + k)), Color(OVERFLOW, 0.8), 1.0)
	draw_rect(box, Color(0.12, 0.08, 0.02, 0.92))
	draw_rect(box, edge, false, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(-width / 2.0, 4.0), text, HORIZONTAL_ALIGNMENT_CENTER, width, 8, edge)
