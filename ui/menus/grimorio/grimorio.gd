class_name GrimorioScreen
extends Control
## El Grimorio (conceptos de Ariel en docs/arte/referencias/grimorio_concepto.webp y
## grimorio_inventario_concepto.webp). Tres páginas, como en Hollow Knight:
##   INVENTARIO (la principal, InventoryPage): fragmentos de vida y de energía, la Nullblade, las
##     habilidades, los coleccionables y los Ecos, con la descripción de lo elegido a la derecha.
##   MAPA (a la izquierda, Q): el libro con el mapa de las zonas.
##   ARCHIVO (a la derecha, E): el libro con las pestañas COMANDOS, CONCEPTOS, AMENAZAS y REGISTROS.
## Arriba, GrimorioNav muestra el título y a qué página se pasa con Q y con E.
## Las entradas son GrimorioEntry de data/grimorio/; las que todavía no se descubren aparecen como «???».
## Durante el juego se abre con G (acción "grimorio", ver CombatHUD) encima de la sala, que queda
## en pausa: GrimorioScreen.open(nodo). G, Esc o CERRAR lo cierran.

const ENTRIES_DIR := "res://data/grimorio"
const SCENE_PATH := "res://ui/menus/grimorio/grimorio.tscn"
## Si se abre como escena suelta (sin juego detrás), al cerrar vuelve al menú.
const RETURN_SCENE := "res://ui/menus/main_menu/main_menu.tscn"

## Páginas del Grimorio (de izquierda a derecha).
enum Page { MAPA, INVENTARIO, ARCHIVO }

# El índice es la categoría (GrimorioEntry.Category); ARSENAL es el INVENTARIO (su propia página).
const CATEGORY_TITLES: PackedStringArray = ["MAPA", "COMANDOS", "AMENAZAS", "CONCEPTOS", "REGISTROS", "INVENTARIO", "BESTIARIO", "MISIONES"]
const CATEGORY_DESCRIPTIONS: PackedStringArray = [
	"Explora las áreas que has visitado y descubre nuevas rutas, secretos y conexiones.",
	"Cómo moverse e interactuar, y los comandos de terminal que Kai aprende.",
	"Lo que acecha en la red: cómo ataca cada amenaza y cómo defenderte.",
	"Ideas de ciberseguridad que Kai va entendiendo en su camino.",
	"Notas, mensajes y recuerdos de lo que ha pasado.",
	"Lo que Kai lleva consigo: su arma, sus habilidades y sus recursos.",
	"Las criaturas digitales que Kai registró con la Visión Digital: no hace falta vencerlas.",
	"La historia, las misiones secundarias, las tareas y los descubrimientos.",
]
const LOCKED_TEXT := "Aún no lo descubres. Sigue avanzando en la historia para completar esta página."

const INK := Color(0.12, 0.09, 0.2)
const INK_MUTED := Color(0.12, 0.09, 0.2, 0.45)
const ACCENT := Color(0.29, 0.21, 0.7)

## Verdadero si está abierto encima del juego (con GrimorioScreen.open).
var overlay := false
var page := Page.INVENTARIO
var _entries: Array[GrimorioEntry] = []
var _category := 0
## Última pestaña elegida en el ARCHIVO (para volver a ella).
var _archive_category := GrimorioEntry.Category.COMANDOS
var _entry_group := ButtonGroup.new()
var _tab_group := ButtonGroup.new()
var _inventory: InventoryPage
var _nav: GrimorioNav
## Mapa del mundo físico o digital (en la página del mapa, en lugar del de la zona).
var _world_map: GrimorioWorldMap

@onready var _book: Control = %Book
@onready var _tabs: Array[Node] = %Tabs.get_children()
@onready var _back_button: Button = %BackButton
@onready var _category_title: Label = %CategoryTitle
@onready var _category_description: Label = %CategoryDescription
@onready var _zone_buttons: Container = %ZoneButtons
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
	_inventory = InventoryPage.new()
	_inventory.name = "Inventory"
	add_child(_inventory)
	_inventory.close_requested.connect(close)
	_nav = GrimorioNav.new()
	_nav.name = "Nav"
	add_child(_nav)
	_nav.page_requested.connect(func(p: int) -> void: show_page(p as Page))
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
	_world_map = GrimorioWorldMap.new()
	_world_map.name = "WorldMap"
	_world_map.position = _map.position
	_world_map.size = _map.size
	_world_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world_map.visible = false
	_map.get_parent().add_child(_world_map)
	show_page(Page.INVENTARIO)
	Sfx.play(&"book_open")
	# Se abre con un pequeño acercamiento.
	for node: Control in [_book, _inventory]:
		node.pivot_offset = Vector2(640, 360)
		node.scale = Vector2.ONE * 0.96
		var tween := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "scale", Vector2.ONE, 0.3)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed(&"grimorio"):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed(&"vision") and page > Page.MAPA:
		get_viewport().set_input_as_handled()
		show_page((page - 1) as Page)
	elif event.is_action_pressed(&"interact") and page < Page.ARCHIVO:
		get_viewport().set_input_as_handled()
		show_page((page + 1) as Page)


## Cambia de página: el inventario, o el libro con el mapa o con el archivo.
func show_page(new_page: Page) -> void:
	if new_page != page:
		Sfx.play(&"book_page", randf_range(0.95, 1.1))
	page = new_page
	_nav.page = page
	var in_book := page != Page.INVENTARIO
	_book.visible = in_book
	_inventory.visible = not in_book
	match page:
		Page.INVENTARIO:
			_inventory.setup(entries_in(GrimorioEntry.Category.ARSENAL))
			if not DisplayServer.is_touchscreen_available():
				_inventory.focus_first()
		Page.MAPA:
			_open_category(GrimorioEntry.Category.MAPA)
		Page.ARCHIVO:
			_open_category(_archive_category)


## Entradas de una categoría, en orden.
func entries_in(category: int) -> Array[GrimorioEntry]:
	var result: Array[GrimorioEntry] = []
	for entry in _entries:
		if entry.category == category:
			result.append(entry)
	return result


func is_unlocked(entry: GrimorioEntry) -> bool:
	return entry.is_unlocked(get_node_or_null("/root/GameState"))


## Abre la página de una categoría: ARSENAL es el inventario, MAPA el mapa y el resto el archivo.
func select_category(category: int) -> void:
	if category == GrimorioEntry.Category.ARSENAL:
		show_page(Page.INVENTARIO)
	elif category == GrimorioEntry.Category.MAPA:
		show_page(Page.MAPA)
	else:
		_archive_category = category as GrimorioEntry.Category
		if page != Page.ARCHIVO:
			show_page(Page.ARCHIVO)
		else:
			_open_category(category)


## Muestra una categoría en el libro. En el mapa no hay pestañas; en el archivo, solo las suyas.
func _open_category(category: int) -> void:
	_category = category
	var is_map := category == GrimorioEntry.Category.MAPA
	for i in _tabs.size():
		var tab := _tabs[i] as GrimorioTab
		tab.visible = not is_map and tab.icon_kind != GrimorioTab.Icon.MAPA
		tab.set_pressed_no_signal(tab.icon_kind == category)
	if not is_map and not DisplayServer.is_touchscreen_available():
		for tab in _tabs:
			if (tab as GrimorioTab).icon_kind == category and not (tab as Control).has_focus():
				(tab as Control).grab_focus()
	_category_title.text = CATEGORY_TITLES[category]
	_category_description.text = CATEGORY_DESCRIPTIONS[category]
	_map.visible = is_map
	_world_map.visible = false
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
	if is_map:
		for data in [["MUNDO FÍSICO", WorldRegion.Kind.FISICA], ["MUNDO DIGITAL", WorldRegion.Kind.DIGITAL]]:
			var world_button := _make_entry_button(data[0], true, true)
			world_button.pressed.connect(show_world.bind(data[1]))
			container.add_child(world_button)
	if first:
		first.set_pressed_no_signal(true)
		show_entry(first_entry)


func show_entry(entry: GrimorioEntry) -> void:
	if entry.category == GrimorioEntry.Category.ARSENAL:
		_inventory.show_entry(entry)
		return
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
		_map.visible = true
		_world_map.visible = false
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

## Muestra el mapa del mundo físico o del digital (WorldAtlas) en la página del mapa.
func show_world(kind: WorldRegion.Kind) -> void:
	_map.visible = false
	_world_map.visible = true
	_world_map.kind = kind
	var physical := kind == WorldRegion.Kind.FISICA
	var here := _world_map.current_region()
	_entry_title.text = "Mundo físico" if physical else "Mundo digital"
	_entry_subtitle.text = "Regiones inspiradas en San José, Cartago y Puntarenas" if physical else "La red: biomas que existían antes que Kai"
	if here and here.kind == kind:
		_entry_text.text = here.description
	elif physical:
		_entry_text.text = "Las regiones donde vive y estudia Kai."
	else:
		_entry_text.text = "Sistemas, conexiones e información. Se entra con la Inmersión Digital desde dispositivos concretos."
	_illustration.visible = false
	_emblem.visible = true
	_emblem.modulate = Color.WHITE
	var regions := _world_map.progress()
	_entry_progress.text = "%d%%" % roundi(100.0 * regions.x / maxi(regions.y, 1))
	_facts_header.text = "EXPLORACIÓN"
	var facts: Dictionary[String, String] = {}
	facts["Regiones visitadas"] = "%d / %d" % [regions.x, regions.y]
	var game_state := get_node_or_null("/root/GameState")
	var known := 0
	var open := 0
	if game_state:
		for link in WorldAtlas.links():
			if WorldAtlas.get_region(link.region_a).kind != kind and WorldAtlas.get_region(link.region_b).kind != kind:
				continue
			if WorldAtlas.is_link_known(link, game_state, get_node_or_null("/root/World")):
				known += 1
				if link.is_open(game_state):
					open += 1
	facts["Conexiones conocidas"] = "%d (%d abiertas)" % [known, open]
	if here:
		facts["Kai está en"] = here.display_name
	if not physical and game_state:
		var seen := 0
		for creature in Bestiary.entries():
			if Bestiary.stage(game_state, creature) > 0:
				seen += 1
		facts["Criaturas registradas"] = "%d / %d" % [seen, Bestiary.entries().size()]
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
	_entries.append_array(_bestiary_entries())
	_entries.append_array(_quest_entries())
	_entries.sort_custom(func(a: GrimorioEntry, b: GrimorioEntry) -> bool:
		return a.order < b.order if a.category == b.category else a.category < b.category)


## Páginas del bestiario (una por criatura que existe en el juego): cada etapa muestra más.
func _bestiary_entries() -> Array[GrimorioEntry]:
	var result: Array[GrimorioEntry] = []
	var game_state := get_node_or_null("/root/GameState")
	var creatures := Bestiary.entries()
	for i in creatures.size():
		var creature := creatures[i]
		var stage := Bestiary.stage(game_state, creature) if game_state else 0
		var region := WorldAtlas.get_region(creature.biome)
		var region_name := region.display_name if region else "?"
		var page := GrimorioEntry.new()
		page.category = GrimorioEntry.Category.BESTIARIO
		page.order = i
		page.title = creature.display_name
		page.subtitle = "%s · %s" % [region_name, Bestiary.STAGE_NAMES[stage]]
		page.unlock_flag = StringName("bestiario_%s_1" % creature.id)
		var parts := PackedStringArray()
		match stage:
			1:
				parts.append(creature.appearance)
			2:
				parts.append(creature.behavior)
			3:
				parts.append(creature.function)
			_:
				parts.append(creature.appearance)
		if stage >= 1 and not creature.kai_notes[stage - 1].is_empty():
			parts.append("Kai: «%s»" % creature.kai_notes[stage - 1])
		page.text = "\n\n".join(parts)
		page.facts = { "Bioma": region_name, "Etapa": "%d / 3 · %s" % [stage, Bestiary.STAGE_NAMES[stage]] }
		if stage >= 3:
			page.facts["Concepto"] = creature.concept
		elif stage == 1:
			page.facts["Siguiente"] = "Seguir observándola con la Visión"
		else:
			page.facts["Siguiente"] = "Entender qué hace en su ecosistema"
		result.append(page)
	return result


## Páginas de las misiones que empezaron: primero las en curso; la historia antes que las actividades.
func _quest_entries() -> Array[GrimorioEntry]:
	var result: Array[GrimorioEntry] = []
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return result
	# Antes del Capítulo 3: lo que falta de los capítulos 1 y 2 (ChapterGate), arriba de todo.
	if game_state.has_flag(ChapterGate.CHAPTER_3_STORY_FLAG) and not game_state.has_flag(&"capitulo_3"):
		var pending := ChapterGate.pending_names(game_state, 3)
		if not pending.is_empty():
			var gate := GrimorioEntry.new()
			gate.category = GrimorioEntry.Category.MISIONES
			gate.order = -1
			gate.title = "Asuntos pendientes"
			gate.subtitle = "Antes del Capítulo 3"
			gate.text = ChapterGate.PENDING_MESSAGE + "

" + "
".join(Array(pending).map(func(n: String) -> String: return "· " + n))
			gate.facts = { "Pendientes": str(pending.size()) }
			result.append(gate)
	var started: Array[StringName] = game_state.get_started_quests()
	for i in started.size():
		var quest := QuestDB.get_quest(started[i])
		if quest == null:
			continue
		var done: bool = game_state.is_quest_completed(quest.id)
		var page := GrimorioEntry.new()
		page.category = GrimorioEntry.Category.MISIONES
		page.order = (1000 if done else 0) + quest.category * 100 + (started.size() - i)
		page.title = quest.title
		page.subtitle = "%s · %s" % [Quest.CATEGORY_NAMES[quest.category], "Completada" if done else "En curso"]
		page.text = "Completada." if done else "Objetivo: " + game_state.get_quest_objective(quest.id)
		page.facts = { "Tipo": Quest.CATEGORY_NAMES[quest.category] }
		if not done:
			var step: int = quest.get_step_index(game_state.get_current_step(quest.id))
			page.facts["Paso"] = "%d / %d" % [step + 1, quest.steps.size()]
		if quest.ecos_reward > 0:
			page.facts["Recompensa"] = "%d Ecos" % quest.ecos_reward
		result.append(page)
	return result


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
