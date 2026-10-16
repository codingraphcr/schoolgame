class_name DialogueChoice
extends CanvasLayer
## Elección de diálogo: Kai elige qué decir entre 2 o 3 opciones. No hay respuestas correctas (para eso están los
## desafíos, ChoiceWindow): cada opción lleva la charla por otro lado. Pausa el juego mientras está abierta y hay que
## elegir (Esc no la cierra). Se maneja con ↑↓ y E/Enter, o con el mouse.
## Uso: var index: int = await DialogueChoice.ask(nodo, "¿Qué le contás?", ["...", "..."]).chosen

signal chosen(index: int)

var question := ""
var options: PackedStringArray = []
var buttons: Array[Button] = []

var _was_paused := false
var _done := false


static func ask(from: Node, text: String, option_texts: PackedStringArray) -> DialogueChoice:
	var choice := DialogueChoice.new()
	choice.question = text
	choice.options = option_texts
	from.get_tree().current_scene.add_child(choice)
	return choice


func _ready() -> void:
	layer = 72
	add_to_group(&"dialogue_choice")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.05, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1c1420")
	style.border_color = Color("6fd3ff")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override(&"panel", style)
	panel.custom_minimum_size = Vector2(560, 0)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-280, -120)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	panel.add_child(column)
	var title := Label.new()
	title.text = question
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override(&"font_size", 19)
	title.add_theme_color_override(&"font_color", Color("6fd3ff"))
	column.add_child(title)
	for i in options.size():
		var button := Button.new()
		button.text = "%d. %s" % [i + 1, options[i]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(500, 40)
		button.add_theme_font_size_override(&"font_size", 16)
		button.add_theme_color_override(&"font_focus_color", Color("f2b860"))
		InspectionWindow.style_button(button)
		button.pressed.connect(choose.bind(i))
		column.add_child(button)
		buttons.append(button)
	if not buttons.is_empty():
		buttons[0].grab_focus.call_deferred()
	Sfx.play(&"popup_open")


func choose(index: int) -> void:
	if _done or index < 0 or index >= options.size():
		return
	_done = true
	get_tree().paused = _was_paused
	Sfx.play(&"popup_close")
	chosen.emit(index)
	queue_free()


func _input(event: InputEvent) -> void:
	# Hay que elegir: Esc no la cierra (pero tampoco abre la pausa por debajo).
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"interact"):
		for i in buttons.size():
			if buttons[i].has_focus():
				get_viewport().set_input_as_handled()
				choose(i)
				return
