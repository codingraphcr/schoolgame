@tool
class_name OldPhoto
extends Node2D
## Descubrimiento «Una fotografía antigua» (biblioteca, Capítulo 1 en adelante): un marco viejo en la pared, entre
## los diplomas del colegio. Con E se mira en la ventana de inspección: la inauguración del Laboratorio 2, con el
## profesor Alvarado joven en la orilla y la etiqueta del convenio arrancada. Es una pista sutil: no explica su
## pasado, no nombra el Proyecto Génesis ni dice nada del origen de Kai.
## La primera vez deja la marca SEEN_FLAG (abre la página del Grimorio) y completa el descubrimiento QUEST.
## El origen es el piso, debajo del marco.

const QUEST := &"foto_antigua"
const SEEN_FLAG := &"foto_antigua_vista"
const SEPIA := Color("c8a878")
const SEPIA_DARK := Color("5a4632")
const FRAME := Color("4a3424")

@export var title := "Una fotografía antigua"
@export var subtitle := "Descubrimiento · Biblioteca"
@export_multiline var description := ""
@export_multiline var kai_note := ""
## Lo que se alcanza a leer en la etiqueta del marco.
@export var lines: Array[String] = []
## Altura del marco sobre el piso.
@export var height := 120.0

var interactable: Interactable


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	interactable = Interactable.new()
	interactable.prompt_text = "E: mirar la foto"
	interactable.prompt_offset = Vector2(-40, -height - 34.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 48)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	interactable.add_child(shape)
	add_child(interactable)
	interactable.interacted.connect(func(_player: Player) -> void: look())


func is_discovered() -> bool:
	var state := get_node_or_null("/root/GameState")
	return state != null and state.has_flag(SEEN_FLAG)


## Muestra la foto. La primera vez la registra (descubrimiento y página del Grimorio).
func look() -> InspectionWindow:
	interactable.busy = true
	var entry := {
		"name": title,
		"subtitle": subtitle,
		"description": description,
		"note": kai_note,
		"lines": PackedStringArray(lines),
		"draw": func(canvas: CanvasItem, rect: Rect2, _t: float) -> void: draw_photo(canvas, rect),
	}
	var window := InspectionWindow.open(self, "BIBLIOTECA", [entry] as Array[Dictionary], "", "seguir")
	window.closed.connect(func() -> void: interactable.busy = false)
	_register()
	return window


func _register() -> void:
	var state := get_node("/root/GameState")
	if state.has_flag(SEEN_FLAG):
		return
	state.set_flag(SEEN_FLAG)
	if QuestDB.get_quest(QUEST) and not state.is_quest_completed(QUEST):
		state.start_quest(QUEST)
		for step in QuestDB.get_quest(QUEST).steps:
			state.complete_step(QUEST, step.id)


## La foto en sepia: un grupo frente a un rack de computadoras recién instalado, un cartel con «LABORATORIO 2»,
## una cinta de inauguración y, en la orilla derecha, un hombre joven de gabacha, anteojos y pelo alborotado.
static func draw_photo(canvas: CanvasItem, rect: Rect2) -> void:
	var photo := Rect2(rect.position + rect.size * Vector2(0.06, 0.12), rect.size * Vector2(0.88, 0.76))
	canvas.draw_rect(photo.grow(4), Color("efe6d2"))
	canvas.draw_rect(photo, SEPIA)
	var s := photo.size.x / 100.0
	var o := photo.position
	# Pared, piso y el rack del fondo.
	canvas.draw_rect(Rect2(o + Vector2(0, 46) * s, Vector2(100, 22) * s), SEPIA.darkened(0.12))
	canvas.draw_rect(Rect2(o + Vector2(14, 8) * s, Vector2(18, 38) * s), SEPIA_DARK.lightened(0.15))
	for k in 5:
		canvas.draw_rect(Rect2(o + Vector2(16, 11 + k * 7) * s, Vector2(14, 4) * s), SEPIA.darkened(0.3))
	# El cartel del laboratorio.
	canvas.draw_rect(Rect2(o + Vector2(36, 5) * s, Vector2(42, 9) * s), Color("e8dcc0"))
	canvas.draw_string(ThemeDB.fallback_font, o + Vector2(36, 11.8) * s, "LABORATORIO 2", HORIZONTAL_ALIGNMENT_CENTER, 42 * s, int(4.6 * s), SEPIA_DARK)
	# La cinta de inauguración.
	canvas.draw_line(o + Vector2(4, 40) * s, o + Vector2(80, 40) * s, SEPIA_DARK.lightened(0.25), 1.2 * s)
	# El grupo (siluetas con la ropa en tonos de sepia).
	var people: Array[Vector2] = [Vector2(12, 0), Vector2(24, 2), Vector2(36, 0), Vector2(48, 1), Vector2(60, 0), Vector2(72, 2)]
	for k in people.size():
		_person(canvas, o + Vector2(people[k].x, 30 + people[k].y) * s, s, SEPIA_DARK.lightened(0.08 * (k % 3)), false)
	# En la orilla, un poco aparte: el profesor joven.
	_person(canvas, o + Vector2(88, 29) * s, s, Color("ece2cc"), true)
	# La foto está gastada: una esquina doblada y una mancha de humedad.
	canvas.draw_colored_polygon(PackedVector2Array([photo.end - Vector2(14, 0) * s, photo.end, photo.end - Vector2(0, 10) * s]), Color("efe6d2"))
	canvas.draw_circle(o + Vector2(8, 60) * s, 6.0 * s, Color(0.35, 0.25, 0.15, 0.18))


static func _person(canvas: CanvasItem, top: Vector2, s: float, coat: Color, professor: bool) -> void:
	canvas.draw_rect(Rect2(top + Vector2(-3.5, 6) * s, Vector2(7, 14) * s), coat)
	canvas.draw_rect(Rect2(top + Vector2(-3, 20) * s, Vector2(2.5, 9) * s), SEPIA_DARK)
	canvas.draw_rect(Rect2(top + Vector2(0.5, 20) * s, Vector2(2.5, 9) * s), SEPIA_DARK)
	canvas.draw_circle(top + Vector2(0, 2.5) * s, 3.2 * s, Color("e0c8a0"))
	if professor:
		# Pelo alborotado, anteojos y la carpeta bajo el brazo.
		for k in 5:
			canvas.draw_circle(top + Vector2(-3 + k * 1.5, -0.8 + (k % 2) * 0.6) * s, 1.4 * s, SEPIA_DARK)
		canvas.draw_rect(Rect2(top + Vector2(-2.6, 2) * s, Vector2(2.2, 1.4) * s), SEPIA_DARK, false, 0.5 * s)
		canvas.draw_rect(Rect2(top + Vector2(0.4, 2) * s, Vector2(2.2, 1.4) * s), SEPIA_DARK, false, 0.5 * s)
		canvas.draw_rect(Rect2(top + Vector2(-1, 7) * s, Vector2(2, 10) * s), SEPIA_DARK.lightened(0.2))
		canvas.draw_rect(Rect2(top + Vector2(3, 11) * s, Vector2(3, 6) * s), SEPIA.lightened(0.2))
	else:
		canvas.draw_circle(top + Vector2(0, 0.6) * s, 3.0 * s, SEPIA_DARK.lightened(0.1))


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	# Un marco viejo en la pared, entre diplomas.
	var frame := Rect2(-22, -height - 16, 44, 32)
	draw_rect(frame.grow(3), FRAME)
	draw_rect(frame, SEPIA)
	for k in 6:
		draw_rect(Rect2(frame.position + Vector2(4 + k * 6, 14), Vector2(4, 12)), SEPIA_DARK.lightened(0.1 * (k % 2)))
	draw_rect(Rect2(frame.position + Vector2(36, 13), Vector2(4, 13)), Color("ece2cc"))
	for diploma_x in [-58.0, 38.0]:
		draw_rect(Rect2(diploma_x, -height - 10, 20, 24), Color("6a5a48"))
		draw_rect(Rect2(diploma_x + 2, -height - 8, 16, 20), Color("efe6d2"))
		draw_line(Vector2(diploma_x + 5, -height - 2), Vector2(diploma_x + 15, -height - 2), Color(0.3, 0.3, 0.3, 0.5), 1.0)
		draw_line(Vector2(diploma_x + 5, -height + 3), Vector2(diploma_x + 13, -height + 3), Color(0.3, 0.3, 0.3, 0.5), 1.0)
