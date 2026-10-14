class_name ChaseTimer
extends Label
## Temporizador de la persecución digital, arriba al centro de la pantalla: «⏱ 3:42». Se pone rojo
## y late en los últimos 30 segundos; muestra «−15 s» un momento al descontar tiempo. Solo muestra:
## el tiempo lo lleva DigitalChaseController.

const NORMAL := Color("d8f6ff")
const URGENT := Color("ff4a6a")
const URGENT_SECONDS := 30.0

var _penalty: Label
var _time := 0.0
var _seconds := 0.0


static func create(parent: Node) -> ChaseTimer:
	var timer := ChaseTimer.new()
	timer.name = "ChaseTimer"
	parent.add_child(timer)
	return timer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	offset_top = 14.0
	offset_left = -110.0
	offset_right = 110.0
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 28)
	add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	add_theme_constant_override("outline_size", 8)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_penalty = Label.new()
	_penalty.position = Vector2(150, 6)
	_penalty.add_theme_font_size_override("font_size", 20)
	_penalty.add_theme_color_override("font_color", URGENT)
	_penalty.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	_penalty.add_theme_constant_override("outline_size", 6)
	_penalty.modulate.a = 0.0
	add_child(_penalty)
	show_seconds(0.0)


func _process(delta: float) -> void:
	_time += delta
	if _seconds <= URGENT_SECONDS and _seconds > 0.0:
		scale = Vector2.ONE * (1.0 + 0.06 * absf(sin(_time * 6.0)))
		pivot_offset = size / 2.0
	else:
		scale = Vector2.ONE


func show_seconds(seconds: float) -> void:
	_seconds = maxf(seconds, 0.0)
	var whole := ceili(_seconds)
	text = "⏱ %d:%02d" % [whole / 60, whole % 60]
	add_theme_color_override("font_color", URGENT if _seconds <= URGENT_SECONDS else NORMAL)


## Muestra «−15 s» un momento.
func show_penalty(seconds: float) -> void:
	_penalty.text = "−%d s" % roundi(seconds)
	_penalty.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_penalty, "modulate:a", 0.0, 1.2).set_delay(0.6)
