@tool
class_name FlowValve
extends Interactable
## Una válvula de flujo del nodo de distribución (Capítulo 3, «Contener el contagio»): corta o deja pasar lo que va
## por su conducto. damaged dice si ese flujo lleva información dañada: solo se nota con la Visión Digital (rastros
## oscuros saliendo por la válvula); sin ella, todas se ven iguales. Con E se abre o se cierra (ContagionNode decide
## si ya se contuvo). Se usa solo en el paso step_id de quest_id. El origen es el piso, al pie de la válvula.

signal toggled(valve: FlowValve)

const CYAN := Color("3ef2ff")
const RED := Color("ff4a6a")

@export var label := "RUTA"
@export var damaged := false
@export var open := true
@export var quest_id: StringName = &"contagio_digital"
@export var step_id: StringName = &"contener_contagio"

var _clock := 0.0


func _init() -> void:
	prompt_offset = Vector2(-50, -96)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(44, 56)
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
	enabled = get_node("/root/GameState").get_current_step(quest_id) == step_id
	prompt_text = "E: cerrar la válvula" if open else "E: abrir la válvula"
	super(delta)


func _on_interacted(_player: Player) -> void:
	open = not open
	Sfx.play(&"terminal_key")
	toggled.emit(self)


func _draw() -> void:
	# Tubo que sube y la rueda de la válvula.
	draw_rect(Rect2(-6, -70, 12, 70), Color("2a3048"))
	draw_rect(Rect2(-8, -74, 16, 6), Color("3a4058"))
	var wheel := Vector2(0, -40)
	draw_arc(wheel, 12.0, 0.0, TAU, 16, Color("8a94a8"), 3.0)
	var angle := 0.0 if open else PI / 2.0
	draw_line(wheel - Vector2(cos(angle), sin(angle)) * 12.0, wheel + Vector2(cos(angle), sin(angle)) * 12.0, Color("8a94a8"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(-40, -82), label, HORIZONTAL_ALIGNMENT_CENTER, 80, 8, Color("c8d0e0"))
	draw_circle(Vector2(14, -60), 3.0, Color("7ee08a") if open else Color("ff8a6a"))
	# Lo que pasa por el conducto: con la Visión, los flujos dañados se ven oscuros.
	if not open:
		return
	var vision: bool = not Engine.is_editor_hint() and get_node("/root/DigitalVision").is_active()
	for k in 3:
		var y := -70.0 - fmod(_clock * 50.0 + k * 22.0, 70.0)
		if damaged and vision:
			draw_circle(Vector2(0, y), 4.0, Color(0.1, 0.02, 0.12, 0.95))
			draw_arc(Vector2(0, y), 4.0, 0.0, TAU, 10, Color(RED, 0.8), 1.0)
		else:
			draw_circle(Vector2(0, y), 2.0, Color(CYAN, 0.7))
