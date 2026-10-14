extends SceneTree
## Prueba automática: Capítulo 1, etapa 1 (guion y datos). Las dos misiones y su orden, los diálogos
## (oradores conocidos y los textos de la especificación sin cambios), los desafíos (una sola respuesta
## correcta, con explicación en todas las opciones), las páginas del Grimorio, las voces de Chip y
## Glitch, y la Biblia: ningún texto del capítulo revela el origen de Kai.
## Ejecutar: godot --headless --path . --script res://tests/test_capitulo1_datos.gd

const DIALOGUES := "res://data/dialogues/capitulo1"
const CHALLENGES := ["cap1_registro_anomalo", "cap1_archivo_privado", "cap1_checkpoint_1", "cap1_checkpoint_2", "cap1_checkpoint_3", "cap1_escudo_chip"]
const PAGES := ["chip", "glitch", "registro_eventos", "acceso_autorizado", "respaldos", "inmersion_digital", "registro_fragmento_cap1"]
## Palabras que revelarían antes de tiempo qué es Kai o quién lo creó (Biblia XV, reglas 1, 11 y 12).
const SPOILERS := ["artificial", "biomateria", "organismo", "te creé", "te creó", "génesis", "genesis", "aegis", "axiom"]

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_quests()
	_test_dialogues()
	_test_challenges()
	_test_pages_and_voices()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_quests() -> void:
	var first := QuestDB.get_quest(&"una_clase_diferente")
	var second := QuestDB.get_quest(&"travesuras_en_el_sistema")
	_check(first != null and second != null, "las dos misiones del capítulo están registradas")
	if first == null or second == null:
		return
	_check(first.title == "Una clase diferente" and second.title == "Travesuras en el sistema", "títulos de los niveles de la especificación")
	_check(first.next_quest == &"travesuras_en_el_sistema" and first.completion_flag == &"nivel_1_completado"
		and second.completion_flag == &"capitulo_1_completado", "el nivel 1 lleva al 2; marcas de nivel y de capítulo")
	_check(first.steps.size() == 6 and second.steps.size() == 5, "pasos: 6 en el nivel 1 y 5 en el nivel 2")
	_check(QuestDB.get_quest(&"cuarto_viejo").next_quest == &"una_clase_diferente", "el prólogo («El cuarto viejo») lleva al Capítulo 1")


func _test_dialogues() -> void:
	var speakers := {}
	for file in ResourceLoader.list_directory("res://data/characters"):
		var character := load("res://data/characters/" + file) as DialogueCharacter
		if character:
			speakers[character.display_name] = true
			for alias in character.aliases:
				speakers[alias] = true
	var unknown: PackedStringArray = []
	var spoilers: PackedStringArray = []
	var all_text := ""
	var count := 0
	for file in ResourceLoader.list_directory(DIALOGUES):
		var dialogue := load(DIALOGUES.path_join(file)) as Dialogue
		if dialogue == null:
			continue
		count += 1
		for line in dialogue.get_lines():
			all_text += "%s: %s\n" % [line["speaker"], line["text"]]
			if not String(line["speaker"]).is_empty() and not speakers.has(line["speaker"]):
				unknown.append("%s (%s)" % [line["speaker"], file])
		for word in SPOILERS:
			if dialogue.script_text.to_lower().contains(word):
				spoilers.append("%s: «%s»" % [file, word])
	_check(count >= 18, "%d diálogos del capítulo" % count)
	_check(unknown.is_empty(), "todos los oradores son personajes conocidos %s" % [unknown])
	_check(spoilers.is_empty(), "ningún diálogo revela el origen de Kai ni nombra el proyecto %s" % [spoilers])
	for expected in ["Glitch: ¡LO LOGRAMOS!", "Chip: Por supuesto. Era un plan perfecto.", "Kai: ¿Decían algo?", "Chip: ¡PLAN B!",
			"Glitch: ¡Ay, ay, ay! ¡Ya no quiero jugar!", "Glitch: Porque hacen ruidos graciosos cuando fallan.",
			"Chip: ¡No digás eso! ¡Teníamos un plan!", "Chip: ... Todavía estábamos trabajando en eso."]:
		_check(all_text.contains(expected), "texto de la especificación: «%s»" % expected)


func _test_challenges() -> void:
	var problems: PackedStringArray = []
	for id in CHALLENGES:
		var challenge := load("res://data/challenges/%s.tres" % id) as ChoiceChallenge
		if challenge == null or challenge.id != StringName(id):
			problems.append("%s no carga" % id)
			continue
		for question in challenge.questions:
			var correct := 0
			for option in question.options:
				correct += 1 if option.correct else 0
				if option.feedback.strip_edges().is_empty():
					problems.append("%s: «%s» sin explicación" % [id, option.text])
			if correct != 1 or question.options.size() < 3:
				problems.append("%s: %d correctas de %d" % [id, correct, question.options.size()])
	_check(problems.is_empty(), "6 desafíos con 3 opciones, una correcta y explicación en todas %s" % [problems])
	var answers := {
		"cap1_checkpoint_1": "Consultar únicamente la información para la que se tiene autorización",
		"cap1_checkpoint_2": "Verificar que la copia de respaldo sea válida",
		"cap1_checkpoint_3": "Utilizar controles de acceso adecuados",
	}
	for id in answers:
		var challenge := load("res://data/challenges/%s.tres" % id) as ChoiceChallenge
		var right := ""
		for option in challenge.questions[0].options:
			if option.correct:
				right = option.text
		_check(right == answers[id], "%s: la respuesta correcta es la de la especificación" % id)
	var shield := load("res://data/challenges/cap1_escudo_chip.tres") as ChoiceChallenge
	var checkpoint_3 := load("res://data/challenges/cap1_checkpoint_3.tres") as ChoiceChallenge
	_check(shield.questions[0].prompt != checkpoint_3.questions[0].prompt, "el escudo de Chip no repite la pregunta del checkpoint 3")


func _test_pages_and_voices() -> void:
	var missing: PackedStringArray = []
	for page in PAGES:
		var entry := load("res://data/grimorio/%s.tres" % page) as GrimorioEntry
		if entry == null or (entry.unlock_flag == &"" and entry.unlock_property == &""):
			missing.append(page)
	_check(missing.is_empty(), "7 páginas del Grimorio del capítulo, cada una con su condición de desbloqueo %s" % [missing])
	var immersion := load("res://data/grimorio/inmersion_digital.tres") as GrimorioEntry
	_check(immersion.inventory_kind == GrimorioEntry.InventoryKind.HABILIDAD and immersion.text.contains("No es lo mismo que la Visión Digital"),
		"Inmersión Digital es una habilidad distinta de la Visión Digital")
	var chip := load("res://data/characters/chip.tres") as DialogueCharacter
	var glitch := load("res://data/characters/glitch.tres") as DialogueCharacter
	_check(Sfx.RECIPES.has(chip.voice) and Sfx.RECIPES.has(glitch.voice) and chip.voice != glitch.voice, "Chip y Glitch tienen voces propias")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
