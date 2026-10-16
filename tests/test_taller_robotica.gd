extends SceneTree
## Prueba automática: el taller de robótica y las anomalías antes de Bucle (expansión del Capítulo 2;
## docs/mundo/COLEGIO.md). El taller es el anexo del laboratorio (la puerta de vidrio) y no está en el prólogo; en el
## Capítulo 1 las estaciones están «en preparación»; las tres simulaciones (condicionales, ciclos, funciones) aciertan
## y explican los errores, y un ciclo sin salida se corta por seguridad; las tres estaciones usan la misma ventana;
## resolverlas paga Ecos una vez y con las tres empieza lo raro: cuatro anomalías que aparecen de a una, que sin la
## Visión parecen fallas normales y con la Visión se investigan; con las cuatro, Kai va al simulador. El Compañero
## recuerda lo que se eligió en el recreo; el profesor manda al taller; guardar y cargar conserva todo; el Dominio
## Nulo sigue bloqueado.
## Ejecutar: godot --headless --path . --script res://tests/test_taller_robotica.gd

const Z := "res://world/zones/zone0/"
const Q2 := &"el_lenguaje_de_las_maquinas"

var _failures := 0
var state: Node
var vision: Node
var room: Room


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	vision = root.get_node("DigitalVision")
	root.get_node("SaveManager").new_game(1)
	_test_sims()
	DevPoints._advance(state, &"prologo", &"hablar_profesor")
	await _open(Z + "laboratorio.tscn")
	_check(not (room.get_node("ATaller") as Node2D).visible, "en el prólogo la puerta del taller no está (el prólogo no cambia)")
	DevPoints._advance(state, &"una_clase_diferente", &"buscar_huellas")
	state.unlock_vision()
	state.set_nullblade_stage(1)
	await _test_chapter_1()
	DevPoints._advance(state, Q2, &"taller_robotica")
	state.unlock_immersion()
	state.set_flag(&"recreo_eleccion_2")
	await _test_professor()
	await _test_stations()
	await _test_anomalies()
	await _test_saved()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_sims() -> void:
	var sorter := (load("res://data/robotics/clasificador.tres") as RoboticsChallenge).create_sim()
	_check(sorter.run([0, 0, 1] as Array[int]).ok, "clasificador: «si es metal → A; si no → B» funciona")
	var wrong := sorter.run([1, 0, 1] as Array[int])
	_check(not wrong.ok and wrong.feedback.contains("tenía que ir"), "clasificador: preguntar por el papel falla y explica por qué: «%s»" % wrong.feedback)
	_check(sorter.run([0, 0, 0] as Array[int]).feedback.contains("misma") or sorter.run([0, 0, 0] as Array[int]).feedback.contains("no decide"),
		"clasificador: las dos ramas a la misma ruta no deciden nada")
	var conveyor := ConveyorSim.new()
	var endless := conveyor.run([0, 0] as Array[int])
	_check(not endless.ok and endless.stopped_for_safety and endless.steps.size() == RoboticsSim.SAFETY_LIMIT,
		"cinta: un ciclo sin salida se corta por seguridad a las %d vueltas (nunca se traba el juego)" % RoboticsSim.SAFETY_LIMIT)
	_check(conveyor.run([0, 1] as Array[int]).ok and conveyor.run([2, 1] as Array[int]).ok, "cinta: con «detener cuando no queden cajas» funciona")
	_check(conveyor.run([1, 0] as Array[int]).feedback.contains("antes de tiempo") and conveyor.run([2, 0] as Array[int]).feedback.contains("vacía"),
		"cinta: explica si paró antes o si siguió girando vacía")
	var assistant := AssistantSim.new()
	_check(assistant.run([0, 1, 2, 1] as Array[int]).ok, "asistente: cable, encender, abrir × 3 mesas funciona")
	_check(assistant.run([2, 0, 1, 1] as Array[int]).feedback.contains("apagada"), "asistente: el orden importa (no se abre con la compu apagada)")
	_check(not assistant.run([0, 1, 2, 0] as Array[int]).ok and assistant.run([0, 1, 2, 0] as Array[int]).feedback.contains("tres mesas"),
		"asistente: una sola llamada deja dos mesas sin preparar")
	_check(not assistant.run([0, 1, 3, 1] as Array[int]).ok, "asistente: apagar al final deshace el trabajo")


func _test_chapter_1() -> void:
	await _open(Z + "laboratorio.tscn")
	var door := room.get_node("ATaller") as Stairway
	_check(door.visible and door.resolve().get("scene") == Z + "taller.tscn", "desde el Capítulo 1, la puerta de vidrio lleva al taller")
	door._on_interacted(room.player)
	await _arrive(Z + "taller.tscn")
	var station := room.get_node("Estaciones/Clasificador") as RoboticsStation
	_check(not station.is_open() and station.prompt_text == "E: mirar el proyecto", "en el Capítulo 1 las estaciones están «en preparación»")
	var line := await _use(station)
	_check(line.contains("próximamente") and get_first_node_in_group(&"robotics_window") == null, "se anuncia la actividad, sin abrirla")
	_check(not (room.get_node("Gente") as Node2D).visible and (room.get_node("ProyectoPerdido") as Node2D).visible,
		"la estudiante de «El proyecto perdido» trabaja aquí; los compañeros todavía no")


func _test_professor() -> void:
	await _open(Z + "sala_3.tscn")
	var profesor := room.get_node("Capitulo2/Profesor") as Npc
	var conversation := profesor._current_conversation()
	_check(conversation != null and conversation.dialogue.resource_path.ends_with("cap2_profesor_taller.tres"),
		"después de la clase, el profesor manda al taller")
	_check(state.get_objective_text().contains("taller"), "objetivo: «%s»" % state.get_objective_text())


func _test_stations() -> void:
	await _open(Z + "taller.tscn")
	var friend := room.get_node("Gente/Companero") as Npc
	_check((room.get_node("Gente") as Node2D).visible and friend._current_conversation().dialogue.resource_path.ends_with("taller_companero_recreo.tres"),
		"el Compañero recuerda lo que hablaron en la soda (la robótica)")
	var economy := root.get_node("Economy")
	var answers := { &"Clasificador": [0, 0, 1], &"Cinta": [0, 1], &"Asistente": [0, 1, 2, 1] }
	var first_window := true
	for station_name: StringName in answers:
		var station := room.get_node("Estaciones/%s" % station_name) as RoboticsStation
		var before: int = economy.ecos
		room.player.teleport_to(Vector2(station.global_position.x, 304))
		await _frames(3)
		station._on_interacted(room.player)
		await _until(func() -> bool: return get_first_node_in_group(&"robotics_window") != null)
		var window := get_first_node_in_group(&"robotics_window") as RoboticsWindow
		if first_window:
			_check(paused and window.choices.size() == 3, "con E se abre la estación (el juego se pausa)")
			window.execute()
			window.skip()
			_check(not window.is_solved and window._feedback.text.contains("Cambia el programa"), "un programa equivocado se puede corregir y volver a ejecutar")
			first_window = false
		var choices: Array = answers[station_name]
		for i in choices.size():
			window.set_choice(i, choices[i])
		window.execute()
		await _frames(2)
		_check(window.running, "%s: la simulación corre animada" % station_name)
		window.skip()
		_check(window.is_solved, "%s: resuelta" % station_name)
		window.close()
		await _frames(4)
		_check(not paused and state.has_flag(RoboticsStation.flag_of(station.challenge.id)) and economy.ecos > before,
			"%s: queda la marca y da Ecos (+%d)" % [station_name, economy.ecos - before])
	var again := room.get_node("Estaciones/Cinta") as RoboticsStation
	var ecos: int = economy.ecos
	RoboticsStation.register(state, economy, again.challenge)
	_check(economy.ecos == ecos, "volver a resolver una estación no paga de nuevo")
	_check(state.get_current_step(Q2) == &"investigar_anomalias", "con las tres estaciones, empieza lo raro: investigar las fallas")


func _test_anomalies() -> void:
	var order := [&"Robot", &"Brazo", &"Mensaje", &"Puerta"]
	var robot := room.get_node("Anomalias/Robot") as Anomaly
	var brazo := room.get_node("Anomalias/Brazo") as Anomaly
	_check(robot.is_active() and not brazo.is_active(), "las fallas aparecen de a una: primero el robot")
	var line := await _use(robot)
	_check(line.contains("Visión") and not state.has_flag(Anomaly.flag_of(&"robot")), "sin la Visión parece un error normal (no cuenta)")
	for anomaly_name: StringName in order:
		var anomaly := room.get_node("Anomalias/%s" % anomaly_name) as Anomaly
		_check(anomaly.is_active(), "%s: ahora falla" % anomaly_name)
		vision.activate(true)
		await _frames(20)
		_check(anomaly._canvas.visible, "%s: con la Visión se ve el ↻ de datos" % anomaly_name)
		line = await _use(anomaly)
		vision.deactivate()
		await _frames(2)
		_check(state.has_flag(Anomaly.flag_of(anomaly.id)) and not anomaly.is_active(), "%s: investigada" % anomaly_name)
	_check(line.contains("simulador") and line.contains("Tengo que entrar") and state.get_current_step(Q2) == &"entrar_simulador",
		"con las cuatro, Kai entiende que todo viene del simulador: va a entrar")
	_check(not line.to_lower().contains("bucle"), "no se revela a Bucle todavía")


func _test_saved() -> void:
	var saves := root.get_node("SaveManager")
	_check(saves.save_game(Z + "taller.tscn", &"desde_laboratorio"), "se guarda la partida")
	state.reset()
	saves.load_slot(1)
	_check(RoboticsStation.solved_count(state) == 3 and ClueTracker.count(state, Anomaly.flags()) == 4
		and state.get_current_step(Q2) == &"entrar_simulador", "al cargar, las estaciones y las anomalías siguen hechas")
	_check(state.domain_stage == 0, "el Dominio Nulo sigue bloqueado (Capítulo 4)")


func _use(node: Interactable) -> String:
	room.player.teleport_to(Vector2(node.global_position.x, 304))
	await _frames(3)
	node._on_interacted(room.player)
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	var text := box._text.text
	var last := text
	for i in 80:
		if not box.is_playing():
			break
		last = box._text.text
		await _action(&"interact")
		await _frames(3)
	await _frames(4)
	return text + "\n" + last


func _open(path: String) -> void:
	change_scene_to_file(path)
	await _arrive(path)


func _arrive(path: String) -> void:
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == path and current_scene.is_node_ready())
	await _frames(6)
	room = current_scene as Room


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
	for i in 2400:
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
