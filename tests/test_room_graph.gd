extends SceneTree
## Prueba automática: M1. El modelo del mapa (RoomTemplate, DoorSpec, RoomGraph): fichas válidas,
## salas en la cuadrícula sin chocar, puertas que solo conectan enfrentadas y compatibles,
## caminos según las habilidades de Kai, atajos de un solo sentido, pasos secretos con la Visión
## Digital y guardar / cargar el grafo (también pasando por JSON).
## Ejecutar: godot --headless --path . --script res://tests/test_room_graph.gd

const L := DoorSpec.Side.LEFT
const R := DoorSpec.Side.RIGHT
const UP := DoorSpec.Side.UP
const DOWN := DoorSpec.Side.DOWN

var _failures := 0


func _initialize() -> void:
	_test_real_templates()
	var templates := _test_templates()
	var graph := _test_building(templates)
	_test_paths(graph)
	_test_save(graph, templates)
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


## Las fichas de data/world/rooms (las salas que ya existen en el juego).
func _test_real_templates() -> void:
	var real := RoomTemplate.load_folder()
	_check(real.has(&"entrada") and real.has(&"pasillo") and real.has(&"laboratorio") and real.has(&"pc_escritorio"),
		"se cargan las fichas de la Entrada, el Pasillo, el Laboratorio y la PC del profesor")
	var errors: PackedStringArray = []
	for template: RoomTemplate in real.values():
		errors.append_array(template.validate())
	_check(errors.is_empty(), "todas las fichas reales son válidas %s" % [errors])
	# Cada puerta lleva a una entrada (RoomEntry) que existe en su escena.
	var missing: PackedStringArray = []
	for template: RoomTemplate in real.values():
		var scene := (load(template.scene_path) as PackedScene).instantiate()
		var ids: Array[StringName] = []
		for entry in scene.find_children("*", "RoomEntry", true, false):
			ids.append((entry as RoomEntry).id)
		for spec in template.doors:
			if not ids.has(spec.entry_id):
				missing.append("%s.%s → %s" % [template.id, spec.id, spec.entry_id])
		scene.free()
	_check(missing.is_empty(), "cada puerta apunta a una entrada que existe en la escena %s" % [missing])
	var colegio := RoomGraph.new(&"colegio", real)
	colegio.add_room(&"entrada", &"entrada", Vector2i(0, 0))
	colegio.add_room(&"pasillo", &"pasillo", Vector2i(1, 0))
	colegio.add_room(&"laboratorio", &"laboratorio", Vector2i(2, 0))
	_check(colegio.link(&"entrada", &"este", &"pasillo", &"oeste") and colegio.link(&"pasillo", &"este", &"laboratorio", &"oeste")
		and colegio.open_doors().is_empty(), "el prólogo de hoy (Entrada ↔ Pasillo ↔ Laboratorio) arma un grafo sin puertas sueltas")


## Un colegio de prueba, armado en el código:
##   [entrada][pasillo  pasillo][almacen]        piso 0 (fila 0)
##                     [escalera]                 la escalera ocupa las filas 0 y -1
##   [secreta][biblioteca][azotea]                piso 1 (fila -1)
## (las filas negativas están arriba)
func _test_templates() -> Dictionary[StringName, RoomTemplate]:
	var t: Dictionary[StringName, RoomTemplate] = {}
	t[&"entrada"] = _template(&"entrada", Vector2i(1, 1), [_door(&"este", R, Vector2i(0, 0))])
	t[&"pasillo"] = _template(&"pasillo", Vector2i(2, 1), [_door(&"oeste", L, Vector2i(0, 0)),
		_door(&"este", R, Vector2i(1, 0)), _door(&"escalera", UP, Vector2i(1, 0), DoorSpec.Kind.STAIRS)])
	t[&"almacen"] = _template(&"almacen", Vector2i(1, 1), [_door(&"oeste", L, Vector2i(0, 0)),
		_door(&"atajo", UP, Vector2i(0, 0))])
	t[&"escalera"] = _template(&"escalera", Vector2i(1, 1), [_door(&"abajo", DOWN, Vector2i(0, 0), DoorSpec.Kind.STAIRS),
		_door(&"oeste", L, Vector2i(0, 0)), _door(&"este", R, Vector2i(0, 0))])
	t[&"biblioteca"] = _template(&"biblioteca", Vector2i(1, 1), [_door(&"este", R, Vector2i(0, 0)),
		_door(&"secreto", L, Vector2i(0, 0), DoorSpec.Kind.SECRET)])
	t[&"secreta"] = _template(&"secreta", Vector2i(1, 1), [_door(&"este", R, Vector2i(0, 0), DoorSpec.Kind.SECRET)])
	t[&"azotea"] = _template(&"azotea", Vector2i(1, 1), [_door(&"oeste", L, Vector2i(0, 0)),
		_door(&"abajo", DOWN, Vector2i(0, 0))])
	t[&"azotea"].minimum_player_abilities = PackedStringArray(["double_jump"])
	var errors: PackedStringArray = []
	for template: RoomTemplate in t.values():
		errors.append_array(template.validate())
	_check(errors.is_empty(), "las fichas de prueba son válidas %s" % [errors])
	# Fichas mal hechas.
	_check(not _template(&"x", Vector2i(2, 1), [_door(&"a", R, Vector2i(0, 0))]).validate().is_empty(),
		"una puerta que no está en el borde de la sala es un error")
	_check(not _template(&"x", Vector2i(1, 1), [_door(&"a", R, Vector2i(3, 0))]).validate().is_empty(),
		"una puerta fuera de la sala es un error")
	_check(not _template(&"x", Vector2i(1, 1), [_door(&"a", R, Vector2i.ZERO, DoorSpec.Kind.STAIRS)]).validate().is_empty(),
		"una escalera a un costado es un error")
	_check(not _template(&"x", Vector2i(1, 1), [_door(&"a", R, Vector2i.ZERO), _door(&"a", L, Vector2i.ZERO)]).validate().is_empty(),
		"dos puertas con el mismo id es un error")
	return t


func _test_building(t: Dictionary[StringName, RoomTemplate]) -> RoomGraph:
	var g := RoomGraph.new(&"colegio", t)
	_check(g.add_room(&"entrada", &"entrada", Vector2i(0, 0)), "coloca la Entrada")
	_check(g.add_room(&"pasillo", &"pasillo", Vector2i(1, 0)), "coloca el Pasillo (dos celdas)")
	_check(not g.add_room(&"choque", &"almacen", Vector2i(2, 0)), "no coloca una sala encima de otra")
	_check(not g.add_room(&"pasillo", &"almacen", Vector2i(9, 9)), "no repite un id de sala")
	_check(not g.add_room(&"rara", &"no_existe", Vector2i(9, 9)), "no coloca una plantilla desconocida")
	g.add_room(&"almacen", &"almacen", Vector2i(3, 0))
	g.add_room(&"escalera", &"escalera", Vector2i(2, -1))
	g.add_room(&"biblioteca", &"biblioteca", Vector2i(1, -1))
	g.add_room(&"secreta", &"secreta", Vector2i(0, -1))
	g.add_room(&"azotea", &"azotea", Vector2i(3, -1))
	_check(g.room_at(Vector2i(2, 0)) == &"pasillo" and g.room_at(Vector2i(5, 5)) == &"", "sabe qué sala ocupa cada celda")

	_check(g.link_error(&"entrada", &"este", &"almacen", &"oeste") != "", "no conecta puertas que no están en celdas vecinas")
	_check(g.link_error(&"pasillo", &"escalera", &"escalera", &"oeste") != "", "no conecta puertas que no quedan enfrentadas")
	_check(g.link_error(&"pasillo", &"este", &"almacen", &"oeste") == "", "conecta puertas enfrentadas y vecinas")
	_check(g.link(&"entrada", &"este", &"pasillo", &"oeste"), "Entrada ↔ Pasillo")
	_check(not g.link(&"entrada", &"este", &"pasillo", &"oeste"), "una puerta no se conecta dos veces")
	_check(g.link(&"pasillo", &"este", &"almacen", &"oeste"), "Pasillo ↔ Almacén")
	_check(g.link(&"pasillo", &"escalera", &"escalera", &"abajo"), "Pasillo ↕ Escalera (escalera con escalera)")
	_check(g.link(&"escalera", &"oeste", &"biblioteca", &"este"), "Escalera ↔ Biblioteca")
	_check(g.link(&"biblioteca", &"secreto", &"secreta", &"este"), "Biblioteca ↔ sala secreta (paso secreto)")
	_check(g.link(&"escalera", &"este", &"azotea", &"oeste"), "Escalera ↔ Azotea")
	# Atajo de un solo sentido: se baja de la azotea al almacén, pero no se sube.
	_check(g.link(&"azotea", &"abajo", &"almacen", &"atajo", PackedStringArray(), true), "atajo Azotea → Almacén (un solo sentido)")
	_check(g.open_doors().is_empty(), "no quedan puertas sin destino")
	var target := g.target_of(&"pasillo", &"escalera")
	_check(target.get("room") == &"escalera" and target.get("door") == &"abajo", "sabe a dónde lleva cada puerta (en los dos sentidos)")
	_check(g.target_of(&"escalera", &"abajo").get("room") == &"pasillo", "y desde el otro lado también")

	# Clases incompatibles: una escalera no se conecta con un pasillo común.
	var t2: Dictionary[StringName, RoomTemplate] = {
		&"a": _template(&"a", Vector2i.ONE, [_door(&"arriba", UP, Vector2i.ZERO, DoorSpec.Kind.STAIRS)]),
		&"b": _template(&"b", Vector2i.ONE, [_door(&"abajo", DOWN, Vector2i.ZERO)]),
	}
	var g2 := RoomGraph.new(&"x", t2)
	g2.add_room(&"a", &"a", Vector2i(0, 0))
	g2.add_room(&"b", &"b", Vector2i(0, -1))
	_check(not g2.link(&"a", &"arriba", &"b", &"abajo") and g2.open_doors().size() == 2,
		"una escalera no conecta con un paso común (y quedan las dos puertas sueltas)")
	return g


func _test_paths(g: RoomGraph) -> void:
	var none := PackedStringArray()
	var start := g.reachable(&"entrada", none)
	_check(start.has(&"biblioteca") and start.has(&"almacen"), "sin habilidades se llega a la biblioteca y al almacén")
	_check(not start.has(&"secreta"), "sin la Visión Digital no se llega a la sala secreta")
	_check(not start.has(&"azotea"), "sin doble salto no se llega a la azotea")
	var vision := g.reachable(&"entrada", PackedStringArray(["vision"]))
	_check(vision.has(&"secreta"), "con la Visión Digital se encuentra la sala secreta")
	_check(g.find_path(&"entrada", &"biblioteca", none) == [&"entrada", &"pasillo", &"escalera", &"biblioteca"],
		"el camino más corto Entrada → Biblioteca pasa por el Pasillo y la Escalera")
	_check(g.find_path(&"entrada", &"azotea", none).is_empty(), "sin camino posible, find_path devuelve []")
	var jump := PackedStringArray(["double_jump"])
	_check(g.find_path(&"entrada", &"azotea", jump).size() == 4, "con doble salto se llega a la azotea")
	# El atajo: de la azotea se baja directo al almacén; del almacén no se sube.
	_check(g.find_path(&"azotea", &"almacen", jump) == [&"azotea", &"almacen"], "el atajo baja directo al almacén")
	_check(g.find_path(&"almacen", &"azotea", jump).size() == 4, "pero desde el almacén se sube por la escalera, no por el atajo")
	var state := Node.new()
	state.set_script(load("res://autoload/game_state.gd"))
	state.dash_level = 1
	state.vision_unlocked = true
	var have := RoomGraph.abilities_of(state)
	_check(have.has("dash") and have.has("vision") and not have.has("double_jump"), "lee las habilidades de Kai desde GameState")
	state.free()


func _test_save(g: RoomGraph, t: Dictionary[StringName, RoomTemplate]) -> void:
	var data := g.to_dict()
	var copy := RoomGraph.from_dict(data, t)
	_check(copy != null and copy.to_dict() == data, "guardar y cargar da el mismo grafo")
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	var from_json := RoomGraph.from_dict(parsed, t)
	_check(from_json != null and from_json.to_dict() == data, "también pasando por JSON (como en la partida)")
	_check(from_json != null and from_json.reachable(&"entrada", PackedStringArray()).size() == g.reachable(&"entrada", PackedStringArray()).size()
		and not from_json.reachable(&"entrada", PackedStringArray()).has(&"secreta"),
		"el grafo cargado conserva los requisitos (el paso secreto sigue pidiendo la Visión)")
	var future := data.duplicate(true)
	future["version"] = 99
	_check(RoomGraph.from_dict(future, t) == null, "un grafo de una versión desconocida no se usa")
	var missing := t.duplicate()
	missing.erase(&"almacen")
	_check(RoomGraph.from_dict(data, missing) == null, "si falta una plantilla, el grafo guardado no se usa")
	var broken := data.duplicate(true)
	broken["rooms"]["almacen"]["cell"] = [7, 7]
	_check(RoomGraph.from_dict(broken, t) == null, "si una conexión guardada ya no encaja, no se usa")


func _template(id: StringName, size: Vector2i, doors: Array[DoorSpec]) -> RoomTemplate:
	var template := RoomTemplate.new()
	template.id = id
	template.size_cells = size
	template.doors = doors
	return template


func _door(id: StringName, side: DoorSpec.Side, cell: Vector2i, kind := DoorSpec.Kind.PASSAGE) -> DoorSpec:
	var spec := DoorSpec.new()
	spec.id = id
	spec.side = side
	spec.cell = cell
	spec.kind = kind
	return spec


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
