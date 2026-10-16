extends SceneTree
## Prueba automática: la cinemática inicial (docs/narrativa/capitulos/CINEMATICA_INICIAL.md). NUEVA PARTIDA la
## reproduce: Kai se despierta tarde, se prepara, desayuna con sus papás, cruza el barrio y llega al colegio; el
## título del juego (el nombre del proyecto) y la Entrada del colegio con el control y el objetivo «Habla con el
## profesor Alvarado». Durante la cinemática no hay control ni HUD de juego. Omitir (Esc dos veces) va directo a la
## Entrada sin duplicar nada; cargar una partida no la repite.
## Ejecutar: godot --headless --path . --script res://tests/test_cinematica_inicial.gd

const MENU := "res://ui/menus/main_menu/main_menu.tscn"
const ENTRADA := "res://world/zones/zone0/entrada.tscn"
const OBJECTIVE := "Habla con el profesor Alvarado."

var _failures := 0
var state: Node
var saves: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	saves = root.get_node("SaveManager")
	await _test_full()
	await _test_load_does_not_replay()
	await _test_skip()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _new_game(slot: int) -> IntroCinematic:
	change_scene_to_file(MENU)
	await _frames(20)
	current_scene.start_new_game(slot)
	await _until(func() -> bool: return current_scene is IntroCinematic and current_scene.is_node_ready())
	return current_scene as IntroCinematic


func _test_full() -> void:
	var intro := await _new_game(1)
	_check(intro != null, "NUEVA PARTIDA empieza con la cinemática inicial")
	if intro == null:
		return
	intro.quick = true
	_check(state.get_current_step(&"prologo") == &"hablar_profesor" and not state.has_flag(IntroCinematic.DONE_FLAG),
		"el prólogo ya empezó (la cinemática va antes de hablar con el profesor)")
	_check(intro.kai.controls_locked and intro.find_children("*", "CombatHUD", true, false).is_empty(),
		"durante la cinemática no hay control del jugador ni HUD de juego")
	_check(intro.find_children("*", "NullbladeStand", true, false).is_empty() and not intro.has_node("Cuarto/SoporteNullblade"),
		"el cuarto no muestra la Nullblade")
	# Cada línea se anota cuando aparece (line_started), aunque se avance rápido.
	var lines: Array[String] = []
	intro._box.line_started.connect(func(_index: int) -> void: lines.append(intro._box._text.text))
	var title_text := ""
	var title_shown := false
	var players := 0
	# Avanza los diálogos como un jugador (E) hasta que termina.
	for i in 6000:
		if not is_instance_valid(intro) or intro.done:
			break
		var box := intro._box
		if box.is_playing():
			await _action(&"interact")
		var title := intro.get_node("UI/Title") as Control
		if title.modulate.a > 0.5:
			title_shown = true
			title_text = (title.get_node("Nombre") as Label).text
		await _frames(1)
	for line in ["Cinco minutitos más", "¡¿LAS SEIS Y TREINTA Y CINCO?!", "...Estoy bien.", "Bueno, ganaste.", "¡Mae, pero qué les pasa hoy!",
			"...Nadie se va a dar cuenta.", "Hasta que descubrí que el tiempo existe.", "Es moda.", "Una moda bastante económica, por cierto.",
			"cuanto más grande sea tu capacidad de cambiar las cosas", "¡Y llevate el almuerzo!", "¡Pura vida, don Carlos!", "¡Es tradición!",
			"...O no.", "¡Uy, no!", "Mae, venís todo despeinado.", "Es parte del estilo.", "Bueno... otro día normal."]:
		_check("\n".join(lines).contains(line), "se ve «%s»" % line)
	_check(title_shown and title_text == String(ProjectSettings.get_setting("application/config/name")),
		"aparece el título del juego con el nombre del proyecto («%s»)" % title_text)
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == ENTRADA and current_scene.is_node_ready())
	await _frames(30)
	var room := current_scene as Room
	_check(room != null and room.scene_file_path == ENTRADA, "termina en la Entrada del colegio")
	if room == null:
		return
	players = room.find_children("*", "Player", true, false).size()
	_check(players == 1 and not room.player.controls_locked, "con un solo Kai y el control del jugador")
	_check(state.has_flag(IntroCinematic.DONE_FLAG) and state.get_current_step(&"prologo") == &"hablar_profesor", "la cinemática queda vista; el prólogo sigue igual")
	var objective: Label = room.get_node("CombatHUD/Objective")._text
	_check(objective.text == OBJECTIVE, "el objetivo: «%s»" % objective.text)


func _test_load_does_not_replay() -> void:
	_check(saves.save_game(ENTRADA, &""), "se guarda la partida en la Entrada")
	state.reset()
	_check(saves.continue_game(1), "se carga la partida")
	await _until(func() -> bool: return current_scene is Room and current_scene.is_node_ready())
	await _frames(10)
	_check(current_scene is Room and current_scene.scene_file_path == ENTRADA and state.has_flag(IntroCinematic.DONE_FLAG),
		"cargar no repite la cinemática: sigue en la Entrada")


func _test_skip() -> void:
	var intro := await _new_game(2)
	await _frames(30)
	_check(not state.has_flag(IntroCinematic.DONE_FLAG), "una partida nueva vuelve a tener la cinemática")
	await _action(&"pause")
	await _frames(3)
	_check(not intro.done and intro.get_node("UI/SkipHint").text.contains("otra vez"), "Esc una vez pide confirmar (no omite por accidente)")
	await _action(&"pause")
	_check(intro.done and intro.skipping, "Esc otra vez omite la cinemática")
	intro.skip()
	_check(intro.done, "omitir dos veces no hace nada más")
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == ENTRADA and current_scene.is_node_ready())
	await _frames(30)
	var room := current_scene as Room
	_check(room != null and room.find_children("*", "Player", true, false).size() == 1 and not room.player.controls_locked,
		"al omitir: Kai en la Entrada, uno solo y con el control")
	if room:
		var objective: Label = room.get_node("CombatHUD/Objective")._text
		_check(objective.text == OBJECTIVE and state.has_flag(IntroCinematic.DONE_FLAG) and state.get_current_step(&"prologo") == &"hablar_profesor",
			"y el objetivo de hablar con el profesor (sin saltar nada del prólogo)")
	await _frames(60)
	_check(current_scene == room, "no se cambia de sala dos veces")
	# Omitir apenas empieza (todavía con el fundido del menú): igual llega a la Entrada.
	var early := await _new_game(3)
	early.skip()
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == ENTRADA and current_scene.is_node_ready())
	_check(current_scene is Room and current_scene.scene_file_path == ENTRADA, "omitir en el primer instante también lleva a la Entrada")


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
