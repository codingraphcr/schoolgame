extends SceneTree
## Prueba automática: M2. El mapa fijo de cada distrito (DistrictLayout) y la pieza global World:
## las salas actuales tienen su room_id, cada salida (RoomExit o Stairway) tiene su door_id, el mapa y el
## respaldo de cada salida (target_scene) coinciden, y al cambiar de sala World sabe dónde está Kai.
## Ejecutar: godot --headless --path . --script res://tests/test_world.gd

const ENTRADA := "res://world/zones/zone0/entrada.tscn"
const PASILLO := "res://world/zones/zone0/pasillo.tscn"
const LAB := "res://world/zones/zone0/laboratorio.tscn"
const PC := "res://world/zones/pc_profesor/escritorio.tscn"

var _failures := 0
var world: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	world = root.get_node("World")
	_test_districts()
	_test_scenes_match_map()
	await _test_entering_rooms()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_districts() -> void:
	_check(world.districts.has(&"colegio") and world.districts.has(&"pc_profesor"), "se arman los distritos Colegio y PC del profesor")
	var colegio: RoomGraph = world.graph(&"colegio")
	_check(colegio != null and colegio.rooms.has(&"entrada") and colegio.rooms.has(&"pasillo") and colegio.rooms.has(&"laboratorio"),
		"el Colegio tiene la Entrada, el Pasillo y el Laboratorio (dos salas)")
	_check(colegio != null and colegio.open_doors().is_empty(), "el Colegio no tiene puertas sin destino")
	var wrong: PackedStringArray = []
	for district_id: StringName in world.districts:
		for room_id: StringName in world.districts[district_id].rooms:
			if world.template_of(room_id).district_id != district_id:
				wrong.append(String(room_id))
	_check(wrong.is_empty(), "cada sala está en el distrito que dice su ficha %s" % [wrong])
	_check(world.district_of(&"pc_escritorio") == &"pc_profesor" and world.scene_of(&"pc_escritorio") == PC,
		"la PC del profesor es un distrito aparte")
	var to_pasillo: Dictionary = world.destination(&"entrada", &"este")
	_check(to_pasillo.get("room") == &"pasillo" and to_pasillo.get("scene") == PASILLO
		and to_pasillo.get("entry") == &"desde_entrada", "la puerta este de la Entrada lleva al Pasillo (entrada desde_entrada)")
	var to_entrada: Dictionary = world.destination(&"pasillo", &"oeste")
	_check(to_entrada.get("room") == &"entrada" and to_entrada.get("entry") == &"desde_pasillo", "y la oeste del Pasillo vuelve a la Entrada")
	var to_lab: Dictionary = world.destination(&"pasillo", &"este")
	_check(to_lab.get("room") == &"laboratorio" and to_lab.get("scene") == LAB and to_lab.get("entry") == &"desde_pasillo",
		"la puerta este del Pasillo lleva al Laboratorio")
	_check(world.destination(&"laboratorio", &"oeste").get("entry") == &"desde_laboratorio", "y la oeste del Laboratorio vuelve al Pasillo")
	_check(world.destination(&"entrada", &"no_existe").is_empty() and world.destination(&"nadie", &"este").is_empty(),
		"una puerta o una sala desconocida no tiene destino")
	_check(world.room_for_scene(ENTRADA) == &"entrada" and world.room_for_scene("res://no.tscn") == &"", "encuentra la sala de cada escena")


## Cada salida de las escenas tiene una puerta en la ficha, y el mapa lleva al mismo lugar que su
## respaldo (target_scene / target_entry): el prólogo se juega igual que antes.
func _test_scenes_match_map() -> void:
	var problems: PackedStringArray = []
	for district_id: StringName in world.districts:
		var graph: RoomGraph = world.graph(district_id)
		for room_id: StringName in graph.rooms:
			var template: RoomTemplate = graph.template_of(room_id)
			var scene := (load(template.scene_path) as PackedScene).instantiate()
			var exits_by_door := {}
			# Salidas por los bordes (RoomExit) y escaleras (Stairway): las dos tienen door_id y respaldo.
			for room_exit in scene.find_children("*", "RoomExit", true, false) + scene.find_children("*", "Stairway", true, false):
				var door: StringName = room_exit.door_id
				if door == &"":
					continue
				exits_by_door[door] = true
				if template.door(door) == null:
					problems.append("%s: la salida %s no está en la ficha" % [room_id, door])
					continue
				var target: Dictionary = world.destination(room_id, door)
				if target.get("scene") != room_exit.target_scene or target.get("entry") != room_exit.target_entry:
					problems.append("%s.%s: el mapa lleva a %s y la salida a %s" % [room_id, door, target, room_exit.target_scene])
			for spec in template.doors:
				if graph.is_linked(room_id, spec.id) and not exits_by_door.has(spec.id):
					problems.append("%s: la puerta %s no tiene salida en la escena" % [room_id, spec.id])
			scene.free()
	_check(problems.is_empty(), "las salidas de las escenas y el mapa coinciden %s" % [problems])


func _test_entering_rooms() -> void:
	var entered: Array[StringName] = []
	world.room_entered.connect(func(room_id: StringName, _district: StringName) -> void: entered.append(room_id))
	change_scene_to_file(ENTRADA)
	await _frames(6)
	var room := current_scene as Room
	_check(room != null and room.room_id == &"entrada" and world.current_room == &"entrada"
		and world.current_district == &"colegio", "al cargar la Entrada, World sabe que Kai está ahí")
	_check(entered == [&"entrada"], "avisa con room_entered")
	var room_exit := room.get_node("Exits/ToPasillo") as RoomExit
	var target := room_exit.resolve()
	_check(target.get("room") == &"pasillo", "la salida de la Entrada le pregunta el destino al mapa")
	# Cambiar de sala como lo hace una salida, con el id de la sala.
	root.get_node("SceneManager").go_to_room(target["scene"], target["entry"], target["room"])
	await _until(func() -> bool: return current_scene != null and current_scene.name == "Pasillo")
	await _frames(6)
	room = current_scene as Room
	_check(room != null and room.room_id == &"pasillo" and world.current_room == &"pasillo",
		"al llegar al Pasillo, World cambia de sala")
	_check(room != null and absf(room.player.global_position.x - 40.0) < 4.0, "Kai aparece en la entrada que dice el mapa")
	# Llegar sin id (p. ej. al continuar una partida): se busca por la escena.
	_check(world.enter(PC) == &"pc_escritorio" and world.current_district == &"pc_profesor", "sin id, la sala se encuentra por su escena")
	_check(world.enter(ENTRADA, &"pc_escritorio") == &"entrada", "un id que no corresponde a la escena se ignora")
	_check(world.enter("res://no.tscn") == &"" and world.current_room == &"", "una escena fuera del mapa no tiene sala")


func _until(condition: Callable) -> void:
	for i in 600:
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
