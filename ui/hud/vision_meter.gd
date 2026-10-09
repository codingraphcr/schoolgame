class_name VisionMeter
extends Control
## Indicador de la Visión Digital (arriba a la derecha), diseño de Ariel:
## ACTIVA (tiempo restante), RECARGANDO o LISTA [Q]. Destella en magenta si se intenta usar
## mientras recarga. Solo aparece cuando la Visión Digital ya se descubrió.

const WIDTH := 180.0
const CYAN := Color("3ef2ff")
const MAG := Color("ff3ea5")
const RECHARGE_COLOR := Color(0.35, 0.42, 0.6)

var _label: Label
var _fill: ColorRect
var _denied_flash := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	var settings := LabelSettings.new()
	settings.font_size = 13
	settings.outline_size = 5
	settings.outline_color = Color(0.02, 0.03, 0.08)
	_label.label_settings = settings
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	var back := ColorRect.new()
	back.color = Color(0.03, 0.05, 0.12, 0.9)
	back.position = Vector2(0, 22)
	back.size = Vector2(WIDTH, 8)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	_fill = ColorRect.new()
	_fill.position = Vector2(1, 23)
	_fill.size = Vector2(WIDTH - 2, 6)
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill)
	_vision().denied.connect(_on_denied)


func _process(delta: float) -> void:
	var vision := _vision()
	visible = vision.is_unlocked()
	if not visible:
		return
	_denied_flash = maxf(_denied_flash - delta, 0.0)
	var ratio: float
	var color: Color
	if vision.is_active():
		ratio = clampf(vision.time_left / vision.duration, 0.0, 1.0)
		color = CYAN
		_label.text = "VISIÓN DIGITAL · ACTIVA %d s" % ceili(vision.time_left)
	elif vision.cooldown_left > 0.0:
		ratio = 1.0 - vision.cooldown_left / vision.cooldown
		color = RECHARGE_COLOR
		_label.text = "VISIÓN DIGITAL · RECARGANDO %d s" % ceili(vision.cooldown_left)
	else:
		ratio = 1.0
		color = CYAN
		_label.text = "VISIÓN DIGITAL · LISTA [Q]"
	if _denied_flash > 0.0:
		color = MAG
	_fill.color = color
	_fill.size.x = (WIDTH - 2.0) * ratio
	_label.label_settings.font_color = color.lerp(Color.WHITE, 0.3)


func _on_denied(reason: StringName, seconds_left: float) -> void:
	if reason == &"recharging":
		_denied_flash = 0.35
		get_tree().call_group(&"toast", &"show_message", "La Visión Digital se está recargando (%d s)" % ceili(seconds_left))


func _vision() -> Node:
	return get_node("/root/DigitalVision")
