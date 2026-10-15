class_name ChallengeKiosk
extends Interactable
## Quiosco del simulador (Capítulo 2): con E abre un desafío de elección (ChoiceChallenge) hasta
## terminarlo. Si tiene misión y paso, solo funciona en ese paso y lo completa al terminar. completed
## avisa al terminar.

signal completed

@export var challenge: ChoiceChallenge
@export var quest_id: StringName = &""
@export var step_id: StringName = &""
@export var label := "REPASO"

var done := false
var _busy := false


func _init() -> void:
	prompt_text = "E: responder"
	prompt_offset = Vector2(-30, -62)


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30, 44)
	shape.shape = rect
	shape.position = Vector2(0, -22)
	add_child(shape)
	super()
	interacted.connect(_on_interacted)


func is_usable() -> bool:
	if done:
		return false
	if quest_id == &"":
		return true
	return get_node("/root/GameState").get_current_step(quest_id) == step_id


func _process(_delta: float) -> void:
	enabled = is_usable() and not _busy
	queue_redraw()


func _on_interacted(_player: Player) -> void:
	if _busy or not is_usable():
		return
	_busy = true
	await StoryHelper.choose_until_done(self, challenge)
	done = true
	_busy = false
	if quest_id != &"":
		get_node("/root/GameState").complete_step(quest_id, step_id)
	completed.emit()


func _draw() -> void:
	var body := Rect2(Vector2(-14, -44), Vector2(28, 44))
	draw_rect(body, Color(0.06, 0.08, 0.16))
	draw_rect(body, Color("5dff9a") if done else Color("ffd166"), false, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(-14, -50), label, HORIZONTAL_ALIGNMENT_CENTER, 28, 7, Color("ffd166"))
	draw_string(ThemeDB.fallback_font, Vector2(-14, -22), "✔" if done else "?", HORIZONTAL_ALIGNMENT_CENTER, 28, 14, Color("5dff9a") if done else Color("ffd166"))
