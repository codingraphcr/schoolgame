@tool
class_name TerminalStation
extends Interactable
## Terminal del juego (en cualquier sala): con E abre la TerminalWindow con su desafío.
## Si se indica quest_id/step_id, solo se puede usar en ese paso de la misión y al resolver el
## desafío lo completa (después de mostrar success_dialogue). Los comandos usados quedan
## aprendidos en GameState (para el Grimorio). El origen es la base, apoyada en el suelo.

const CYAN := Color("3ef2ff")
const DIM := Color(0.4, 0.5, 0.7)

@export var challenge: TerminalChallenge
@export var quest_id: StringName = &""
@export var step_id: StringName = &""
## Diálogo al cerrar la terminal con el desafío resuelto (p. ej. Kai cuenta lo que encontró).
@export var success_dialogue: Dialogue

var _canvas: VectorCanvas
var _shape: CollisionShape2D


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)
	if Engine.is_editor_hint():
		return
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 56)
	_shape.shape = rect
	_shape.position = Vector2(0, -28)
	add_child(_shape)
	super()
	interacted.connect(_on_interacted)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	enabled = is_usable()
	super(delta)


func is_usable() -> bool:
	if challenge == null:
		return false
	if quest_id == &"":
		return true
	return get_node("/root/GameState").get_current_step(quest_id) == step_id


func _on_interacted(player: Player) -> void:
	busy = true
	player.controls_locked = true
	player.velocity.x = 0.0
	var window := TerminalWindow.open(self, challenge)
	window.interpreter.command_run.connect(_on_command_run)
	var solved: bool = await window.closed
	if solved:
		var box := DialogueBox.find(self)
		if success_dialogue and box:
			await box.play(success_dialogue)
		if quest_id != &"":
			get_node("/root/GameState").complete_step(quest_id, step_id)
	player.controls_locked = false
	busy = false


func _on_command_run(command: String, _args: PackedStringArray, _target: String) -> void:
	get_node("/root/GameState").learn_command(StringName(command))


func _paint(c: VectorCanvas, t: float) -> void:
	var active := Engine.is_editor_hint() or is_usable()
	var color := CYAN if active else DIM
	var pulse := 0.5 + 0.5 * sin(t * 3.0)
	var screen := Rect2(-22, -50, 44, 32)
	c.glow(screen.get_center(), 30.0, Color(color, (0.22 if active else 0.06) + 0.08 * pulse))
	# Soporte y pantalla.
	c.draw_rect(Rect2(-2, -18, 4, 15), Color("1b2647"))
	c.gradient_box(Rect2(-12, -4, 24, 4), 1.0, Color("2a3a6a"), Color("1b2647"), Color("0a0d1c"), 0.6)
	c.gradient_box(screen, 3.0, Color("0b1226"), Color("050913"), color, 1.2)
	c.crisp_text(screen.position + Vector2(5, 13), ">_", 8, color, HORIZONTAL_ALIGNMENT_LEFT)
	if active and fmod(t, 1.0) < 0.5:
		c.draw_rect(Rect2(screen.position + Vector2(17, 7), Vector2(5, 7)), color)
	c.crisp_text(Vector2(-30, -55), "TERMINAL", 5, Color(color, 0.8), HORIZONTAL_ALIGNMENT_CENTER, 60)
