class_name ProgressTracker
extends RefCounted
## Resumen del avance de una partida, para las tarjetas de las ranuras y «Mi perfil»: año, capítulo,
## nivel, % de historia y % educativo. Se calcula a partir de GameState y Economy (no guarda nada
## propio). Estructura de la Biblia Narrativa: prólogo + 12 capítulos de 2 niveles (24 niveles);
## décimo = capítulos 1–4, undécimo = 5–8, duodécimo = 9–12.
##
## Marcas que irá dejando el contenido de cada capítulo: «capitulo_N» (empezó el capítulo N) y
## «nivel_N_completado» (terminó el nivel N). El prólogo cuenta por sus misiones.

const PROLOGUE_QUESTS: Array[StringName] = [&"prologo", &"contrasena_profesor", &"cuarto_viejo"]
const TOTAL_LEVELS := 24
const TERMINALS_FOLDER := "res://data/terminals"
const CHALLENGES_FOLDER := "res://data/challenges"


## Capítulo en curso: 0 = prólogo; 1 al terminar «EL DESPERTAR» (tutorial_terminado); después, el
## último «capitulo_N». El mapa se abre según esto (World.lock_reason()).
static func chapter(game_state: Node) -> int:
	for n in range(12, 0, -1):
		if game_state.has_flag(StringName("capitulo_%d" % n)):
			return n
	return 1 if game_state.has_flag(&"tutorial_terminado") else 0


## { anio, capitulo, nivel, historia, educativo } (historia y educativo: 0–100).
static func summary(game_state: Node, economy: Node) -> Dictionary:
	var chapter := chapter(game_state)
	var levels_done := 0
	for n in range(1, TOTAL_LEVELS + 1):
		if game_state.has_flag(StringName("nivel_%d_completado" % n)):
			levels_done += 1
	var level := 0 if chapter == 0 else mini(levels_done + 1, TOTAL_LEVELS)
	var prologue := 0.0
	for quest in PROLOGUE_QUESTS:
		if game_state.is_quest_completed(quest):
			prologue += 1.0 / PROLOGUE_QUESTS.size()
	var story := (prologue + levels_done) / (TOTAL_LEVELS + 1) * 100.0
	var learning := education(game_state, economy)
	return {
		"anio": "decimo" if chapter <= 4 else ("undecimo" if chapter <= 8 else "duodecimo"),
		"capitulo": chapter,
		"nivel": level,
		"historia": int(floor(story)),
		"educativo": learning["porcentaje"],
	}


## Lo educativo completado: terminales resueltas, desafíos de elección y comandos aprendidos, y el
## porcentaje sobre las actividades que existen hoy en el juego.
static func education(game_state: Node, economy: Node) -> Dictionary:
	var terminals := _completed(TERMINALS_FOLDER, "terminal", economy)
	var challenges := _completed(CHALLENGES_FOLDER, "desafio", economy)
	var total := _count(TERMINALS_FOLDER) + _count(CHALLENGES_FOLDER)
	var done: int = terminals.size() + challenges.size()
	return {
		"terminales": terminals,
		"desafios": challenges,
		"comandos": game_state.get_learned_commands(),
		"porcentaje": 0 if total == 0 else int(floor(100.0 * done / total)),
	}


static func _completed(folder: String, prefix: String, economy: Node) -> Array[String]:
	var result: Array[String] = []
	for id in _ids(folder):
		if economy.is_claimed(StringName("%s:%s" % [prefix, id])):
			result.append(id)
	return result


static func _count(folder: String) -> int:
	return _ids(folder).size()


static func _ids(folder: String) -> Array[String]:
	var result: Array[String] = []
	var files := Array(ResourceLoader.list_directory(folder))
	files.sort()
	for file: String in files:
		if file.ends_with(".tres"):
			var resource := load(folder.path_join(file))
			if resource and "id" in resource:
				result.append(String(resource.id))
	return result
