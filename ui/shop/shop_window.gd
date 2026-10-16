class_name ShopWindow
extends CanvasLayer
## La tienda de la soda: a la izquierda el catálogo (lo que se ve en este capítulo, con su precio y si ya se compró);
## a la derecha el artículo elegido (qué es, qué hace, lo que comenta la señora) y «Comprar». Arriba, los Ecos de la
## bolsa (máximo 999). Comprar pregunta antes (ConfirmPrompt) y usa Shop.buy (cobra, aplica y marca). Pausa el juego;
## Esc cierra. Se maneja con teclado, mando y mouse.
## Uso: await ShopWindow.open(nodo).closed

signal closed
signal bought(item: ShopItem)

const PANEL := Color("1c1420")
const BORDER := Color("f2b860")
const INK := Color("f4ead8")
const MUTED := Color("b8a890")
const GOOD := Color("7ee08a")
const BAD := Color("ff8a6a")
const ECO := Color("b46bff")

var items: Array[ShopItem] = []
var selected := -1

var _state: Node
var _economy: Node
var _buttons: Array[Button] = []
var _ecos: Label
var _name: Label
var _kind: Label
var _description: Label
var _note: Label
var _price: Label
var _status: Label
var _buy: Button
var _was_paused := false
var _confirming := false


static func open(from: Node) -> ShopWindow:
	var window := ShopWindow.new()
	from.get_tree().current_scene.add_child(window)
	return window


func _ready() -> void:
	layer = 70
	add_to_group(&"shop_window")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	_state = get_node("/root/GameState")
	_economy = get_node("/root/Economy")
	items = Shop.visible_items(_state)
	_build()
	Sfx.play(&"popup_open")
	if not items.is_empty():
		select(0)
		_buttons[0].grab_focus.call_deferred()


func select(index: int) -> void:
	if index < 0 or index >= items.size():
		return
	selected = index
	var item := items[index]
	_name.text = item.title
	_kind.text = ShopItem.KIND_NAMES[item.kind]
	_description.text = item.description
	_note.text = "«%s»" % item.note if not item.note.is_empty() else ""
	_price.text = "%d Ecos" % item.price
	_refresh()


## Compra el artículo elegido sin preguntar (lo usa la confirmación y las pruebas). true si se compró.
func purchase(item: ShopItem) -> bool:
	if not Shop.buy(_state, _economy, item):
		Sfx.play(&"error")
		_refresh()
		return false
	Sfx.play(&"eco_pickup")
	bought.emit(item)
	_refresh()
	return true


func close() -> void:
	if _confirming:
		return
	get_tree().paused = _was_paused
	Sfx.play(&"popup_close")
	closed.emit()
	queue_free()


func _ask_purchase() -> void:
	if selected < 0 or _confirming:
		return
	var item := items[selected]
	if Shop.status(_state, _economy, item) != Shop.Status.DISPONIBLE:
		Sfx.play(&"error")
		return
	_confirming = true
	var prompt := ConfirmPrompt.ask(self, "¿Comprar «%s» por %d Ecos?" % [item.title, item.price],
		"Te quedarían %d Ecos." % (_economy.ecos - item.price))
	var yes: bool = await prompt.answered
	# El ConfirmPrompt devuelve la pausa como la encontró (pausado): la tienda sigue abierta.
	get_tree().paused = true
	_confirming = false
	if yes:
		purchase(item)
	if selected >= 0 and selected < _buttons.size():
		_buttons[selected].grab_focus()


func _refresh() -> void:
	_ecos.text = "Tus Ecos: %d / %d" % [_economy.ecos, Economy.MAX_ECOS]
	for i in items.size():
		var item := items[i]
		var status := Shop.status(_state, _economy, item)
		_buttons[i].text = "%s   ·   %s" % [item.title, "Comprado" if status == Shop.Status.COMPRADO else "%d Ecos" % item.price]
		_buttons[i].modulate = Color(1, 1, 1, 0.55) if status == Shop.Status.COMPRADO else Color.WHITE
	if selected < 0:
		return
	var item := items[selected]
	var status := Shop.status(_state, _economy, item)
	match status:
		Shop.Status.COMPRADO:
			_status.text = "Ya lo compraste."
			_status.add_theme_color_override(&"font_color", GOOD)
		Shop.Status.BLOQUEADO:
			_status.text = Shop.blocked_reason(_state, item)
			_status.add_theme_color_override(&"font_color", MUTED)
		Shop.Status.SIN_ECOS:
			_status.text = "Te faltan %d Ecos." % (item.price - _economy.ecos)
			_status.add_theme_color_override(&"font_color", BAD)
		_:
			_status.text = "Disponible."
			_status.add_theme_color_override(&"font_color", GOOD)
	_buy.disabled = status != Shop.Status.DISPONIBLE


func _input(event: InputEvent) -> void:
	if _confirming:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


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
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override(&"panel", style)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(980, 520)
	panel.position = Vector2(-490, -260)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _label("TIENDA DE LA SODA", 19, BORDER)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_ecos = _label("", 17, ECO)
	_ecos.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.add_child(_ecos)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 20)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override(&"separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for i in items.size():
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(400, 38)
		button.add_theme_font_size_override(&"font_size", 15)
		button.add_theme_color_override(&"font_focus_color", BORDER)
		InspectionWindow.style_button(button)
		button.focus_entered.connect(select.bind(i))
		button.pressed.connect(func() -> void:
			select(i)
			_ask_purchase())
		list.add_child(button)
		_buttons.append(button)
	if items.is_empty():
		list.add_child(_label("Todavía no hay nada a la venta.", 15, MUTED))
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override(&"separation", 8)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail)
	_name = _label("", 22, INK)
	detail.add_child(_name)
	_kind = _label("", 14, BORDER)
	detail.add_child(_kind)
	_description = _label("", 16, INK)
	detail.add_child(_description)
	_note = _label("", 15, Color("8fd8ff"))
	detail.add_child(_note)
	_price = _label("", 20, ECO)
	detail.add_child(_price)
	_status = _label("", 15, MUTED)
	detail.add_child(_status)
	_buy = Button.new()
	_buy.text = "Comprar"
	_buy.custom_minimum_size = Vector2(160, 42)
	_buy.add_theme_font_size_override(&"font_size", 17)
	InspectionWindow.style_button(_buy)
	_buy.pressed.connect(_ask_purchase)
	detail.add_child(_buy)
	column.add_child(_label("↑↓: elegir   ·   E: comprar   ·   Esc: salir", 13, MUTED))
	_refresh()


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label
