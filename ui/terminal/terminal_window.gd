class_name TerminalWindow
extends CanvasLayer
## Ventana de la terminal simulada (encima del juego). Muestra el objetivo, la salida de los
## comandos y una línea para escribir. Teclado: Enter ejecuta, ↑/↓ historial, Tab completa,
## Esc cierra. En celular, los botones de abajo escriben los comandos más usados.
## Si un comando pide la contraseña de una carpeta protegida, aparecen las opciones del desafío
## (flechas y Enter, o 1/2/3): la correcta desbloquea y repite el comando; cada una explica por qué.
## Uso: var window := TerminalWindow.open(self, challenge); var solved: bool = await window.closed

signal solved
signal closed(was_solved: bool)

const CYAN := Color("3ef2ff")
const MAG := Color("ff3ea5")
const GREEN := Color("5dff9a")
const YELLOW := Color("ffd84a")
const TEXT := Color("d8e4ff")
const PANEL := Color("070b18")
const FONT_SIZE := 18
## Botones rápidos: texto del botón → lo que escribe ("⏎" al final = lo ejecuta).
const QUICK := [["ls", "ls⏎"], ["pwd", "pwd⏎"], ["cd …", "cd "], ["cd ..", "cd ..⏎"], ["cat …", "cat "]]

var challenge: TerminalChallenge
var interpreter: CommandInterpreter
var is_solved := false

var _output: RichTextLabel
var _line: LineEdit
var _prompt: Label
var _objective: Label
var _continue: Button
var _history_index := -1
var _hint_index := 0
var _password_panel: VBoxContainer
var _quick_row: HBoxContainer
var _password_buttons: Array[Button] = []


static func open(from: Node, terminal_challenge: TerminalChallenge) -> TerminalWindow:
	var window := TerminalWindow.new()
	window.challenge = terminal_challenge
	from.get_tree().current_scene.add_child(window)
	return window


func _ready() -> void:
	layer = 60
	add_to_group(&"terminal_window")
	interpreter = challenge.create_interpreter()
	interpreter.command_run.connect(_on_command_run)
	_build()
	_print_line(challenge.welcome, TEXT)
	_refresh_prompt()
	_focus_input()


## Ejecuta una línea como si el jugador la hubiera escrito.
func submit(line: String) -> void:
	_print_line("[color=#%s]%s[/color] %s" % [CYAN.to_html(false), _escape(interpreter.prompt()), _escape(line)], TEXT, false)
	Sfx.play(&"terminal_enter")
	var result := interpreter.execute(line)
	if not result["ok"]:
		Sfx.play(&"error", 1.0, -6.0)
	if result["clear"]:
		_output.clear()
	elif not String(result["output"]).is_empty():
		_print_line(result["output"], TEXT if result["ok"] else MAG)
	_history_index = -1
	_refresh_prompt()
	if result.get("password", false) and not challenge.password_options.is_empty():
		_ask_password()


## Muestra las contraseñas para elegir.
func _ask_password() -> void:
	_print_line(challenge.password_prompt if not challenge.password_prompt.is_empty() else "Elige la contraseña:", YELLOW)
	_line.editable = false
	_password_panel.show()
	_password_buttons[0].grab_focus.call_deferred()


## Elige una contraseña (índice en password_options).
func choose_password(index: int) -> void:
	if not _password_panel.visible or index < 0 or index >= challenge.password_options.size():
		return
	var option := challenge.password_options[index]
	_password_panel.hide()
	_line.editable = true
	_print_line("[sudo] contraseña: ••••••••", CYAN)
	if option.correct:
		Sfx.play(&"terminal_ok")
		_print_line("✔ " + option.feedback, GREEN)
		interpreter.unlock()
		var pending := interpreter.pending_line
		if not pending.is_empty():
			submit(pending)
	else:
		Sfx.play(&"error", 1.0, -6.0)
		_print_line("✘ " + option.feedback, MAG)
	_focus_input()


func is_asking_password() -> bool:
	return _password_panel.visible


func show_hint() -> void:
	if challenge.hints.is_empty():
		_print_line("No hay pistas para esta terminal.", YELLOW)
		return
	_print_line("Pista: " + challenge.hints[mini(_hint_index, challenge.hints.size() - 1)], YELLOW)
	_hint_index += 1


func close() -> void:
	closed.emit(is_solved)
	queue_free()


func _on_command_run(command: String, _args: PackedStringArray, target: String) -> void:
	if is_solved or not challenge.is_goal(interpreter, command, target):
		return
	is_solved = true
	Sfx.play(&"terminal_ok")
	_objective.text = "✔ " + challenge.objective
	_objective.add_theme_color_override("font_color", GREEN)
	# La salida del comando se imprime después de esta señal: el mensaje va un instante más tarde.
	_print_success.call_deferred()
	_line.editable = false
	# Resuelto: los botones de comandos ya no sirven (y así entran Continuar y Cerrar).
	_quick_row.hide()
	_continue.show()
	_continue.grab_focus.call_deferred()
	solved.emit()


func _print_success() -> void:
	_print_line("✔ ¡Objetivo cumplido!", GREEN)
	if not challenge.success_text.is_empty():
		_print_line(challenge.success_text, GREEN)


func _input(event: InputEvent) -> void:
	if _password_panel.visible and event is InputEventKey and event.pressed and not event.echo:
		var number := (event as InputEventKey).keycode - KEY_1
		if number >= 0 and number < challenge.password_options.size():
			get_viewport().set_input_as_handled()
			choose_password(number)
			return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if _password_panel.visible:
			# Esc solo cancela la contraseña.
			_password_panel.hide()
			_line.editable = true
			_print_line("Cancelado.", TEXT)
			_focus_input()
			return
		close()


func _on_input_key(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	Sfx.play(&"terminal_key", randf_range(0.85, 1.15))
	match key.keycode:
		KEY_TAB:
			_line.text = interpreter.complete(_line.text)
			_line.caret_column = _line.text.length()
		KEY_UP:
			_browse_history(-1)
		KEY_DOWN:
			_browse_history(1)
		_:
			return
	_line.accept_event()


func _browse_history(direction: int) -> void:
	var history := interpreter.history
	if history.is_empty():
		return
	if _history_index == -1:
		_history_index = history.size()
	_history_index = clampi(_history_index + direction, 0, history.size())
	_line.text = history[_history_index] if _history_index < history.size() else ""
	_line.caret_column = _line.text.length()


func _on_submitted(line: String) -> void:
	_line.clear()
	submit(line)
	_focus_input()


func _on_quick(text: String) -> void:
	if not _line.editable:
		return
	if text.ends_with("⏎"):
		_line.clear()
		submit(text.trim_suffix("⏎"))
	else:
		_line.text = text
		_line.caret_column = text.length()
	_focus_input()


func _refresh_prompt() -> void:
	_prompt.text = interpreter.prompt()


func _focus_input() -> void:
	if _line.editable and not DisplayServer.is_touchscreen_available():
		_line.grab_focus.call_deferred()


func _print_line(text: String, color: Color, escape := true) -> void:
	_output.append_text("[color=#%s]%s[/color]\n" % [color.to_html(false), _escape(text) if escape else text])


func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


# --- Construcción de la ventana ---

func _build() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "DejaVu Sans Mono", "Droid Sans Mono", "monospace"])

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.01, 0.04, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 120
	panel.offset_right = -120
	panel.offset_top = 56
	panel.offset_bottom = -56
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_border_width_all(2)
	style.border_color = CYAN
	style.set_corner_radius_all(6)
	style.shadow_color = Color(CYAN, 0.25)
	style.shadow_size = 18
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	var title := Label.new()
	title.text = ">_ %s — %s@%s" % [challenge.title, interpreter.user, challenge.host]
	title.add_theme_color_override("font_color", CYAN)
	title.add_theme_font_size_override("font_size", 16)
	column.add_child(title)

	_objective = Label.new()
	_objective.text = "OBJETIVO: " + challenge.objective
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.add_theme_color_override("font_color", YELLOW)
	_objective.add_theme_font_size_override("font_size", 16)
	column.add_child(_objective)

	_output = RichTextLabel.new()
	_output.bbcode_enabled = true
	_output.scroll_following = true
	_output.selection_enabled = true
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output.add_theme_font_override("normal_font", font)
	_output.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	column.add_child(_output)

	var line := HBoxContainer.new()
	column.add_child(line)
	_prompt = Label.new()
	_prompt.add_theme_font_override("font", font)
	_prompt.add_theme_font_size_override("font_size", FONT_SIZE)
	_prompt.add_theme_color_override("font_color", CYAN)
	line.add_child(_prompt)
	_line = LineEdit.new()
	_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_line.placeholder_text = "escribe un comando y pulsa Enter"
	_line.caret_blink = true
	_line.context_menu_enabled = false
	_line.max_length = CommandInterpreter.MAX_LINE
	_line.add_theme_font_override("font", font)
	_line.add_theme_font_size_override("font_size", FONT_SIZE)
	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color("0d1428")
	input_style.set_content_margin_all(6)
	_line.add_theme_stylebox_override("normal", input_style)
	_line.add_theme_stylebox_override("focus", input_style)
	_line.text_submitted.connect(_on_submitted)
	_line.gui_input.connect(_on_input_key)
	line.add_child(_line)

	_password_panel = VBoxContainer.new()
	_password_panel.add_theme_constant_override("separation", 6)
	_password_panel.hide()
	column.add_child(_password_panel)
	for i in challenge.password_options.size():
		var choice := _button("%d · %s" % [i + 1, challenge.password_options[i].text], choose_password.bind(i), font)
		choice.focus_mode = Control.FOCUS_ALL
		choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_password_panel.add_child(choice)
		_password_buttons.append(choice)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	column.add_child(buttons)
	_quick_row = HBoxContainer.new()
	_quick_row.add_theme_constant_override("separation", 8)
	buttons.add_child(_quick_row)
	# Solo los comandos que esta terminal permite.
	for quick: Array in QUICK:
		if not interpreter.is_available(String(quick[1]).trim_suffix("⏎").get_slice(" ", 0)):
			continue
		_quick_row.add_child(_button(quick[0], _on_quick.bind(quick[1]), font))
		if quick[0] == "ls" and interpreter.is_option_allowed("ls", "a") and not interpreter.allowed.is_empty():
			_quick_row.add_child(_button("ls -a", _on_quick.bind("ls -a⏎"), font))
	_quick_row.add_child(_button("Tab: completar", func() -> void:
		_line.text = interpreter.complete(_line.text)
		_line.caret_column = _line.text.length()
		_focus_input(), font))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)
	buttons.add_child(_button("Pista", show_hint, font))
	_continue = _button("Continuar ▶", close, font)
	_continue.focus_mode = Control.FOCUS_ALL
	_continue.hide()
	buttons.add_child(_continue)
	buttons.add_child(_button("✕ Cerrar (Esc)", close, font))


func _button(text: String, action: Callable, font: Font) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 40)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(action)
	return button
