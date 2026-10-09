extends Control
## El Grimorio: el glosario del juego con forma de libro (concepto de Ariel). Pestañas MAPA,
## COMANDOS, AMENAZAS, CONCEPTOS y REGISTROS. La página izquierda muestra el mapa o la lista de
## entradas y la derecha la entrada elegida. Las entradas son GrimorioEntry de data/grimorio/;
## las que todavía no se descubren aparecen como «???».
## Se abre desde Opciones. Esc o VOLVER regresan.

const ENTRIES_DIR := "res://data/grimorio"
const RETURN_SCENE := "res://ui/menus/settings/settings_screen.tscn"

const CATEGORY_TITLES: PackedStringArray = ["MAPA", "COMANDOS", "AMENAZAS", "CONCEPTOS", "REGISTROS"]
const CATEGORY_DESCRIPTIONS: PackedStringArray = [
	"Explora las áreas que has visitado y descubre nuevas rutas, secretos y conexiones.",
	"Las habilidades de Kai y las teclas para usarlas. Las teclas se cambian en Opciones.",
	"Lo que acecha en la red: cómo ataca cada amenaza y cómo defenderte.",
	"Ideas de ciberseguridad que Kai va entendiendo en su camino.",
	"Notas, mensajes y recuerdos de lo que ha pasado.",
]
const LOCKED_TEXT := "Aún no lo descubres. Sigue avanzando en la historia para completar esta página."

const INK := Color(0.12, 0.09, 0.2)
const INK_MUTED := Color(0.12, 0.09, 0.2, 0.45)
const ACCENT := Color(0.29, 0.21, 0.7)

var _entries: Array[GrimorioEntry] = []
var _category := 0
var _entry_group := ButtonGroup.new()
var _tab_group := ButtonGroup.new()

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
	_load_entries()
	for i in _tabs.size():
		var tab := _tabs[i] as Button
		tab.button_group = _tab_group
		tab.pressed.connect(select_category.bind(i))
		# Con teclado o mando, la pestaña se abre al pasar por ella.
		tab.focus_entered.connect(func() -> void:
			if _category != i:
				select_category(i))
	_back_button.pressed.connect(_go_back)
	select_category(0)
	if not DisplayServer.is_touchscreen_available():
		(_tabs[0] as Control).grab_focus()
	# El libro se abre con un pequeño acercamiento.
	_book.scale = Vector2.ONE * 0.96
	_book.modulate.a = 0.0
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_book, "scale", Vector2.ONE, 0.3)
	tween.tween_property(_book, "modulate:a", 1.0, 0.25)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()


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
		(_tabs[i] as Button).set_pressed_no_signal(i == category)
	_category_title.text = CATEGORY_TITLES[category]
	_category_description.text = CATEGORY_DESCRIPTIONS[category]
	var is_map := category == GrimorioEntry.Category.MAPA
	_map.visible = is_map
	_zone_buttons.visible = is_map
	_entry_scroll.visible = not is_map
	_entry_group = ButtonGroup.new()
	var container: Container = _zone_buttons if is_map else _entry_list
	for child in _zone_buttons.get_children() + _entry_list.get_children():
		child.queue_free()
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
	_emblem.visible = not _illustration.visible
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
			facts.merge(entry.facts)
	_fill_facts(facts)


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


func _go_back() -> void:
	SceneManager.change_scene(RETURN_SCENE)
