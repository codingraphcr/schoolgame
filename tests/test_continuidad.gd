extends SceneTree
## Prueba automática: la continuidad antes de Aegis (Capítulo 3; docs/misiones/SISTEMA_DE_MISIONES.md). El Capítulo 3
## solo empieza con los capítulos 1 y 2 terminados y todas sus secundarias y tareas completas (los descubrimientos no
## cuentan); si falta una, la cama y el Grimorio dicen cuál (con qué hacer); esas misiones siguen disponibles hasta
## completarse (el amigo del recreo y la estudiante no desaparecen); la tarea nueva del Capítulo 2 («El robot que no
## obedece») se puede hacer; con todo completo, la cama empieza el Capítulo 3 y se guarda; otra ranura no comparte.
## Ejecutar: godot --headless --path . --script res://tests/test_continuidad.gd

const Z := "res://world/zones/zone0/"
const B := "res://world/zones/barrio/"
const SIDE := [&"un_recreo_diferente", &"proyecto_perdido", &"robot_desobediente"]

var _failures := 0
var state: Node
var room: Room


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	root.get_node("SaveManager").new_game(1)
	_test_rule()
	DevPoints._advance(state, &"el_lenguaje_de_las_maquinas", &"taller_robotica")
	state.unlock_vision()
	state.unlock_immersion()
	state.set_nullblade_stage(1)
	await _test_still_available()
	await _test_robot_task()
	await _test_bed_pending()
	await _test_bed_starts_chapter_3()
	await _test_saved()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_rule() -> void:
	var ids := func() -> Array:
		return ChapterGate.pending_before(state, 3).map(func(q: Quest) -> StringName: return q.id)
	_check(ids.call() == SIDE, "secundarias y tareas de los capítulos 1 y 2: %s" % [ids.call()])
	_check(not (ids.call() as Array).has(&"foto_antigua") and not (ids.call() as Array).has(&"senal_del_barrio"),
		"los descubrimientos y las misiones del Capítulo 3 no cuentan")
	state.set_flag(ChapterGate.CHAPTER_3_STORY_FLAG)
	for quest_id: StringName in SIDE:
		_check(not ChapterGate.can_start_chapter_3(state), "falta «%s»: el Capítulo 3 no se puede empezar" % QuestDB.get_quest(quest_id).title)
		_complete(quest_id)
	_check(ChapterGate.can_start_chapter_3(state), "con todas completas, el Capítulo 3 se puede empezar")
	state.clear_flag(ChapterGate.CHAPTER_3_STORY_FLAG)
	_check(not ChapterGate.can_start_chapter_3(state), "sin terminar la historia del Capítulo 2, tampoco")
	root.get_node("SaveManager").new_game(1)


func _test_still_available() -> void:
	await _open(Z + "soda.tscn")
	_check((room.get_node("Gente/Amigo") as Node2D).visible, "en el Capítulo 2, el amigo del recreo sigue en la soda (se puede hacer)")
	await _open(Z + "taller.tscn")
	_check((room.get_node("ProyectoPerdido") as Node2D).visible, "la estudiante de «El proyecto perdido» sigue en el taller")


func _test_robot_task() -> void:
	await _frames(10)
	_check(state.get_current_step(&"robot_desobediente") == &"hablar_companera", "al entrar al taller en el Capítulo 2 empieza «El robot que no obedece»")
	var companera := room.get_node("Gente/Companera") as Npc
	var line := await _talk(companera)
	_check(line.contains("no obedece") and state.get_current_step(&"robot_desobediente") == &"arreglar_robot", "la Compañera pide ayuda con su robot")
	var station := room.get_node("Estaciones/RobotCompanera") as RoboticsStation
	var sim := station.challenge.create_sim()
	_check(not sim.run([3, 0, 1, 0] as Array[int]).ok and sim.run([0, 1, 0, 3] as Array[int]).ok,
		"el orden de la Compañera falla; avanzar, girar a la izquierda, avanzar, soltar funciona")
	var ecos_before: int = root.get_node("Economy").ecos
	room.player.teleport_to(Vector2(station.global_position.x, 304))
	await _frames(3)
	station._on_interacted(room.player)
	await _until(func() -> bool: return get_first_node_in_group(&"robotics_window") != null)
	var window := get_first_node_in_group(&"robotics_window") as RoboticsWindow
	for i in 4:
		window.set_choice(i, [0, 1, 0, 3][i])
	window.execute()
	window.skip()
	window.close()
	await _frames(4)
	_check(state.get_current_step(&"robot_desobediente") == &"contarle" and root.get_node("Economy").ecos > ecos_before,
		"ordenar las instrucciones arregla el robot (Ecos una vez)")
	line = await _talk(companera)
	_check(line.contains("orden") and state.is_quest_completed(&"robot_desobediente"), "Kai le cuenta: tarea completada")


func _test_bed_pending() -> void:
	DevPoints._advance(state, &"codigo_fuera_de_control", &"hablar_profesor")
	state.complete_step(&"codigo_fuera_de_control", &"hablar_profesor")
	_check(state.has_flag(ChapterGate.CHAPTER_3_STORY_FLAG), "terminó el Capítulo 2")
	var grimorio := GrimorioScreen.open(current_scene)
	await _frames(3)
	var gate: GrimorioEntry = null
	for page in grimorio._quest_entries():
		if page.title == "Asuntos pendientes":
			gate = page
	_check(gate != null and gate.text.contains("Un recreo diferente") and gate.text.contains("Siéntate con tu amigo"),
		"el Grimorio muestra lo pendiente y qué hacer")
	grimorio.close()
	await _frames(3)
	await _open(B + "cuarto_kai.tscn")
	var rest := room.get_node("ChapterThreeRest") as ChapterThreeRest
	rest.quick = true
	var bed := room.get_node("Cuarto/Cama") as KaiBed
	room.player.teleport_to(Vector2(bed.global_position.x, 304))
	await _frames(3)
	bed._on_interacted(room.player)
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	_check(box._text.text.contains("asuntos pendientes") and not state.has_flag(&"capitulo_3"),
		"con pendientes, la cama no avanza: «%s»" % box._text.text)
	await _advance(box)
	await _frames(4)


func _test_bed_starts_chapter_3() -> void:
	for quest_id: StringName in SIDE:
		_complete(quest_id)
	var bed := room.get_node("Cuarto/Cama") as KaiBed
	bed._on_interacted(room.player)
	await _until(func() -> bool: return get_first_node_in_group(&"confirm_prompt") != null)
	(get_first_node_in_group(&"confirm_prompt") as ConfirmPrompt).answer(true)
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	await _until(func() -> bool: return not (room.get_node("ChapterThreeRest") as ChapterThreeRest).busy)
	_check(state.has_flag(&"capitulo_3") and ProgressTracker.chapter(state) == 3 and state.get_current_step(&"contagio_digital") == &"dia_normal",
		"sin pendientes, la cama empieza el Capítulo 3 («Contagio digital»)")
	await _open(Z + "soda.tscn")
	_check(not (room.get_node("Gente/Amigo") as Node2D).visible, "en el Capítulo 3 el amigo ya no espera en la soda (la charla quedó atrás)")


func _test_saved() -> void:
	var saves := root.get_node("SaveManager")
	state.reset()
	saves.load_slot(1)
	_check(state.has_flag(&"capitulo_3") and state.is_quest_completed(&"robot_desobediente"), "al cargar, el Capítulo 3 y la tarea siguen ahí (se guardó en la cama)")
	saves.new_game(2)
	_check(not state.has_flag(&"capitulo_3") and ChapterGate.pending_before(state, 3).size() == SIDE.size(), "otra ranura no comparte nada")


func _complete(quest_id: StringName) -> void:
	state.start_quest(quest_id)
	for step in QuestDB.get_quest(quest_id).steps:
		state.complete_step(quest_id, step.id)


func _talk(npc: Npc) -> String:
	room.player.teleport_to(Vector2(npc.global_position.x + 24, 304))
	await _frames(3)
	npc._on_interacted(room.player)
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	var text := box._text.text
	await _advance(box)
	await _frames(4)
	return text


func _advance(box: DialogueBox) -> void:
	for i in 80:
		if not box.is_playing():
			return
		await _action(&"interact")
		await _frames(3)


func _open(path: String) -> void:
	change_scene_to_file(path)
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
	for i in 3000:
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
