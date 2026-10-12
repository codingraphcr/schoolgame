class_name GrimorioNav
extends Control
## Barra de arriba del Grimorio: el título de la página en una placa de neón y, a los lados, a qué
## página se pasa con Q (izquierda: el MAPA) y con E (derecha: el ARCHIVO con comandos, conceptos,
## amenazas y registros). Desde el mapa o el archivo, la otra tecla vuelve al INVENTARIO.
## Los costados también se pueden tocar o cliquear.

signal page_requested(page: int)

const NEON := Color("a47cff")
const LINE := Color("4b2bd6")
const PALE := Color("e9e1ff")
const NIGHT := Color("0a0716")
const TITLES: PackedStringArray = ["Mapa", "Grimorio", "Archivo"]

## Página actual (0 mapa, 1 inventario, 2 archivo).
var page := 1:
	set(value):
		page = value
		_refresh()

var _left: Button
var _right: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	offset_left = -640.0
	offset_right = 640.0
	offset_top = 0.0
	offset_bottom = 70.0
	_left = _side_button(Vector2(56, 16))
	_left.pressed.connect(func() -> void: page_requested.emit(page - 1))
	_right = _side_button(Vector2(1044, 16))
	_right.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_right.pressed.connect(func() -> void: page_requested.emit(page + 1))
	_refresh()


func _side_button(at: Vector2) -> Button:
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.position = at
	button.size = Vector2(180, 34)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override(&"font_size", 16)
	button.add_theme_color_override(&"font_color", PALE)
	button.add_theme_color_override(&"font_hover_color", NEON.lightened(0.3))
	add_child(button)
	return button


func _refresh() -> void:
	if _left == null:
		return
	_left.visible = page > 0
	_right.visible = page < 2
	if page > 0:
		_left.text = "[%s]  %s" % [GameSettings.key_name(&"vision"), TITLES[page - 1]]
	if page < 2:
		_right.text = "%s  [%s]" % [TITLES[page + 1], GameSettings.key_name(&"interact")]
	queue_redraw()


func _draw() -> void:
	# Placa del título: un trapecio de neón con un rombo debajo.
	var center := Vector2(640, 34)
	var plate := PackedVector2Array([center + Vector2(-150, -22), center + Vector2(150, -22), center + Vector2(130, 22), center + Vector2(-130, 22)])
	draw_colored_polygon(plate, NIGHT)
	for i in 3:
		var glow := plate.duplicate()
		glow.append(glow[0])
		draw_polyline(glow, Color(LINE, 0.12), 6.0 + i * 4.0, true)
	var edge := plate.duplicate()
	edge.append(edge[0])
	draw_polyline(edge, NEON, 2.0, true)
	draw_line(center + Vector2(-330, 0), center + Vector2(-160, 0), Color(NEON, 0.45), 1.0)
	draw_line(center + Vector2(160, 0), center + Vector2(330, 0), Color(NEON, 0.45), 1.0)
	var d := center + Vector2(0, 30)
	draw_colored_polygon(PackedVector2Array([d + Vector2(0, -7), d + Vector2(5, 0), d + Vector2(0, 7), d + Vector2(-5, 0)]), NEON)
	var font := ThemeDB.fallback_font
	var title := TITLES[page]
	var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	draw_string(font, center + Vector2(-width / 2.0, 9), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, PALE)
