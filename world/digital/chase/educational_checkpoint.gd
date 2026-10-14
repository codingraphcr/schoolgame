@tool
class_name EducationalCheckpoint
extends Interactable
## Checkpoint educativo de la persecución digital (Capítulo 1): al final de cada tramo, en la zona
## segura. Al llegar abre su pregunta (ChoiceChallenge en ChoiceWindow, la ventana de siempre); con E
## se vuelve a abrir si se cerró sin terminar. Respuesta incorrecta: emite wrong_answer (el
## controlador descuenta tiempo; la ventana ya muestra por qué no y deja intentar de nuevo). Correcta:
## emite solved. La puerta (gate, una ArenaBarrier) la abre el controlador.
## Se dibuja como un pilar de datos con su número. El origen es la base, apoyada en el suelo.

signal reached(checkpoint: EducationalCheckpoint)
signal wrong_answer(checkpoint: EducationalCheckpoint)
signal solved(checkpoint: EducationalCheckpoint)

const CYAN := Color("3ef2ff")
const GREEN := Color("5dff9a")

## 1, 2 o 3.
@export var number := 1:
	set(value):
		number = value
		queue_redraw()
@export var challenge: ChoiceChallenge
## Desde qué x (global) empieza la zona segura de este checkpoint.
@export var safe_from_x := 0.0
## Puerta que se abre al responder bien.
@export var gate: ArenaBarrier
## Entrada (RoomEntry.id) donde se reaparece y se guarda la partida después de este checkpoint.
@export var entry_id: StringName = &""

var done := false:
	set(value):
		done = value
		enabled = not value
		queue_redraw()

var _arrived := false
var _window: ChoiceWindow
var _time := 0.0


func _init() -> void:
	prompt_text = "E: responder"
	prompt_offset = Vector2(-34, -86)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(64, 64)
	shape.shape = rect
	shape.position = Vector2(0, -32)
	add_child(shape)
	super()
	body_entered.connect(_on_arrived)
	interacted.connect(func(_player: Player) -> void: open())


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()


func is_open() -> bool:
	return _window != null and is_instance_valid(_window)


## Abre la pregunta (si no está resuelta ni abierta).
func open() -> void:
	if done or is_open() or challenge == null:
		return
	busy = true
	_window = ChoiceWindow.open(self, challenge)
	_window.answered.connect(_on_answered)
	_window.closed.connect(_on_closed)


func _on_arrived(body: Node) -> void:
	if not body is Player or done:
		return
	if not _arrived:
		_arrived = true
		reached.emit(self)
	open()


func _on_answered(_question: int, _option: int, correct: bool) -> void:
	if not correct:
		wrong_answer.emit(self)


func _on_closed(completed: bool) -> void:
	_window = null
	busy = false
	if completed:
		done = true
		solved.emit(self)


func _draw() -> void:
	var color := GREEN if done else CYAN
	var pulse := 0.5 + 0.5 * sin(_time * 2.4)
	var pillar := Rect2(-12, -64, 24, 64)
	draw_rect(pillar.grow(6), Color(color, 0.1 + 0.08 * pulse))
	draw_rect(pillar, Color(0.04, 0.09, 0.18))
	draw_rect(pillar, Color(color, 0.8), false, 1.5)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-12, -38), str(number), HORIZONTAL_ALIGNMENT_CENTER, 24, 16, color)
	draw_string(font, Vector2(-30, -70), "CHECKPOINT" if not done else "✔ LISTO", HORIZONTAL_ALIGNMENT_CENTER, 60, 8, Color(color, 0.9))
	for k in 3:
		var y := -10.0 - k * 8.0 - fmod(_time * 12.0, 8.0)
		draw_rect(Rect2(-6, y, 12, 2), Color(color, 0.4))
