extends SceneTree
## Prueba automática: el Capítulo 2 de punta a punta (Los primeros códigos). El capítulo 1 lleva al 2
## (marca capitulo_2: se abren las salas del simulador); la clase de programación en la Sala 3; la
## conexión del laboratorio (con la Visión) al simulador; las salas de variables (la puerta con
## condición), condiciones (plataformas si / si no) y ciclos (el puente de n bloques y el repaso):
## «NIVEL 3 COMPLETADO»; los procesos repetidos (el generador, el registro y el manejo de errores);
## Bucle y el derrumbe (se dan por hechos: tienen sus pruebas) con la salida al laboratorio; y el profesor:
## «FIN DEL CAPÍTULO 2». Con E sobre un nodo de variable de verdad.
## Ejecutar: godot --headless --path . --script res://tests/test_capitulo2.gd

const Z := "res://world/zones/zone0/"
const SIM := "res://world/zones/simulador/"
const Q2 := &"travesuras_en_el_sistema"
const Q3 := &"el_lenguaje_de_las_maquinas"
const Q4 := &"codigo_fuera_de_control"

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
	var final_point := {}
	for point in DevPoints.POINTS:
		if point["nombre"] == "Final (GENESIS_ARCHIVE)":
			final_point = point
	DevPoints.prepare(final_point, state)
	state.quest_completed.connect(func(quest_id: StringName) -> void: titles.append(String(QuestDB.get_quest(quest_id).completion_title)))
	_test_start()
	await _test_class()
	await _test_lab()
	await _test_variables()
	await _test_conditions()
	await _test_loops()
	await _test_processes()
	await _test_bucle_and_exit()
	await _test_ending()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_start() -> void:
	_check(root.get_node("World").lock_reason(&"sim_variables") != "", "antes del capítulo 2 el simulador está cerrado")
	state.complete_step(Q2, &"hablar_profesor")
	_check(state.is_quest_completed(Q2) and state.get_current_step(Q3) == &"clase_programacion" and state.has_flag(&"capitulo_2"),
		"al terminar el capítulo 1 empieza el 2: «El lenguaje de las máquinas»")
	_check(ProgressTracker.chapter(state) == 2 and root.get_node("World").lock_reason(&"sim_variables") == "", "la partida está en el capítulo 2 y el simulador se abre")
	_check(QuestDB.get_quest(Q2).followup_title == "CAPÍTULO 2", "después de «FIN DEL CAPÍTULO 1» aparece «CAPÍTULO 2 · LOS PRIMEROS CÓDIGOS»")


func _test_class() -> void:
	await _open(Z + "sala_3.tscn")
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing() and (room.get_node("Capitulo2/Profesor") as Node2D).visible and (room.get_node("Capitulo2/Clase") as Node2D).visible,
		"en la Sala 3 empieza la clase de programación (el profesor y los compañeros)")
	await _advance(box)
	await _until(func() -> bool: return state.get_current_step(Q3) == &"entrar_simulador")
	_check(state.get_current_step(Q3) == &"entrar_simulador", "después hay que entrar al simulador del laboratorio")


func _test_lab() -> void:
	await _open(Z + "laboratorio.tscn")
	var portal := room.get_node("Capitulo2/ConexionSimulador") as ImmersionPortal
	_check(portal.is_available() and portal.resolve()["scene"] == SIM + "sim_entrada.tscn", "en el laboratorio está la conexión al simulador")
	root.get_node("DigitalVision").activate(true)
	room.player.teleport_to(portal.global_position + Vector2(0, 52))
	await _frames(8)
	await _action(&"interact")
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == SIM + "sim_entrada.tscn" and current_scene.is_node_ready())
	await _frames(6)
	room = current_scene as Room
	_check(room.scene_file_path == SIM + "sim_entrada.tscn", "con la Visión, Kai entra al simulador")
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	await _until(func() -> bool: return state.get_current_step(Q3) == &"variables")
	_check(state.get_current_step(Q3) == &"variables", "llega al simulador de prácticas")
	root.get_node("DigitalVision").reset()


func _test_variables() -> void:
	await _open(SIM + "sim_variables.tscn")
	var door := room.get_node("Capitulo2/Puerta") as LogicDoor
	var llave := room.get_node("Capitulo2/Nodo_llave") as VariableNode
	var energia := room.get_node("Capitulo2/Nodo_energia") as VariableNode
	_check(door.active and not door.condition_met() and door._label.text.begins_with("si llave == falso") == false,
		"la puerta está cerrada y muestra su condición (%s)" % door._label.text)
	# Con E de verdad sobre el nodo.
	room.player.teleport_to(llave.global_position + Vector2(-10, 0))
	await _frames(6)
	await _action(&"interact")
	await _frames(3)
	_check(llave.value() == true, "con E, «llave» pasa a verdadero")
	_check(door.active, "pero falta energía: la puerta sigue cerrada")
	energia.next_value()
	energia.next_value()
	await _frames(3)
	_check(energia.value() == 3 and door.is_open and not door.active, "con energia = 3 se cumple la condición y la puerta se abre")
	await _frames(2)
	_check(state.get_current_step(Q3) == &"condiciones", "paso cumplido: ahora las condiciones")


func _test_conditions() -> void:
	await _open(SIM + "sim_condiciones.tscn")
	var si := room.get_node("Platforms/Si1") as LogicPlatform
	var sino := room.get_node("Platforms/SiNo1") as LogicPlatform
	await _frames(3)
	_check(not si.present and sino.present, "con modo = noche existen las plataformas «si no» y no las «si»")
	(room.get_node("Capitulo2/Nodo_modo") as VariableNode).next_value()
	await _frames(3)
	_check(si.present and not sino.present, "con modo = día se invierten")
	var gaps_ok := true
	var path: Array[Node2D] = [room.get_node("Platforms/Si1"), room.get_node("Platforms/Si2"), room.get_node("Platforms/Pilar"),
		room.get_node("Platforms/SiNo1"), room.get_node("Platforms/SiNo2")]
	var previous_end := 190.0
	var previous_y := 304.0
	for platform: Node2D in path:
		gaps_ok = gaps_ok and platform.position.x - previous_end <= 64.0 and previous_y - platform.position.y <= 60.0
		previous_end = platform.position.x + platform.get("width")
		previous_y = platform.position.y
	gaps_ok = gaps_ok and 720.0 - previous_end <= 64.0
	_check(gaps_ok, "los saltos del camino se alcanzan con salto y dash (huecos y alturas)")
	var finish := room.get_node("Capitulo2/Llegada") as Node2D
	room.player.teleport_to(finish.global_position + Vector2(0, 30))
	await _until(func() -> bool: return state.get_current_step(Q3) == &"ciclos")
	_check(state.get_current_step(Q3) == &"ciclos", "al cruzar, paso cumplido: ahora los ciclos")


func _test_loops() -> void:
	await _open(SIM + "sim_ciclos.tscn")
	var bridge := room.get_node("Capitulo2/Puente") as LoopBridge
	var node := room.get_node("Capitulo2/Nodo_n") as VariableNode
	await _frames(3)
	_check(bridge.built.size() == 1 and not bridge.is_complete, "con n = 1 el puente queda corto")
	var variables := room.get_node("Variables") as SimVariables
	variables.set_value(&"n", 6)
	await _frames(3)
	_check(bridge.built.is_empty() and bridge._message.begins_with("ERROR"), "con n = 6 el ciclo se pasa: choca con la pared (ERROR)")
	variables.set_value(&"n", 3)
	node.next_value()
	await _frames(3)
	_check(bridge.built.size() == 4 and bridge.is_complete, "con n = 4 justo, el puente llega")
	var kiosk := room.get_node("Capitulo2/Repaso") as ChallengeKiosk
	room.player.teleport_to(kiosk.global_position + Vector2(-10, 0))
	await _frames(6)
	await _action(&"interact")
	var window := await _window()
	_check(window != null and window.challenge.id == &"cap2_repaso_funciones", "al final, el repaso de funciones y objetos")
	_answer_all(window)
	await _until(func() -> bool: return state.is_quest_completed(Q3))
	_check(state.is_quest_completed(Q3) and titles.has("NIVEL 3 COMPLETADO") and state.has_flag(&"nivel_3_completado"),
		"«NIVEL 3 COMPLETADO»")
	_check(state.get_current_step(Q4) == &"procesos", "y empieza «Código fuera de control»")


func _test_processes() -> void:
	await _open(SIM + "sim_procesos.tscn")
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	var spawner := room.get_node("Capitulo2/Generador") as ProcessSpawner
	var gate := room.get_node("Capitulo2/Puerta") as ArenaBarrier
	room.player.damage.protected = true
	await _until(func() -> bool: return spawner.spawned.size() >= 2)
	_check(spawner.running and spawner.spawned.size() >= 2 and gate.active, "el generador crea procesos repetidos sin parar y la puerta está cerrada")
	var terminal := room.get_node("Capitulo2/Terminal") as TerminalStation
	var interpreter := terminal.challenge.create_interpreter()
	interpreter.execute("cd registro")
	_check(String(interpreter.execute("cat procesos.log")["output"]).contains("mientras tarea_pendiente"), "el registro muestra la lista de procesos y el ciclo")
	terminal.solved.emit()
	var window := await _window()
	_check(window != null and window.challenge.id == &"cap2_manejo_errores", "después de leerlo: el desafío de manejo de errores")
	_answer_all(window)
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	await _until(func() -> bool: return state.get_current_step(Q4) == &"vencer_bucle")
	await _frames(30)
	_check(not spawner.running and spawner.spawned.is_empty() and get_nodes_in_group(&"enemy").filter(func(e: Node) -> bool: return e is RepeatedProcess and not e.is_dead).is_empty(),
		"el ciclo se corta y los procesos se deshacen")
	_check(not gate.active and state.get_current_step(Q4) == &"vencer_bucle", "se abre la puerta del núcleo: ahora Bucle")


func _test_bucle_and_exit() -> void:
	# Bucle y el derrumbe tienen sus pruebas (test_bucle, test_dominio_nulo): aquí se dan por hechos.
	var scene := (load(SIM + "arena_bucle.tscn") as PackedScene).instantiate()
	(scene.get_node("Fight") as BucleArenaController).skip_cinematics = true
	current_scene.queue_free()
	await process_frame
	root.add_child(scene)
	current_scene = scene
	await _frames(6)
	room = scene as Room
	var fight := room.get_node("Fight") as BucleArenaController
	var boss := fight.boss
	room.player.damage.protected = true
	while boss.impacts < 7:
		await _until(func() -> bool: return boss.is_vulnerable())
		boss.hurtbox.hit_received.emit(HitData.new())
		await _frames(2)
	await _until(func() -> bool: return state.get_current_step(Q4) == &"salir_simulador")
	_check(state.get_current_step(Q4) == &"salir_simulador", "vencer a Bucle cumple su paso")
	await _until(func() -> bool: return fight.phase == BucleArenaController.Phase.COLLAPSE and state.domain_stage >= 1)
	room.player.domain.activate(true)
	fight.wall.health.take_damage(99.0)
	await _until(func() -> bool: return fight.phase == BucleArenaController.Phase.DONE)
	_check(state.get_current_step(Q4) == &"hablar_profesor" and state.has_flag(&"cap2_anomalia_vista"),
		"salir del simulador cumple su paso (y queda la pista: «arquitectura reconocida»)")
	var exit := room.get_node("Exits/Salida") as RoomExit
	_check(exit.resolve().get("scene", "") == Z + "laboratorio.tscn", "la salida lleva al laboratorio")


func _test_ending() -> void:
	await _open(Z + "laboratorio.tscn")
	var profesor := room.get_node("Capitulo2/Profesor") as Npc
	_check(profesor.visible, "el profesor espera en el laboratorio")
	room.player.teleport_to(profesor.global_position + Vector2(24, 0))
	await _frames(6)
	await _action(&"interact")
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	await _until(func() -> bool: return state.is_quest_completed(Q4))
	_check(state.is_quest_completed(Q4) and titles.has("FIN DEL CAPÍTULO 2") and state.has_flag(&"capitulo_2_completado")
		and state.has_flag(&"nivel_4_completado"), "«FIN DEL CAPÍTULO 2»")


## --- Ayudas ---

func _open(path: String) -> void:
	change_scene_to_file(path)
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == path and current_scene.is_node_ready())
	await _frames(4)
	room = current_scene as Room


func _box() -> DialogueBox:
	return room.get_node("CombatHUD/DialogueBox") as DialogueBox


func _advance(box: DialogueBox) -> void:
	for i in 80:
		if not box.is_playing():
			return
		await _action(&"interact")
		await _frames(3)


func _window() -> ChoiceWindow:
	for i in 240:
		var window := get_first_node_in_group(&"choice_window") as ChoiceWindow
		if window:
			return window
		await process_frame
	return null


func _answer_all(window: ChoiceWindow) -> void:
	for q in window.challenge.questions.size():
		var options := window.challenge.questions[window.question_index].options
		for i in options.size():
			if options[i].correct:
				window.choose(i)
		window.next()


func _action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventAction.new()
	release.action = action
	Input.parse_input_event(release)
	await process_frame


func _until(condition: Callable) -> void:
	for i in 1500:
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
