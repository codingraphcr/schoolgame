class_name ChapterThreeRest
extends Node
## Empezar el Capítulo 3 desde la cama de Kai (hijo del cuarto). Después de «FIN DEL CAPÍTULO 2», la cama ofrece
## descansar («pasan unas semanas»): si ChapterGate dice que quedan secundarias o tareas de los capítulos 1 y 2, Kai lo
## dice (y no pasa nada); si no, Kai se duerme, se recupera, empieza QUEST (marca capitulo_3), aparece
## «CAPÍTULO 3 · AMENAZAS INVISIBLES» y se guarda en la cama. Antes del Capítulo 2 terminado o después de empezar el
## 3, la cama sigue como siempre.

const QUEST := &"contagio_digital"

@export var bed: KaiBed
@export var pending_dialogue_intro := "Kai [pensativo]: Todavía quedan asuntos pendientes antes de continuar esta aventura."
@export var wake_dialogue: Dialogue
@export var bed_entry: StringName = &"cama"
@export var quick := false

var busy := false


func _ready() -> void:
	if bed:
		bed.alternate_rest = _on_rest


## Si ahora la cama sirve para pasar al Capítulo 3.
func applies() -> bool:
	var state := _state()
	return state.has_flag(ChapterGate.CHAPTER_3_STORY_FLAG) and not state.has_reached_step(QUEST)


func _on_rest(player: Player) -> bool:
	if not applies() or busy:
		return false
	busy = true
	bed.interactable.busy = true
	var state := _state()
	if not ChapterGate.can_start_chapter_3(state):
		var dialogue := Dialogue.new()
		var lines := PackedStringArray([pending_dialogue_intro])
		for quest_name in ChapterGate.pending_names(state, 3):
			lines.append("(Pendiente: %s.)" % quest_name)
		lines.append("Kai: Mejor termino lo que empecé. Las misiones pendientes están en el Grimorio.")
		dialogue.script_text = "\n".join(lines)
		await StoryHelper.say(self, dialogue)
	else:
		var prompt := ConfirmPrompt.ask(self, "¿Descansar?", "Pasarán unas semanas. Empieza el Capítulo 3 y se guarda la partida.")
		var yes: bool = await prompt.answered
		if yes:
			await _sleep(player)
	bed.interactable.busy = false
	busy = false
	return true


func _sleep(player: Player) -> void:
	player.controls_locked = true
	player.velocity.x = 0.0
	var scenes := get_node("/root/SceneManager")
	await scenes.transition(func() -> void:
		player.visible = false
		bed.sleeping = true
		_restore(player))
	await _wait(1.0)
	_state().start_quest(QUEST)
	var card := _title_card()
	if card:
		card.show_title("CAPÍTULO 3", "AMENAZAS INVISIBLES · EL ÚLTIMO GUARDIÁN")
	await _wait(4.0)
	await scenes.transition(func() -> void:
		bed.sleeping = false
		player.visible = true
		player.global_position = bed.global_position + Vector2(-72, 0)
		player.face(1))
	await _wait(0.5)
	await StoryHelper.say(self, wake_dialogue)
	player.controls_locked = false
	var saves := get_node("/root/SaveManager")
	if saves.active_slot != 0:
		var saved: bool = saves.save_game((get_parent() as Room).scene_file_path, bed_entry)
		get_tree().call_group(&"toast", &"show_message",
			"Partida guardada · cristales y energía llenos" if saved else "No se pudo guardar la partida", 2.5)


func _restore(player: Player) -> void:
	player.health.restore_full()
	player.set_energy(player.max_energy)
	_state().current_masks = -1.0
	_state().current_energy = -1.0


func _title_card() -> TitleCard:
	for node in get_parent().find_children("*", "TitleCard", true, false):
		return node as TitleCard
	return null


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds * (0.1 if quick else 1.0), false, true).timeout


func _state() -> Node:
	return get_node("/root/GameState")
