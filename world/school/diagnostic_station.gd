@tool
class_name DiagnosticStation
extends Interactable
## Un equipo de la clase para diagnosticar (Capítulo 3, «Contagio digital»): en el paso step_id de quest_id, con E se
## abre su ficha en la ventana de inspección (síntomas que se ven, a qué está conectado y lo que nota Kai) y queda la
## marca «diag_<id>». Es todo simulado: no se ejecuta nada. DiagnosisBoard junta los tres. Mientras falla, la pantalla
## parpadea con un error; con la Visión Digital se ven rastros oscuros saliendo por el cable.
## El origen es el piso, frente al escritorio.

const RED := Color("ff5a6a")
const CYAN := Color("3ef2ff")

@export var id: StringName = &""
@export var title := "Equipo"
@export var symptoms: PackedStringArray = []
@export var connections: PackedStringArray = []
@export var kai_note := ""
@export var quest_id: StringName = &"contagio_digital"
@export var step_id: StringName = &"diagnostico"
## Lo que dice la pantalla.
@export var screen_error := "ERROR"
## false: el escritorio ya está en la sala (p. ej. el puesto de Kai del Capítulo 1): solo se dibuja la falla.
@export var draw_desk := true

var _clock := 0.0


func _init() -> void:
	prompt_offset = Vector2(-50, -86)
	prompt_text = "E: revisar el equipo"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(52, 56)
	shape.shape = rect
	shape.position = Vector2(0, -28)
	add_child(shape)
	super()
	interacted.connect(_on_interacted)


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()
	if Engine.is_editor_hint():
		return
	enabled = is_active()
	super(delta)


func is_active() -> bool:
	return get_node("/root/GameState").get_current_step(quest_id) == step_id


func is_failing() -> bool:
	if Engine.is_editor_hint():
		return true
	var state := get_node("/root/GameState")
	return state.has_reached_step(quest_id, &"diagnostico") and not state.has_flag(&"contagio_contenido")


static func flag_of(station_id: StringName) -> StringName:
	return StringName("diag_%s" % station_id)


func _on_interacted(_player: Player) -> void:
	busy = true
	var lines := PackedStringArray()
	lines.append("SÍNTOMAS:")
	for symptom in symptoms:
		lines.append("· " + symptom)
	lines.append("CONECTADO A:")
	for connection in connections:
		lines.append("· " + connection)
	var entry := {
		"name": title,
		"subtitle": "Diagnóstico · sin tocar nada",
		"description": "Kai mira lo que pasa y anota. No borra, no reinicia, no abre nada.",
		"lines": lines,
		"note": kai_note,
		"draw": func(canvas: CanvasItem, rect: Rect2, t: float) -> void: _draw_screen(canvas, rect, t),
	}
	var window := InspectionWindow.open(self, "DIAGNÓSTICO", [entry] as Array[Dictionary], "", "seguir")
	get_node("/root/GameState").set_flag(flag_of(id))
	await window.closed
	busy = false


func _draw_screen(canvas: CanvasItem, rect: Rect2, t: float) -> void:
	var screen := Rect2(rect.position + rect.size * Vector2(0.1, 0.15), rect.size * Vector2(0.8, 0.55))
	canvas.draw_rect(screen, Color("101824"))
	canvas.draw_rect(screen, Color("8a94a8"), false, 2.0)
	var blink := fmod(t, 1.0) < 0.6
	canvas.draw_rect(Rect2(screen.position + Vector2(12, 14), Vector2(screen.size.x - 24, 22)), Color(RED, 0.8 if blink else 0.4))
	canvas.draw_string(ThemeDB.fallback_font, screen.position + Vector2(16, 30), screen_error, HORIZONTAL_ALIGNMENT_LEFT, screen.size.x - 30, 13, Color.WHITE)
	for k in 3:
		canvas.draw_line(screen.position + Vector2(14, 50 + k * 12), screen.position + Vector2(screen.size.x - 30 - k * 18, 50 + k * 12), Color(0.5, 0.6, 0.7, 0.6), 2.0)


func _draw() -> void:
	# Escritorio y monitor (si la sala no los tiene ya).
	var screen := Rect2(-18, -58, 36, 26)
	var failing := is_failing()
	if draw_desk:
		draw_rect(Rect2(-30, -30, 60, 6), Color("6a4a32"))
		draw_rect(Rect2(-26, -24, 4, 24), Color("4a3424"))
		draw_rect(Rect2(22, -24, 4, 24), Color("4a3424"))
		draw_rect(screen.grow(2), Color("2a2e38"))
		draw_rect(screen, Color("2a1418") if failing else Color("1a2a3a"))
	if failing and fmod(_clock, 1.2) < 0.8:
		# Sin escritorio propio, el error va sobre la pantalla de la terminal de la sala.
		var bar := Rect2(screen.position + Vector2(4, 8), Vector2(28, 8)) if draw_desk else Rect2(-18, -44, 36, 8)
		draw_rect(bar, Color(RED, 0.9))
	if draw_desk:
		draw_rect(Rect2(-3, -32, 6, 4), Color("2a2e38"))
	# Cable hacia la red (abajo); con la Visión, los rastros oscuros bajan por él (ver DigitalWorld/Visión).
	draw_line(Vector2(18, -30), Vector2(30, 0), Color("3a3f4a"), 2.0)
	if not Engine.is_editor_hint() and failing and get_node("/root/DigitalVision").is_active():
		for k in 3:
			var p := fmod(_clock * 0.8 + k / 3.0, 1.0)
			draw_circle(Vector2(18, -30).lerp(Vector2(30, 0), p), 3.0, Color(0.15, 0.05, 0.2, 0.9))
			draw_circle(Vector2(18, -30).lerp(Vector2(30, 0), p), 1.5, Color(RED, 0.8))
	if not Engine.is_editor_hint() and is_active() and not get_node("/root/GameState").has_flag(flag_of(id)):
		draw_string(ThemeDB.fallback_font, Vector2(-4, -64), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("f2c14e"))
