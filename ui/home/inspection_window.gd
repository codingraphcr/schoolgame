class_name InspectionWindow
extends CanvasLayer
## Pantalla para mirar de cerca objetos del cuarto de Kai (estanterías, soporte de la Nullblade). A la
## izquierda, la lista; a la derecha, el objeto en grande, su nombre, su descripción y lo que piensa Kai.
## Pausa el juego (Kai no se mueve) mientras está abierta; ↑/↓ (o el mando, o el mouse) eligen y
## E / Esc vuelven a la habitación. Mismo estilo de panel que el Grimorio, pero en ámbar: es lo
## personal de Kai, no el libro.
## Uso: await InspectionWindow.open(nodo, "ESTANTERÍA DE RECUERDOS", entradas).closed
## Cada entrada: { "name", "subtitle", "description", "note", "lines" (PackedStringArray),
##                 "locked" (bool), "draw" (Callable(canvas: CanvasItem, rect: Rect2, time: float)) }

signal closed

const ACCENT := Color("f2b860")
const INK := Color("f4ead8")
const MUTED := Color("b8a890")
const NOTE := Color("9be8ff")
const PANEL := Color("1c1420")
const PANEL_BORDER := Color("8a6a40")

var title := ""
var entries: Array[Dictionary] = []
var empty_text := "Todavía no hay nada aquí."
var selected := -1

var _buttons: Array[Button] = []
var _art: _ArtView
var _name: Label
var _subtitle: Label
var _description: Label
var _lines: Label
var _note_title: Label
var _note: Label
var _was_paused := false


static func open(from: Node, window_title: String, list: Array[Dictionary], empty := "") -> InspectionWindow:
	var window := InspectionWindow.new()
	window.title = window_title
	window.entries = list
	if not empty.is_empty():
		window.empty_text = empty
	from.get_tree().current_scene.add_child(window)
	return window


func _ready() -> void:
	layer = 70
	add_to_group(&"inspection_window")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	_build()
	Sfx.play(&"popup_open")
	if entries.is_empty():
		_show_empty()
	else:
		select(0)
		_buttons[0].grab_focus.call_deferred()


func select(index: int) -> void:
	if index < 0 or index >= entries.size():
		return
	selected = index
	var entry := entries[index]
	var locked: bool = entry.get("locked", false)
	_art.painter = entry.get("draw", Callable())
	_art.locked = locked
	_name.text = "???" if locked else String(entry.get("name", ""))
	_subtitle.text = String(entry.get("subtitle", ""))
	_subtitle.visible = not _subtitle.text.is_empty()
	_description.text = String(entry.get("locked_text", "Todavía no lo tengo.")) if locked else String(entry.get("description", ""))
	var lines: PackedStringArray = entry.get("lines", PackedStringArray())
	_lines.text = "" if locked else "\n".join(lines)
	_lines.visible = not _lines.text.is_empty()
	var note := "" if locked else String(entry.get("note", ""))
	_note.text = "«%s»" % note if not note.is_empty() else ""
	_note.visible = not note.is_empty()
	_note_title.visible = _note.visible
	for i in _buttons.size():
		_buttons[i].button_pressed = i == index


func close() -> void:
	if is_queued_for_deletion():
		return
	get_tree().paused = _was_paused
	Sfx.play(&"popup_close")
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause") or event.is_action_pressed(&"interact"):
		get_viewport().set_input_as_handled()
		close()


func _show_empty() -> void:
	_art.painter = Callable()
	_name.text = ""
	_subtitle.hide()
	_description.text = empty_text
	_lines.hide()
	_note.hide()
	_note_title.hide()


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.02, 0.05, 0.82)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var page := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(22)
	page.add_theme_stylebox_override(&"panel", style)
	page.custom_minimum_size = Vector2(900, 500)
	page.set_anchors_preset(Control.PRESET_CENTER)
	page.position = -page.custom_minimum_size / 2.0
	add_child(page)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	page.add_child(column)
	column.add_child(_label(title, 16, ACCENT))
	var body := HBoxContainer.new()
	body.add_theme_constant_override(&"separation", 22)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	# Lista.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(250, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override(&"separation", 4)
	scroll.add_child(list)
	for i in entries.size():
		var button := Button.new()
		var locked: bool = entries[i].get("locked", false)
		button.text = "???" if locked else String(entries[i].get("name", ""))
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override(&"font_size", 15)
		button.add_theme_color_override(&"font_color", MUTED if locked else INK)
		button.add_theme_color_override(&"font_pressed_color", ACCENT)
		button.add_theme_color_override(&"font_focus_color", ACCENT)
		button.add_theme_color_override(&"font_hover_color", ACCENT)
		InspectionWindow.style_button(button)
		var index := i
		button.focus_entered.connect(func() -> void: select(index))
		button.pressed.connect(func() -> void: select(index))
		list.add_child(button)
		_buttons.append(button)
	# Detalle.
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override(&"separation", 8)
	body.add_child(detail)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 18)
	detail.add_child(top)
	_art = _ArtView.new()
	_art.custom_minimum_size = Vector2(176, 176)
	top.add_child(_art)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	_name = _label("", 24, INK)
	heading.add_child(_name)
	_subtitle = _label("", 14, ACCENT)
	heading.add_child(_subtitle)
	_lines = _label("", 14, Color("b9a6ff"))
	heading.add_child(_lines)
	_description = _label("", 16, INK)
	detail.add_child(_description)
	_note_title = _label("KAI", 13, NOTE)
	detail.add_child(_note_title)
	_note = _label("", 16, NOTE)
	detail.add_child(_note)
	var hint := _label("↑↓: elegir   ·   E / Esc: volver al cuarto", 13, Color(MUTED, 0.9))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(hint)


## Botones cálidos (ámbar) de las ventanas del hogar: transparentes, con borde al elegirlos.
static func style_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1.0, 1.0, 1.0, 0.03)
	normal.border_color = Color(PANEL_BORDER, 0.5)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(8)
	var active := normal.duplicate() as StyleBoxFlat
	active.bg_color = Color(ACCENT, 0.16)
	active.border_color = ACCENT
	active.set_border_width_all(2)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", active)
	button.add_theme_stylebox_override(&"pressed", active)
	button.add_theme_stylebox_override(&"hover_pressed", active)
	button.add_theme_stylebox_override(&"focus", active)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(120, 0)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label


## El objeto en grande (lo dibuja painter), sobre un fondo con luz cálida.
class _ArtView extends Control:
	var painter := Callable()
	var locked := false
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("140e18"))
		draw_circle(size / 2.0, size.x * 0.42, Color(1.0, 0.75, 0.4, 0.07))
		draw_rect(rect, Color("8a6a40"), false, 2.0)
		var inner := rect.grow(-14.0)
		if locked or not painter.is_valid():
			KeepsakeArt.draw_art(self, &"bloqueado", inner, _time)
			return
		painter.call(self, inner, _time)
