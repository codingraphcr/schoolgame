class_name KaiComputerWindow
extends CanvasLayer
## La computadora del cuarto de Kai: mensajes de amigos, proyectos del colegio y notas personales
## (ComputerEntry, según la etapa de la historia). Es contenido del juego: no hay internet ni archivos
## reales. Pausa el juego mientras está abierta; con las flechas (o el mando, o el mouse) se elige y
## E / Esc la apagan. Los mensajes leídos quedan marcados en la partida (marca «pc_leido_<archivo>»).
## Uso: await KaiComputerWindow.open(nodo).closed

signal closed

const SCREEN := Color("0c1626")
const BAR := Color("13233a")
const CYAN := Color("3ef2ff")
const INK := Color("dff6ff")
const MUTED := Color("7f9bb3")

var section := ComputerEntry.Section.MENSAJES
var entries: Array[ComputerEntry] = []

var _tabs: Array[Button] = []
var _list: VBoxContainer
var _title: Label
var _from: Label
var _body: Label
var _was_paused := false


static func open(from: Node) -> KaiComputerWindow:
	var window := KaiComputerWindow.new()
	from.get_tree().current_scene.add_child(window)
	return window


func _ready() -> void:
	layer = 70
	add_to_group(&"kai_computer")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	_build()
	Sfx.play(&"popup_open")
	show_section(ComputerEntry.Section.MENSAJES)


func show_section(section_id: ComputerEntry.Section) -> void:
	section = section_id
	for i in _tabs.size():
		_tabs[i].button_pressed = i == section_id
	for child in _list.get_children():
		child.queue_free()
	entries = ComputerEntry.visible_in(section_id, _state())
	if entries.is_empty():
		_title.text = ComputerEntry.SECTION_NAMES[section_id]
		_from.text = ""
		_body.text = "No hay nada nuevo."
		return
	for i in entries.size():
		var button := Button.new()
		var read: bool = _state().has_flag(_read_flag(entries[i]))
		button.text = ("   " if read else "● ") + entries[i].title
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.add_theme_font_size_override(&"font_size", 15)
		button.add_theme_color_override(&"font_color", MUTED if read else INK)
		button.add_theme_color_override(&"font_pressed_color", CYAN)
		button.add_theme_color_override(&"font_focus_color", CYAN)
		var index := i
		button.focus_entered.connect(func() -> void: open_entry(index))
		button.pressed.connect(func() -> void: open_entry(index))
		_list.add_child(button)
	open_entry(0)
	(_list.get_child(0) as Button).grab_focus.call_deferred()


func open_entry(index: int) -> void:
	if index < 0 or index >= entries.size():
		return
	var entry := entries[index]
	_title.text = entry.title
	_from.text = ("De: %s" if entry.section == ComputerEntry.Section.MENSAJES else "%s") % entry.from if not entry.from.is_empty() else ""
	_body.text = entry.body
	_state().set_flag(_read_flag(entry))
	for i in _list.get_child_count():
		(_list.get_child(i) as Button).button_pressed = i == index


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


func _read_flag(entry: ComputerEntry) -> StringName:
	return StringName("pc_leido_%s" % entry.resource_path.get_file().get_basename())


func _state() -> Node:
	return get_node("/root/GameState")


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.01, 0.03, 0.8)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var monitor := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = SCREEN
	style.border_color = Color("2a3a50")
	style.set_border_width_all(10)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(18)
	monitor.add_theme_stylebox_override(&"panel", style)
	monitor.custom_minimum_size = Vector2(880, 500)
	monitor.set_anchors_preset(Control.PRESET_CENTER)
	monitor.position = -monitor.custom_minimum_size / 2.0
	add_child(monitor)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	monitor.add_child(column)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override(&"separation", 8)
	column.add_child(bar)
	bar.add_child(_label("PC de Kai", 16, CYAN))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	for i in ComputerEntry.SECTION_NAMES.size():
		var tab := Button.new()
		tab.text = ComputerEntry.SECTION_NAMES[i]
		tab.toggle_mode = true
		tab.add_theme_font_size_override(&"font_size", 15)
		tab.add_theme_color_override(&"font_pressed_color", CYAN)
		tab.add_theme_color_override(&"font_focus_color", CYAN)
		var section_id: ComputerEntry.Section = i
		tab.pressed.connect(func() -> void: show_section(section_id))
		bar.add_child(tab)
		_tabs.append(tab)
	var body := HBoxContainer.new()
	body.add_theme_constant_override(&"separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(280, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var reader := PanelContainer.new()
	var reader_style := StyleBoxFlat.new()
	reader_style.bg_color = BAR
	reader_style.set_corner_radius_all(4)
	reader_style.set_content_margin_all(16)
	reader.add_theme_stylebox_override(&"panel", reader_style)
	reader.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(reader)
	var text := VBoxContainer.new()
	text.add_theme_constant_override(&"separation", 8)
	reader.add_child(text)
	_title = _label("", 20, INK)
	text.add_child(_title)
	_from = _label("", 14, CYAN)
	text.add_child(_from)
	_body = _label("", 16, INK)
	text.add_child(_body)
	var hint := _label("Flechas: elegir   ·   E / Esc: apagar", 13, MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(hint)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(80, 0)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label
