extends SceneTree
## Prueba automática: la misión secundaria «El proyecto perdido» (expansión del Capítulo 1; docs/mundo/COLEGIO.md).
## La estudiante del laboratorio aparece cuando el profesor prepara el acceso; al entrar empieza la misión (sin
## quitarle el lugar a la historia); hablar con ella lleva a la computadora; la terminal es simulada (solo help,
## pwd, ls, cd y cat; nada de comandos reales ni de borrar); el archivo no se borró sino que está en otra carpeta,
## y el registro de cambios dice dónde; leerlo resuelve el paso (con Ecos una vez); volver con ella termina la
## misión; después solo agradece; guardar y cargar conserva todo y otra ranura no.
## Ejecutar: godot --headless --path . --script res://tests/test_proyecto_perdido.gd

const Z := "res://world/zones/zone0/"
const Q1 := &"una_clase_diferente"
const Q := &"proyecto_perdido"

var _failures := 0
var state: Node
var room: Room


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	root.get_node("SaveManager").new_game(1)
	DevPoints._advance(state, Q1, &"pedir_permiso")
	state.unlock_vision()
	state.set_nullblade_stage(1)
	await _open(Z + "taller.tscn")
	_check(not _group().visible and not state.has_reached_step(Q), "antes de pedir permiso, la estudiante no está (ni empieza la misión)")
	DevPoints._advance(state, Q1, &"buscar_huellas")
	await _open(Z + "taller.tscn")
	await _test_start()
	await _test_terminal_rules()
	await _test_solve()
	await _test_thanks()
	await _test_saved()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_start() -> void:
	room.player.teleport_to(Vector2(_student().global_position.x - 40, 304))
	await _until(func() -> bool: return state.has_reached_step(Q))
	_check(_group().visible and state.get_current_step(Q) == &"hablar_estudiante" and state.active_quest == Q1
		and state.get_side_quest() == Q, "al entrar al taller empieza «El proyecto perdido» (la historia sigue arriba)")
	_check(not _station().is_usable(), "la computadora todavía no se usa (primero hay que hablar con ella)")
	var line := await _talk(_student())
	_check(line.contains("¿Dónde está?") and state.get_current_step(Q) == &"buscar_archivo", "la estudiante perdió su proyecto de la feria")
	line = await _talk(_student())
	_check(line.contains("¿Lo encontraste?") and state.get_current_step(Q) == &"buscar_archivo", "si Kai vuelve sin el archivo, ella pregunta")


func _test_terminal_rules() -> void:
	var challenge := _station().challenge
	var interpreter := challenge.create_interpreter()
	_check(Array(challenge.allowed_commands) == ["help", "pwd", "ls", "cd", "cat"], "la terminal solo tiene help, pwd, ls, cd y cat")
	for blocked in ["rm proyectos/notas.txt", "mv respaldo/viejos/seguidor.py proyectos/", "sudo ls", "del seguidor.py"]:
		var result := interpreter.execute(blocked)
		_check(not result["ok"] and interpreter.fs.exists("~/proyectos/notas.txt"), "«%s» no se permite: «%s»" % [blocked, result["output"]])
	_check(_out(interpreter, "pwd") == "/home/estudiante", "pwd dice dónde está")
	_check(not _out(interpreter, "ls proyectos").contains("seguidor.py"), "el archivo ya no está en proyectos/")
	_check(_out(interpreter, "cat temporal/registro_de_cambios.txt").contains("respaldo/viejos/seguidor.py"), "el registro de cambios dice a dónde se movió")
	interpreter.execute("cd respaldo/viejos")
	_check(_out(interpreter, "ls").contains("seguidor.py") and _out(interpreter, "cat seguidor.py").contains("si sensor_ve_linea()"),
		"está en respaldo/viejos y se puede leer (un «si / si no»: lo del Capítulo 2)")


func _out(interpreter: CommandInterpreter, line: String) -> String:
	return String(interpreter.execute(line)["output"]).strip_edges()


func _test_solve() -> void:
	var station := _station()
	var before: int = root.get_node("Economy").ecos
	room.player.teleport_to(Vector2(station.global_position.x, 304))
	await _frames(4)
	_check(station.is_usable() and station.enabled, "ahora la computadora «Equipo 4» se puede usar")
	station._on_interacted(room.player)
	await _until(func() -> bool: return get_first_node_in_group(&"terminal_window") != null)
	var window := get_first_node_in_group(&"terminal_window") as TerminalWindow
	_check(window != null, "con E se abre la terminal")
	if window == null:
		return
	for command in ["cat proyectos/notas.txt", "cat temporal/registro_de_cambios.txt", "cd respaldo/viejos", "cat seguidor.py"]:
		window.submit(command)
		await _frames(2)
	await _frames(4)
	window.close()
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	_check(box._text.text.contains("No se borró"), "Kai lo encuentra: «%s»" % box._text.text)
	await _advance(box)
	await _until(func() -> bool: return state.get_current_step(Q) == &"volver_estudiante")
	_check(state.get_current_step(Q) == &"volver_estudiante" and root.get_node("Economy").ecos > before,
		"leer el archivo resuelve el paso y da Ecos (+%d)" % (root.get_node("Economy").ecos - before))


func _test_thanks() -> void:
	var line := await _talk(_student())
	await _until(func() -> bool: return state.is_quest_completed(Q))
	_check(line.contains("no se borró") and state.is_quest_completed(Q), "Kai le cuenta dónde estaba: misión completada")
	_check(state.get_current_step(Q1) == &"buscar_huellas" and state.active_quest == Q1, "no cambia el objetivo de la historia")
	line = await _talk(_student())
	_check(line.contains("tres copias"), "después, la estudiante solo agradece")
	_check(not _station().is_usable(), "la computadora ya no hace falta")


func _test_saved() -> void:
	var saves := root.get_node("SaveManager")
	_check(saves.save_game(Z + "taller.tscn", &"desde_laboratorio"), "se guarda la partida")
	state.reset()
	saves.load_slot(1)
	_check(state.is_quest_completed(Q), "al cargar, la misión sigue completada")
	saves.new_game(2)
	_check(not state.has_reached_step(Q), "otra ranura no la comparte")


func _group() -> Node2D:
	return room.get_node("ProyectoPerdido") as Node2D


func _student() -> Npc:
	return room.get_node("ProyectoPerdido/Estudiante") as Npc


func _station() -> TerminalStation:
	return room.get_node("ProyectoPerdido/Equipo4") as TerminalStation


func _talk(npc: Npc) -> String:
	room.player.teleport_to(Vector2(npc.global_position.x - 24, 304))
	await _frames(3)
	npc._on_interacted(room.player)
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	var text := box._text.text
	await _advance(box)
	await _frames(4)
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
