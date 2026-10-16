extends SceneTree
## Prueba automática: el Nivel 6, «La señal perdida» (Capítulo 3; docs/narrativa/capitulos/CAPITULO_03.md). En la
## Estación Lázaro: el registro principal (UNIDAD: AEGIS...), el encuentro con Aegis dañado y «Eco en la Red» en tres
## etapas (el tablero eléctrico, los tres guardianes con su pregunta y sus módulos, las Bitcucarachas). La decisión
## (una invitación, no una orden), Aegis Pulse, el escape (el interruptor y el puente que Aegis sostiene), la salida al
## bosque (los colores y los 23 metros), el regreso al colegio («Un amigo»: FIN DEL CAPÍTULO 3) y la escena del
## pasillo. Aegis acompaña a Kai en todas las salas y guardar y cargar lo conserva.
## Ejecutar: godot --headless --path . --script res://tests/test_estacion_lazaro.gd

const F := "res://world/zones/bosque_fibra/"
const L := "res://world/zones/lazaro/"
const Z := "res://world/zones/zone0/"
const Q := &"la_senal_perdida"
const ECO := &"eco_en_la_red"
## La solución más corta del tablero: (columna, fila, giros).
const SOLUTION := [[0, 1, 1], [1, 1, 2], [3, 1, 2], [4, 1, 1], [1, 2, 3], [2, 2, 1], [3, 2, 2], [4, 2, 2]]

var _failures := 0
var state: Node
var room: Room


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	root.get_node("SaveManager").new_game(1)
	DevPoints._advance(state, Q, &"explorar_estacion")
	state.set_flag(&"bosque_descubierto")
	state.set_flag(StationDoor.OPEN_FLAG)
	state.unlock_vision()
	state.unlock_immersion()
	state.set_nullblade_stage(1)
	state.set_dash_level(1)
	_test_grid()
	await _test_vestibule()
	await _test_encounter()
	await _test_power()
	for sector in [["superior", &"procesamiento"], ["exterior", &"comunicacion"], ["inferior", &"proteccion"]]:
		await _test_sector(sector[0], sector[1])
	await _test_core()
	await _test_escape()
	await _test_forest_exit()
	await _test_return()
	await _test_saved()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_grid() -> void:
	var grid := load("res://data/puzzles/lazaro_energia.tres") as PowerGrid
	_check(not grid.is_solved(grid.start_rotations), "el tablero eléctrico empieza desordenado")
	var rotations := grid.start_rotations.duplicate()
	for move: Array in SOLUTION:
		var index := grid.index_of(Vector2i(move[0], move[1]))
		rotations[index] = (rotations[index] + move[2]) % 4
	_check(grid.is_solved(rotations), "y tiene solución (la energía llega de la fuente al núcleo)")


func _test_vestibule() -> void:
	await _open(L + "lazaro_vestibulo.tscn")
	var line := await _read_all_from_start()
	_check(line.contains("Qué lugar más solo"), "al entrar, la estación está medio apagada")
	var to_core := room.get_node("Exits/ToNucleo") as RoomExit
	_check(not to_core.is_open(), "la compuerta del núcleo no responde todavía")
	var up := room.get_node("Mundo/SubirSuperior") as PoweredStairway
	up._on_interacted(room.player)
	await _frames(10)
	_check(current_scene == room and not up._used, "sin energía, las escaleras a los sectores están bloqueadas")
	var terminal := room.get_node("Mundo/Registro_aegis_principal") as StationLog
	terminal._on_interacted(room.player)
	await _until(func() -> bool: return get_first_node_in_group(&"inspection_window") != null)
	var window := get_first_node_in_group(&"inspection_window") as InspectionWindow
	var lines := "\n".join(window.entries[0]["lines"])
	_check(lines.contains("UNIDAD: AEGIS") and lines.contains("ESTADO: AISLADA") and lines.contains("ORIGEN DEL INCIDENTE: [DATOS NO DISPONIBLES]"),
		"el registro principal: UNIDAD: AEGIS · PROTECCIÓN · AISLADA · ... · [DATOS NO DISPONIBLES]")
	window.close()
	await _until(func() -> bool: return state.get_current_step(Q) == &"encontrar_aegis")
	_check(state.get_current_step(Q) == &"encontrar_aegis" and to_core.is_open(), "leído el registro, se puede seguir al núcleo")
	var entry := load("res://data/grimorio/registro_aegis.tres") as GrimorioEntry
	_check(state.has_flag(entry.unlock_flag), "y el Grimorio guarda la página de Aegis")
	room.player.teleport_to(Vector2(954, 304))
	await _arrive(L + "lazaro_nucleo.tscn")


func _test_encounter() -> void:
	var body := room.get_node("Mundo/AegisSitio/Aegis") as AegisBody
	_check(body.visible and body.mood == AegisBody.Mood.DANADO, "en el núcleo, una esferita dañada en el piso")
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	var seen := await _read_all(box)
	_check(seen.contains("Unidad... AEGIS") and seen.contains("si hubiera hecho caso a todas las advertencias") and seen.contains("Evaluación... correcta"),
		"Kai y Aegis: «Función principal... proteger» / «Evaluación... correcta»")
	await _until(func() -> bool: return state.get_current_step(ECO) == &"restablecer_energia")
	_check(state.get_current_step(Q) == &"reparar_aegis" and state.get_current_step(ECO) == &"restablecer_energia",
		"empieza «Eco en la Red»: primero, la energía")
	_check(state.aegis_stage == 0 and room.find_children("*", "AegisCompanion", true, false).is_empty(), "Aegis Pulse todavía no está disponible")


func _test_power() -> void:
	var board := room.get_node("Mundo/Tablero") as PowerBoard
	room.player.teleport_to(Vector2(board.global_position.x, 304))
	await _frames(3)
	board._on_interacted(room.player)
	await _until(func() -> bool: return get_first_node_in_group(&"power_grid_window") != null or _find_window() != null)
	var window := _find_window()
	_check(window != null and not window.is_solved, "el tablero abre el puzzle eléctrico")
	window.rotate_selected()
	window.reset()
	_check(window.rotations == window.grid.start_rotations, "reiniciar deja el tablero como al principio")
	for move: Array in SOLUTION:
		window.cursor = Vector2i(move[0], move[1])
		for i in move[2]:
			window.rotate_selected()
	_check(window.is_solved, "girando las fichas, la energía llega al núcleo")
	window.close()
	var line := await _read_all_from_start()
	await _until(func() -> bool: return state.get_current_step(ECO) == &"recuperar_modulos")
	_check(line.contains("restablecido parcialmente") and state.has_flag(PowerBoard.SOLVED_FLAG), "«Suministro energético... restablecido parcialmente»")
	room.player.teleport_to(Vector2(6, 304))
	await _arrive(L + "lazaro_vestibulo.tscn")


func _test_sector(sector: String, id: StringName) -> void:
	if sector == "inferior":
		var down := room.get_node("Mundo/BajarInferior") as Stairway
		down._on_interacted(room.player)
	else:
		if room.scene_file_path != L + "lazaro_superior.tscn":
			(room.get_node("Mundo/SubirSuperior") as Stairway)._on_interacted(room.player)
			await _arrive(L + "lazaro_superior.tscn")
		if sector == "exterior":
			var climb := room.get_node("Mundo/SubirExterior") as Stairway
			climb._on_interacted(room.player)
	await _arrive(L + "lazaro_%s.tscn" % sector)
	var guardian := room.get_node("Mundo/Guardian") as KnowledgeGuardian
	var gate := room.get_node("Mundo/Barrera") as LazaroGate
	var module := room.get_node("Mundo/Modulo") as AegisModule
	guardian.quick = true
	_check(not gate.is_open() and not module.is_taken(), "%s: el guardián custodia el módulo de %s" % [sector, AegisModule.NAMES[id]])
	room.player.teleport_to(Vector2(guardian.global_position.x - 30.0, 304))
	await _frames(3)
	guardian._on_interacted(room.player)
	await _read_box()
	await _until(func() -> bool: return get_first_node_in_group(&"choice_window") != null)
	var window := get_first_node_in_group(&"choice_window") as ChoiceWindow
	window.choose(_option(window, false))
	var hint: String = window.challenge.questions[0].options[_option(window, false)].feedback
	window.choose(_option(window, true))
	_check(window.mistakes[0] == 1 and hint.begins_with("Pista"), "%s: si Kai se equivoca, recibe una pista y vuelve a intentar" % sector)
	window.next()
	var line := await _read_box()
	await _until(func() -> bool: return not guardian.presenting)
	_check(line.contains("CORRECT") and gate.is_open() and guardian.is_passed(), "%s: al acertar, la proyección se disuelve y la barrera se abre" % sector)
	room.player.teleport_to(module.global_position + Vector2(0, -2))
	await _until(func() -> bool: return module.is_taken())
	_check(state.has_flag(AegisModule.flag_of(id)), "%s: Kai recupera el módulo de %s" % [sector, AegisModule.NAMES[id]])
	# De vuelta al vestíbulo.
	if sector == "exterior":
		(room.get_node("Mundo/BajarSuperior") as Stairway)._on_interacted(room.player)
		await _arrive(L + "lazaro_superior.tscn")
	if sector != "superior":
		var back := room.get_node("Mundo/BajarVestibulo" if sector == "exterior" else "Mundo/SubirVestibulo") as Stairway
		back._on_interacted(room.player)
		await _arrive(L + "lazaro_vestibulo.tscn")


func _test_core() -> void:
	_check(state.get_current_step(ECO) == &"estabilizar_nucleo", "con los tres módulos, falta estabilizar el núcleo")
	room.player.teleport_to(Vector2(954, 304))
	await _arrive(L + "lazaro_nucleo.tscn")
	var core := room.get_node("Nucleo") as CoreDefense
	core.quick = true
	var install := room.get_node("Mundo/Instalar") as CoreInstall
	room.player.teleport_to(Vector2(install.global_position.x, 304))
	await _frames(3)
	install._on_interacted(room.player)
	await _read_box()
	await _until(func() -> bool: return _bugs().size() > 0)
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	var alarm := await _read_all(box)
	_check(alarm.contains("¡¿Y ESTAS COSAS DE DÓNDE SALIERON?!") and alarm.contains("¡PUES IDENTIFICALOS MÁS RÁPIDO!"),
		"aparecen las Bitcucarachas: «¡¿Y ESTAS COSAS DE DÓNDE SALIERON?!»")
	# Una llega al núcleo: pierde estabilidad (sin derrota).
	var first := _bugs()[0]
	first.reached_core.emit(first)
	_check(core.stability < 100.0 and core.running, "si una llega al núcleo, pierde estabilidad (sin derrota)")
	var waves := 0
	for i in 400:
		if core.is_stable():
			break
		for bug in _bugs():
			bug.queue_free()
		waves = maxi(waves, core.wave + 1)
		await _frames(4)
		if box.is_playing():
			break
	_check(waves == 3, "tres oleadas chicas (hubo %d)" % waves)
	# Al estabilizarse el núcleo siguen, sin pausa, la decisión y la alarma: se lee todo lo que va saliendo.
	var story := await _read_all(box)
	for i in 600:
		if story.contains("En ese caso... acepto.") or state.get_current_step(Q) == &"escapar":
			break
		if box.is_playing():
			story += await _read_all(box)
		await _frames(1)
	_check(story.contains("¡LO LOGRAMOS!") and state.is_quest_completed(ECO) and state.has_flag(&"aegis_reparado"),
		"el núcleo se estabiliza: «Eco en la Red» completa")
	_check(story.contains("No te pregunté qué te ordenaron. Te pregunté qué querés vos.") and story.contains("Es una invitación.")
		and story.contains("En ese caso... acepto."), "la decisión: una invitación, no una orden; Aegis acepta")
	await _until(func() -> bool: return state.get_current_step(Q) == &"escapar")
	_check(state.aegis_stage == 1 and state.has_flag(AegisCompanion.FLAG) and state.has_flag(LazaroPropsFlags.ALARM)
		and state.get_current_step(Q) == &"escapar", "Aegis acompaña a Kai, Aegis Pulse queda disponible y suena la alarma")
	_check(room.find_children("*", "AegisCompanion", true, false).size() == 1, "Aegis aparece junto a Kai")
	_check(not (room.get_node("Mundo/CompuertaOeste") as LazaroGate).is_open() and (room.get_node("Mundo/CompuertaEste") as LazaroGate).is_open(),
		"la estación se sella: solo queda la salida de emergencia")
	room.player.teleport_to(Vector2(954, 304))
	await _arrive(L + "lazaro_escape.tscn")


func _test_escape() -> void:
	var line := await _read_box()
	_check(line.contains("Compuerta") or line.contains("compuerta"), "una compuerta de emergencia corta el pasillo")
	var companions := room.find_children("*", "AegisCompanion", true, false)
	_check(companions.size() == 1, "Aegis sigue a Kai a la sala siguiente")
	var companion := companions[0] as AegisCompanion
	var gate := room.get_node("Mundo/Compuerta") as LazaroGate
	_check(not gate.is_open(), "el interruptor está fuera del alcance de Kai")
	room.player.teleport_to(Vector2(340, 304))
	await _frames(40)
	var target := companion.pulse()
	_check(target == room.get_node("Mundo/Interruptor"), "Aegis Pulse apunta solo al blanco válido más cercano")
	await _until(func() -> bool: return gate.is_open())
	_check(gate.is_open(), "el disparo activa el interruptor y la compuerta se abre")
	room.player.teleport_to(Vector2(620, 304))
	var hold := await _read_all_from_start()
	var bridge := room.get_node("Puente") as EscapeBridge
	bridge.quick = true
	var first := room.get_node("Mundo/Tramo1") as DataPlatform
	_check(hold.contains("Yo mantengo el puente") and first.stabilized, "Aegis sostiene el puente que se deshace")
	room.player.teleport_to(Vector2(1240, 304))
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	var leave := await _read_all(box)
	await _until(func() -> bool: return state.has_flag(EscapeBridge.HELD_FLAG) and companion.visible)
	_check(leave.contains("¡Aegis, la tuya también importa!") and not first.stabilized, "«¡Aegis, la tuya también importa!»: Aegis suelta el puente y se salva")
	room.player.teleport_to(Vector2(1434, 304))
	await _arrive(F + "bosque_estacion.tscn")


func _test_forest_exit() -> void:
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	var seen := await _read_all(box)
	await _until(func() -> bool: return state.get_current_step(Q) == &"volver_colegio")
	_check(seen.contains("No sabía que existían tantos colores") and seen.contains("veintitrés metros") and seen.contains("El cálculo fue incorrecto"),
		"en el bosque: los colores y la caída de veintitrés metros")
	_check(state.has_flag(ForestExitScene.EXIT_FLAG) and state.has_flag(LazaroPropsFlags.ESCAPED) and not state.has_flag(LazaroPropsFlags.ALARM),
		"la estación se calma y el bosque tiene salida al colegio")
	_check(room.find_children("*", "AegisCompanion", true, false).size() == 1, "Aegis está en el bosque con Kai")


func _test_return() -> void:
	await _open(F + "fibra_claro.tscn")
	var portal := room.get_node("Historia/SalidaAlColegio") as ImmersionPortal
	_check(portal.is_available(), "en el claro, la troncal lleva de vuelta al colegio")
	portal._on_interacted(room.player)
	await _arrive(Z + "cuarto_tecnico.tscn")
	await _until(func() -> bool: return state.get_current_step(Q) == &"hablar_profesor")
	_check(state.get_current_step(Q) == &"hablar_profesor", "Kai vuelve al cuarto técnico")
	room.player.teleport_to(Vector2(350, 304))
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	var talk := await _read_all(box)
	await _until(func() -> bool: return state.is_quest_completed(Q))
	_check(talk.contains("Un amigo.") and talk.contains("¿Lo vio?"), "«¿Qué encontraste?» «Un amigo.» (el profesor mira donde flota Aegis)")
	_check(state.is_quest_completed(Q) and state.has_flag(&"capitulo_3_completado") and state.has_flag(&"nivel_6_completado"), "FIN DEL CAPÍTULO 3")
	await _open(Z + "pasillo.tscn")
	await _until(func() -> bool: return _box().is_playing())
	var hall := await _read_all(_box())
	_check(hall.contains("memes") and hall.contains("parezco loco hablando solo"), "en el pasillo, Aegis observa a los humanos")
	_check(room.find_children("*", "AegisCompanion", true, false).size() == 1, "Aegis acompaña a Kai en el colegio")


func _test_saved() -> void:
	var saves := root.get_node("SaveManager")
	_check(saves.save_game(Z + "pasillo.tscn", &""), "se guarda la partida")
	state.reset()
	_check(state.aegis_stage == 0, "(la partida se reinicia)")
	saves.load_slot(1)
	_check(state.aegis_stage == 1 and state.has_flag(AegisCompanion.FLAG) and state.is_quest_completed(Q) and state.is_quest_completed(ECO),
		"al cargar, Aegis sigue siendo el compañero de Kai y el capítulo sigue completo")
	await _open(Z + "pasillo_segundo.tscn")
	await _frames(20)
	_check(room.find_children("*", "AegisCompanion", true, false).size() == 1 and not _box().is_playing(),
		"y aparece junto a Kai (la escena del pasillo no se repite)")


func _bugs() -> Array[Bitcucaracha]:
	var result: Array[Bitcucaracha] = []
	for node in room.find_children("*", "Bitcucaracha", true, false):
		if not node.is_queued_for_deletion():
			result.append(node as Bitcucaracha)
	return result


func _find_window() -> PowerGridWindow:
	for node in root.find_children("*", "PowerGridWindow", true, false):
		return node as PowerGridWindow
	return null


func _option(window: ChoiceWindow, correct: bool) -> int:
	var options := window.challenge.questions[window.question_index].options
	for i in options.size():
		if options[i].correct == correct:
			return i
	return 0


## Lee todas las líneas del diálogo que está sonando (hasta que termina).
func _read_all(box: DialogueBox) -> String:
	var seen := ""
	for i in 120:
		if not box.is_playing():
			break
		await _frames(2)
		seen += box._text.text + "\n"
		await _action(&"interact")
		await _frames(2)
	return seen


func _read_all_from_start() -> String:
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	return await _read_all(box)


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
	# La transición (el fundido) tiene que terminar antes de poder usar otra salida.
	await _until(func() -> bool: return not root.get_node("SceneManager")._is_changing)
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
