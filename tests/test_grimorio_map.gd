extends SceneTree
## Prueba automática: M5. El mapa del Grimorio se dibuja con el mapa real (World): estados de las salas
## (desconocida, descubierta, se abre más adelante, visitada, completada), las salas del generador,
## dónde está Kai, partidas anteriores al mapa (marcas visitada_<escena>) y el libro abierto en el mapa.
## Ejecutar: godot --headless --path . --script res://tests/test_grimorio_map.gd

const S := GrimorioMap.State
const ENTRADA := "res://world/zones/zone0/entrada.tscn"
const PASILLO := "res://world/zones/zone0/pasillo.tscn"
const GRIMORIO := "res://ui/menus/grimorio/grimorio.tscn"

var _failures := 0
var world: Node
var state: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	world = root.get_node("World")
	state = root.get_node("GameState")
	state.reset()
	world.new_world(77)
	var map := GrimorioMap.new()
	map.size = Vector2(560, 420)
	root.add_child(map)
	map.zone = &"colegio"

	var states := map.room_states()
	_check(states.size() == world.graph(&"colegio").rooms.size() and _count(states, S.UNKNOWN) == states.size(),
		"sin explorar, todas las salas del Colegio (también las del generador) son desconocidas")
	world.enter(ENTRADA, &"entrada")
	states = map.room_states()
	_check(states[&"entrada"] == S.VISITED and states[&"pasillo"] == S.DISCOVERED and states[&"laboratorio"] == S.UNKNOWN,
		"al entrar: la Entrada visitada, el Pasillo descubierto y el Laboratorio desconocido")
	world.enter(PASILLO, &"pasillo")
	states = map.room_states()
	_check(states[&"escaleras"] == S.LOCKED and states[&"laboratorio"] == S.DISCOVERED,
		"desde el Pasillo se ven las escaleras, cerradas hasta el Capítulo 1")
	_check(map.progress() == Vector2i(2, states.size()), "avance: 2 salas visitadas de %d" % states.size())
	state.set_flag(&"tutorial_terminado")
	_check(map.room_states()[&"escaleras"] == S.DISCOVERED, "en el Capítulo 1 las escaleras ya no salen cerradas")

	# Salas del generador: aparecen al visitar la biblioteca.
	var school: RoomGraph = world.graph(&"colegio")
	var optional: StringName = school.target_of(&"biblioteca", &"este")["room"]
	_check(map.room_states()[optional] == S.UNKNOWN, "la sala del generador (%s) no se ve antes de llegar a la biblioteca" % optional)
	world.visited[&"escaleras"] = true
	world.visited[&"biblioteca"] = true
	_check(map.room_states()[optional] == S.DISCOVERED, "al visitar la biblioteca se descubre la sala de al lado")

	# Completada: visitada y con todas sus misiones terminadas.
	_check(map.room_states()[&"pasillo"] == S.VISITED, "el Pasillo no está completado mientras falte el prólogo")
	state.start_quest(&"prologo")
	for step in [&"hablar_profesor", &"revisar_computadora", &"volver_profesor"]:
		state.complete_step(&"prologo", step)
	_check(state.is_quest_completed(&"prologo") and map.room_states()[&"pasillo"] == S.COMPLETED, "al terminar el prólogo, el Pasillo queda completado")

	# Partidas anteriores al mapa: cuentan las marcas visitada_<escena>.
	world.new_world(77)
	state.set_flag(&"visitada_laboratorio")
	_check(map.room_states()[&"laboratorio"] == S.VISITED, "una partida vieja (marca visitada_laboratorio) ve el Laboratorio visitado")

	# Dibujo: no falla con la zona del Colegio ni con la de la computadora.
	map.queue_redraw()
	await process_frame
	map.zone = &"pc_profesor"
	world.enter("res://world/zones/pc_profesor/escritorio.tscn", &"pc_escritorio")
	_check(map.room_states()[&"pc_escritorio"] == S.VISITED and map.progress() == Vector2i(1, 1), "la computadora del profesor: 1 sala visitada")
	await process_frame

	# El libro abierto en el mapa.
	var grimorio := (load(GRIMORIO) as PackedScene).instantiate()
	root.add_child(grimorio)
	await process_frame
	await process_frame
	var book_map := grimorio.get_node("%Map") as GrimorioMap
	grimorio.show_page(GrimorioScreen.Page.MAPA)
	await process_frame
	_check(book_map.visible and grimorio.get_node("%EntryProgress").text.ends_with("%"), "el Grimorio muestra el mapa con su avance")
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _count(states: Dictionary, value: int) -> int:
	var total := 0
	for room_id in states:
		if states[room_id] == value:
			total += 1
	return total


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
