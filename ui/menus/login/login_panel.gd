class_name LoginPanel
extends Control
## Pantalla de inicio de sesión del menú principal (cuentas en el servidor: Profiles). No muestra
## ninguna lista de usuarios: hay que escribir el nombre. Tres modos:
##   · Entrar: usuario y contraseña.
##   · Crear usuario: nombre (un apodo, no el nombre real; al salir del campo avisa si ya existe),
##     contraseña con las reglas del juego y confirmación; al terminar muestra el código de respaldo.
##   · Olvidé mi contraseña: usuario, código de respaldo y contraseña nueva (la partida se conserva).
## Los campos se sanitizan mientras se escribe (sin pegar, arrastrar ni menú). Enter avanza; las
## flechas mueven entre campos y botones. Emite done cuando hay sesión iniciada.

signal done

enum Mode { LOGIN, CREATE, RECOVER, CODE }

const CYAN := Color("3ef2ff")
const MAG := Color("ff3ea5")
const GREEN := Color("5dff9a")
const YELLOW := Color("ffd84a")
const TEXT := Color("d8e4ff")
const PANEL := Color("070b18")

var mode := Mode.LOGIN

var _title: Label
var _note: Label
var _user: LineEdit
var _password: LineEdit
var _repeat: LineEdit
var _code: LineEdit
var _rules: Label
var _message: Label
var _big_code: Label
var _main_button: Button
var _create_button: Button
var _forgot_button: Button
var _back_button: Button
var _busy := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	show_mode(Mode.LOGIN)


func show_mode(new_mode: Mode) -> void:
	mode = new_mode
	_message.text = ""
	_password.text = ""
	_repeat.text = ""
	_code.text = ""
	_title.text = { Mode.LOGIN: "INICIAR SESIÓN", Mode.CREATE: "CREAR USUARIO",
		Mode.RECOVER: "OLVIDÉ MI CONTRASEÑA", Mode.CODE: "TU CÓDIGO DE RESPALDO" }[mode]
	_note.text = {
		Mode.LOGIN: "Tu partida te sigue en cualquier dispositivo. Nadie más puede verla.",
		Mode.CREATE: "Usa un apodo, no tu nombre real. La contraseña es una frase larga (las reglas que aprendiste en el juego).",
		Mode.RECOVER: "Escribe el código de respaldo que anotaste al crear tu usuario y elige una contraseña nueva.",
		Mode.CODE: "Anótalo en un lugar seguro: lo necesitas si olvidas tu contraseña. No se lo des a nadie.",
	}[mode]
	_user.visible = mode != Mode.CODE
	_password.visible = mode != Mode.CODE
	_password.placeholder_text = "contraseña nueva" if mode == Mode.RECOVER else "contraseña"
	_repeat.visible = mode in [Mode.CREATE, Mode.RECOVER]
	_code.visible = mode == Mode.RECOVER
	_rules.visible = mode in [Mode.CREATE, Mode.RECOVER]
	_big_code.visible = mode == Mode.CODE
	_create_button.visible = mode == Mode.LOGIN
	_forgot_button.visible = mode == Mode.LOGIN
	_back_button.visible = mode in [Mode.CREATE, Mode.RECOVER]
	_main_button.text = { Mode.LOGIN: "Entrar ▶", Mode.CREATE: "Crear ▶", Mode.RECOVER: "Cambiar contraseña ▶",
		Mode.CODE: "Ya lo anoté ▶" }[mode]
	_update_rules()
	(_main_button if mode == Mode.CODE else _user).grab_focus.call_deferred()


## Usa el modo actual (como el botón principal o Enter).
func submit() -> void:
	if _busy:
		return
	if mode == Mode.CODE:
		done.emit()
		return
	var username := _user.text.strip_edges()
	if username.is_empty() or _password.text.is_empty():
		_show_error("Escribe tu usuario y tu contraseña.")
		return
	if mode in [Mode.CREATE, Mode.RECOVER] and _password.text != _repeat.text:
		_show_error("Las contraseñas no coinciden.")
		return
	_busy = true
	_message.add_theme_color_override("font_color", TEXT)
	_message.text = "Verificando..."
	# La huella de la contraseña tarda un momento a propósito: primero se muestra el mensaje.
	await get_tree().process_frame
	await get_tree().process_frame
	var profiles := get_node("/root/Profiles")
	var result: Dictionary
	match mode:
		Mode.LOGIN:
			result = await profiles.login(username, _password.text)
		Mode.CREATE:
			result = await profiles.create(username, _password.text)
		Mode.RECOVER:
			result = await profiles.recover(username, _code.text, _password.text)
	_busy = false
	if not result["ok"]:
		_show_error(result["error"])
		_password.text = ""
		_repeat.text = ""
		return
	if mode == Mode.LOGIN:
		done.emit()
		return
	var migrated: bool = result.get("migrated", false)
	show_mode(Mode.CODE)
	_big_code.text = result["backup_code"]
	if migrated:
		_note.text += "\nLa partida que había en este dispositivo ahora es tuya."


func _show_error(text: String) -> void:
	Sfx.play(&"error", 1.0, -6.0)
	_message.add_theme_color_override("font_color", MAG)
	_message.text = text


func _update_rules() -> void:
	if not _rules.visible:
		return
	var report := PasswordRules.evaluate(_password.text, PackedStringArray([_user.text.to_lower()]))
	var lines: PackedStringArray = []
	for rule: Dictionary in report["rules"]:
		lines.append(("✔ " if rule["ok"] else "✘ ") + String(rule["text"]))
	_rules.text = "\n".join(lines)
	_rules.add_theme_color_override("font_color", GREEN if report["valid"] else YELLOW)


## Al crear un usuario, al salir del campo del nombre se pregunta al servidor si está libre.
func check_name() -> void:
	if mode != Mode.CREATE or _busy:
		return
	var username := _user.text.strip_edges()
	if username.is_empty():
		return
	var reply: Dictionary = await get_node("/root/Profiles").is_available(username)
	if mode != Mode.CREATE or _user.text.strip_edges() != username:
		return
	if reply["available"]:
		_message.add_theme_color_override("font_color", GREEN)
		_message.text = "✔ «%s» está libre." % username
	else:
		_show_error(reply["error"])


func _on_user_changed(text: String) -> void:
	var clean := ProfileManager.sanitize_name(text)
	if clean != text:
		var caret := _user.caret_column
		_user.text = clean
		_user.caret_column = mini(caret, clean.length())
	_update_rules()


func _on_secret_changed(text: String, field: LineEdit) -> void:
	var clean := PasswordRules.sanitize(text)
	if clean != text:
		var caret := field.caret_column
		field.text = clean
		field.caret_column = mini(caret, clean.length())
	_update_rules()


func _on_code_changed(text: String) -> void:
	var clean := ""
	for i in text.length():
		if "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-".contains(text[i]):
			clean += text[i].to_upper()
	clean = clean.substr(0, 9)
	if clean != text:
		_code.text = clean
		_code.caret_column = clean.length()


# --- Construcción ---

func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PANEL, 0.94)
	style.set_border_width_all(2)
	style.border_color = CYAN
	style.set_corner_radius_all(6)
	style.shadow_color = Color(CYAN, 0.25)
	style.shadow_size = 18
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	_title = _label(column, "", CYAN, 22)
	_note = _label(column, "", TEXT, 15)
	_user = _field(column, "usuario (3 a 16: letras, números y _)", false)
	_user.max_length = ProfileManager.NAME_MAX
	_user.text_changed.connect(_on_user_changed)
	_user.focus_exited.connect(check_name)
	_code = _field(column, "código de respaldo (p. ej. K7QM-4XPR)", false)
	_code.text_changed.connect(_on_code_changed)
	_password = _field(column, "contraseña", true)
	_password.text_changed.connect(_on_secret_changed.bind(_password))
	_repeat = _field(column, "repite la contraseña", true)
	_repeat.text_changed.connect(_on_secret_changed.bind(_repeat))
	_rules = _label(column, "", YELLOW, 14)
	_big_code = _label(column, "", GREEN, 44)
	_big_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message = _label(column, "", MAG, 16)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(buttons)
	_back_button = _button(buttons, "◀ Volver", show_mode.bind(Mode.LOGIN))
	_forgot_button = _button(buttons, "Olvidé mi contraseña", show_mode.bind(Mode.RECOVER))
	_create_button = _button(buttons, "Crear usuario nuevo", show_mode.bind(Mode.CREATE))
	_main_button = _button(buttons, "Entrar ▶", submit)
	_main_button.custom_minimum_size = Vector2(180, 44)
	for field: LineEdit in [_user, _code, _password, _repeat]:
		field.text_submitted.connect(func(_text: String) -> void: submit())


func _field(parent: Control, placeholder: String, secret: bool) -> LineEdit:
	var field := LineEdit.new()
	field.placeholder_text = placeholder
	field.secret = secret
	field.custom_minimum_size = Vector2(0, 44)
	field.add_theme_font_size_override("font_size", 19)
	# Solo texto escrito: sin menú, atajos de pegar, arrastrar ni pegar con el botón del medio.
	field.context_menu_enabled = false
	field.shortcut_keys_enabled = false
	field.drag_and_drop_selection_enabled = false
	field.middle_mouse_paste_enabled = false
	field.max_length = PasswordRules.MAX_LENGTH
	if secret:
		field.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_PASSWORD
	parent.add_child(field)
	return field


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
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(action)
	parent.add_child(button)
	return button
