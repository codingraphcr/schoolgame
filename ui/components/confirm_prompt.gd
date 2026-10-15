class_name ConfirmPrompt
extends CanvasLayer
## Pregunta de sí o no (p. ej. «¿Descansar hasta mañana?»). Pausa el juego mientras está abierta;
## empieza en «No» para que no se confirme sin querer. Esc / pausa = No.
## Uso: var yes: bool = await ConfirmPrompt.ask(nodo, "¿Descansar hasta mañana?", "Se guardará la partida.").answered

signal answered(yes: bool)

var question := ""
var detail := ""
var yes_text := "Sí"
var no_text := "No"

var yes_button: Button
var no_button: Button
var _was_paused := false
var _done := false


static func ask(from: Node, text: String, detail_text := "") -> ConfirmPrompt:
	var prompt := ConfirmPrompt.new()
	prompt.question = text
	prompt.detail = detail_text
	from.get_tree().current_scene.add_child(prompt)
	return prompt


func _ready() -> void:
	layer = 72
	add_to_group(&"confirm_prompt")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.05, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1c1420")
	style.border_color = Color("f2b860")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override(&"panel", style)
	panel.custom_minimum_size = Vector2(440, 0)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-220, -80)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	panel.add_child(column)
	column.add_child(_label(question, 20, Color("f4ead8")))
	if not detail.is_empty():
		column.add_child(_label(detail, 14, Color("b8a890")))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 24)
	column.add_child(row)
	yes_button = _button(yes_text)
	no_button = _button(no_text)
	row.add_child(yes_button)
	row.add_child(no_button)
	yes_button.pressed.connect(answer.bind(true))
	no_button.pressed.connect(answer.bind(false))
	no_button.grab_focus.call_deferred()
	Sfx.play(&"popup_open")


func answer(yes: bool) -> void:
	if _done:
		return
	_done = true
	get_tree().paused = _was_paused
	Sfx.play(&"popup_close")
	answered.emit(yes)
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		answer(false)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120, 40)
	button.add_theme_font_size_override(&"font_size", 17)
	button.add_theme_color_override(&"font_focus_color", Color("f2b860"))
	InspectionWindow.style_button(button)
	return button
