@tool
class_name DiagnosisBoard
extends Interactable
## La consola del profesor donde se comparan los equipos revisados (Capítulo 3, «Contagio digital»). Con los tres
## DiagnosticStation revisados, con E: el desafío de comparar y decidir (challenge, hasta completarlo), lo que ve Kai
## con la Visión (vision_dialogue: rastros oscuros por las conexiones) y la autorización del profesor
## (authorize_dialogue). Completa step_id. Antes de revisar los tres, Kai dice qué falta.
## El origen es el piso.

@export var stations: Array[NodePath] = []
@export var challenge: ChoiceChallenge
@export var missing_dialogue: Dialogue
@export var vision_dialogue: Dialogue
@export var authorize_dialogue: Dialogue
@export var quest_id: StringName = &"contagio_digital"
@export var step_id: StringName = &"diagnostico"

var _clock := 0.0


func _init() -> void:
	prompt_offset = Vector2(-70, -96)
	prompt_text = "E: comparar los equipos"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 56)
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
	super(delta)


## Cuántos equipos se revisaron.
func reviewed() -> int:
	var flags: Array[StringName] = []
	for path in stations:
		var station := get_node_or_null(path) as DiagnosticStation
		if station:
			flags.append(DiagnosticStation.flag_of(station.id))
	return ClueTracker.count(get_node("/root/GameState"), flags)


func _on_interacted(_player: Player) -> void:
	busy = true
	if reviewed() < stations.size():
		await StoryHelper.say(self, missing_dialogue)
		busy = false
		return
	await StoryHelper.choose_until_done(self, challenge)
	await StoryHelper.say(self, vision_dialogue)
	await StoryHelper.say(self, authorize_dialogue)
	get_node("/root/GameState").complete_step(quest_id, step_id)
	busy = false


func _draw() -> void:
	# La consola del profesor: un monitor grande con las tres fichas.
	draw_rect(Rect2(-34, -30, 68, 6), Color("4a5470"))
	draw_rect(Rect2(-6, -24, 12, 24), Color("3a3f4a"))
	var screen := Rect2(-30, -76, 60, 40)
	draw_rect(screen.grow(2), Color("2a2e38"))
	draw_rect(screen, Color("101824"))
	var count := 0 if Engine.is_editor_hint() else reviewed()
	for k in 3:
		var card := Rect2(screen.position + Vector2(4 + k * 19, 6), Vector2(15, 28))
		draw_rect(card, Color("7ee08a") if k < count else Color("3a3f4a"))
	draw_string(ThemeDB.fallback_font, Vector2(-30, -82), "CONSOLA", HORIZONTAL_ALIGNMENT_CENTER, 60, 8, Color("8a94a8"))
