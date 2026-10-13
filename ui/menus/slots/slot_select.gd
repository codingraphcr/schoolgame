class_name SlotSelect
extends Control
## Selección de partida: las 3 ranuras de la identidad actual (SaveManager), como tarjetas con año,
## capítulo, nivel, lugar, tiempo jugado, último guardado y estado (correcta, recuperada desde el
## respaldo, dañada, de una versión más nueva o posible conflicto).
##
## Dos modos: NEW (elegir dónde empezar una partida nueva; sobrescribir pide confirmación) y LOAD
## (elegir qué partida cargar). Borrar pide doble confirmación. Se navega con flechas, Enter y Esc.
## Emite chosen(ranura) o cancelled; quien la abre decide qué hacer (SaveManager.new_game / continue).

signal chosen(slot: int)
signal cancelled

enum Mode { NEW, LOAD }

const CYAN := Color("3ef2ff")
const MAG := Color("ff3ea5")
const GREEN := Color("5dff9a")
const YELLOW := Color("ffd84a")
const TEXT := Color("d8e4ff")
const DIM := Color("8a96b8")
const PANEL := Color("070b18")
const YEAR_NAMES := { "decimo": "Décimo", "undecimo": "Undécimo", "duodecimo": "Duodécimo" }
const STATE_TEXT := {
	"ok": ["Correcta", GREEN],
	"recuperada": ["Recuperada desde la copia de respaldo", YELLOW],
	"danada": ["Dañada: no se puede cargar", MAG],
	"incompatible": ["De una versión más nueva del juego", YELLOW],
	"vacia": ["Vacía", DIM],
}

var mode := Mode.LOAD

var _title: Label
var _cards: HBoxContainer
var _dialog: ConfirmationDialog


static func open(parent: Node, how: Mode) -> SlotSelect:
	var screen := SlotSelect.new()
	screen.name = "SlotSelect"
	screen.mode = how
	parent.add_child(screen)
	return screen


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	refresh()
	get_node("/root/SaveManager").slots_changed.connect(refresh)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not (_dialog and _dialog.visible):
		get_viewport().set_input_as_handled()
		cancel()


func cancel() -> void:
	cancelled.emit()
	queue_free()


## Vuelve a dibujar las tarjetas con el estado actual de las ranuras.
func refresh() -> void:
	_title.text = "NUEVA PARTIDA · ELIGE UNA RANURA" if mode == Mode.NEW else "CARGAR PARTIDA"
	for child in _cards.get_children():
		child.queue_free()
	var first_button: Button = null
	for slot in range(1, SaveManager.SLOTS + 1):
		var button := _card(get_node("/root/SaveManager").slot_info(slot))
		if first_button == null and button and not button.disabled:
			first_button = button
	if first_button and not DisplayServer.is_touchscreen_available():
		first_button.grab_focus.call_deferred()


## Lo que pasa al elegir una ranura (con las confirmaciones que correspondan).
func pick(slot: int) -> void:
	var info: Dictionary = get_node("/root/SaveManager").slot_info(slot)
	var empty: bool = info["estado"] == "vacia"
	if mode == Mode.NEW and not empty:
		_confirm("La ranura %d ya tiene una partida (%s). ¿Empezar una partida nueva encima? La anterior se perderá." % [slot, _summary(info)],
			"Sobrescribir", func() -> void: _choose(slot))
	elif mode == Mode.LOAD and info["conflicto"]:
		_confirm("Posible conflicto: esta partida es más vieja que la última que se jugó en esta computadora (puede venir de otra). ¿Cargarla igual?",
			"Cargar igual", func() -> void: _choose(slot))
	else:
		_choose(slot)


## Borrar: doble confirmación.
func ask_delete(slot: int) -> void:
	_confirm("¿Borrar la partida de la ranura %d?" % slot, "Borrar", func() -> void:
		_confirm("Seguro: la partida de la ranura %d se borra para siempre y no se puede recuperar." % slot, "Sí, borrarla",
			func() -> void: get_node("/root/SaveManager").delete_slot(slot)))


func _choose(slot: int) -> void:
	chosen.emit(slot)
	queue_free()


func _summary(info: Dictionary) -> String:
	var meta: Dictionary = info["meta"]
	return "%s · %s" % [_chapter_text(meta), format_time(int(meta.get("tiempo_jugado", 0)))]


static func _chapter_text(meta: Dictionary) -> String:
	var chapter := int(meta.get("capitulo", 0))
	if chapter == 0:
		return "Prólogo"
	return "%s — Capítulo %d · Nivel %d" % [YEAR_NAMES.get(meta.get("anio", ""), "Décimo"), chapter, int(meta.get("nivel", 0))]


## 2903 → "00:48:23".
static func format_time(seconds: int) -> String:
	return "%02d:%02d:%02d" % [seconds / 3600, (seconds / 60) % 60, seconds % 60]


## Fecha local del último guardado (informativa).
static func format_date(unix: int) -> String:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var d := Time.get_datetime_dict_from_unix_time(unix + bias)
	return "%02d/%02d/%d %02d:%02d" % [d["day"], d["month"], d["year"], d["hour"], d["minute"]]


func _confirm(text: String, ok_text: String, action: Callable) -> void:
	if _dialog:
		_dialog.queue_free()
	_dialog = ConfirmationDialog.new()
	_dialog.title = "Confirmar"
	_dialog.dialog_text = text
	_dialog.dialog_autowrap = true
	_dialog.min_size = Vector2i(520, 0)
	_dialog.ok_button_text = ok_text
	_dialog.cancel_button_text = "Cancelar"
	_dialog.confirmed.connect(action, CONNECT_DEFERRED)
	add_child(_dialog)
	_dialog.popup_centered()
	_dialog.get_cancel_button().grab_focus.call_deferred()


# --- Construcción ---

func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.01, 0.04, 0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 60
	column.offset_right = -60
	column.offset_top = 50
	column.offset_bottom = -40
	column.add_theme_constant_override("separation", 22)
	add_child(column)
	_title = _label(column, "", CYAN, 26)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cards = HBoxContainer.new()
	_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards.add_theme_constant_override("separation", 18)
	column.add_child(_cards)
	var back := Button.new()
	back.text = "◀ Volver (Esc)"
	back.custom_minimum_size = Vector2(200, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(cancel)
	column.add_child(back)


## Una tarjeta. Devuelve su botón principal (o null si no hay nada que elegir).
func _card(info: Dictionary) -> Button:
	var slot: int = info["slot"]
	var state: String = info["estado"]
	var panel := PanelContainer.new()
	panel.name = "Ranura%d" % slot
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PANEL, 0.95)
	style.set_border_width_all(2)
	style.border_color = CYAN if state in ["ok", "recuperada"] else (MAG if state == "danada" else Color("2c3a66"))
	style.set_corner_radius_all(8)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	_cards.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_label(box, "RANURA %d" % slot, CYAN, 20)
	var meta: Dictionary = info["meta"]
	var usable: bool = state in ["ok", "recuperada"]
	if usable:
		_label(box, _chapter_text(meta), TEXT, 18)
		_label(box, String(meta.get("lugar", "")) if not String(meta.get("lugar", "")).is_empty() else "—", TEXT, 16)
		_label(box, "Tiempo jugado: %s" % format_time(int(meta.get("tiempo_jugado", 0))), TEXT, 16)
		_label(box, "Guardada: %s" % format_date(int(meta.get("guardada", 0))), DIM, 14)
	elif state == "vacia":
		_label(box, "Nueva partida" if mode == Mode.NEW else "Vacía", DIM, 18)
	var status: Array = STATE_TEXT.get(state, ["", TEXT])
	if state != "vacia":
		_label(box, "Estado: %s" % status[0], status[1], 14)
	if info["conflicto"]:
		_label(box, "⚠ Posible conflicto con otra computadora", YELLOW, 14)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var main := Button.new()
	main.name = "Elegir"
	main.custom_minimum_size = Vector2(0, 44)
	if mode == Mode.NEW:
		main.text = "Empezar aquí" if state == "vacia" else "Sobrescribir"
		main.disabled = state == "incompatible"
	else:
		main.text = "Cargar"
		main.disabled = not usable
	main.pressed.connect(pick.bind(slot))
	box.add_child(main)
	if state != "vacia" and state != "incompatible":
		var delete := Button.new()
		delete.name = "Borrar"
		delete.text = "Borrar"
		delete.custom_minimum_size = Vector2(0, 36)
		delete.pressed.connect(ask_delete.bind(slot))
		box.add_child(delete)
	return main


func _label(parent: Control, text: String, color: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label
