class_name ChapterGate
extends RefCounted
## La regla de continuidad antes de Aegis: el Capítulo 3 (cuando Kai conoce a Aegis) solo empieza con la historia de
## los capítulos 1 y 2 terminada y con TODAS sus misiones secundarias y tareas completas (Quest.chapter < 3). Así
## ninguna historia de antes de Aegis se juega por primera vez con Aegis al lado. Los descubrimientos no cuentan
## (son secretos opcionales). Se calcula siempre con el estado real de las misiones (por ranura), sin contadores.

const CHAPTER_3_STORY_FLAG := &"capitulo_2_completado"
const PENDING_MESSAGE := "Todavía quedan asuntos pendientes antes de continuar esta aventura."


## Las secundarias y tareas de capítulos anteriores a chapter que todavía no se completaron (en el orden de QuestDB).
static func pending_before(state: Node, chapter: int) -> Array[Quest]:
	var result: Array[Quest] = []
	for quest_id: StringName in QuestDB.PATHS:
		var quest := QuestDB.get_quest(quest_id)
		if quest == null or quest.chapter <= 0 or quest.chapter >= chapter:
			continue
		if quest.category != Quest.Category.SECUNDARIA and quest.category != Quest.Category.TAREA:
			continue
		if not state.is_quest_completed(quest_id):
			result.append(quest)
	return result


## Si ya se puede empezar el Capítulo 3.
static func can_start_chapter_3(state: Node) -> bool:
	return state.has_flag(CHAPTER_3_STORY_FLAG) and pending_before(state, 3).is_empty()


## Lista legible de lo pendiente, con qué hacer: «Un recreo diferente» (Capítulo 1): Siéntate con tu amigo en la soda.
## (Si la misión ya empezó, su objetivo actual; si no, el primero.)
static func pending_names(state: Node, chapter: int) -> PackedStringArray:
	var names := PackedStringArray()
	for quest in pending_before(state, chapter):
		var objective: String = state.get_quest_objective(quest.id)
		if objective.is_empty() and not quest.steps.is_empty():
			objective = quest.steps[0].objective
		names.append("«%s» (Capítulo %d): %s" % [quest.title, quest.chapter, objective])
	return names
