extends SceneTree
## Prueba automática: el comienzo del Capítulo 3, «Contagio digital» (fases 1–3; docs/narrativa/capitulos/CAPITULO_03.md).
## Un día normal (los amigos en la entrada); la clase en la Sala 3 y las computadoras que fallan; el diagnóstico de tres
## equipos (sin tocar nada) y la comparación en la consola (desafío con reintentos); la Visión y la autorización del
## profesor; la conexión del equipo 7 con la Visión; la advertencia del Grimorio, la plataforma que se desintegra y la
## caída (sin daño ni pérdidas); el aterrizaje en el Bosque de Fibra (el Fibroluz, «NUEVA REGIÓN»), el conducto roto y
## el camino a las Raíces; guardar y cargar.
## Ejecutar: godot --headless --path . --script res://tests/test_contagio.gd

const Z := "res://world/zones/zone0/"
const F := "res://world/zones/bosque_fibra/"
const Q := &"contagio_digital"

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
	DevPoints._advance(state, Q, &"dia_normal")
	state.unlock_vision()
	state.unlock_immersion()
	state.set_nullblade_stage(1)
	state.set_dash_level(1)
	await _test_friends()
	await _test_class()
	await _test_diagnosis()
	await _test_connection()
	await _test_landing()
	await _test_saved()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_friends() -> void:
	_check(ProgressTracker.chapter(state) == 3 and state.get_objective_text().contains("Sala 3"), "Capítulo 3: «%s»" % state.get_objective_text())
	await _open(Z + "entrada.tscn")
	var group := room.get_node("Capitulo3") as Node2D
	_check(group.visible, "en la entrada están los amigos")
	room.player.teleport_to(Vector2(400, 304))
	var line := await _read_box()
	_check(line.contains("impresora") and state.has_flag(&"cap3_amigos_hablaron"), "comentan que Kai reconoce los problemas antes que nadie")


func _test_class() -> void:
	await _open(Z + "sala_3.tscn")
	var line := await _read_box()
	_check(line.contains("redes") and state.get_current_step(Q) == &"diagnostico", "la clase empieza y las computadoras fallan")
	_check((room.get_node("Capitulo3/Profesor") as Node2D).visible and not (room.get_node("Gente") as Node2D).visible,
		"el profesor y la clase (los del recreo no)")


func _test_diagnosis() -> void:
	var board := room.get_node("Capitulo3/Consola") as DiagnosisBoard
	var line := await _use(board)
	_check(line.contains("revisar los tres equipos") and state.get_current_step(Q) == &"diagnostico", "sin revisar los equipos, no hay qué comparar")
	for station_name in ["Equipo2", "Equipo7", "Equipo11"]:
		var station := room.get_node("Capitulo3/" + station_name) as DiagnosticStation
		room.player.teleport_to(Vector2(station.global_position.x, 304))
		await _frames(3)
		station._on_interacted(room.player)
		await _until(func() -> bool: return get_first_node_in_group(&"inspection_window") != null)
		var window := get_first_node_in_group(&"inspection_window") as InspectionWindow
		_check(paused and " ".join(window.entries[0]["lines"]).contains("Carpeta compartida CLASE_3"),
			"%s: síntomas y conexiones (todos comparten la carpeta)" % station_name)
		window.close()
		await _frames(3)
	_check(board.reviewed() == 3, "los tres equipos revisados")
	room.player.teleport_to(Vector2(board.global_position.x, 304))
	await _frames(3)
	board._on_interacted(room.player)
	var mistakes := 0
	for question in 3:
		await _until(func() -> bool: return get_first_node_in_group(&"choice_window") != null)
		var window := get_first_node_in_group(&"choice_window") as ChoiceWindow
		if question == 0:
			window.choose(_option(window, false))
			mistakes = window.mistakes[0]
		window.choose(_option(window, true))
		window.next()
		await _frames(3)
	_check(mistakes == 1, "una respuesta equivocada explica por qué y deja reintentar")
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	_check(box._text.text.contains("Visión"), "con la Visión, Kai ve rastros oscuros saliendo de la carpeta compartida")
	await _advance(box)
	await _until(func() -> bool: return box.is_playing() or state.get_current_step(Q) == &"investigar_conexion")
	await _advance(box)
	await _until(func() -> bool: return state.get_current_step(Q) == &"investigar_conexion")
	_check(state.get_current_step(Q) == &"investigar_conexion", "el profesor aísla la carpeta y autoriza una investigación controlada")


func _test_connection() -> void:
	var portal := room.get_node("Capitulo3/ConexionEquipo7") as ImmersionPortal
	vision.activate(true)
	await _frames(20)
	_check(portal.is_available(), "con la Visión aparece la conexión del equipo 7")
	vision.deactivate()
	await _open(F + "conexion_contagio.tscn")
	await _read_box()
	var fall := room.get_node("FallSequence") as FallSequence
	fall.quick = true
	var crumble := room.get_node("Mundo/Inestable") as DataPlatform
	room.player.teleport_to(Vector2(900, 304))
	await _until(func() -> bool: return get_first_node_in_group(&"grimorio_alert") != null)
	var alert := get_first_node_in_group(&"grimorio_alert") as GrimorioAlert
	_check(alert != null and alert.lines[0] == "ADVERTENCIA DE INTEGRIDAD", "el Grimorio avisa que la plataforma no es estable")
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	_check(box._text.text.contains("12 %"), "Kai, confiado, decide saltar igual")
	await _advance(box)
	var masks: float = room.player.health.current
	var ecos: int = root.get_node("Economy").ecos
	room.player.teleport_to(crumble.global_position + Vector2(50, -2))
	await _until(func() -> bool: return fall.falling)
	_check(fall.falling, "al pisarla, la plataforma se desintegra y Kai cae")
	await _until(func() -> bool: return get_first_node_in_group(&"fall_overlay") != null)
	_check(get_first_node_in_group(&"fall_overlay") != null and is_equal_approx(room.player.health.current, masks)
		and root.get_node("Economy").ecos == ecos, "la caída es una escena: sin daño y sin perder Ecos")
	await _arrive(F + "bosque_caida.tscn")


func _test_landing() -> void:
	var landing := room.get_node("Historia/LandingScene") as LandingScene
	landing.quick = true
	var lines := PackedStringArray()
	var box := _box()
	for i in 4:
		await _until(func() -> bool: return box.is_playing())
		await _frames(2)
		lines.append(box._text.text)
		await _advance(box)
	await _until(func() -> bool: return not landing.playing)
	_check(lines[0].contains("Estoy vivo") and lines[3].contains("falta de respeto"), "Kai aterriza y el Fibroluz se burla de él %s" % [lines])
	_check(state.get_current_step(Q) == &"encontrar_salida" and state.get_objective_text().contains("otra salida"), "objetivo: buscar otra salida")
	var conduit := room.get_node("Mundo/ConductoRoto") as Examinable
	var line := await _use(conduit)
	_check(line.contains("roto"), "el conducto de la caída está roto: no se puede volver por ahí")
	room.player.teleport_to(Vector2(954, 304))
	await _arrive(F + "fibra_raices.tscn")
	_check(room.player.global_position.distance_to(Vector2(40, 304)) < 2.0, "por la derecha se sigue a las Raíces")


func _test_saved() -> void:
	var saves := root.get_node("SaveManager")
	_check(saves.save_game(F + "fibra_raices.tscn", &"desde_caida"), "se guarda la partida")
	state.reset()
	saves.load_slot(1)
	_check(state.get_current_step(Q) == &"encontrar_salida" and state.has_flag(DiagnosticStation.flag_of(&"equipo_7")), "al cargar, sigue en el bosque")


func _option(window: ChoiceWindow, correct: bool) -> int:
	var options := window.challenge.questions[window.question_index].options
	for i in options.size():
		if options[i].correct == correct:
			return i
	return 0


func _use(node: Interactable) -> String:
	room.player.teleport_to(Vector2(node.global_position.x, 304))
	await _frames(3)
	node._on_interacted(room.player)
	return await _read_box()


func _read_box() -> String:
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	var text := box._text.text
	await _advance(box)
	await _frames(3)
	return text


func _box() -> DialogueBox:
	return room.get_node("CombatHUD/DialogueBox") as DialogueBox


func _advance(box: DialogueBox) -> void:
	for i in 80:
		if not box.is_playing():
			return
		await _action(&"interact")
		await _frames(3)


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
