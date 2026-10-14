extends SceneTree
## Prueba automática: Capítulo 1, etapas 11 y 12 (la historia completa, de punta a punta). El prólogo
## lleva al capítulo; la clase con el profesor y los compañeros; Chip y Glitch solo con la Visión; el
## registro de eventos y su desafío; la persecución corta; la biblioteca y el archivo privado; la
## puerta cerrada y el permiso del profesor («NIVEL 1 COMPLETADO»); el servidor y la conexión; y el
## final con el profesor y GENESIS_ARCHIVE («FIN DEL CAPÍTULO 1»). La persecución y la pelea tienen
## sus propias pruebas (test_persecucion, test_jefe_hermanos): aquí se dan por hechas.
## Ejecutar: godot --headless --path . --script res://tests/test_capitulo1_historia.gd

const Z := "res://world/zones/zone0/"
const Q0 := &"cuarto_viejo"
const Q1 := &"una_clase_diferente"
const Q2 := &"travesuras_en_el_sistema"

var _failures := 0
var state: Node
var room: Room
var titles: Array[String] = []


func _initialize() -> void:
	Engine.max_physics_steps_per_frame = 1
	Engine.physics_jitter_fix = 0.0
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	root.get_node("SaveManager").new_game(1)
	state.unlock_vision()
	state.quest_completed.connect(func(quest_id: StringName) -> void: titles.append(String(QuestDB.get_quest(quest_id).completion_title)))
	_test_prologue_leads_to_chapter()
	await _test_class()
	await _test_registro()
	await _test_short_chase()
	await _test_library()
	await _test_permission()
	await _test_server()
	await _test_ending()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_prologue_leads_to_chapter() -> void:
	state.start_quest(Q0)
	for step in [&"hablar_profesor", &"ir_pasillo_viejo", &"abrir_puerta", &"explorar_cuarto", &"salir_cuarto"]:
		state.complete_step(Q0, step)
	_check(state.has_flag(&"tutorial_terminado") and state.get_current_step(Q1) == &"ir_a_clase",
		"al terminar «EL DESPERTAR» empieza el Capítulo 1: «Una clase diferente»")
	_check(ProgressTracker.chapter(state) == 1, "la partida está en el Capítulo 1")


func _test_class() -> void:
	await _open(Z + "laboratorio.tscn")
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing(), "en el laboratorio empieza la clase del profesor")
	_check((room.get_node("Capitulo1/Profesor") as Node2D).visible and (room.get_node("Capitulo1/Clase") as Node2D).visible,
		"el profesor y los compañeros están en la clase")
	await _advance(box)
	_check(state.get_current_step(Q1) == &"ver_fallas", "después, las computadoras fallan: hay que usar la Visión")
	var chip := room.get_node("Capitulo1/Chip") as SiblingActor
	await _frames(30)
	_check(not chip.is_shown(), "sin la Visión Digital, Chip y Glitch no se ven")
	root.get_node("DigitalVision").activate(true)
	await _until(func() -> bool: return box.is_playing())
	await _frames(20)
	_check(chip.is_shown() and box.is_playing(), "con la Visión, Kai los ve saltando entre los monitores (y se dan cuenta)")
	await _advance(box)
	await _until(func() -> bool: return state.get_current_step(Q1) == &"revisar_registro")
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	root.get_node("DigitalVision").deactivate()
	_check(state.get_current_step(Q1) == &"revisar_registro", "escapan y el profesor pide revisar el registro de eventos")


func _test_registro() -> void:
	var terminal := room.get_node("Capitulo1/PuestoKai") as TerminalStation
	_check(terminal.is_usable(), "la terminal del puesto de Kai se puede usar")
	var interpreter := terminal.challenge.create_interpreter()
	interpreter.execute("cd registro")
	var log := String(interpreter.execute("cat eventos.log")["output"])
	_check(log.contains("chip_y_glitch") and log.contains("340 archivos"), "el registro muestra el usuario que no existe y los cambios masivos")
	_check(not interpreter.execute("rm eventos.log")["ok"] and interpreter.available_commands() == PackedStringArray(["help", "ls", "cd", "cat"]),
		"la terminal solo tiene los comandos que hacen falta")
	terminal.solved.emit()
	var window := await _window()
	_check(window != null and window.challenge.id == &"cap1_registro_anomalo", "después de leerlo: el desafío «Comportamiento anómalo»")
	window.choose(_option(window, true))
	window.next()
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	await _until(func() -> bool: return state.get_current_step(Q1) == &"seguir_criaturas")
	_check(state.has_flag(&"cap1_registro_revisado") and (load("res://data/grimorio/registro_eventos.tres") as GrimorioEntry).is_unlocked(state),
		"queda el registro revisado y su página del Grimorio")


func _test_short_chase() -> void:
	await _open(Z + "pasillo.tscn")
	_check(not (room.get_node("Npcs/Profesor") as Node2D).visible, "el profesor del pasillo no está (está en la clase)")
	var run := room.get_node("Capitulo1/SiblingRun") as SiblingRun
	var glitch := run.actors[1]
	await _frames(10)
	_check(glitch.is_shown(), "en el pasillo, Chip y Glitch esperan a Kai")
	var box := _box()
	room.player.teleport_to(Vector2(560, 296))
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing(), "al acercarse, gritan y corren hacia las escaleras")
	await _advance(box)
	for i in 6:
		await _until(func() -> bool: return not run._moving)
		if run.is_done():
			break
		room.player.teleport_to(run.actors[0].global_position + Vector2(60, 0))
		await _frames(6)
	await _frames(30)
	_check(run.is_done() and not glitch.is_shown(), "Kai los sigue hasta la escalera y suben (punto %d de %d)" % [run.index, run.path.size()])


func _test_library() -> void:
	await _open(Z + "biblioteca.tscn")
	await _until(func() -> bool: return state.get_current_step(Q1) == &"biblioteca")
	_check(state.get_current_step(Q1) == &"biblioteca", "llega a la biblioteca detrás de ellos")
	var catalog := room.get_node("Capitulo1/Catalogo") as CatalogScene
	await _frames(4)
	_check(catalog.enabled, "la computadora del catálogo muestra un archivo privado")
	room.player.teleport_to(catalog.global_position + Vector2(0, 56))
	await _frames(6)
	await _action(&"interact")
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	var window := await _window()
	_check(window != null and window.challenge.id == &"cap1_archivo_privado", "el desafío «Un archivo que no es tuyo»")
	window.choose(_option(window, false))
	window.choose(_option(window, true))
	window.next()
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	await _until(func() -> bool: return state.get_current_step(Q1) == &"pedir_permiso")
	_check(state.has_flag(&"cap1_archivo_protegido") and state.get_current_step(Q1) == &"pedir_permiso",
		"Kai protege el archivo sin mirarlo; los hermanos escapan al cuarto técnico")


func _test_permission() -> void:
	await _open(Z + "escaleras.tscn")
	var door := room.get_node("Exits/ToCuartoTecnico") as RoomExit
	_check(not door.is_open(), "la puerta del cuarto técnico está cerrada con llave")
	await _open(Z + "laboratorio.tscn")
	var profesor := room.get_node("Capitulo1/Profesor") as Npc
	room.player.teleport_to(profesor.global_position + Vector2(20, 0))
	await _frames(6)
	await _action(&"interact")
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	await _until(func() -> bool: return state.is_quest_completed(Q1))
	_check(state.is_quest_completed(Q1) and state.has_flag(&"nivel_1_completado") and titles.has("NIVEL 1 COMPLETADO"),
		"Kai le pide permiso al profesor: «NIVEL 1 COMPLETADO»")
	await _open(Z + "escaleras.tscn")
	door = room.get_node("Exits/ToCuartoTecnico") as RoomExit
	_check(state.get_current_step(Q2) == &"revisar_servidor" and door.is_open(), "empieza «Travesuras en el sistema» y la puerta se abre")


func _test_server() -> void:
	await _open(Z + "cuarto_tecnico.tscn")
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing(), "en el cuarto técnico, Chip y Glitch se ríen desde el monitor")
	await _advance(box)
	await _until(func() -> bool: return state.get_current_step(Q2) == &"seguirlos_adentro")
	_check(state.get_current_step(Q2) == &"seguirlos_adentro", "y se meten en la computadora: hay que seguirlos")
	var portal := room.get_node("ImmersionPortal") as ImmersionPortal
	_check(portal.target_scene.ends_with("persecucion.tscn"), "la conexión del monitor lleva a la red de entrenamiento")


func _test_ending() -> void:
	# La persecución y la pelea se prueban aparte: aquí se dan por hechas.
	for step in [&"seguirlos_adentro", &"persecucion", &"vencer_hermanos"]:
		state.complete_step(Q2, step)
	state.set_flag(&"cap1_hermanos_vencidos")
	await _open(Z + "cuarto_tecnico.tscn")
	var story := room.get_node("TechRoomStory") as TechRoomStory
	story.quick = true
	_check(not story.props.alert, "el servidor ya no está en rojo")
	var profesor := room.get_node("Capitulo1/Profesor") as Npc
	_check(profesor.visible, "el profesor está en el cuarto técnico")
	room.player.teleport_to(profesor.global_position + Vector2(24, 0))
	await _frames(6)
	await _action(&"interact")
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	var saw_genesis := [false]
	await _until(func() -> bool:
		if story.props.genesis:
			saw_genesis[0] = true
		return state.is_quest_completed(Q2))
	_check(saw_genesis[0] and state.has_flag(&"cap1_genesis_visto"), "Kai se va y el profesor ve aparecer GENESIS_ARCHIVE")
	_check(state.is_quest_completed(Q2) and state.has_flag(&"capitulo_1_completado") and titles.has("FIN DEL CAPÍTULO 1"), "«FIN DEL CAPÍTULO 1»")
	_check(not room.player.controls_locked, "y Kai puede seguir jugando")


## --- Ayudas ---

func _open(path: String) -> void:
	change_scene_to_file(path)
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == path and current_scene.is_node_ready())
	await _frames(4)
	room = current_scene as Room


func _box() -> DialogueBox:
	return room.get_node("CombatHUD/DialogueBox") as DialogueBox


func _advance(box: DialogueBox) -> void:
	for i in 60:
		if not box.is_playing():
			return
		await _action(&"interact")
		await _frames(3)


func _window() -> ChoiceWindow:
	for i in 120:
		var window := get_first_node_in_group(&"choice_window") as ChoiceWindow
		if window:
			return window
		await process_frame
	return null


func _option(window: ChoiceWindow, correct: bool) -> int:
	var options := window.challenge.questions[window.question_index].options
	for i in options.size():
		if options[i].correct == correct:
			return i
	return 0


func _action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _until(condition: Callable) -> void:
	for i in 900:
		if condition.call():
			return
		await process_frame
		await physics_frame


func _frames(count: int) -> void:
	for i in count:
		await process_frame
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
