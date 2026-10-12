class_name GrimorioScreen
extends Control
## El Grimorio: el glosario del juego con forma de libro (concepto de Ariel). Pestañas INVENTARIO (la
## principal, estilo Hollow Knight: una cuadrícula con el arma, las habilidades y los recursos de Kai,
## como los Ecos o los fragmentos de vida), MAPA, COMANDOS, CONCEPTOS, AMENAZAS y REGISTROS. La página
## izquierda muestra el inventario, el mapa o la lista de entradas y la derecha la entrada elegida.
## Las entradas son GrimorioEntry de data/grimorio/; las que todavía no se descubren aparecen como «???»
## (en el inventario solo está lo que Kai ya tiene).
## Durante el juego se abre con G (acción "grimorio", ver CombatHUD) encima de la sala, que queda
## en pausa: GrimorioScreen.open(nodo). G, Esc o CERRAR lo cierran.

const ENTRIES_DIR := "res://data/grimorio"
const SCENE_PATH := "res://ui/menus/grimorio/grimorio.tscn"
## Si se abre como escena suelta (sin juego detrás), al cerrar vuelve al menú.
const RETURN_SCENE := "res://ui/menus/main_menu/main_menu.tscn"

# El índice es la categoría (GrimorioEntry.Category); la de índice 5 (ARSENAL) se muestra como INVENTARIO.
const CATEGORY_TITLES: PackedStringArray = ["MAPA", "COMANDOS", "AMENAZAS", "CONCEPTOS", "REGISTROS", "INVENTARIO"]
const CATEGORY_DESCRIPTIONS: PackedStringArray = [
	"Explora las áreas que has visitado y descubre nuevas rutas, secretos y conexiones.",
	"Cómo moverse e interactuar, y los comandos de terminal que Kai aprende.",
	"Lo que acecha en la red: cómo ataca cada amenaza y cómo defenderte.",
	"Ideas de ciberseguridad que Kai va entendiendo en su camino.",
	"Notas, mensajes y recuerdos de lo que ha pasado.",
	"Lo que Kai lleva consigo: su arma, sus habilidades y sus recursos.",
]
const LOCKED_TEXT := "Aún no lo descubres. Sigue avanzando en la historia para completar esta página."

const INK := Color(0.12, 0.09, 0.2)
const INK_MUTED := Color(0.12, 0.09, 0.2, 0.45)
const ACCENT := Color(0.29, 0.21, 0.7)

## Verdadero si está abierto encima del juego (con GrimorioScreen.open).
var overlay := false
var _entries: Array[GrimorioEntry] = []
var _category := 0
var _entry_group := ButtonGroup.new()
var _tab_group := ButtonGroup.new()
## Cuadrícula del INVENTARIO (en el lugar de la lista de entradas).
var _inventory: GridContainer

@onready var _book: Control = %Book
@onready var _tabs: Array[Node] = %Tabs.get_children()
@onready var _back_button: Button = %BackButton
@onready var _category_title: Label = %CategoryTitle
@onready var _category_description: Label = %CategoryDescription
@onready var _zone_buttons: HBoxContainer = %ZoneButtons
@onready var _map: GrimorioMap = %Map
@onready var _entry_scroll: ScrollContainer = %EntryScroll
@onready var _entry_list: VBoxContainer = %EntryList
@onready var _entry_title: Label = %EntryTitle
@onready var _entry_progress: Label = %EntryProgress
@onready var _entry_subtitle: Label = %EntrySubtitle
@onready var _illustration: TextureRect = %Illustration
@onready var _emblem: Control = %Emblem
@onready var _entry_text: Label = %EntryText
@onready var _facts_header: Label = %FactsHeader
@onready var _facts_grid: GridContainer = %FactsGrid


func _ready() -> void:
	GameSettings.ensure_loaded()
	# Encima del juego se ve la sala oscurecida detrás, no el fondo del menú.
	if overlay:
		$Background.visible = false
		$Shade.color.a = 0.78
	_load_entries()
	_build_inventory()
	for i in _tabs.size():
		var tab := _tabs[i] as Button
		tab.button_group = _tab_group
		# Cada pestaña abre la categoría de su ícono (así el orden en pantalla puede ser cualquiera).
		var category: int = (tab as GrimorioTab).icon_kind
		tab.pressed.connect(select_category.bind(category))
		# Con teclado o mando, la pestaña se abre al pasar por ella.
		tab.focus_entered.connect(func() -> void:
			if _category != category:
				select_category(category))
	_back_button.pressed.connect(close)
	select_category(GrimorioEntry.Category.ARSENAL)
	if not DisplayServer.is_touchscreen_available():
		(_tabs[0] as Control).grab_focus()
	Sfx.play(&"book_open")
	# El libro se abre con un pequeño acercamiento.
	_book.scale = Vector2.ONE * 0.96
	_book.modulate.a = 0.0
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_book, "scale", Vector2.ONE, 0.3)
	tween.tween_property(_book, "modulate:a", 1.0, 0.25)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed(&"grimorio"):
		get_viewport().set_input_as_handled()
		close()


## Entradas de una categoría, en orden.
func entries_in(category: int) -> Array[GrimorioEntry]:
	var result: Array[GrimorioEntry] = []
	for entry in _entries:
		if entry.category == category:
			result.append(entry)
	return result


func is_unlocked(entry: GrimorioEntry) -> bool:
	return entry.is_unlocked(get_node_or_null("/root/GameState"))


func select_category(category: int) -> void:
	_category = category
	for i in _tabs.size():
		(_tabs[i] as Button).set_pressed_no_signal((_tabs[i] as GrimorioTab).icon_kind == category)
	_category_title.text = CATEGORY_TITLES[category]
	_category_description.text = CATEGORY_DESCRIPTIONS[category]
	var is_map := category == GrimorioEntry.Category.MAPA
	var is_inventory := category == GrimorioEntry.Category.ARSENAL
	_map.visible = is_map
	_zone_buttons.visible = is_map
	_entry_scroll.visible = not is_map and not is_inventory
	_inventory.visible = is_inventory
	_entry_group = ButtonGroup.new()
	var container: Container = _zone_buttons if is_map else _entry_list
	for child in _zone_buttons.get_children() + _entry_list.get_children() + _inventory.get_children():
		child.queue_free()
	if is_inventory:
		_fill_inventory()
		return
	# Se muestra la primera entrada descubierta (o la primera, si no hay ninguna).
	var first: Button
	var first_entry: GrimorioEntry
	for entry in entries_in(category):
		var unlocked := is_unlocked(entry)
		var button := _make_entry_button(entry.title.to_upper() if is_map else entry.title, unlocked, is_map)
		button.pressed.connect(show_entry.bind(entry))
		container.add_child(button)
		if first == null or (unlocked and not is_unlocked(first_entry)):
			first = button
			first_entry = entry
	if first:
		first.set_pressed_no_signal(true)
		show_entry(first_entry)


func show_entry(entry: GrimorioEntry) -> void:
	var unlocked := is_unlocked(entry)
	_entry_title.text = entry.title if unlocked else "???"
	_entry_subtitle.text = entry.subtitle if unlocked else "Página sin descubrir"
	_entry_text.text = entry.text if unlocked else LOCKED_TEXT
	_illustration.texture = entry.image if unlocked else null
	_illustration.visible = _illustration.texture != null
	var fragments := unlocked and entry.shows_life_fragments
	_show_life_fragments(fragments)
	_emblem.visible = not _illustration.visible and not fragments
	_emblem.modulate = Color.WHITE if unlocked else Color(1, 1, 1, 0.35)
	var facts: Dictionary[String, String] = {}
	if entry.category == GrimorioEntry.Category.MAPA:
		_map.zone = entry.resource_path.get_file().get_basename()
		var rooms := _map.progress()
		_entry_progress.text = "%d%%" % roundi(100.0 * rooms.x / maxi(rooms.y, 1))
		_facts_header.text = "COLECCIONABLES"
		facts["Salas visitadas"] = "%d / %d" % [rooms.x, rooms.y]
		facts["Entradas descubiertas"] = "%d / %d" % _count_unlocked(-1)
		facts["Registros"] = "%d / %d" % _count_unlocked(GrimorioEntry.Category.REGISTROS)
		facts["Secretos"] = "0 / ?"
	else:
		_entry_progress.text = "%d / %d" % _count_unlocked(entry.category)
		_facts_header.text = "DATOS"
		if unlocked:
			if entry.action != &"":
				facts["Tecla"] = GameSettings.key_name(entry.action)
			if entry.shows_life_fragments:
				facts["Fragmentos"] = "%d / %d" % [_life_fragments(), GameState.LIFE_FRAGMENTS_PER_MASK]
			if entry.shows_amount != &"":
				facts["Tienes"] = str(_amount_of(entry))
			facts.merge(entry.facts)
	_fill_facts(facts)


## La cuadrícula del inventario, en el mismo lugar que la lista de entradas.
func _build_inventory() -> void:
	_inventory = GridContainer.new()
	_inventory.name = "Inventory"
	_inventory.columns = 4
	_inventory.add_theme_constant_override(&"h_separation", 12)
	_inventory.add_theme_constant_override(&"v_separation", 12)
	_entry_scroll.get_parent().add_child(_inventory)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_inventory.set_anchor(side, _entry_scroll.get_anchor(side))
		_inventory.set_offset(side, _entry_scroll.get_offset(side))
	_inventory.offset_top += 8.0
	_inventory.visible = false


## Una casilla por cada cosa que Kai ya tiene (en el orden de las entradas); muestra la primera.
func _fill_inventory() -> void:
	var first: InventorySlot
	for entry in entries_in(GrimorioEntry.Category.ARSENAL):
		if not is_unlocked(entry):
			continue
		var slot := InventorySlot.new()
		slot.entry = entry
		slot.button_group = _entry_group
		slot.amount = _amount_of(entry) if entry.shows_amount != &"" else -1
		slot.fragments = _life_fragments()
		slot.pressed.connect(show_entry.bind(entry))
		# Con teclado o mando, el objeto se muestra al pasar por él.
		slot.focus_entered.connect(func() -> void:
			slot.set_pressed_no_signal(true)
			slot.pressed.emit())
		_inventory.add_child(slot)
		if first == null:
			first = slot
	if first:
		first.set_pressed_no_signal(true)
		show_entry(first.entry)
	else:
		var entries := entries_in(GrimorioEntry.Category.ARSENAL)
		if not entries.is_empty():
			show_entry(entries[0])


## Cantidad de un recurso del inventario (p. ej. los Ecos).
func _amount_of(entry: GrimorioEntry) -> int:
	if entry.shows_amount == &"ecos":
		var economy := get_node_or_null("/root/Economy")
		return economy.ecos if economy else 0
	return 0


## El cristal de vida en negro que se va llenando (en el recuadro de la ilustración).
func _show_life_fragments(on: bool) -> void:
	var icon := _illustration.get_parent().get_node_or_null("LifeFragments") as LifeFragmentIcon
	if not on:
		if icon:
			icon.visible = false
		return
	if icon == null:
		icon = LifeFragmentIcon.new()
		icon.name = "LifeFragments"
		_illustration.get_parent().add_child(icon)
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 24.0
		icon.offset_right = -24.0
		icon.offset_top = 12.0
		icon.offset_bottom = -12.0
	icon.visible = true
	icon.count = _life_fragments()


func _life_fragments() -> int:
	var game_state := get_node_or_null("/root/GameState")
	return game_state.life_fragments if game_state else 0


func _fill_facts(facts: Dictionary[String, String]) -> void:
	for child in _facts_grid.get_children():
		child.queue_free()
	_facts_header.visible = not facts.is_empty()
	for key in facts:
		_facts_grid.add_child(_fact_label(key, INK_MUTED.lerp(INK, 0.6), false))
		_facts_grid.add_child(_fact_label(facts[key], INK, true))


func _fact_label(text: String, color: Color, value: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_font_override(&"font", _entry_text.get_theme_font(&"font"))
	label.add_theme_font_size_override(&"font_size", 13)
	if value:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 200
	return label


## Desbloqueadas y total de una categoría (-1 = todas): [desbloqueadas, total].
func _count_unlocked(category: int) -> Array:
	var unlocked := 0
	var total := 0
	for entry in _entries:
		if category == -1 or entry.category == category:
			total += 1
			if is_unlocked(entry):
				unlocked += 1
	return [unlocked, total]


func _make_entry_button(text: String, unlocked: bool, compact: bool) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.button_group = _entry_group
	button.text = ("› " + text) if unlocked else "› ???"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 30 if compact else 34)
	button.add_theme_font_override(&"font", _entry_text.get_theme_font(&"font"))
	button.add_theme_font_size_override(&"font_size", 14 if compact else 15)
	var color := INK if unlocked else INK_MUTED
	for state in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color", &"font_hover_pressed_color"]:
		button.add_theme_color_override(state, color)
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 10.0
	empty.content_margin_right = 10.0
	var band := StyleBoxFlat.new()
	band.bg_color = Color(ACCENT, 0.18)
	band.border_color = ACCENT
	band.border_width_left = 3
	band.content_margin_left = 10.0
	band.content_margin_right = 10.0
	var hover := band.duplicate() as StyleBoxFlat
	hover.bg_color = Color(ACCENT, 0.08)
	button.add_theme_stylebox_override(&"normal", empty)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", band)
	button.add_theme_stylebox_override(&"hover_pressed", band)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = ACCENT
	focus.set_border_width_all(1)
	button.add_theme_stylebox_override(&"focus", focus)
	# Con teclado o mando, la entrada se muestra al pasar por ella.
	button.focus_entered.connect(func() -> void:
		button.set_pressed_no_signal(true)
		button.pressed.emit())
	return button


func _load_entries() -> void:
	_entries.clear()
	for file in ResourceLoader.list_directory(ENTRIES_DIR):
		var entry := load(ENTRIES_DIR.path_join(file)) as GrimorioEntry
		if entry:
			_entries.append(entry)
	_entries.sort_custom(func(a: GrimorioEntry, b: GrimorioEntry) -> bool:
		return a.order < b.order if a.category == b.category else a.category < b.category)


## Abre el Grimorio encima del juego y lo pone en pausa.
static func open(from: Node) -> GrimorioScreen:
	var layer := CanvasLayer.new()
	layer.name = "GrimorioLayer"
	layer.layer = 90
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var screen := (load(SCENE_PATH) as PackedScene).instantiate() as GrimorioScreen
	screen.overlay = true
	layer.add_child(screen)
	from.get_tree().root.add_child(layer)
	from.get_tree().paused = true
	return screen


## Cierra el Grimorio: vuelve al juego (y quita la pausa) o, si era una escena suelta, al menú.
func close() -> void:
	Sfx.play(&"book_close")
	if overlay:
		get_tree().paused = false
		get_parent().queue_free()
	else:
		get_node("/root/SceneManager").change_scene(RETURN_SCENE)
