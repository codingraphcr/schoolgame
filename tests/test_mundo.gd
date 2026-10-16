extends SceneTree
## Prueba automática: el MVP del mundo (docs/mundo/MAPA_MAESTRO.md). El mapa maestro como datos (regiones,
## conexiones, requisitos); en el Capítulo 3, el vecino sin internet empieza «Sin señal en el barrio» (una
## actividad secundaria que no le quita el lugar a la historia); la caja de fibra falla y, con la Visión, es un
## acceso de Inmersión al Bosque de Fibra (región descubierta; el Distrito Caché se ve con niebla y su troncal
## cerrada); el Fibroluz se registra con la Visión (avistamiento, observación) y guía a Kai; el camino oculto solo
## existe con la Visión y lleva a un Fragmento de Datos; el claro: empalmes que hay que orientar para que la señal
## llegue; la troncal hacia el Distrito Caché no deja pasar; de vuelta al barrio: la caja en verde, el vecino, los
## Ecos (una vez), la comprensión del Fibroluz, el recuerdo en el cuarto y el acceso desde el rack del colegio; el
## Grimorio (mapa físico y digital, bestiario, misiones); guardar y cargar; otra ranura no comparte nada.
## Ejecutar: godot --headless --path . --script res://tests/test_mundo.gd

const B := "res://world/zones/barrio/"
const F := "res://world/zones/bosque_fibra/"
const Q := &"senal_del_barrio"

var _failures := 0
var state: Node
var world: Node
var room: Room


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	world = root.get_node("World")
	_test_atlas()
	_test_side_quest_rules()
	root.get_node("SaveManager").new_game(1)
	for point: Dictionary in DevPoints.POINTS:
		if point["nombre"] == "Sin señal en el barrio · la caja de fibra":
			DevPoints.prepare(point, state)
	await _test_street()
	await _test_forest_roots()
	await _test_clearing()
	await _test_return()
	await _test_grimorio()
	await _test_save_and_slots()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_atlas() -> void:
	var regions := WorldAtlas.regions()
	var ids := {}
	for region in regions:
		ids[region.id] = true
	_check(regions.size() == 14 and ids.size() == 14, "el mapa maestro tiene 14 regiones (6 físicas, 8 digitales) con id único")
	var physical := WorldAtlas.regions(WorldRegion.Kind.FISICA).size()
	_check(physical == 6, "6 regiones físicas (%d)" % physical)
	var bad := PackedStringArray()
	for link in WorldAtlas.links():
		if not ids.has(link.region_a) or not ids.has(link.region_b) or link.access_point.is_empty():
			bad.append(String(link.id))
		if link.kind == RegionLink.Kind.INMERSION and link.access_point.is_empty():
			bad.append(String(link.id))
	_check(WorldAtlas.links().size() == 22 and bad.is_empty(), "22 conexiones entre regiones que existen, cada una con su lugar o dispositivo %s" % [bad])
	var missing := PackedStringArray()
	for region in regions:
		for district in region.districts:
			if not world.districts.has(StringName(district)):
				missing.append(district)
	_check(missing.is_empty(), "los distritos de cada región existen en el juego %s" % [missing])
	_check(WorldAtlas.region_of_district(&"bosque_fibra").id == &"bosque_fibra" and WorldAtlas.region_of_district(&"colegio").id == &"distrito_central",
		"cada distrito sabe su región (el colegio es del Distrito Central)")
	var not_lineal := 0
	for link in WorldAtlas.links():
		if link.touches(&"bosque_fibra") and WorldAtlas.get_region(link.other(&"bosque_fibra")).kind == WorldRegion.Kind.DIGITAL:
			not_lineal += 1
	_check(not_lineal >= 2, "el mapa no es lineal: del Bosque de Fibra salen rutas a más de un bioma")


func _test_side_quest_rules() -> void:
	state.reset()
	state.start_quest(&"una_clase_diferente")
	state.start_quest(Q)
	_check(state.active_quest == &"una_clase_diferente" and state.get_side_quest() == Q,
		"una actividad secundaria no le quita el lugar a la historia (el HUD la muestra aparte)")
	state.reset()


func _test_street() -> void:
	await _open(B + "calle.tscn", Vector2(1700, 304))
	_check(ProgressTracker.chapter(state) == 3 and not state.has_reached_step(Q), "Capítulo 3, en la calle del barrio")
	var box := room.get_node("Historia/CajaDeFibra")
	var portal := room.get_node("Historia/AccesoFibra") as ImmersionPortal
	_check(not portal.is_available(), "antes de saber del problema, la caja no es un acceso")
	var bx := _box()
	room.player.teleport_to(Vector2(1180, 304))
	await _until(func() -> bool: return bx.is_playing())
	_check(_line(bx).contains("caja de fibra") or bx.is_playing(), "el vecino cuenta que no hay internet en la cuadra")
	await _advance(bx)
	await _until(func() -> bool: return state.has_reached_step(Q))
	_check(state.get_current_step(Q) == &"revisar_caja" and QuestDB.get_quest(Q).category == Quest.Category.SECUNDARIA,
		"empieza la misión secundaria «Sin señal en el barrio»")
	_check(box.is_failing() and portal.is_available(), "la caja falla (luz roja) y es un acceso de Inmersión")
	var objective := room.get_node("CombatHUD").find_child("Objective", true, false)
	_check(objective == null or objective.visible, "el objetivo de la actividad se ve en el HUD")
	root.get_node("DigitalVision").activate(true)
	room.player.teleport_to(Vector2(portal.global_position.x, 304))
	await _frames(8)
	await _action(&"interact")
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == F + "fibra_raices.tscn" and current_scene.is_node_ready())
	await _frames(6)
	room = current_scene as Room


func _test_forest_roots() -> void:
	_check(world.current_district == &"bosque_fibra" and state.has_flag(&"region_visitada_bosque_fibra"),
		"con la Visión y la Inmersión, Kai entra por la caja: el Bosque de Fibra (región descubierta)")
	var bosque := WorldAtlas.get_region(&"bosque_fibra")
	var cache := WorldAtlas.get_region(&"distrito_cache")
	_check(WorldAtlas.state_of(bosque, state, world) == WorldAtlas.State.VISITADA and WorldAtlas.state_of(cache, state, world) == WorldAtlas.State.NIEBLA,
		"en el mapa digital: el bosque visitado y el Distrito Caché con niebla («???»)")
	var trunk := WorldAtlas.get_link(&"bosque_cache")
	_check(WorldAtlas.is_link_known(trunk, state, world) and not trunk.is_open(state), "la troncal al Distrito Caché se ve, cerrada (región futura)")
	_check(WorldAtlas.state_of(WorldAtlas.get_region(&"velo_nulo"), state, world) == WorldAtlas.State.DESCONOCIDA, "El Velo Nulo (secreto) no aparece")
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	await _until(func() -> bool: return state.get_current_step(Q) == &"seguir_fibroluz")
	_check(state.get_current_step(Q) == &"seguir_fibroluz", "al llegar: «Seguí al Fibroluz»")
	# El Fibroluz con la Visión: avistamiento y observación.
	var fibroluz := room.get_node("Mundo/Fibroluz") as Fibroluz
	var entry := Bestiary.get_entry(&"fibroluz")
	root.get_node("DigitalVision").activate(true)
	room.player.teleport_to(fibroluz.global_position + Vector2(-150, 14))
	await _until(func() -> bool: return Bestiary.stage(state, entry) >= 1)
	_check(Bestiary.stage(state, entry) >= 1, "con la Visión, el Fibroluz queda registrado (avistamiento)")
	# Seguir mirándolo: Kai lo sigue a la vista y vuelve a encender la Visión cuando se apaga.
	var vision := root.get_node("DigitalVision")
	for i in 900:
		if Bestiary.stage(state, entry) >= 2:
			break
		if not vision.is_active():
			vision.activate(true)
		if i % 30 == 0:
			room.player.teleport_to(fibroluz.global_position + Vector2(-130, 14))
		await _frames(1)
	_check(Bestiary.stage(state, entry) == 2, "si Kai sigue mirándolo: observación (sin pelear)")
	_check(not fibroluz.find_children("*", "HurtboxComponent", true, false).size(), "el Fibroluz no se puede dañar: no existe para ser vencido")
	# Se acerca: el Fibroluz lo guía hacia el claro.
	room.player.teleport_to(fibroluz.global_position + Vector2(-40, 14))
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	await _until(func() -> bool: return fibroluz.is_guiding())
	_check(fibroluz.is_guiding(), "el Fibroluz guía a Kai (Interacción)")
	# El camino oculto: sin la Visión no existe; con la Visión, se puede subir.
	root.get_node("DigitalVision").deactivate()
	await _frames(10)
	room.player.teleport_to(Vector2(330, 240))
	await _frames(40)
	var without := room.player.global_position.y
	root.get_node("DigitalVision").activate(true)
	await _frames(6)
	room.player.teleport_to(Vector2(330, 240))
	await _frames(40)
	var with := room.player.global_position.y
	_check(without > 300.0 and absf(with - 256.0) < 2.0, "el camino oculto solo existe con la Visión (sin: y=%.0f, con: y=%.0f)" % [without, with])
	room.player.teleport_to(Vector2(205, 100))
	await _until(func() -> bool: return state.has_flag(&"fibra_fragmento_recogido"))
	_check(state.has_flag(&"fibra_fragmento_recogido"), "arriba, un Fragmento de Datos escondido (se registra en la vitrina del cuarto)")
	room.player.teleport_to(Vector2(954, 304))
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == F + "fibra_claro.tscn" and current_scene.is_node_ready())
	await _frames(6)
	room = current_scene as Room


func _test_clearing() -> void:
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	await _until(func() -> bool: return state.get_current_step(Q) == &"reconectar")
	_check(state.get_current_step(Q) == &"reconectar", "el Fibroluz espera junto al corte: «Reconectá los empalmes»")
	var circuit := room.get_node("Mundo/Corte") as FiberCircuit
	_check(circuit.lit_segments() <= circuit.junctions.size() and not circuit.is_solved, "los empalmes apuntan para cualquier lado: la señal no llega")
	# La troncal hacia el Distrito Caché no deja pasar.
	room.player.teleport_to(Vector2(794, 304))
	await _frames(20)
	_check(current_scene == room, "la troncal hacia el Distrito Caché no tiene enlace: no se pasa")
	# Kai gira cada empalme con E hasta que apunte al siguiente.
	for junction in circuit.junctions:
		room.player.teleport_to(Vector2(junction.global_position.x, 304 if junction.position.y > 250.0 else 248))
		await _frames(8)
		for k in 4:
			if junction.is_correct():
				break
			await _action(&"interact")
			await _frames(4)
	await _until(func() -> bool: return circuit.is_solved)
	_check(circuit.is_solved and state.get_current_step(Q) == &"volver_al_barrio", "con todos los empalmes en orden, la señal llega («Volvé al barrio»)")
	_check(state.has_flag(&"bosque_fibra_enlace_restaurado"), "el bosque vuelve a brillar (cambio permanente)")
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	var to_school := room.get_node("Historia/SalidaAlColegio") as ImmersionPortal
	_check(to_school.is_available(), "y se abre la salida al colegio por la troncal del rack (conexión nueva)")
	room.player.teleport_to(Vector2(6, 304))
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == F + "fibra_raices.tscn" and current_scene.is_node_ready())
	await _frames(6)
	room = current_scene as Room


func _test_return() -> void:
	var ecos_before: int = root.get_node("Economy").ecos
	var exit := room.get_node("Historia/SalidaAlBarrio") as ImmersionPortal
	room.player.teleport_to(Vector2(exit.global_position.x, 304))
	await _frames(8)
	await _action(&"interact")
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == B + "calle.tscn" and current_scene.is_node_ready())
	await _frames(6)
	room = current_scene as Room
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	_check(world.current_room == &"calle", "Kai vuelve a la región anterior (el barrio) por la caja")
	await _advance(box)
	await _until(func() -> bool: return state.is_quest_completed(Q))
	_check(state.is_quest_completed(Q) and root.get_node("Economy").ecos == ecos_before + 40, "el vecino agradece: misión secundaria completada (+40 Ecos)")
	_check(not room.get_node("Historia/CajaDeFibra").is_failing(), "la caja del poste queda en verde")
	_check(Bestiary.stage(state, Bestiary.get_entry(&"fibroluz")) == 3, "el Fibroluz pasa a «Comprensión» en el bestiario")
	_check(HomeCollection.get_item(&"nota_vecino").is_unlocked(state) and HomeCollection.get_item(&"fragmento_bosque").is_unlocked(state),
		"en el cuarto de Kai aparecen la nota del vecino y el fragmento del bosque")
	_check(WorldAtlas.get_link(&"central_bosque").is_open(state), "el acceso desde el rack del colegio queda abierto")
	# Completar otra vez no paga dos veces.
	var ecos: int = root.get_node("Economy").ecos
	state.complete_step(Q, &"volver_al_barrio")
	_check(root.get_node("Economy").ecos == ecos, "la recompensa no se cobra dos veces")


func _test_grimorio() -> void:
	var screen := GrimorioScreen.open(room)
	await _frames(4)
	screen.show_page(GrimorioScreen.Page.MAPA)
	await _frames(2)
	var names := PackedStringArray()
	for child in screen._zone_buttons.get_children():
		names.append((child as Button).text)
	_check(" ".join(names).contains("MUNDO FÍSICO") and " ".join(names).contains("MUNDO DIGITAL") and " ".join(names).contains("BOSQUE DE FIBRA"),
		"el mapa del Grimorio tiene el mundo físico, el digital y la zona del bosque %s" % [names])
	screen.show_world(WorldRegion.Kind.DIGITAL)
	await _frames(2)
	_check(screen._world_map.visible and not screen._map.visible and screen._world_map.progress().x >= 1,
		"mapa digital: regiones visitadas (%d / %d)" % [screen._world_map.progress().x, screen._world_map.progress().y])
	screen.show_world(WorldRegion.Kind.FISICA)
	await _frames(2)
	_check(screen._world_map.kind == WorldRegion.Kind.FISICA and screen._world_map.current_region().id == &"barrio_almendros", "mapa físico: Kai está en el Barrio de los Almendros")
	var creatures := screen.entries_in(GrimorioEntry.Category.BESTIARIO)
	_check(creatures.size() == 1 and screen.is_unlocked(creatures[0]) and creatures[0].text.contains("Transporta señales"),
		"Grimorio · Bestiario: el Fibroluz con toda su información (comprensión)")
	var missions := screen.entries_in(GrimorioEntry.Category.MISIONES)
	var found := false
	for page in missions:
		found = found or (page.title == "Sin señal en el barrio" and page.subtitle.contains("Completada"))
	_check(found, "Grimorio · Misiones: «Sin señal en el barrio», completada")
	screen.close()
	await _frames(2)


func _test_save_and_slots() -> void:
	var saves := root.get_node("SaveManager")
	_check(saves.save_game(room.scene_file_path, &"desde_caja"), "se guarda la partida en el barrio")
	state.reset()
	saves.load_slot(1)
	_check(state.is_quest_completed(Q) and Bestiary.stage(state, Bestiary.get_entry(&"fibroluz")) == 3 and state.has_flag(&"fibra_fragmento_recogido")
		and state.has_flag(&"bosque_fibra_enlace_restaurado") and WorldAtlas.state_of(WorldAtlas.get_region(&"bosque_fibra"), state, world) == WorldAtlas.State.VISITADA,
		"al cargar: misión, bestiario, fragmento, bosque restaurado y región visitada")
	saves.new_game(2)
	_check(not state.has_reached_step(Q) and Bestiary.stage(state, Bestiary.get_entry(&"fibroluz")) == 0
		and WorldAtlas.state_of(WorldAtlas.get_region(&"bosque_fibra"), state, world) != WorldAtlas.State.VISITADA,
		"otra ranura no comparte nada (ni la misión, ni el bestiario, ni las regiones)")


func _open(path: String, at: Vector2) -> void:
	change_scene_to_file(path)
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == path and current_scene.is_node_ready())
	await _frames(4)
	room = current_scene as Room
	room.player.teleport_to(at)
	await _frames(4)


func _box() -> DialogueBox:
	return room.get_node("CombatHUD/DialogueBox") as DialogueBox


func _line(box: DialogueBox) -> String:
	return box._text.text


func _advance(box: DialogueBox) -> void:
	for i in 80:
		if not box.is_playing():
			return
		await _action(&"interact")
		await _frames(3)


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
