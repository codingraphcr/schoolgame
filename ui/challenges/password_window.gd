class_name PasswordWindow
extends CanvasLayer
## Ventana para que el jugador CREE una contraseña (p. ej. la nueva del profesor), encima del juego.
## Tres pasos: 1) escribirla, con el medidor que explica cada regla (PasswordRules) y «Sugerir frase»;
## 2) escribirla otra vez para confirmarla; 3) anotar el código de respaldo. Al terminar se guarda
## solo su huella (GameState.set_password): el jugador tendrá que recordarla más adelante.
##
## Entrada segura: solo acepta caracteres de contraseña (PasswordRules.sanitize; lo demás se quita al
## escribir), sin copiar, pegar, arrastrar ni sugerencias del teclado, y el juego queda en pausa
## mientras está abierta (nada más reacciona a las teclas). Las flechas (o el mando) se mueven entre
## el campo y los botones; Enter los activa.
## Uso: var window := PasswordWindow.open(self, &"profesor", "TÍTULO · PASO 1 DE 2")
##      var completed: bool = await window.closed

signal closed(completed: bool)

enum Step { CREATE, CONFIRM, BACKUP }

const CYAN := Color("3ef2ff")
const MAG := Color("ff3ea5")
const GREEN := Color("5dff9a")
const YELLOW := Color("ffd84a")
const TEXT := Color("d8e4ff")
const PANEL := Color("070b18")
const METER_COLORS := [Color("ff3ea5"), Color("ff8a3d"), Color("ffd84a"), Color("8dff6a"), Color("3ef2ff")]

var password_id: StringName = &""
var header := ""
## Palabras personales extra que no deben aparecer (además de PasswordRules.PERSONAL).
var personal_words: PackedStringArray = []
var step := Step.CREATE
var completed := false
## Código de respaldo que se muestra una sola vez.
var backup := ""

var _password := ""
var _was_paused := false
var _header_label: Label
var _prompt: Label
var _warning: Label
var _line: LineEdit
var _show_button: Button
var _suggest_button: Button
var _rules_box: VBoxContainer
var _rule_labels: Array[Label] = []
var _meter_fill: ColorRect
var _meter_label: Label
var _message: Label
var _code_label: Label
var _back_button: Button
var _next_button: Button


static func open(from: Node, id: StringName, title := "Crear contraseña", extra_personal: PackedStringArray = []) -> PasswordWindow:
	var window := PasswordWindow.new()
	window.password_id = id
	window.header = title
	window.personal_words = extra_personal
	from.get_tree().current_scene.add_child(window)
	return window


func _ready() -> void:
	layer = 60
	add_to_group(&"password_window")
	# En pausa mientras se escribe: el juego no reacciona a las teclas (la ventana sí, PROCESS_MODE_ALWAYS).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	_build()
	_show_step(Step.CREATE)


## Escribe en la línea (lo mismo que teclear) y actualiza el medidor.
func set_text(text: String) -> void:
	_line.text = text
	_on_text_changed(text)


## Botón principal: Guardar → Confirmar → Ya lo anoté.
func submit() -> void:
	match step:
		Step.CREATE:
			if not PasswordRules.evaluate(_line.text, personal_words)["valid"]:
				Sfx.play(&"error")
				return
			_password = _line.text
			_show_step(Step.CONFIRM)
		Step.CONFIRM:
			if _line.text != _password:
				Sfx.play(&"error")
				_message.text = "✖ No coincide. Escríbela igual que antes (mayúsculas incluidas)."
				_message.add_theme_color_override("font_color", MAG)
				_line.clear()
				return
			backup = PasswordRules.backup_code()
			_show_step(Step.BACKUP)
		Step.BACKUP:
			get_node("/root/GameState").set_password(password_id, _password, backup)
			_password = ""
			completed = true
			Sfx.play(&"terminal_ok")
			close()


func back() -> void:
	if step == Step.CONFIRM:
		_password = ""
		_show_step(Step.CREATE)


func close() -> void:
	_password = ""
	_line.clear()
	get_tree().paused = _was_paused
	closed.emit(completed)
	queue_free()


func suggest() -> void:
	set_text(PasswordRules.suggest())
	_line.secret = false
	_show_button.text = "Ocultar"


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func _show_step(new_step: Step) -> void:
	step = new_step
	_message.text = ""
	_line.clear()
	var creating := step == Step.CREATE
	_rules_box.visible = creating
	_suggest_button.visible = creating
	_line.visible = step != Step.BACKUP
	_show_button.visible = step != Step.BACKUP
	_code_label.visible = step == Step.BACKUP
	_back_button.visible = step == Step.CONFIRM
	match step:
		Step.CREATE:
			_prompt.text = "Crea la nueva contraseña. Tendrás que recordarla: más adelante la vas a necesitar."
			_warning.text = "⚠ Invéntala ahora. Nunca escribas una contraseña que uses en la vida real."
			_next_button.text = "Guardar ▶"
			_on_text_changed("")
		Step.CONFIRM:
			_prompt.text = "Escríbela otra vez para confirmarla."
			_warning.text = "Así se evita guardar una contraseña con un error de tipeo."
			_next_button.text = "Confirmar ▶"
			_next_button.disabled = false
		Step.BACKUP:
			_prompt.text = "Este es tu código de respaldo. Si olvidas la contraseña, te permitirá recuperar la cuenta."
			_warning.text = "Anótalo en papel, en un lugar seguro. Se muestra una sola vez."
			_code_label.text = backup
			_next_button.text = "Ya lo anoté ▶"
			_next_button.disabled = false
	if step != Step.BACKUP and not DisplayServer.is_touchscreen_available():
		_line.grab_focus.call_deferred()


func _on_text_changed(text: String) -> void:
	var clean := PasswordRules.sanitize(text)
	if clean != text:
		# Se quitan los caracteres no permitidos sin perder la posición del cursor.
		var caret := maxi(_line.caret_column - (text.length() - clean.length()), 0)
		_line.text = clean
		_line.caret_column = mini(caret, clean.length())
		text = clean
		Sfx.play(&"error")
		_message.text = "Solo letras, números y estos símbolos: %s" % PasswordRules.ALLOWED_SYMBOLS.strip_edges()
		_message.add_theme_color_override("font_color", YELLOW)
	if step != Step.CREATE:
		return
	var result := PasswordRules.evaluate(text, personal_words)
	var rules: Array = result["rules"]
	for i in rules.size():
		var ok: bool = rules[i]["ok"]
		_rule_labels[i].text = ("✔ " if ok else "✖ ") + String(rules[i]["text"])
		_rule_labels[i].add_theme_color_override("font_color", GREEN if ok else (MAG if not text.is_empty() else Color(TEXT, 0.6)))
	var level: int = result["level"]
	var fraction := 0.0 if text.is_empty() else (level + 1) / 5.0
	_meter_fill.size.x = 560.0 * fraction
	_meter_fill.color = METER_COLORS[level]
	_meter_label.text = "" if text.is_empty() else "%s · tiempo estimado para adivinarla: %s" % [PasswordRules.LEVEL_NAMES[level], result["time"]]
	_meter_label.add_theme_color_override("font_color", METER_COLORS[level])
	_next_button.disabled = not result["valid"]


## Las flechas no mueven el cursor del texto: se mueven entre el campo y los botones.
func _on_line_input(event: InputEvent) -> void:
	for pair in [[&"ui_up", SIDE_TOP], [&"ui_down", SIDE_BOTTOM], [&"ui_left", SIDE_LEFT], [&"ui_right", SIDE_RIGHT]]:
		if event.is_action_pressed(pair[0], true):
			_line.accept_event()
			_move_focus(_line, pair[1])
			return


func _move_focus(from: Control, side: Side) -> void:
	var next := from.find_valid_focus_neighbor(side)
	if side == SIDE_BOTTOM and not _next_button.disabled:
		next = _next_button
	if next == null and (side == SIDE_BOTTOM or side == SIDE_RIGHT):
		next = _show_button
	if next:
		next.grab_focus()
		Sfx.play(&"ui_move")


func _toggle_secret() -> void:
	_line.secret = not _line.secret
	_show_button.text = "Mostrar" if _line.secret else "Ocultar"


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.01, 0.04, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 150
	panel.offset_right = -150
	panel.offset_top = 50
	panel.offset_bottom = -50
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
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	_header_label = _label(column, header.to_upper(), CYAN, 15)
	_prompt = _label(column, "", TEXT, 21)
	_warning = _label(column, "", YELLOW, 16)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	_line = LineEdit.new()
	_line.secret = true
	_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_line.custom_minimum_size = Vector2(0, 46)
	_line.add_theme_font_size_override("font_size", 20)
	# Solo una contraseña: sin menú, copiar, pegar, arrastrar ni sugerencias del teclado del celular.
	_line.context_menu_enabled = false
	_line.shortcut_keys_enabled = false
	_line.drag_and_drop_selection_enabled = false
	_line.middle_mouse_paste_enabled = false
	_line.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_PASSWORD
	_line.max_length = PasswordRules.MAX_LENGTH
	_line.gui_input.connect(_on_line_input)
	_line.placeholder_text = "escribe aquí"
	_line.text_changed.connect(_on_text_changed)
	_line.text_submitted.connect(func(_text: String) -> void: submit())
	row.add_child(_line)
	_show_button = _button(row, "Mostrar", _toggle_secret)
	_suggest_button = _button(row, "Sugerir frase", suggest)

	_code_label = _label(column, "", GREEN, 44)
	_code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_rules_box = VBoxContainer.new()
	_rules_box.add_theme_constant_override("separation", 2)
	column.add_child(_rules_box)
	for i in 4:
		_rule_labels.append(_label(_rules_box, "", TEXT, 16))
	var meter_back := ColorRect.new()
	meter_back.custom_minimum_size = Vector2(560, 10)
	meter_back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	meter_back.color = Color("1b2647")
	_rules_box.add_child(meter_back)
	_meter_fill = ColorRect.new()
	_meter_fill.size = Vector2(0, 10)
	meter_back.add_child(_meter_fill)
	_meter_label = _label(_rules_box, "", TEXT, 15)

	_message = _label(column, "", MAG, 16)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)
	_button(buttons, "✕ Cerrar (Esc)", close)
	_back_button = _button(buttons, "◀ Cambiarla", back)
	_next_button = _button(buttons, "Guardar ▶", submit)
	_next_button.custom_minimum_size = Vector2(170, 44)
	# Con ↓ se llega al botón principal (Guardar / Confirmar), y con ↑ se vuelve al campo.
	for control: Control in [_line, _show_button, _suggest_button]:
		control.focus_neighbor_bottom = control.get_path_to(_next_button)
	_next_button.focus_neighbor_top = _next_button.get_path_to(_line)


func _label(parent: Control, text: String, color: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.focus_mode = Control.FOCUS_ALL  # Se llega con las flechas o el mando.
	button.pressed.connect(action)
	parent.add_child(button)
	return button
