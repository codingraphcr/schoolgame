@tool
class_name LabMonitor
extends Node2D
## Monitor de pared del laboratorio, dibujado en pixel art (un píxel del dibujo = un píxel del mundo).
## Estados: apagado, encendiéndose, interferencia, el ojo de la entidad desconocida y normal.
## LabComputer lo usa en la escena 3 del prólogo: se enciende solo, se llena de estática, aparece
## el ojo mientras «???» habla y al final parpadea y se apaga un momento.

enum State { OFF, POWERING, STATIC, EYE, IDLE }

const SIZE := Vector2i(52, 32)
const SCREEN := Rect2i(3, 3, 46, 24)
const OUTLINE := Color("0a0d1c")
const BEZEL := Color("1b2238")
const BEZEL_LIGHT := Color("2c3656")
const SCREEN_OFF := Color("05070d")
const CYAN := Color("3ef2ff")
const CYAN_DARK := Color("0b2a3a")
const IDLE_BG := Color("071425")
const MAGENTA := Color("ff3db8")
const MAGENTA_DARK := Color("1c0616")
const WHITE := Color("e8f6ff")

@export var state := State.OFF:
	set(value):
		state = value
		_update_light()
		queue_redraw()
## Avance de la línea de encendido (0 a 1).
var power := 0.0:
	set(value):
		power = value
		queue_redraw()

var _light: PointLight2D
var _time := 0.0
## Cada animación tiene un número; si empieza otra, la anterior se corta.
var _sequence := 0


func _ready() -> void:
	_light = PointLight2D.new()
	_light.position = Vector2(SIZE) * 0.5
	_light.texture = load("res://assets/art/light_soft.tres")
	_light.texture_scale = 0.9
	add_child(_light, false, INTERNAL_MODE_FRONT)
	_update_light()


func _process(delta: float) -> void:
	_time += delta
	if state in [State.STATIC, State.EYE, State.IDLE]:
		queue_redraw()
	if state == State.STATIC and _light:
		_light.energy = randf_range(0.3, 1.0)


## Cambia de estado al instante y corta cualquier animación que esté corriendo.
func switch_to(new_state: State) -> void:
	_sequence += 1
	state = new_state


## Se enciende solo y se llena de interferencia unos segundos.
func power_on_with_static(seconds := 1.0) -> void:
	var sequence := _start()
	state = State.POWERING
	power = 0.0
	var tween := create_tween()
	tween.tween_property(self, "power", 1.0, 0.18)
	await tween.finished
	if sequence != _sequence:
		return
	state = State.STATIC
	await get_tree().create_timer(seconds).timeout


## El ojo de la entidad aparece entre la estática.
func show_eye() -> void:
	var sequence := _start()
	for i in 3:
		state = State.STATIC
		await get_tree().create_timer(0.06).timeout
		if sequence != _sequence:
			return
		state = State.EYE
		await get_tree().create_timer(0.08 + 0.05 * i).timeout
		if sequence != _sequence:
			return


## Parpadea y se apaga (queda apagado hasta que se cambie el estado).
func flicker_off() -> void:
	var sequence := _start()
	for wait in [0.07, 0.05, 0.1, 0.04, 0.12]:
		state = State.OFF if state != State.OFF else State.STATIC
		await get_tree().create_timer(wait).timeout
		if sequence != _sequence:
			return
	state = State.OFF


## Empieza una animación nueva: las que estaban corriendo se cortan solas.
func _start() -> int:
	_sequence += 1
	return _sequence


func _update_light() -> void:
	if _light == null:
		return
	_light.enabled = state != State.OFF
	match state:
		State.EYE:
			_light.color = MAGENTA
			_light.energy = 1.0
		State.STATIC:
			_light.color = MAGENTA.lerp(CYAN, 0.5)
			_light.energy = 0.7
		_:
			_light.color = CYAN
			_light.energy = 0.55 if state == State.IDLE else 0.8


func _draw() -> void:
	# Soportes a la pared, marco y reflejo.
	_px(Rect2i(10, -6, 2, 6), OUTLINE)
	_px(Rect2i(40, -6, 2, 6), OUTLINE)
	_px(Rect2i(0, 0, SIZE.x, SIZE.y), OUTLINE)
	_px(Rect2i(1, 1, SIZE.x - 2, SIZE.y - 2), BEZEL)
	_px(Rect2i(1, 1, SIZE.x - 2, 1), BEZEL_LIGHT)
	_px(Rect2i(SIZE.x - 6, SIZE.y - 3, 2, 1), CYAN if state != State.OFF else CYAN_DARK)
	match state:
		State.OFF:
			_px(SCREEN, SCREEN_OFF)
			for i in 5:
				_px(Rect2i(SCREEN.position.x + 4 + i, SCREEN.position.y + 2 + i, 1, 1), BEZEL)
		State.POWERING:
			_px(SCREEN, SCREEN_OFF)
			var h := maxi(1, int(SCREEN.size.y * power))
			var w := maxi(2, int(SCREEN.size.x * minf(1.0, power * 3.0)))
			_px(Rect2i(SCREEN.get_center().x - w / 2, SCREEN.get_center().y - h / 2, w, h), WHITE)
		State.STATIC:
			_draw_static()
		State.EYE:
			_draw_eye()
		State.IDLE:
			_draw_idle()


## Filas de ruido cian y magenta, con una banda que corre hacia abajo.
func _draw_static() -> void:
	var band := int(_time * 40.0) % SCREEN.size.y
	for row in SCREEN.size.y:
		var y := SCREEN.position.y + row
		var x := SCREEN.position.x
		while x < SCREEN.end.x:
			var w := mini(randi_range(1, 7), SCREEN.end.x - x)
			var roll := randf()
			var color := SCREEN_OFF
			if roll > 0.9:
				color = MAGENTA
			elif roll > 0.78:
				color = CYAN
			elif roll > 0.5:
				color = CYAN_DARK
			if absi(row - band) <= 1:
				color = color.lightened(0.4)
			_px(Rect2i(x, y, w, 1), color)
			x += w


## El ojo: contorno magenta, iris y pupila, con líneas de barrido. Parpadea de vez en cuando.
func _draw_eye() -> void:
	_px(SCREEN, MAGENTA_DARK)
	for row in range(0, SCREEN.size.y, 2):
		_px(Rect2i(SCREEN.position.x, SCREEN.position.y + row, SCREEN.size.x, 1), Color(MAGENTA, 0.08))
	var c := SCREEN.get_center()
	var blink := fmod(_time, 2.6) < 0.12
	if blink:
		_px(Rect2i(c.x - 9, c.y, 18, 1), MAGENTA)
		return
	# Contorno (rombo alargado, como un ojo).
	var rows := [Vector2i(-4, 3), Vector2i(-3, 6), Vector2i(-2, 8), Vector2i(-1, 9), Vector2i(0, 9),
		Vector2i(1, 9), Vector2i(2, 8), Vector2i(3, 6), Vector2i(4, 3)]
	for r: Vector2i in rows:
		_px(Rect2i(c.x - r.y, c.y + r.x, r.y * 2, 1), MAGENTA)
	for r: Vector2i in rows.slice(1, rows.size() - 1):
		_px(Rect2i(c.x - r.y + 1, c.y + r.x, r.y * 2 - 2, 1), MAGENTA_DARK)
	# Iris y pupila: miran un poco hacia donde está Kai (abajo a la izquierda).
	var look := Vector2i(-2 + int(sin(_time * 0.7) * 1.5), 1)
	_px(Rect2i(c.x - 3 + look.x, c.y - 3 + look.y, 6, 5), MAGENTA)
	_px(Rect2i(c.x - 1 + look.x, c.y - 2 + look.y, 2, 3), WHITE)
	# Cursor.
	if fmod(_time, 0.8) < 0.4:
		_px(Rect2i(SCREEN.end.x - 6, SCREEN.end.y - 4, 3, 2), MAGENTA)


## Pantalla normal: líneas de texto cian y un cursor.
func _draw_idle() -> void:
	_px(SCREEN, IDLE_BG)
	var lengths := [18, 30, 12, 24, 8]
	for i in lengths.size():
		_px(Rect2i(SCREEN.position.x + 3, SCREEN.position.y + 3 + i * 4, lengths[i], 1), Color(CYAN, 0.55))
	if fmod(_time, 1.0) < 0.5:
		_px(Rect2i(SCREEN.position.x + 3 + 8 + 2, SCREEN.position.y + 3 + 16, 3, 2), CYAN)


func _px(rect: Rect2i, color: Color) -> void:
	draw_rect(Rect2(rect), color)
