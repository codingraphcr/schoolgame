class_name KaiBed
extends Node2D
## La cama de Kai. Con E, cuando la historia lo permite (la misión está en quest_id / step_id),
## pregunta si descansar (ConfirmPrompt, empieza en «No») y emite rest_confirmed: la escena de la noche
## la hace quien escucha (HomeNight). Si no es momento, Kai lo dice y no pasa nada (no se salta nada
## de la historia ni se reinicia nada). Con sleeping, se dibuja a Kai dormido. El origen es el piso, al
## medio de la cama.

signal rest_confirmed

const FRAME := Color("6a4a32")
const FRAME_DARK := Color("3e2a1c")
const SHEET := Color("5a7ab8")
const SHEET_LIGHT := Color("7a9ad8")
const PILLOW := Color("e8e4d8")

@export var quest_id: StringName = &"camino_a_casa"
@export var step_id: StringName = &"descansar"
@export var not_now_lines: PackedStringArray = ["Todavía es temprano para dormir.", "Ahora no tengo sueño."]
@export var question := "¿Descansar hasta mañana?"
@export var detail := "Termina el día y se guarda la partida."

var sleeping := false:
	set(value):
		sleeping = value
		queue_redraw()
var interactable: Interactable


func _ready() -> void:
	interactable = Interactable.new()
	interactable.prompt_text = "E: descansar"
	interactable.prompt_offset = Vector2(-32, -64)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(96, 40)
	shape.shape = rect
	shape.position = Vector2(0, -20)
	interactable.add_child(shape)
	add_child(interactable)
	interactable.interacted.connect(_on_interacted)


func can_rest() -> bool:
	return get_node("/root/GameState").get_current_step(quest_id) == step_id


func _on_interacted(player: Player) -> void:
	if not can_rest():
		SpeechBark.say(player, not_now_lines[randi() % not_now_lines.size()], Vector2(0, -44), 1.8)
		return
	interactable.busy = true
	var prompt := ConfirmPrompt.ask(self, question, detail)
	var yes: bool = await prompt.answered
	interactable.busy = false
	if yes:
		rest_confirmed.emit()


func _draw() -> void:
	# Cabecera a la izquierda, patas, colchón, sábana y almohada.
	draw_rect(Rect2(-50, -40, 8, 40), FRAME_DARK)
	draw_rect(Rect2(-48, -38, 4, 36), FRAME)
	draw_rect(Rect2(-44, -18, 92, 10), FRAME)
	draw_rect(Rect2(-44, -8, 4, 8), FRAME_DARK)
	draw_rect(Rect2(42, -8, 4, 8), FRAME_DARK)
	draw_rect(Rect2(-42, -24, 88, 7), Color("efeae0"))
	draw_rect(Rect2(-40, -30, 18, 8), PILLOW)
	if sleeping:
		# Kai acostado: la cabeza en la almohada y la sábana marcando el cuerpo.
		draw_circle(Vector2(-31, -31), 5.0, Color("e8e8f0"))
		draw_rect(Rect2(-24, -32, 66, 10), SHEET)
		draw_rect(Rect2(-20, -34, 40, 4), SHEET_LIGHT)
	else:
		draw_rect(Rect2(-18, -26, 62, 6), SHEET)
		draw_rect(Rect2(-18, -26, 62, 2), SHEET_LIGHT)
