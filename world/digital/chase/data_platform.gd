@tool
class_name DataPlatform
extends AnimatableBody2D
## Plataforma de datos de la red de entrenamiento (persecución digital del Capítulo 1): un bloque
## flotante que se pisa desde arriba (de un solo sentido). Tres clases:
##
## - FIXED: quieta.
## - MOVING: va y viene entre su posición y move_offset (con la física, como Kai: siempre igual
##   aunque la computadora vaya lenta).
## - TEMPORARY: al pisarla parpadea close_delay segundos, desaparece reopen_delay y vuelve.
##
## Las que se mueven o desaparecen están en el grupo "unsafe_ground": Kai nunca reaparece sobre ellas.
## El origen es la esquina superior izquierda (arriba = donde pisa Kai). Se ve también en el editor.

enum Kind { FIXED, MOVING, TEMPORARY }

const CYAN := Color("3ef2ff")
const VIOLET := Color("a77bff")
const AMBER := Color("ffc24a")
const FILL := Color("0b1830")
const THICKNESS := 12.0

@export var kind := Kind.FIXED:
	set(value):
		kind = value
		queue_redraw()
@export var width := 96.0:
	set(value):
		width = value
		_rebuild()
@export_group("Movimiento")
@export var move_offset := Vector2(120, 0)
@export var move_time := 2.0
@export_group("Temporal")
@export var close_delay := 0.6
@export var reopen_delay := 2.0

var _shape: CollisionShape2D
var _closing := false
var _closed := false
var _time := 0.0
var _blink := 0.0


func _ready() -> void:
	_rebuild()
	if Engine.is_editor_hint():
		return
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = kind == Kind.MOVING
	if kind != Kind.FIXED:
		add_to_group(&"unsafe_ground")
	if kind == Kind.MOVING:
		var origin := position
		var tween := create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tween.tween_property(self, "position", origin + move_offset, move_time).set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "position", origin, move_time).set_trans(Tween.TRANS_SINE)
	if kind == Kind.TEMPORARY:
		var sensor := Area2D.new()
		sensor.collision_layer = 0
		sensor.collision_mask = 2  # Capa del jugador
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(width - 4.0, 6.0)
		shape.shape = rect
		shape.position = Vector2(width / 2.0, -3.0)
		sensor.add_child(shape)
		add_child(sensor)
		sensor.body_entered.connect(_on_stepped)


func _physics_process(delta: float) -> void:
	_time += delta
	if _closing:
		_blink += delta
	queue_redraw()


func is_closed() -> bool:
	return _closed


func _on_stepped(body: Node) -> void:
	if _closing or _closed or not body is Player:
		return
	_closing = true
	_blink = 0.0
	# Los tiempos corren con la física (como Kai) y se detienen en pausa.
	await get_tree().create_timer(close_delay, false, true).timeout
	_closing = false
	_closed = true
	_shape.set_deferred(&"disabled", true)
	await get_tree().create_timer(reopen_delay, false, true).timeout
	_closed = false
	_shape.set_deferred(&"disabled", false)


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.one_way_collision = true
		add_child(_shape)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 8.0)
	_shape.shape = rect
	_shape.position = Vector2(width / 2.0, 4.0)
	queue_redraw()


func _draw() -> void:
	if _closed:
		draw_rect(Rect2(0, 0, width, 2), Color(AMBER, 0.25))
		return
	var accent := CYAN if kind == Kind.FIXED else (VIOLET if kind == Kind.MOVING else AMBER)
	var alpha := 1.0
	if _closing:
		alpha = 0.35 if int(_blink / 0.08) % 2 == 0 else 1.0
	var body := Rect2(0, 0, width, THICKNESS)
	draw_rect(body, Color(FILL, alpha))
	draw_rect(Rect2(0, 0, width, 2), Color(accent, alpha))
	draw_rect(body, Color(accent, 0.6 * alpha), false, 1.0)
	# Bits que corren por dentro del bloque.
	var font := ThemeDB.fallback_font
	var bits := ""
	for i in int(width / 7.0):
		bits += "1" if (int(_time * 4.0) + i * 3) % 5 < 2 else "0"
	draw_string(font, Vector2(3, THICKNESS - 2), bits, HORIZONTAL_ALIGNMENT_LEFT, width - 4.0, 7, Color(accent, 0.45 * alpha))
	if kind == Kind.TEMPORARY:
		# Marcas de «se rompe».
		for k in int(width / 24.0):
			var x := 12.0 + k * 24.0
			draw_line(Vector2(x, 3), Vector2(x + 4, THICKNESS - 2), Color(accent, 0.6 * alpha), 1.0)
