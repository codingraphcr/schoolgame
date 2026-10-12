class_name ConnectionLostScreen
extends Control
## Pantalla de la muerte de Kai (paso 10 de la hoja de muerte de Ariel): todo se oscurece, franjas
## de glitch magenta cruzan la pantalla y en el centro aparece el cartel "CONEXIÓN PERDIDA...".
## La crea DeathSequence. Con "reducir glitch" las franjas no se mueven.

const MAGENTA := Color("ff3dd8")
const PINK := Color("ff9cf2")
const NIGHT := Color("0b0614")
const PANEL := Vector2(380, 64)

var _time := 0.0
var _bars: Array[Dictionary] = []
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_label = Label.new()
	_label.text = "CONEXIÓN PERDIDA"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.offset_left = -PANEL.x * 0.5
	_label.offset_right = PANEL.x * 0.5
	_label.offset_top = -PANEL.y * 0.5
	_label.offset_bottom = PANEL.y * 0.5
	_label.add_theme_font_size_override(&"font_size", 26)
	_label.add_theme_color_override(&"font_color", PINK)
	add_child(_label)
	_new_bars()


func _process(delta: float) -> void:
	_time += delta
	# Los puntos suspensivos se escriben de a uno, como una señal que intenta volver.
	_label.text = "CONEXIÓN PERDIDA" + ".".repeat(int(_time * 5.0) % 4)
	if not GameSettings.reduce_glitch and randf() < 0.35:
		_new_bars()
	queue_redraw()


func _new_bars() -> void:
	_bars.clear()
	for i in 14:
		_bars.append({ "y": randf(), "h": randf_range(2.0, 14.0), "x": randf_range(-0.2, 0.5), "w": randf_range(0.3, 1.0),
			"color": [MAGENTA, PINK, Color("7a1a9c")].pick_random(), "a": randf_range(0.25, 0.8) })


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), NIGHT)
	for bar in _bars:
		draw_rect(Rect2(bar.x * size.x, bar.y * size.y, bar.w * size.x, bar.h), Color(bar.color, bar.a))
	# Cartel: fondo oscuro con borde magenta (y una sombra corrida, como una señal doble).
	var rect := Rect2(size * 0.5 - PANEL * 0.5, PANEL)
	draw_rect(rect, Color(NIGHT, 0.92))
	draw_rect(rect.grow(-2.0), Color(MAGENTA, 0.12))
	draw_rect(rect, MAGENTA, false, 2.0)
	draw_rect(Rect2(rect.position + Vector2(4, 3), rect.size), Color(MAGENTA, 0.25), false, 1.0)
