class_name RecessChat
extends Interactable
## Una charla con un amigo que incluye una elección pequeña (actividad «Un recreo diferente», Capítulo 1). Con E:
## intro → Kai elige qué decir (DialogueChoice) → la respuesta de esa opción → outro. La primera vez completa la misión
## quest_id (secundaria, sin Ecos) y deja la marca «<choice_flag>_<n>» con la opción elegida (para que más adelante el
## amigo lo recuerde). Nada es irreversible: después repite repeat_dialogue. Se pone junto al amigo (un BackgroundNpc),
## y los dos aparecen con StoryPresence. El origen es el piso.

signal finished(option: int)

@export var quest_id: StringName = &""
@export var intro: Dialogue
@export var question := "¿Qué le decís?"
@export var options: PackedStringArray = []
## Una respuesta por opción, en el mismo orden.
@export var answers: Array[Dialogue] = []
@export var outro: Dialogue
@export var repeat_dialogue: Dialogue
## Prefijo de la marca de la opción elegida (p. ej. &"recreo_eleccion" → recreo_eleccion_0).
@export var choice_flag: StringName = &""


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 48)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	add_child(shape)
	super()
	interacted.connect(_on_interacted)


func is_done() -> bool:
	return quest_id != &"" and get_node("/root/GameState").is_quest_completed(quest_id)


## La opción que eligió Kai (−1 = todavía no charlaron).
func chosen_option() -> int:
	var state := get_node("/root/GameState")
	for i in options.size():
		if state.has_flag(_option_flag(i)):
			return i
	return -1


func _on_interacted(_player: Player) -> void:
	busy = true
	if is_done():
		await StoryHelper.say(self, repeat_dialogue)
	else:
		await _chat()
	# Un cuadro de espera: la tecla que cerró el diálogo no vuelve a abrirlo.
	await get_tree().process_frame
	busy = false


func _chat() -> void:
	await StoryHelper.say(self, intro)
	await get_tree().process_frame
	var option: int = await DialogueChoice.ask(self, question, options).chosen
	if option < answers.size():
		await StoryHelper.say(self, answers[option])
	await StoryHelper.say(self, outro)
	var state := get_node("/root/GameState")
	state.set_flag(_option_flag(option))
	if quest_id != &"" and not state.is_quest_completed(quest_id):
		state.start_quest(quest_id)
		for step in QuestDB.get_quest(quest_id).steps:
			state.complete_step(quest_id, step.id)
	finished.emit(option)


func _option_flag(index: int) -> StringName:
	return StringName("%s_%d" % [choice_flag, index])
