@tool
class_name NoticeBoard
extends Node2D
## Tablón de anuncios del colegio (corcho con papeles clavados): muestra los avisos que la partida ya puede ver
## (Announcement, según el capítulo y las marcas) y con E los abre en la ventana de inspección (InspectionWindow,
## la misma del cuarto de Kai). Los que no se leyeron tienen una chincheta roja; leerlos deja la marca
## «anuncio_leido_<id>» en la partida. El origen es el centro de la base del tablón (las patas, en el piso).

const CORK := Color("9a7448")
const FRAME := Color("5a4028")
const PIN_NEW := Color("ff4a6a")
const PIN_READ := Color("8a8fa8")

@export var title := "TABLÓN DE ANUNCIOS"
@export var announcements: Array[Announcement] = []
@export var size := Vector2(96, 60)
## Altura del corcho sobre el piso.
@export var height := 104.0

var interactable: Interactable


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	interactable = Interactable.new()
	interactable.prompt_text = "E: leer el tablón"
	interactable.prompt_offset = Vector2(-40, -height - size.y / 2.0 - 16.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x + 20.0, 48.0)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	interactable.add_child(shape)
	add_child(interactable)
	interactable.interacted.connect(func(_player: Player) -> void: open())


func _process(_delta: float) -> void:
	queue_redraw()


## Los avisos que se ven ahora.
func visible_announcements() -> Array[Announcement]:
	var result: Array[Announcement] = []
	var state := get_node_or_null("/root/GameState")
	for item in announcements:
		if item and (state == null or Engine.is_editor_hint() or item.is_visible_for(state)):
			result.append(item)
	return result


func is_read(item: Announcement) -> bool:
	var state := get_node_or_null("/root/GameState")
	return state != null and state.has_flag(_read_flag(item))


## Abre el tablón (los nuevos primero). Leer un aviso lo marca como leído.
func open() -> InspectionWindow:
	var items := visible_announcements()
	items.sort_custom(func(a: Announcement, b: Announcement) -> bool: return not is_read(a) and is_read(b))
	var list: Array[Dictionary] = []
	for item in items:
		var paper := item.paper
		list.append({
			"name": ("● " if not is_read(item) else "") + item.title,
			"subtitle": Announcement.KIND_NAMES[item.kind],
			"description": item.text,
			"note": item.kai_note,
			"draw": func(canvas: CanvasItem, rect: Rect2, _t: float) -> void: _draw_paper(canvas, rect, paper),
		})
	interactable.busy = true
	var window := InspectionWindow.open(self, title, list, "No hay avisos nuevos.", "seguir")
	var state := get_node("/root/GameState")
	window.closed.connect(func() -> void: interactable.busy = false)
	# Se lee el que se mira (el primero ya se está mirando al abrir).
	var mark := func(index: int) -> void:
		if index >= 0 and index < items.size():
			state.set_flag(_read_flag(items[index]))
	mark.call(0)
	for i in window._buttons.size():
		var index := i
		window._buttons[i].focus_entered.connect(func() -> void: mark.call(index))
		window._buttons[i].pressed.connect(func() -> void: mark.call(index))
	return window


func _read_flag(item: Announcement) -> StringName:
	return StringName("anuncio_leido_%s" % item.id)


static func _draw_paper(canvas: CanvasItem, rect: Rect2, paper: Color) -> void:
	var sheet := Rect2(rect.position + rect.size * Vector2(0.15, 0.08), rect.size * Vector2(0.7, 0.84))
	canvas.draw_rect(sheet, paper)
	canvas.draw_rect(sheet, Color(0, 0, 0, 0.25), false, 2.0)
	for k in 6:
		var y := sheet.position.y + sheet.size.y * (0.2 + k * 0.12)
		canvas.draw_line(Vector2(sheet.position.x + 10, y), Vector2(sheet.end.x - 10 - (k % 3) * 12, y), Color(0.2, 0.2, 0.3, 0.5), 2.0)
	canvas.draw_circle(Vector2(sheet.get_center().x, sheet.position.y + 8), 6.0, PIN_NEW)


func _draw() -> void:
	# Patas, marco y corcho.
	draw_rect(Rect2(-size.x / 2.0 + 6, -height, 4, height), FRAME)
	draw_rect(Rect2(size.x / 2.0 - 10, -height, 4, height), FRAME)
	var board := Rect2(Vector2(-size.x / 2.0, -height - size.y / 2.0), size)
	draw_rect(board.grow(3), FRAME)
	draw_rect(board, CORK)
	draw_rect(Rect2(board.position + Vector2(0, -12), Vector2(size.x, 10)), Color("1f6f5a"))
	# Un papel por aviso visible (hasta 6), con su chincheta.
	var items := visible_announcements()
	for k in mini(items.size(), 6):
		var col := k % 3
		var row := int(k / 3.0)
		var paper := Rect2(board.position + Vector2(6 + col * (size.x - 12) / 3.0, 5 + row * (size.y - 8) / 2.0), Vector2((size.x - 24) / 3.0, (size.y - 16) / 2.0))
		draw_rect(paper, items[k].paper)
		for line in 3:
			draw_line(paper.position + Vector2(3, 6 + line * 4), paper.position + Vector2(paper.size.x - 3, 6 + line * 4), Color(0.2, 0.2, 0.3, 0.4), 1.0)
		draw_circle(paper.position + Vector2(paper.size.x / 2.0, 2), 1.6, PIN_READ if is_read(items[k]) else PIN_NEW)
