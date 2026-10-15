class_name KeepsakeShelf
extends Node2D
## Estantería del cuarto de Kai: muestra en sus repisas los objetos que ya tiene (Keepsake de las
## categorías que exhibe) y con E abre la ventana de inspección (InspectionWindow). Los recuerdos
## aparecen solo cuando Kai los tiene; los Fragmentos de Datos que faltan se ven como «???» en la
## ventana (son coleccionables). El origen es la base de la estantería (los pies, en el piso).

const WOOD := Color("7a5236")
const WOOD_DARK := Color("4a3020")

@export var title := "ESTANTERÍA DE RECUERDOS"
@export var prompt_text := "E: mirar los recuerdos"
## Qué exhibe (Keepsake.Category).
@export var show_memories := true
@export var show_fragments := false
@export var show_gifts := true
## Si los que faltan se listan como «???» (coleccionables) o no se listan (recuerdos).
@export var list_locked := false
@export var columns := 3
@export var rows := 2
@export var cell := 16.0
@export var empty_text := "Todavía no hay nada aquí."

var interactable: Interactable
var _time := 0.0


func _ready() -> void:
	interactable = Interactable.new()
	interactable.prompt_text = prompt_text
	interactable.prompt_offset = Vector2(-50, -_height() - 22)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(_width() + 24.0, 48.0)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	interactable.add_child(shape)
	add_child(interactable)
	interactable.interacted.connect(func(_player: Player) -> void: inspect())


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func categories() -> Array[Keepsake.Category]:
	var result: Array[Keepsake.Category] = []
	if show_memories:
		result.append(Keepsake.Category.RECUERDO)
	if show_fragments:
		result.append(Keepsake.Category.FRAGMENTO)
	if show_gifts:
		result.append(Keepsake.Category.REGALO)
	return result


## Los objetos que se ven en las repisas (los que Kai ya tiene).
func displayed() -> Array[Keepsake]:
	return HomeCollection.of_categories(categories(), _state(), true)


## Abre la ventana con lo que hay (y, si list_locked, lo que falta como «???»).
func inspect() -> InspectionWindow:
	var list: Array[Dictionary] = []
	for item in HomeCollection.of_categories(categories(), _state(), not list_locked):
		list.append(entry_for(item, _state()))
	interactable.busy = true
	var window := InspectionWindow.open(self, title, list, empty_text)
	window.closed.connect(func() -> void: interactable.busy = false)
	return window


static func entry_for(item: Keepsake, state: Node) -> Dictionary:
	var subtitle: String = ["Recuerdo", "Fragmento de Datos", "Regalo"][item.category]
	return {
		"name": item.display_name,
		"subtitle": subtitle,
		"description": item.description,
		"note": item.note_for(state),
		"lines": item.data_lines,
		"locked": not item.is_unlocked(state),
		"locked_text": "Un fragmento que todavía no encontré." if item.category == Keepsake.Category.FRAGMENTO else "Todavía no lo tengo.",
		"draw": func(canvas: CanvasItem, rect: Rect2, time: float) -> void: KeepsakeArt.draw(canvas, item, rect, time),
	}


func _width() -> float:
	return columns * (cell + 6.0) + 6.0


func _height() -> float:
	return rows * (cell + 8.0) + 8.0


func _draw() -> void:
	var w := _width()
	var h := _height()
	var body := Rect2(Vector2(-w / 2.0, -h), Vector2(w, h))
	draw_rect(body, WOOD_DARK)
	draw_rect(body.grow(-2.0), Color("2a1c14"))
	for row in rows + 1:
		draw_rect(Rect2(Vector2(-w / 2.0, -h + row * (cell + 8.0)), Vector2(w, 3.0)), WOOD)
	draw_rect(Rect2(Vector2(-w / 2.0, -h), Vector2(3.0, h)), WOOD)
	draw_rect(Rect2(Vector2(w / 2.0 - 3.0, -h), Vector2(3.0, h)), WOOD)
	for item in displayed():
		var slot := item.shelf_slot % (columns * rows)
		var col := slot % columns
		var row := slot / columns
		var rect := Rect2(Vector2(-w / 2.0 + 6.0 + col * (cell + 6.0), -h + 3.0 + row * (cell + 8.0) + 4.0), Vector2(cell, cell))
		KeepsakeArt.draw(self, item, rect, _time)


func _state() -> Node:
	return get_node("/root/GameState")
