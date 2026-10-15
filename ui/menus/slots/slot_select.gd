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
## Estilo de la maqueta de Ariel (ranuras): violeta, lavanda y la tipografía Cinzel.
const VIOLET := Color("8a5cff")
const TITLE := Color("ece4ff")
const INFO := Color("c3b8e8")
const OK_COLOR := Color("5dffc8")
const CINZEL := preload("res://assets/fonts/cinzel/Cinzel.ttf")
const THUMB_SOURCE := preload("res://assets/art/ui/menu_fondo.webp")
## Pedazos del fondo del menú para las miniaturas (el pasillo de servidores y la columna de glitch, sin rombos:
## el rombo lo dibuja la miniatura).
const THUMB_REGIONS: Array[Rect2] = [Rect2(820, 610, 560, 230), Rect2(560, 640, 500, 210), Rect2(860, 30, 500, 210)]
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


# --- Construcción (estilo de la maqueta de Ariel: tarjetas con borde violeta, Cinzel y miniaturas) ---

func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.0, 0.07, 0.62)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 150
	column.offset_right = -110
	column.offset_top = 46
	column.offset_bottom = -34
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	_title = _label(column, "", TITLE, 30, _cinzel(700, 6))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_shadow_color", Color(VIOLET, 0.6))
	_title.add_theme_constant_override("shadow_outline_size", 6)
	var rule := TitleRule.new()
	rule.custom_minimum_size = Vector2(0, 22)
	column.add_child(rule)
	_cards = HBoxContainer.new()
	_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards.add_theme_constant_override("separation", 26)
	column.add_child(_cards)
	var back := Button.new()
	back.name = "Volver"
	back.text = "◀  Volver (Esc)"
	back.custom_minimum_size = Vector2(300, 46)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_button(back, 18, true)
	back.pressed.connect(cancel)
	column.add_child(back)
	# Abajo a la izquierda, el nombre del juego y la versión (como en la maqueta).
	var brand := VBoxContainer.new()
	brand.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	brand.offset_left = 22
	brand.offset_top = -70
	brand.offset_bottom = -14
	brand.add_theme_constant_override("separation", 0)
	add_child(brand)
	for line: Label in [_label(brand, "NULLVEIL", TEXT, 16, _cinzel(600, 5)), _label(brand, "BEYOND THE FIREWALL", DIM, 10, _cinzel(500, 3)),
			_label(brand, "v" + String(ProjectSettings.get_setting("application/config/version", "0.1.0")), DIM, 10, _cinzel(500, 2))]:
		line.autowrap_mode = TextServer.AUTOWRAP_OFF


## Una tarjeta. Devuelve su botón principal (o null si no hay nada que elegir).
func _card(info: Dictionary) -> Button:
	var slot: int = info["slot"]
	var state: String = info["estado"]
	var usable: bool = state in ["ok", "recuperada"]
	var panel := PanelContainer.new()
	panel.name = "Ranura%d" % slot
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.02, 0.09, 0.86)
	style.set_border_width_all(2)
	style.border_color = Color(MAG, 0.8) if state == "danada" else Color(VIOLET, 0.75 if state != "vacia" else 0.45)
	style.set_content_margin_all(18)
	style.content_margin_top = 14
	panel.add_theme_stylebox_override("panel", style)
	_cards.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var decor := CardDecor.new()
	decor.color = style.border_color
	panel.add_child(decor)
	# Cabecera: el número grande, «RANURA n» y un rombo.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	var number := _label(head, "%02d" % slot, TITLE, 34, _mono())
	number.autowrap_mode = TextServer.AUTOWRAP_OFF
	var name_label := _label(head, "RANURA %d" % slot, TEXT, 16, _cinzel(600, 4))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon := Diamond.new()
	icon.custom_minimum_size = Vector2(22, 22)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.color = style.border_color.lightened(0.3)
	head.add_child(icon)
	var line := ColorRect.new()
	line.color = Color(VIOLET, 0.35)
	line.custom_minimum_size = Vector2(0, 1)
	box.add_child(line)
	var meta: Dictionary = info["meta"]
	var info_font := _cinzel(500, 2)
	if usable:
		_label(box, _chapter_text(meta), TEXT, 14, info_font).uppercase = true
		var place := String(meta.get("lugar", ""))
		_label(box, place if not place.is_empty() else "—", TEXT, 14, info_font).uppercase = true
		_label(box, "Tiempo jugado: %s" % format_time(int(meta.get("tiempo_jugado", 0))), INFO, 13, info_font).uppercase = true
		_label(box, "Guardada: %s" % format_date(int(meta.get("guardada", 0))), INFO, 13, info_font).uppercase = true
	elif state == "vacia":
		_label(box, "Nueva partida" if mode == Mode.NEW else "Vacía", DIM, 15, info_font).uppercase = true
	var status: Array = STATE_TEXT.get(state, ["", TEXT])
	if state != "vacia":
		_label(box, "Estado: %s" % status[0], OK_COLOR if state == "ok" else status[1], 13, info_font).uppercase = true
	if info["conflicto"]:
		_label(box, "⚠ Posible conflicto con otra computadora", YELLOW, 12, info_font).uppercase = true
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	box.add_child(_thumbnail(slot, state))
	var main := Button.new()
	main.name = "Elegir"
	main.custom_minimum_size = Vector2(0, 42)
	if mode == Mode.NEW:
		main.text = "Empezar aquí" if state == "vacia" else "Sobrescribir"
		main.disabled = state == "incompatible"
	else:
		main.text = "Cargar"
		main.disabled = not usable
	_style_button(main, 16)
	main.pressed.connect(pick.bind(slot))
	box.add_child(main)
	if state != "vacia" and state != "incompatible":
		var delete := Button.new()
		delete.name = "Borrar"
		delete.text = "Borrar"
		delete.custom_minimum_size = Vector2(0, 38)
		_style_button(delete, 16)
		delete.pressed.connect(ask_delete.bind(slot))
		box.add_child(delete)
	# La tarjeta elegida (con el foco en uno de sus botones) brilla más.
	var base_border := style.border_color
	for button: Button in box.find_children("*", "Button", false, false):
		button.focus_entered.connect(_light_card.bind(style, base_border, decor, true))
		button.focus_exited.connect(_light_card.bind(style, base_border, decor, false))
	return main


func _light_card(style: StyleBoxFlat, base_border: Color, decor: CardDecor, lit: bool) -> void:
	style.shadow_color = Color(VIOLET, 0.45 if lit else 0.0)
	style.shadow_size = 14 if lit else 0
	style.set_border_width_all(3 if lit else 2)
	style.border_color = base_border.lightened(0.35) if lit else base_border
	if is_instance_valid(decor):
		decor.color = style.border_color
		decor.queue_redraw()


## Miniatura del lugar: un pedazo del fondo del menú (uno distinto por ranura) con un rombo que brilla.
func _thumbnail(slot: int, state: String) -> Control:
	var frame := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.01, 0.05)
	style.set_border_width_all(1)
	style.border_color = Color(VIOLET, 0.45)
	frame.add_theme_stylebox_override("panel", style)
	frame.custom_minimum_size = Vector2(0, 104)
	frame.clip_contents = true
	var picture := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = THUMB_SOURCE
	atlas.region = THUMB_REGIONS[(slot - 1) % THUMB_REGIONS.size()]
	picture.texture = atlas
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.modulate = Color(1, 1, 1, 0.9) if state != "vacia" else Color(0.5, 0.5, 0.6, 0.6)
	frame.add_child(picture)
	var glow := Diamond.new()
	glow.color = Color("c9a8ff")
	glow.glowing = true
	frame.add_child(glow)
	return frame


## Botón con contorno (como la maqueta): transparente, borde violeta; con el foco, borde claro, brillo y un
## rombo a la izquierda. El texto se ve en mayúsculas (el texto del botón no cambia).
func _style_button(button: Button, size: int, angled := false) -> void:
	button.add_theme_font_override("font", _cinzel(600, 4))
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(DIM, 0.6))
	button.text = button.text.to_upper()
	var lit := _button_box(Color(VIOLET, 0.2), Color("d9c4ff"), 2, 0.5, angled)
	button.add_theme_stylebox_override("normal", _button_box(Color(0.03, 0.02, 0.08, 0.7), Color(VIOLET, 0.7), 1, 0.0, angled))
	button.add_theme_stylebox_override("hover", lit)
	button.add_theme_stylebox_override("pressed", lit)
	button.add_theme_stylebox_override("focus", _button_box(Color(0, 0, 0, 0), Color("d9c4ff"), 2, 0.5, angled))
	button.add_theme_stylebox_override("disabled", _button_box(Color(0.03, 0.02, 0.08, 0.5), Color(DIM, 0.35), 1, 0.0, angled))
	button.focus_entered.connect(button.queue_redraw)
	button.focus_exited.connect(button.queue_redraw)
	button.draw.connect(func() -> void:
		if button.has_focus():
			Diamond.paint(button, Vector2(-2.0, button.size.y * 0.5), 7.0, Color("d9c4ff"), Color(0.05, 0.02, 0.12)))


func _button_box(bg: Color, border: Color, width: int, glow: float, angled: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(2)
	box.content_margin_left = 16
	box.content_margin_right = 16
	if glow > 0.0:
		box.shadow_color = Color(VIOLET, glow)
		box.shadow_size = 8
	if angled:
		box.skew = Vector2(0.12, 0)
	return box


func _label(parent: Control, text: String, color: Color, size: int, font: Font = null) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	if font:
		label.add_theme_font_override("font", font)
	parent.add_child(label)
	return label


## Cinzel (la tipografía del menú, con remates afilados como el logo) con ese grosor y espacio entre letras.
static func _cinzel(weight: int, spacing: int) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = CINZEL
	font.variation_opentype = { TextServerManager.get_primary_interface().name_to_tag("wght"): weight }
	font.spacing_glyph = spacing
	return font


## Los números grandes de las ranuras («01»): una letra de pantalla, monoespaciada y gruesa.
static func _mono() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "Courier New", "monospace"])
	font.font_weight = 800
	return font


## Esquinas decoradas de la tarjeta (corchetes en las esquinas y muescas en los costados, como la maqueta).
## Va dentro del PanelContainer (que lo estira como al contenido) y dibuja sobre el borde.
class CardDecor extends Control:
	var color := Color.WHITE

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		# El panel deja 18 px de margen (14 arriba): el borde está por fuera de este control.
		var r := Rect2(Vector2(-18, -14), size + Vector2(36, 32))
		var bright := color.lightened(0.45)
		var arm := 18.0
		for corner: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			var dx := arm if corner.x == r.position.x else -arm
			var dy := arm if corner.y == r.position.y else -arm
			draw_polyline(PackedVector2Array([corner + Vector2(0, dy), corner, corner + Vector2(dx, 0)]), bright, 3.0)
		for y: float in [r.position.y + r.size.y * 0.42, r.position.y + r.size.y * 0.62]:
			draw_rect(Rect2(Vector2(r.position.x - 2, y), Vector2(4, 12)), Color(bright, 0.8))
			draw_rect(Rect2(Vector2(r.end.x - 2, y - 30), Vector2(4, 8)), Color(bright, 0.6))


## Rombo con un rombo adentro (el símbolo de Nullveil). glowing: centrado en el control, con halo.
class Diamond extends Control:
	var color := Color.WHITE
	var glowing := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		if glowing:
			for k in 5:
				draw_colored_polygon(Diamond.shape(center, 26.0 - k * 4.0), Color(color, 0.05 + k * 0.03))
			Diamond.paint(self, center, 15.0, color, Color(0.12, 0.04, 0.3, 0.9))
		else:
			Diamond.paint(self, center, minf(size.x, size.y) * 0.45, color, Color(0, 0, 0, 0))

	static func shape(center: Vector2, r: float) -> PackedVector2Array:
		return PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0)])

	## Un rombo con borde y otro chiquito adentro, dibujado en cualquier CanvasItem.
	static func paint(ci: CanvasItem, center: Vector2, r: float, line: Color, fill: Color) -> void:
		var outer := Diamond.shape(center, r)
		if fill.a > 0.0:
			ci.draw_colored_polygon(outer, fill)
		outer.append(outer[0])
		ci.draw_polyline(outer, line, 1.6, true)
		ci.draw_colored_polygon(Diamond.shape(center, r * 0.42), line)


## La línea bajo el título: se desvanece hacia los costados, con marcas y un rombo en el medio.
class TitleRule extends Control:
	func _draw() -> void:
		var y := size.y * 0.5
		var mid := size.x * 0.5
		var half := minf(size.x * 0.32, 430.0)
		var steps := 24
		for k in steps:
			var t := float(k) / steps
			var step := half / steps
			draw_line(Vector2(mid + half * t, y), Vector2(mid + half * t + step, y), Color(0.85, 0.78, 1.0, 1.0 - t), 1.5)
			draw_line(Vector2(mid - half * t, y), Vector2(mid - half * t - step, y), Color(0.85, 0.78, 1.0, 1.0 - t), 1.5)
		for side: float in [-1.0, 1.0]:
			draw_rect(Rect2(Vector2(mid + side * half * 0.62 - 8.0, y - 1.5), Vector2(16, 3)), Color(0.9, 0.85, 1.0, 0.8))
		Diamond.paint(self, Vector2(mid, y), 10.0, Color("e2d4ff"), Color(0.08, 0.03, 0.18))
