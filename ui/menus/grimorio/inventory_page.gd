class_name InventoryPage
extends Control
## El INVENTARIO del Grimorio (la página principal; referencia de Ariel en
## docs/arte/referencias/grimorio_inventario_concepto.webp, estilo Hollow Knight):
##   Izquierda: FRAGMENTOS (vida: un solo símbolo dividido en cuatro, cada fragmento ilumina una parte),
##     ENERGÍA (otro símbolo en cuatro, cian), ARMA (la Nullblade grande y en vertical), HABILIDADES (la
##     definitiva en grande y las demás: dash, Visión Digital, curación, doble salto) y ECOS (la moneda y
##     la cantidad).
##   Centro: los coleccionables, con sus íconos y cantidades.
##   Derecha: la descripción de lo elegido (título, imagen, texto y datos).
## Lo que todavía no se tiene aparece apagado (o con candado) y su descripción es «???».

signal close_requested

const DESIGN := Vector2(1280, 720)
const NIGHT := Color("0a0716")
const PANEL := Color("0e0a1d")
const LINE := Color("4b2bd6")
const NEON := Color("a47cff")
const PALE := Color("e9e1ff")
const MUTED := Color("9a8cc4")
const DIM := Color("3d3560")
const SWORD := preload("res://assets/art/items/nullblade/nullblade_espada.png")
## Casillas del centro (los coleccionables): columnas y filas.
const GRID := Vector2i(4, 3)
const LOCKED_TEXT := "Aún no lo descubres. Sigue avanzando en la historia para completar esta página."

var _entries: Array[GrimorioEntry] = []
var _group := ButtonGroup.new()
var _canvas: Control
var _title: Label
var _subtitle: Label
var _text: Label
var _facts: GridContainer
var _facts_header: Label
var _art: Control
var _art_entry: GrimorioEntry
var _art_symbol: LifeFragmentIcon
var _ecos_amount: Label
var _first_slot: InventorySlot
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -DESIGN.x / 2.0
	offset_top = -DESIGN.y / 2.0
	offset_right = DESIGN.x / 2.0
	offset_bottom = DESIGN.y / 2.0
	_canvas = Control.new()
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.size = DESIGN
	_canvas.draw.connect(_draw_frame)
	add_child(_canvas)
	_build_description()
	var close := Button.new()
	close.text = "CERRAR"
	close.flat = true
	close.position = Vector2(1140, 650)
	close.size = Vector2(96, 26)
	close.add_theme_font_size_override(&"font_size", 13)
	close.add_theme_color_override(&"font_color", MUTED)
	close.add_theme_color_override(&"font_hover_color", PALE)
	close.pressed.connect(close_requested.emit)
	add_child(close)


func _process(delta: float) -> void:
	_time += delta
	_canvas.queue_redraw()
	# Las casillas tienen partes animadas (la moneda, la definitiva).
	for slot in slots():
		slot.queue_redraw()
	if _art:
		_art.queue_redraw()


## Arma las casillas con las entradas del INVENTARIO (categoría ARSENAL del Grimorio).
func setup(entries: Array[GrimorioEntry]) -> void:
	_entries = entries
	for child in get_children():
		if child is InventorySlot:
			child.queue_free()
	_group = ButtonGroup.new()
	_first_slot = null
	var abilities: Array[GrimorioEntry] = []
	var collectibles: Array[GrimorioEntry] = []
	for entry in entries:
		match entry.inventory_kind:
			GrimorioEntry.InventoryKind.FRAGMENTO_VIDA:
				_add_fragment_slot(entry, Rect2(96, 138, 70, 84), false)
			GrimorioEntry.InventoryKind.FRAGMENTO_ENERGIA:
				_add_fragment_slot(entry, Rect2(96, 262, 70, 84), true)
			GrimorioEntry.InventoryKind.ARMA:
				_add_slot(entry, Rect2(84, 392, 112, 214), InventorySlot.Frame.SQUARE, _paint_weapon)
			GrimorioEntry.InventoryKind.DEFINITIVA:
				_add_slot(entry, Rect2(250, 400, 104, 104), InventorySlot.Frame.CIRCLE, _paint_icon)
			GrimorioEntry.InventoryKind.HABILIDAD:
				abilities.append(entry)
			GrimorioEntry.InventoryKind.ECOS:
				_add_slot(entry, Rect2(86, 624, 58, 58), InventorySlot.Frame.CIRCLE, _paint_ecos)
			_:
				collectibles.append(entry)
	# Habilidades: 4 por fila (la quinta, la Inmersión Digital, va abajo).
	for i in abilities.size():
		_add_slot(abilities[i], Rect2(214 + (i % 4) * 46, 524 + (i / 4) * 48, 44, 44), InventorySlot.Frame.HEX, _paint_icon)
	# Coleccionables: los que ya tiene primero; el resto de las casillas, apagadas.
	collectibles.sort_custom(func(a: GrimorioEntry, b: GrimorioEntry) -> bool: return _unlocked(a) and not _unlocked(b))
	for i in GRID.x * GRID.y:
		var at := Vector2(466 + (i % GRID.x) * 96, 150 + (i / GRID.x) * 96)
		var entry: GrimorioEntry = collectibles[i] if i < collectibles.size() else null
		_add_slot(entry, Rect2(at, Vector2(80, 80)), InventorySlot.Frame.SQUARE, _paint_collectible)
	_ecos_amount.text = str(_ecos())
	if _first_slot:
		_first_slot.set_pressed_no_signal(true)
		show_entry(_first_slot.entry)


## Pone el foco en el arma (para el teclado o el mando).
func focus_first() -> void:
	if _first_slot:
		_first_slot.grab_focus()


func slots() -> Array[InventorySlot]:
	var result: Array[InventorySlot] = []
	for child in get_children():
		if child is InventorySlot and not child.is_queued_for_deletion():
			result.append(child)
	return result


func _add_slot(entry: GrimorioEntry, rect: Rect2, frame: InventorySlot.Frame, painter: Callable) -> InventorySlot:
	var slot := InventorySlot.new()
	slot.entry = entry
	slot.unlocked = entry != null and _unlocked(entry)
	slot.frame = frame
	slot.painter = painter
	slot.position = rect.position
	slot.size = rect.size
	slot.button_group = _group
	slot.pressed.connect(func() -> void: show_entry(entry))
	# Con teclado o mando, se muestra al pasar por la casilla.
	slot.focus_entered.connect(func() -> void:
		slot.set_pressed_no_signal(true)
		show_entry(entry))
	add_child(slot)
	# Al abrir se elige el arma si ya la tiene; si no, lo primero que Kai tenga.
	if slot.unlocked and (_first_slot == null or entry.inventory_kind == GrimorioEntry.InventoryKind.ARMA):
		_first_slot = slot
	return slot


## El símbolo de los fragmentos (vida o energía) con las partes juntadas.
func _add_fragment_slot(entry: GrimorioEntry, rect: Rect2, energy: bool) -> void:
	var slot := _add_slot(entry, rect, InventorySlot.Frame.NONE, Callable())
	var icon := LifeFragmentIcon.new()
	icon.energy = energy
	icon.position = Vector2.ZERO
	icon.size = rect.size
	icon.count = _fragments(energy)
	slot.add_child(icon)


# --- Descripción (derecha) ---

func _build_description() -> void:
	_title = _label(Vector2(892, 112), Vector2(344, 44), 30, PALE)
	_subtitle = _label(Vector2(894, 154), Vector2(344, 22), 14, MUTED)
	_art = Control.new()
	_art.position = Vector2(890, 188)
	_art.size = Vector2(348, 168)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.draw.connect(_draw_art)
	add_child(_art)
	_art_symbol = LifeFragmentIcon.new()
	_art_symbol.position = Vector2(134, 14)
	_art_symbol.size = Vector2(80, 140)
	_art.add_child(_art_symbol)
	# Texto y datos, uno debajo del otro (se puede desplazar si el texto es largo).
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(892, 370)
	scroll.size = Vector2(346, 274)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 10)
	scroll.add_child(column)
	_text = Label.new()
	_text.add_theme_font_size_override(&"font_size", 14)
	_text.add_theme_color_override(&"font_color", PALE)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = 330
	column.add_child(_text)
	_facts_header = Label.new()
	_facts_header.text = "◇  DATOS"
	_facts_header.add_theme_font_size_override(&"font_size", 14)
	_facts_header.add_theme_color_override(&"font_color", PALE)
	column.add_child(_facts_header)
	_facts = GridContainer.new()
	_facts.columns = 2
	_facts.add_theme_constant_override(&"v_separation", 4)
	column.add_child(_facts)
	_ecos_amount = _label(Vector2(156, 640), Vector2(220, 40), 30, PALE)


func _label(at: Vector2, area: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = area
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	add_child(label)
	return label


func show_entry(entry: GrimorioEntry) -> void:
	var unlocked := entry != null and _unlocked(entry)
	_art_entry = entry if unlocked else null
	_title.text = entry.title if unlocked else "???"
	_subtitle.text = entry.subtitle if unlocked else ("Página sin descubrir" if entry else "Casilla vacía")
	_text.text = entry.text if unlocked else LOCKED_TEXT
	var fragment := unlocked and entry.inventory_kind in [GrimorioEntry.InventoryKind.FRAGMENTO_VIDA, GrimorioEntry.InventoryKind.FRAGMENTO_ENERGIA]
	_art_symbol.visible = fragment
	if fragment:
		_art_symbol.energy = entry.inventory_kind == GrimorioEntry.InventoryKind.FRAGMENTO_ENERGIA
		_art_symbol.count = _fragments(_art_symbol.energy)
	for child in _facts.get_children():
		child.queue_free()
	_facts_header.visible = unlocked
	if not unlocked:
		return
	var facts: Dictionary[String, String] = {}
	if entry.action != &"":
		facts["Tecla"] = GameSettings.key_name(entry.action)
	match entry.inventory_kind:
		GrimorioEntry.InventoryKind.FRAGMENTO_VIDA:
			facts["Fragmentos"] = "%d / %d" % [_fragments(false), GameState.LIFE_FRAGMENTS_PER_MASK]
		GrimorioEntry.InventoryKind.FRAGMENTO_ENERGIA:
			facts["Fragmentos"] = "%d / %d" % [_fragments(true), GameState.ENERGY_FRAGMENTS_PER_CELL]
		GrimorioEntry.InventoryKind.ECOS:
			facts["Tienes"] = str(_ecos())
	facts.merge(entry.facts)
	for key in facts:
		_facts.add_child(_fact(key, MUTED, false))
		_facts.add_child(_fact(facts[key], PALE, true))


func _fact(text: String, color: Color, value: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", 13)
	label.add_theme_color_override(&"font_color", color)
	if value:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 190
	return label


# --- Datos ---

func _unlocked(entry: GrimorioEntry) -> bool:
	return entry.is_unlocked(get_node_or_null("/root/GameState"))


func _fragments(energy: bool) -> int:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return 0
	return game_state.energy_fragments if energy else game_state.life_fragments


func _ecos() -> int:
	var economy := get_node_or_null("/root/Economy")
	return economy.ecos if economy else 0


# --- Dibujo ---

func _draw_frame() -> void:
	var c := _canvas
	# Fondo oscuro de toda la pantalla (no se ve el juego de atrás).
	c.draw_rect(Rect2(-400, -200, DESIGN.x + 800, DESIGN.y + 400), Color(NIGHT, 0.96))
	var outer := Rect2(20, 28, 1240, 668)
	c.draw_rect(outer, NIGHT)
	# Marco de neón con esquinas en ángulo y brillo.
	for i in 3:
		c.draw_rect(outer.grow(2 + i * 3), Color(LINE, 0.08), false, 2.0)
	c.draw_rect(outer, Color(LINE, 0.9), false, 2.0)
	c.draw_rect(outer.grow(-8), Color(NEON, 0.25), false, 1.0)
	for corner: Vector2 in [outer.position, Vector2(outer.end.x, outer.position.y), outer.end, Vector2(outer.position.x, outer.end.y)]:
		var sx := 1.0 if corner.x < 640.0 else -1.0
		var sy := 1.0 if corner.y < 360.0 else -1.0
		c.draw_line(corner + Vector2(-4 * sx, 18 * sy), corner + Vector2(-4 * sx, -4 * sy), NEON, 2.0)
		c.draw_line(corner + Vector2(-4 * sx, -4 * sy), corner + Vector2(18 * sx, -4 * sy), NEON, 2.0)
	# Columnas: separadores con rombos.
	for x: float in [420.0, 862.0]:
		c.draw_line(Vector2(x, 110), Vector2(x, 660), Color(NEON, 0.35), 1.0)
		for y: float in [110.0, 385.0, 660.0]:
			_diamond(Vector2(x, y), 6.0, NEON)
	# Títulos de las secciones.
	_section("FRAGMENTOS", Vector2(76, 114), 330)
	_section("ENERGÍA", Vector2(76, 240), 330)
	_section("ARMA", Vector2(76, 370), 120)
	_section("HABILIDADES", Vector2(214, 370), 190)
	_section("COLECCIONABLES", Vector2(466, 114), 370)
	# Cantidades de los fragmentos junto a sus símbolos.
	var font := ThemeDB.fallback_font
	c.draw_string(font, Vector2(186, 178), "Vida", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, MUTED)
	c.draw_string(font, Vector2(186, 206), "%d / %d" % [_fragments(false), GameState.LIFE_FRAGMENTS_PER_MASK], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, PALE)
	c.draw_string(font, Vector2(186, 302), "Energía", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, MUTED)
	c.draw_string(font, Vector2(186, 330), "%d / %d" % [_fragments(true), GameState.ENERGY_FRAGMENTS_PER_CELL], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, LifeFragmentIcon.CYAN)
	c.draw_string(font, Vector2(158, 638), "ECOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MUTED)
	# Separador de los coleccionables y descripción vacía.
	c.draw_line(Vector2(466, 460), Vector2(834, 460), Color(NEON, 0.3), 1.0)
	_diamond(Vector2(650, 460), 4.0, NEON)


func _section(title: String, at: Vector2, width: float) -> void:
	var c := _canvas
	_diamond(at + Vector2(4, -5), 4.0, NEON)
	c.draw_string(ThemeDB.fallback_font, at + Vector2(16, 0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, PALE)
	var text_width := ThemeDB.fallback_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	c.draw_line(at + Vector2(24 + text_width, -5), at + Vector2(width, -5), Color(NEON, 0.35), 1.0)


func _diamond(center: Vector2, r: float, color: Color) -> void:
	_canvas.draw_polyline(PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r),
		center + Vector2(-r, 0), center + Vector2(0, -r)]), color, 1.0, true)


## La imagen de la descripción: la ilustración del objeto o su ícono en grande.
func _draw_art() -> void:
	var rect := Rect2(Vector2.ZERO, _art.size)
	_art.draw_rect(rect, PANEL)
	_art.draw_rect(rect, Color(NEON, 0.5), false, 1.0)
	var entry := _art_entry
	if entry == null:
		_art.draw_string(ThemeDB.fallback_font, rect.get_center() + Vector2(-10, 14), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, DIM)
		return
	if entry.image:
		var tex := entry.image.get_size()
		var fit := minf((rect.size.x - 16) / tex.x, (rect.size.y - 16) / tex.y)
		var shown := tex * fit
		_art.draw_texture_rect(entry.image, Rect2(rect.get_center() - shown / 2.0, shown), false)
	elif entry.icon != &"":
		_draw_glyph(_art, entry.icon, rect.get_center(), 48.0, true)


func _paint_weapon(slot: InventorySlot, rect: Rect2) -> void:
	var tex := SWORD.get_size()
	var fit := (rect.size.y - 6.0) / tex.y
	var shown := tex * fit
	var center := rect.get_center()
	if slot.unlocked:
		for i in 3:
			slot.draw_circle(center, 30.0 + i * 12.0, Color(NEON, 0.05))
	# La espada con la punta hacia arriba (la imagen la tiene hacia abajo).
	slot.draw_set_transform(center, PI, Vector2.ONE)
	slot.draw_texture_rect(SWORD, Rect2(-shown / 2.0, shown), false, Color.WHITE if slot.unlocked else Color(0.3, 0.24, 0.5, 0.35))
	slot.draw_set_transform(Vector2.ZERO)
	if not slot.unlocked:
		_draw_glyph(slot, &"candado", center, 14.0, false)


## La moneda de los Ecos: anillos de energía con un núcleo (como en la referencia).
func _paint_ecos(slot: InventorySlot, rect: Rect2) -> void:
	var center := rect.get_center()
	var r := rect.size.x * 0.5
	var color := NEON if slot.unlocked else DIM
	if slot.unlocked:
		slot.draw_circle(center, r * 0.9, Color(LINE, 0.25))
	slot.draw_arc(center, r * 0.85, 0.0, TAU, 40, color, 2.0, true)
	slot.draw_arc(center, r * 0.6, _time, _time + PI * 1.4, 24, Color(color, 0.8), 1.5, true)
	slot.draw_circle(center, r * 0.32, color)
	slot.draw_circle(center, r * 0.14, PALE if slot.unlocked else NIGHT)
	for i in 4:
		var angle := TAU * i / 4.0 + PI / 4.0
		var dir := Vector2(cos(angle), sin(angle))
		slot.draw_line(center + dir * r * 0.95, center + dir * r * 1.1, color, 1.5)


func _paint_icon(slot: InventorySlot, rect: Rect2) -> void:
	if not slot.unlocked:
		_draw_glyph(slot, &"candado", rect.get_center(), rect.size.x * 0.32, false)
		return
	_draw_glyph(slot, slot.entry.icon, rect.get_center(), rect.size.x * 0.42, true)


func _paint_collectible(slot: InventorySlot, rect: Rect2) -> void:
	if slot.entry == null or not slot.unlocked:
		_diamond_on(slot, rect.get_center(), 8.0, DIM)
		return
	if slot.entry.image:
		var tex := slot.entry.image.get_size()
		var fit := minf(rect.size.x / tex.x, rect.size.y / tex.y)
		var shown := tex * fit
		slot.draw_texture_rect(slot.entry.image, Rect2(rect.get_center() - shown / 2.0, shown), false)
	else:
		_draw_glyph(slot, slot.entry.icon, rect.get_center(), rect.size.x * 0.4, true)


func _diamond_on(canvas: CanvasItem, center: Vector2, r: float, color: Color) -> void:
	canvas.draw_polyline(PackedVector2Array([center + Vector2(0, -r), center + Vector2(r * 0.7, 0), center + Vector2(0, r),
		center + Vector2(-r * 0.7, 0), center + Vector2(0, -r)]), color, 1.0, true)


## Íconos dibujados con líneas (habilidades y coleccionables sin imagen). r = medio tamaño.
func _draw_glyph(canvas: CanvasItem, kind: StringName, c: Vector2, r: float, lit: bool) -> void:
	var color := PALE if lit else DIM
	var accent := NEON if lit else DIM
	var w := maxf(1.5, r / 10.0)
	match kind:
		&"dash":
			for i in 3:
				var y := (i - 1) * r * 0.45
				canvas.draw_line(c + Vector2(-r, y), c + Vector2(r * (0.1 - absf(i - 1) * 0.3), y), Color(accent, 0.6 + 0.2 * i), w)
			canvas.draw_polyline(PackedVector2Array([c + Vector2(r * 0.2, -r * 0.7), c + Vector2(r, 0), c + Vector2(r * 0.2, r * 0.7)]), color, w * 1.4)
		&"vision":
			var eye := PackedVector2Array()
			for i in 17:
				var t := float(i) / 16.0
				eye.append(c + Vector2(lerpf(-r, r, t), -sin(t * PI) * r * 0.55))
			for i in 17:
				var t := 1.0 - float(i) / 16.0
				eye.append(c + Vector2(lerpf(-r, r, t), sin(t * PI) * r * 0.55))
			canvas.draw_polyline(eye, color, w)
			canvas.draw_circle(c, r * 0.32, accent)
			canvas.draw_circle(c, r * 0.13, NIGHT)
		&"curacion":
			canvas.draw_polyline(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.6, 0), c + Vector2(0, r), c + Vector2(-r * 0.6, 0), c + Vector2(0, -r)]), accent, w)
			canvas.draw_line(c + Vector2(0, -r * 0.4), c + Vector2(0, r * 0.4), color, w * 1.4)
			canvas.draw_line(c + Vector2(-r * 0.4, 0), c + Vector2(r * 0.4, 0), color, w * 1.4)
		&"doble_salto":
			for i in 2:
				var y := r * 0.35 - i * r * 0.7
				canvas.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.7, y + r * 0.35), c + Vector2(0, y - r * 0.3), c + Vector2(r * 0.7, y + r * 0.35)]), color if i == 1 else accent, w * 1.3)
		&"definitiva":
			for i in 3:
				var start := _time * 1.5 + TAU * i / 3.0
				var points := PackedVector2Array()
				for j in 13:
					var t := float(j) / 12.0
					points.append(c + Vector2(cos(start + t * 2.4), sin(start + t * 2.4)) * r * (0.2 + 0.75 * t))
				canvas.draw_polyline(points, accent if i % 2 == 0 else color, w * 1.3)
			canvas.draw_circle(c, r * 0.16, color)
		&"datos":
			canvas.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.6, -r), c + Vector2(r * 0.3, -r), c + Vector2(r * 0.6, -r * 0.7),
				c + Vector2(r * 0.6, r), c + Vector2(-r * 0.6, r), c + Vector2(-r * 0.6, -r)]), accent, w)
			for i in 3:
				var y := -r * 0.3 + i * r * 0.4
				canvas.draw_line(c + Vector2(-r * 0.35, y), c + Vector2(r * 0.35, y), color, w)
		&"inmersion":
			# Un monitor y una flecha que entra en él.
			canvas.draw_rect(Rect2(c + Vector2(-r * 0.15, -r * 0.75), Vector2(r * 1.05, r * 1.1)), color, false, w)
			canvas.draw_line(c + Vector2(r * 0.2, r * 0.55), c + Vector2(r * 0.55, r * 0.55), color, w)
			canvas.draw_line(c + Vector2(-r, -r * 0.2), c + Vector2(r * 0.35, -r * 0.2), accent, w * 1.3)
			canvas.draw_polyline(PackedVector2Array([c + Vector2(r * 0.05, -r * 0.5), c + Vector2(r * 0.35, -r * 0.2), c + Vector2(r * 0.05, r * 0.1)]), accent, w * 1.3)
		&"candado":
			canvas.draw_arc(c + Vector2(0, -r * 0.25), r * 0.45, PI, TAU, 12, color, w)
			canvas.draw_rect(Rect2(c + Vector2(-r * 0.65, -r * 0.25), Vector2(r * 1.3, r * 1.05)), color, false, w)
			canvas.draw_circle(c + Vector2(0, r * 0.25), r * 0.12, color)
		_:
			_diamond_on(canvas, c, r, accent)
