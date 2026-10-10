@tool
class_name SpamPopup
extends AnimatableBody2D
## Ventana de anuncio SPAM dentro de una computadora. Su barra de título es una plataforma de un
## sentido (se sube desde abajo). Puede moverse de ida y vuelta (move_offset) y cerrarse sola poco
## después de pisarla (closes_when_stepped); luego vuelve a abrirse. El origen es la esquina superior
## izquierda. Los textos muestran señales de estafa reales: urgencia, premios, direcciones raras.

const BAR_HEIGHT := 10.0
const TEXT_DARK := Color("1b2647")
const URL_COLOR := Color("2d6fd4")

@export var size := Vector2(96, 56):
	set(value):
		size = value.max(Vector2(48, 28))
		_rebuild()
@export var ad_title := "¡GRATIS!":
	set(value):
		ad_title = value
		_redraw()
@export var ad_lines: PackedStringArray = ["Descarga ya", "Solo hoy"]:
	set(value):
		ad_lines = value
		_redraw()
@export var ad_url := "gratis-ya.xyz":
	set(value):
		ad_url = value
		_redraw()
@export var accent := Color("ff3ea5"):
	set(value):
		accent = value
		_redraw()
## Desplazamiento de ida y vuelta (cero = quieta).
@export var move_offset := Vector2.ZERO
@export var move_time := 2.0
@export var closes_when_stepped := false
@export var close_delay := 0.7
@export var reopen_delay := 2.5

var _canvas: VectorCanvas
var _shape: CollisionShape2D
var _sensor: Area2D
var _closing := false
var _closed := false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_rebuild()
	if Engine.is_editor_hint():
		return
	if move_offset != Vector2.ZERO:
		var origin := position
		var tween := create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tween.tween_property(self, "position", origin + move_offset, move_time).set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "position", origin, move_time).set_trans(Tween.TRANS_SINE)
	if closes_when_stepped:
		_sensor = Area2D.new()
		_sensor.collision_layer = 0
		_sensor.collision_mask = 2  # Capa del jugador
		var sensor_shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(size.x - 4.0, 6.0)
		sensor_shape.shape = rect
		sensor_shape.position = Vector2(size.x / 2.0, -3.0)
		_sensor.add_child(sensor_shape)
		add_child(_sensor)
		_sensor.body_entered.connect(_on_stepped)


func is_closed() -> bool:
	return _closed


func _on_stepped(body: Node) -> void:
	if _closing or _closed or not body is Player:
		return
	_closing = true
	# Parpadea para avisar que se va a cerrar.
	var blink := create_tween().set_loops(int(close_delay / 0.1))
	blink.tween_property(_canvas, "modulate:a", 0.35, 0.05)
	blink.tween_property(_canvas, "modulate:a", 1.0, 0.05)
	await get_tree().create_timer(close_delay).timeout
	blink.kill()
	_closed = true
	Sfx.play(&"popup_close", 1.0, -4.0)
	_closing = false
	_shape.set_deferred(&"disabled", true)
	var close := create_tween()
	close.tween_property(_canvas, "scale", Vector2(1.0, 0.0), 0.12)
	await get_tree().create_timer(reopen_delay).timeout
	_shape.set_deferred(&"disabled", false)
	_closed = false
	Sfx.play(&"popup_open", 1.0, -4.0)
	var reopen := create_tween()
	reopen.tween_property(_canvas, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
	_canvas.modulate.a = 1.0


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape == null:
		_shape = get_node_or_null("Shape") as CollisionShape2D
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.name = "Shape"
		add_child(_shape)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x, 6.0)
	_shape.shape = rect
	_shape.position = Vector2(size.x / 2.0, 3.0)
	_shape.one_way_collision = true
	if _canvas == null:
		_canvas = VectorCanvas.new()
		_canvas.painter = _paint
		_canvas.animated = true
		add_child(_canvas)
	_redraw()


func _redraw() -> void:
	if _canvas:
		_canvas.queue_redraw()


func _paint(c: VectorCanvas, t: float) -> void:
	var window := Rect2(Vector2.ZERO, size)
	# Sombra y cuerpo.
	c.draw_rect(Rect2(window.position + Vector2(2, 2), window.size), Color(0, 0, 0, 0.35))
	c.gradient_box(window, 2.0, Color("f4f7ff"), Color("d6deef"), Color("0a0d1c"), 1.0)
	# Barra de título con el botón de cerrar.
	c.gradient_box(Rect2(0, 0, size.x, BAR_HEIGHT), 2.0, accent.lightened(0.15), accent.darkened(0.2), Color("0a0d1c"), 1.0)
	c.crisp_text(Vector2(3, 7), ad_title, 5, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, size.x - 14)
	c.draw_rect(Rect2(size.x - 9, 2, 7, 6), Color("e9eef8"))
	c.crisp_text(Vector2(size.x - 9, 7), "x", 5, accent.darkened(0.3), HORIZONTAL_ALIGNMENT_CENTER, 7)
	# Texto del anuncio.
	var y := BAR_HEIGHT + 9.0
	for line in ad_lines:
		c.crisp_text(Vector2(4, y), line, 5, TEXT_DARK, HORIZONTAL_ALIGNMENT_LEFT, size.x - 8)
		y += 8.0
	# Dirección sospechosa.
	c.crisp_text(Vector2(4, size.y - 3), ad_url, 4, URL_COLOR, HORIZONTAL_ALIGNMENT_LEFT, size.x - 8)
	# Sello "¡!" que late.
	var pulse := 1.0 + 0.12 * sin(t * 6.0)
	var badge := Vector2(size.x - 10, size.y - 12)
	c.draw_circle(badge, 6.0 * pulse, Color("ffd23f"))
	c.crisp_text(badge + Vector2(-5, 3), "¡!", 6, Color("a8384a"), HORIZONTAL_ALIGNMENT_CENTER, 10)
