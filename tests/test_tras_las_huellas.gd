extends SceneTree
## Prueba automática: «Tras las huellas del error» (expansión del Capítulo 1; docs/mundo/COLEGIO.md). Después de
## pedir permiso, el profesor prepara el acceso al cuarto técnico y Kai busca rastros de la falla: hay tres (patio,
## soda y pasillo) que solo se ven con la Visión Digital y bastan dos. Sin la Visión no se ven ni se pueden tocar;
## mirar uno lo registra; con dos se vuelve con el profesor (sin temporizador) y ahí termina el Nivel 1; el rastro
## que falta ya no aparece; la partida guarda lo encontrado; fuera de ese momento no hay rastros.
## Ejecutar: godot --headless --path . --script res://tests/test_tras_las_huellas.gd

const Z := "res://world/zones/zone0/"
const Q1 := &"una_clase_diferente"

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
	DevPoints._advance(state, Q1, &"pedir_permiso")
	state.unlock_vision()
	state.set_nullblade_stage(1)
	await _test_before()
	DevPoints._advance(state, Q1, &"buscar_huellas")
	await _test_waiting_professor()
	await _test_patio()
	await _test_soda()
	await _test_leftover()
	await _test_professor()
	await _test_saved()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_before() -> void:
	await _open(Z + "patio.tscn")
	var trace := _trace()
	vision.activate(true)
	await _frames(20)
	_check(not trace.is_searchable() and not trace.enabled and not trace._canvas.visible,
		"antes de pedir permiso no hay rastros (ni con la Visión)")
	vision.deactivate()
	await _frames(4)


func _test_waiting_professor() -> void:
	_check(QuestDB.get_quest(Q1).steps.size() == 8 and state.get_objective_text().contains("rastros"),
		"objetivo: buscar rastros mientras el profe prepara el acceso «%s»" % state.get_objective_text())
	await _open(Z + "sala_3.tscn")
	var profesor := room.get_node("Capitulo1/Profesor") as Npc
	var line := await _talk(profesor)
	_check(line.contains("Todavía no me dan la llave") and state.get_current_step(Q1) == &"buscar_huellas",
		"si Kai vuelve antes, el profesor le pide un par de rastros (no hay que esperar un tiempo)")


func _test_patio() -> void:
	await _open(Z + "patio.tscn")
	var trace := _trace()
	await _frames(4)
	_check(trace.is_searchable() and not trace.enabled and not trace._canvas.visible, "sin la Visión, el rastro del patio no se ve")
	vision.activate(true)
	await _frames(20)
	_check(trace.enabled and trace._canvas.visible, "con la Visión aparece «CHIP ESTUVO AQUÍ»")
	var line := await _use(trace)
	_check(line.contains("CHIP ESTUVO AQUÍ") and state.has_flag(&"huella_patio") and ErrorTrace.found_count(state) == 1,
		"mirarlo lo registra (1 de 2)")
	_check(state.get_current_step(Q1) == &"buscar_huellas" and not trace.is_searchable() and not trace.enabled,
		"con uno todavía no alcanza; el rastro ya mirado no vuelve a aparecer")
	vision.deactivate()


func _test_soda() -> void:
	await _open(Z + "soda.tscn")
	var trace := _trace()
	vision.activate(true)
	await _frames(20)
	var line := await _use(trace)
	_check(line.contains("JIJIJI") and state.has_flag(&"huella_soda"), "en la soda, Glitch dejó un mensaje que se repite en la radio")
	_check(state.get_current_step(Q1) == &"volver_profesor" and state.get_objective_text().contains("Sala 3"),
		"con dos rastros, el objetivo es volver con el profe")
	vision.deactivate()


func _test_leftover() -> void:
	await _open(Z + "pasillo.tscn")
	var trace := _trace()
	vision.activate(true)
	await _frames(20)
	_check(not trace.is_searchable() and not trace.enabled and not trace._canvas.visible and not state.has_flag(&"huella_pasillo"),
		"el rastro que faltaba (pasillo) ya no aparece: no hace falta encontrarlos todos")
	vision.deactivate()


func _test_professor() -> void:
	await _open(Z + "sala_3.tscn")
	var profesor := room.get_node("Capitulo1/Profesor") as Npc
	var line := await _talk(profesor)
	await _until(func() -> bool: return state.is_quest_completed(Q1))
	_check(line.contains("encontré rastros") and state.is_quest_completed(Q1) and state.has_flag(&"nivel_1_completado"),
		"el profesor ya tiene la llave: termina el Nivel 1")
	_check(state.get_current_step(&"travesuras_en_el_sistema") == &"revisar_servidor", "y sigue la historia: el cuarto técnico")


func _test_saved() -> void:
	var saves := root.get_node("SaveManager")
	_check(saves.save_game(Z + "sala_3.tscn", &"desde_pasillo"), "se guarda la partida")
	state.reset()
	saves.load_slot(1)
	_check(state.has_flag(&"huella_patio") and state.has_flag(&"huella_soda") and state.is_quest_completed(Q1),
		"al cargar, la partida recuerda los rastros encontrados")


func _trace() -> ErrorTrace:
	return room.get_node("Huellas/Huella") as ErrorTrace


func _use(trace: ErrorTrace) -> String:
	room.player.teleport_to(Vector2(trace.global_position.x, 304))
	await _frames(3)
	trace._on_interacted(room.player)
	return await _read_box()


func _talk(npc: Npc) -> String:
	room.player.teleport_to(Vector2(npc.global_position.x + 24, 304))
	await _frames(3)
	npc._on_interacted(room.player)
	return await _read_box()


## Lo que dice el primer renglón del diálogo que se abre; después lo pasa hasta el final.
func _read_box() -> String:
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	var text := box._text.text
	for i in 80:
		if not box.is_playing():
			break
		await _action(&"interact")
		await _frames(3)
	await _frames(3)
	return text


func _open(path: String) -> void:
	change_scene_to_file(path)
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == path and current_scene.is_node_ready())
	await _frames(4)
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
