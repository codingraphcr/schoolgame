class_name FragmentReading
extends CanvasLayer
## El Grimorio lee un Fragmento de Datos (cierre del Capítulo 1): el libro se abre sobre la escena y
## escribe, línea por línea, lo que el fragmento dice. Con E (o Esc) se cierra cuando terminó de
## escribir. Pausa el juego mientras está abierto.
## Uso: await FragmentReading.show_lines(nodo, ["ORIGEN: DESCONOCIDO", ...]).closed

signal closed

const INK := Color("e6deff")
const ACCENT := Color("b9a6ff")
const RED := Color("ff4a6a")
const CHARS_PER_SECOND := 28.0

var lines: PackedStringArray = []
var title := "GRIMORIO · LECTURA DE FRAGMENTO"

var _label: Label
var _hint: Label
var _shown := 0.0
var _total := 0
var _was_paused := false


static func show_lines(from: Node, text_lines: PackedStringArray) -> FragmentReading:
	var reading := FragmentReading.new()
	reading.lines = text_lines
	from.get_tree().current_scene.add_child(reading)
	return reading


func _ready() -> void:
	layer = 70
	add_to_group(&"fragment_reading")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.01, 0.06, 0.85)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var page := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("100c20")
	style.border_color = ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(28)
	page.add_theme_stylebox_override("panel", style)
	page.set_anchors_preset(Control.PRESET_CENTER)
	page.custom_minimum_size = Vector2(560, 300)
	page.position = Vector2(-280, -150)
	add_child(page)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	page.add_child(column)
	var header := Label.new()
	header.text = title
	header.add_theme_color_override("font_color", ACCENT)
	header.add_theme_font_size_override("font_size", 16)
	column.add_child(header)
	_label = Label.new()
	_label.add_theme_color_override("font_color", INK)
	_label.add_theme_font_size_override("font_size", 24)
	_label.custom_minimum_size = Vector2(500, 170)
	column.add_child(_label)
	_hint = Label.new()
	_hint.text = "E: cerrar el Grimorio"
	_hint.add_theme_color_override("font_color", Color(ACCENT, 0.8))
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.visible = false
	column.add_child(_hint)
	_total = "\n".join(lines).length()


func _process(delta: float) -> void:
	if _shown < _total:
		_shown = minf(_shown + delta * CHARS_PER_SECOND, _total)
		_label.text = "\n".join(lines).substr(0, int(_shown))
		_hint.visible = _shown >= _total


## Termina de escribir de una vez.
func finish_writing() -> void:
	_shown = _total
	_label.text = "\n".join(lines)
	_hint.visible = true


func is_done() -> bool:
	return _shown >= _total


func close() -> void:
	get_tree().paused = _was_paused
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if not (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		return
	get_viewport().set_input_as_handled()
	if is_done():
		close()
	else:
		finish_writing()
