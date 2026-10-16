extends SceneTree
## Prueba automática: el Bosque de Fibra del Nivel 5 después de la caída (fase 5; docs/narrativa/capitulos/CAPITULO_03.md).
## Del claro se trepa al puente inestable: sin ayuda se deshace, y una señal azul desconocida lo estabiliza (aviso del
## Grimorio, Kai pregunta y nadie responde); al cruzar, Kai encontró otra salida. En el nodo de distribución, cinco
## válvulas: con la Visión se ven los flujos dañados; cerrar una sana no sirve; cerrar las dañadas contiene el contagio
## (el colegio deja de fallar) y la señal salva a Kai («POR FAVOR, EVITA VOLVER A CAER»), cada vez más débil. La
## compuerta de la Estación Lázaro rechaza el acceso hasta que la señal la abre: fin del Nivel 5, empieza el 6.
## Guardar y cargar conserva todo.
## Ejecutar: godot --headless --path . --script res://tests/test_senal_protectora.gd

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
	DevPoints._advance(state, Q, &"encontrar_salida")
	state.set_flag(&"bosque_descubierto")
	state.unlock_vision()
	state.unlock_immersion()
	state.set_nullblade_stage(1)
	state.set_dash_level(1)
	await _test_climb()
	await _test_bridge()
	await _test_node()
	await _test_station()
	await _test_saved()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_climb() -> void:
	await _open(F + "fibra_claro.tscn")
	var climb := room.get_node("Historia/SubirAlPuente") as Stairway
	_check(climb.resolve().get("scene") == F + "bosque_puente.tscn", "en el claro, la raíz alta sube al puente")
	climb._on_interacted(room.player)
	await _arrive(F + "bosque_puente.tscn")


func _test_bridge() -> void:
	var bridge := room.get_node("SignalBridge") as SignalBridge
	var first := room.get_node("Mundo/Tramo1") as DataPlatform
	_check(not first.stabilized and first.kind == DataPlatform.Kind.TEMPORARY, "el puente es inestable: sus tramos se deshacen al pisarlos")
	room.player.teleport_to(Vector2(230, 304))
	await _until(func() -> bool: return get_first_node_in_group(&"grimorio_alert") != null)
	var alert := get_first_node_in_group(&"grimorio_alert") as GrimorioAlert
	_check(alert.lines[0] == "RUTA ALTERNATIVA DISPONIBLE" and alert.lines[2] == "POR FAVOR, TEN CUIDADO", "una señal azul avisa: «RUTA ALTERNATIVA DISPONIBLE»...")
	var line := await _read_box()
	_check(line.contains("¿Qué fue eso?") and first.stabilized and state.has_flag(SignalBridge.STABLE_FLAG),
		"la señal estabiliza el puente; Kai pregunta y nadie responde")
	room.player.teleport_to(first.global_position + Vector2(40, -4))
	await _frames(40)
	_check(not first.is_closed(), "estabilizado, el tramo no se deshace al pisarlo")
	room.player.teleport_to(Vector2(1100, 304))
	await _until(func() -> bool: return state.get_current_step(Q) == &"contener_contagio")
	_check(state.get_current_step(Q) == &"contener_contagio", "al cruzar, Kai encontró otra salida: ahora, el nodo")
	room.player.teleport_to(Vector2(1274, 304))
	await _arrive(F + "bosque_nodo.tscn")


func _test_node() -> void:
	await _read_box()
	var node := room.get_node("Mundo/Nodo") as ContagionNode
	node.quick = true
	_check(not node.is_contained() and not (room.get_node("Exits/ToEstacion") as RoomExit).is_open(), "el nodo reenvía lo dañado; todavía no se sigue")
	var healthy := room.get_node("Mundo/HaciaBarrio") as FlowValve
	healthy._on_interacted(room.player)
	var line := await _read_box()
	_check(line.contains("estaba sana") and not node.is_contained(), "cerrar una ruta sana no sirve: Kai la vuelve a abrir")
	healthy._on_interacted(room.player)
	await _frames(3)
	var names := ["HaciaColegio", "Reenvio", "HaciaTroncal"]
	for i in names.size():
		var valve := room.get_node("Mundo/" + names[i]) as FlowValve
		_check(valve.damaged, "%s: con la Visión se ve que lleva datos dañados" % names[i])
		valve._on_interacted(room.player)
		await _frames(3)
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	_check(box._text.text.contains("deja de latir") and state.has_flag(ContagionNode.CONTAINED_FLAG), "con las tres dañadas cerradas, el contagio queda contenido")
	await _advance(box)
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	var rescue := box._text.text
	await _advance(box)
	await _until(func() -> bool: return state.get_current_step(Q) == &"llegar_estacion")
	_check(rescue.contains("EVITA VOLVER A CAER") and state.get_current_step(Q) == &"llegar_estacion",
		"la señal salva a Kai de la caída («POR FAVOR, EVITA VOLVER A CAER») y se sigue hacia la estación")
	room.player.teleport_to(Vector2(954, 304))
	await _arrive(F + "bosque_estacion.tscn")


func _test_station() -> void:
	await _read_box()
	var door := room.get_node("Mundo/Compuerta") as StationDoor
	door.quick = true
	_check(not door.is_open() and door.enabled, "la compuerta de la Estación Lázaro, cerrada")
	room.player.teleport_to(Vector2(door.global_position.x, 304))
	await _frames(3)
	door._on_interacted(room.player)
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	var alerts := get_nodes_in_group(&"grimorio_alert")
	await _advance(box)
	await _until(func() -> bool: return state.is_quest_completed(Q))
	_check(state.is_quest_completed(Q) and door.is_open() and state.has_flag(&"nivel_5_completado"),
		"la señal abre la compuerta (ACCESO CONCEDIDO): «NIVEL 5 COMPLETADO»")
	_check(state.get_current_step(&"la_senal_perdida") == &"explorar_estacion" and state.active_quest == &"la_senal_perdida",
		"empieza el Nivel 6, «La señal perdida»")


func _test_saved() -> void:
	var saves := root.get_node("SaveManager")
	_check(saves.save_game(F + "bosque_estacion.tscn", &"desde_nodo"), "se guarda la partida")
	state.reset()
	saves.load_slot(1)
	_check(state.has_flag(SignalBridge.STABLE_FLAG) and state.has_flag(ContagionNode.CONTAINED_FLAG) and state.has_flag(StationDoor.OPEN_FLAG)
		and state.get_current_step(&"la_senal_perdida") == &"explorar_estacion", "al cargar, el puente, el nodo y la compuerta siguen como quedaron")


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
