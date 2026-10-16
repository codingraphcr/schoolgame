class_name RoboticsWindow
extends CanvasLayer
## La ventana de las estaciones de robótica (la misma para las tres: condicionales, ciclos y funciones). A la
## izquierda, la simulación (RoboticsSim); a la derecha, el programa: una fila por casilla con ◀ opción ▶. «Ejecutar»
## corre la simulación (animada, siempre finita) y explica qué pasó; si salió mal se corrige y se vuelve a ejecutar.
## «Pista» muestra las pistas de una en una. Pausa el juego; Esc cierra.
## Uso: var solved: bool = await RoboticsWindow.open(nodo, desafio).closed

signal solved
signal closed(was_solved: bool)

const PANEL := Color("141824")
const BORDER := Color("6fd3ff")
const INK := Color("e8eef8")
const MUTED := Color("8a94a8")
const GOOD := Color("7ee08a")
const BAD := Color("ff8a6a")

var challenge: RoboticsChallenge
var sim: RoboticsSim
var choices: Array[int] = []
var result: RoboticsRun
var is_solved := false
var running := false

var _progress := 1.0
var _clock := 0.0
var _hint_index := 0
var _was_paused := false
var _option_labels: Array[Label] = []
var _slot_buttons: Array[Button] = []
var _run_button: Button
var _feedback: Label
var _art: Control


static func open(from: Node, robotics_challenge: RoboticsChallenge) -> RoboticsWindow:
	var window := RoboticsWindow.new()
	window.challenge = robotics_challenge
	from.get_tree().current_scene.add_child(window)
	return window


func _ready() -> void:
	layer = 70
	add_to_group(&"robotics_window")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	sim = challenge.create_sim()
	for slot in challenge.slots:
		choices.append(clampi(slot.start, 0, maxi(slot.options.size() - 1, 0)))
	_build()
	Sfx.play(&"popup_open")
	if not _slot_buttons.is_empty():
		_slot_buttons[0].grab_focus.call_deferred()


func _process(delta: float) -> void:
	_clock += delta
	if running:
		_progress = minf(_progress + delta / sim.duration(result), 1.0)
		if _progress >= 1.0:
			_finish_run()
	_art.queue_redraw()


## Cambia la opción de una casilla (+1 / −1, en círculo).
func cycle(slot: int, direction: int) -> void:
	if running or slot < 0 or slot >= choices.size():
		return
	var count := challenge.slots[slot].options.size()
	if count == 0:
		return
	choices[slot] = posmod(choices[slot] + direction, count)
	_option_labels[slot].text = challenge.slots[slot].options[choices[slot]]
	result = null
	_feedback.text = ""
	Sfx.play(&"ui_move")


## Pone directamente una opción (para pruebas y para el mouse).
func set_choice(slot: int, option: int) -> void:
	if slot >= 0 and slot < choices.size():
		choices[slot] = option
		_option_labels[slot].text = challenge.slots[slot].options[option]


## Ejecuta el programa: la simulación corre animada y al final explica qué pasó.
func execute() -> void:
	if running:
		return
	result = sim.run(choices)
	_progress = 0.0
	running = true
	_run_button.disabled = true
	_feedback.text = "Ejecutando..."
	_feedback.add_theme_color_override(&"font_color", MUTED)


## Termina la animación ya (para pruebas o si el jugador no quiere esperar).
func skip() -> void:
	if running:
		_progress = 1.0
		_finish_run()


func show_hint() -> void:
	if challenge.hints.is_empty():
		return
	_feedback.text = "Pista: " + challenge.hints[mini(_hint_index, challenge.hints.size() - 1)]
	_feedback.add_theme_color_override(&"font_color", Color("f2c14e"))
	_hint_index += 1


func close() -> void:
	get_tree().paused = _was_paused
	Sfx.play(&"popup_close")
	closed.emit(is_solved)
	queue_free()


func _finish_run() -> void:
	running = false
	_run_button.disabled = false
	if result.ok:
		_feedback.text = result.feedback + "\n\n" + challenge.success_text
		_feedback.add_theme_color_override(&"font_color", GOOD)
		if not is_solved:
			is_solved = true
			Sfx.play(&"terminal_ok")
			solved.emit()
	else:
		_feedback.text = result.feedback + "\nCambia el programa y vuelve a ejecutarlo."
		_feedback.add_theme_color_override(&"font_color", BAD)
		Sfx.play(&"error")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()
		return
	for i in _slot_buttons.size():
		if not _slot_buttons[i].has_focus():
			continue
		if event.is_action_pressed(&"ui_left"):
			get_viewport().set_input_as_handled()
			cycle(i, -1)
		elif event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"interact"):
			get_viewport().set_input_as_handled()
			cycle(i, 1)


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.05, 0.7)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override(&"panel", style)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(1040, 560)
	panel.position = Vector2(-520, -280)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	panel.add_child(column)
	column.add_child(_label("TALLER · " + challenge.title.to_upper(), 18, BORDER))
	column.add_child(_label(challenge.goal, 15, INK))
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	_art = Control.new()
	_art.custom_minimum_size = Vector2(500, 300)
	_art.draw.connect(_draw_art)
	row.add_child(_art)
	var program := VBoxContainer.new()
	program.add_theme_constant_override(&"separation", 8)
	program.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(program)
	program.add_child(_label("PROGRAMA", 13, MUTED))
	for i in challenge.slots.size():
		var slot := challenge.slots[i]
		var line := HBoxContainer.new()
		line.add_theme_constant_override(&"separation", 6)
		program.add_child(line)
		var caption := _label(slot.label, 15, INK)
		caption.custom_minimum_size = Vector2(180, 0)
		caption.autowrap_mode = TextServer.AUTOWRAP_OFF
		line.add_child(caption)
		var left := _small_button("◀")
		left.pressed.connect(cycle.bind(i, -1))
		line.add_child(left)
		var button := _small_button("")
		button.custom_minimum_size = Vector2(250, 36)
		button.pressed.connect(cycle.bind(i, 1))
		line.add_child(button)
		var option := _label(slot.options[choices[i]] if not slot.options.is_empty() else "", 15, Color("f2c14e"))
		option.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		option.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		option.set_anchors_preset(Control.PRESET_FULL_RECT)
		option.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(option)
		var right := _small_button("▶")
		right.pressed.connect(cycle.bind(i, 1))
		line.add_child(right)
		_slot_buttons.append(button)
		_option_labels.append(option)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override(&"separation", 10)
	program.add_child(actions)
	_run_button = _small_button("▶ Ejecutar")
	_run_button.custom_minimum_size = Vector2(150, 40)
	_run_button.pressed.connect(execute)
	actions.add_child(_run_button)
	var hint := _small_button("Pista")
	hint.custom_minimum_size = Vector2(90, 40)
	hint.pressed.connect(show_hint)
	actions.add_child(hint)
	var back := _small_button("Salir")
	back.custom_minimum_size = Vector2(90, 40)
	back.pressed.connect(close)
	actions.add_child(back)
	_feedback = _label("", 15, MUTED)
	_feedback.custom_minimum_size = Vector2(0, 110)
	program.add_child(_feedback)
	column.add_child(_label("↑↓: casilla   ·   ◀ ▶ o E: cambiar   ·   Ejecutar: probar   ·   Esc: salir", 12, MUTED))


func _draw_art() -> void:
	var rect := Rect2(Vector2.ZERO, _art.size)
	_art.draw_rect(rect, Color("0c0f18"))
	_art.draw_rect(rect, Color(BORDER, 0.4), false, 1.0)
	sim.draw(_art, rect.grow(-8), result, _progress, _clock)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(36, 36)
	button.add_theme_font_size_override(&"font_size", 15)
	button.add_theme_color_override(&"font_focus_color", Color("f2b860"))
	InspectionWindow.style_button(button)
	return button
