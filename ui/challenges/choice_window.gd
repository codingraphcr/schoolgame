class_name ChoiceWindow
extends CanvasLayer
## Ventana de un desafío de elección (ChoiceChallenge), encima del juego: pregunta, opciones grandes
## (teclado, mando, mouse o pantalla táctil) y la explicación de cada elección. Una opción incorrecta
## explica por qué y deja volver a elegir; la correcta habilita «Continuar».
## Las flechas (o el mando) se mueven entre las opciones y los botones; Enter elige. El juego queda en
## pausa mientras está abierta. Las opciones se muestran en un orden al azar cada vez que aparece una
## pregunta (la respuesta no está siempre en el mismo lugar); choose() sigue usando el índice original.
## Uso: var window := ChoiceWindow.open(self, desafio); var completed: bool = await window.closed

signal answered(question: int, option: int, correct: bool)
signal closed(completed: bool)

const CYAN := Color("3ef2ff")
const MAG := Color("ff3ea5")
const GREEN := Color("5dff9a")
const TEXT := Color("d8e4ff")
const PANEL := Color("070b18")

var challenge: ChoiceChallenge
## Si el desafío es parte de una secuencia más larga: pasos anteriores y total (0 = solo este).
var step_offset := 0
var step_total := 0
var question_index := 0
var completed := false
## Intentos fallidos por pregunta (para registros y puntuación futura).
var mistakes: Array[int] = []

var _step: Label
var _prompt: Label
var _options: VBoxContainer
var _feedback: Label
var _continue: Button
## Botón de cada opción, por su índice original (el orden en pantalla es al azar).
var _buttons: Array[Button] = []
## Orden en pantalla: índices originales de las opciones, de arriba hacia abajo.
var display_order: Array[int] = []
var _was_paused := false


static func open(from: Node, choice_challenge: ChoiceChallenge, offset := 0, total := 0) -> ChoiceWindow:
	var window := ChoiceWindow.new()
	window.challenge = choice_challenge
	window.step_offset = offset
	window.step_total = total
	from.get_tree().current_scene.add_child(window)
	return window


func _ready() -> void:
	layer = 60
	add_to_group(&"choice_window")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	mistakes.resize(challenge.questions.size())
	mistakes.fill(0)
	_build()
	_show_question(0)


## Elige una opción de la pregunta actual (lo mismo que pulsar su botón).
func choose(option: int) -> void:
	var question := challenge.questions[question_index]
	if option < 0 or option >= question.options.size() or _continue.visible:
		return
	var picked := question.options[option]
	answered.emit(question_index, option, picked.correct)
	_feedback.text = ("✔ " if picked.correct else "✖ ") + picked.feedback
	_feedback.add_theme_color_override("font_color", GREEN if picked.correct else MAG)
	_feedback.show()
	var button := _buttons[option]
	if picked.correct:
		Sfx.play(&"terminal_ok")
		for other in _buttons:
			other.disabled = other != button
		_mark(button, GREEN)
		_continue.text = "Continuar ▶" if question_index < challenge.questions.size() - 1 else "Terminar ▶"
		_continue.show()
		_continue.grab_focus.call_deferred()
	else:
		Sfx.play(&"error")
		mistakes[question_index] += 1
		button.disabled = true
		_mark(button, MAG)
		_focus_first_enabled()


## Pasa a la siguiente pregunta o termina el desafío.
func next() -> void:
	if not _continue.visible:
		return
	if question_index < challenge.questions.size() - 1:
		_show_question(question_index + 1)
	else:
		completed = true
		close()


func close() -> void:
	get_tree().paused = _was_paused
	closed.emit(completed)
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func _show_question(index: int) -> void:
	question_index = index
	var question := challenge.questions[index]
	var total := step_total if step_total > 0 else challenge.questions.size()
	_step.text = "%s · PASO %d DE %d" % [challenge.title.to_upper(), step_offset + index + 1, total]
	_prompt.text = question.prompt
	_feedback.hide()
	_continue.hide()
	for button in _buttons:
		button.queue_free()
	_buttons.clear()
	display_order.clear()
	for i in question.options.size():
		display_order.append(i)
	display_order.shuffle()
	for i in question.options.size():
		var option := question.options[i]
		var button := Button.new()
		button.text = "%s\n%s" % [option.text, option.detail] if not option.detail.is_empty() else option.text
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 64)
		button.add_theme_font_size_override("font_size", 19)
		button.pressed.connect(choose.bind(i))
		button.focus_entered.connect(func() -> void: Sfx.play(&"ui_move"))
		_buttons.append(button)
	for i in display_order:
		_options.add_child(_buttons[i])
	_focus_first_enabled()


func _focus_first_enabled() -> void:
	if DisplayServer.is_touchscreen_available():
		return
	for i in display_order:
		if not _buttons[i].disabled:
			_buttons[i].grab_focus.call_deferred()
			return


func _mark(button: Button, color: Color) -> void:
	for state in [&"font_color", &"font_disabled_color", &"font_focus_color", &"font_hover_color"]:
		button.add_theme_color_override(state, color)


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.01, 0.04, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 150
	panel.offset_right = -150
	panel.offset_top = 60
	panel.offset_bottom = -60
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_border_width_all(2)
	style.border_color = CYAN
	style.set_corner_radius_all(6)
	style.shadow_color = Color(CYAN, 0.25)
	style.shadow_size = 18
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	_step = Label.new()
	_step.add_theme_color_override("font_color", CYAN)
	_step.add_theme_font_size_override("font_size", 15)
	column.add_child(_step)

	_prompt = Label.new()
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.add_theme_color_override("font_color", TEXT)
	_prompt.add_theme_font_size_override("font_size", 23)
	column.add_child(_prompt)

	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 8)
	column.add_child(_options)

	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_feedback.add_theme_font_size_override("font_size", 18)
	column.add_child(_feedback)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)
	var close_button := Button.new()
	close_button.text = "✕ Cerrar (Esc)"
	close_button.custom_minimum_size = Vector2(0, 44)
	close_button.focus_mode = Control.FOCUS_ALL
	close_button.pressed.connect(close)
	buttons.add_child(close_button)
	_continue = Button.new()
	_continue.custom_minimum_size = Vector2(160, 44)
	_continue.pressed.connect(next)
	buttons.add_child(_continue)
