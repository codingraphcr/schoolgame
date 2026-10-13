extends SceneTree
## Prueba automática: M4. El generador del mapa (DistrictGenerator), fases A–C y F.
## Con fichas de prueba: la parte fija queda igual, la misma semilla da siempre el mismo mapa,
## semillas distintas dan mapas distintos y todos válidos, las salas opcionales solo se cuelgan de
## puertas enfrentadas y compatibles, nunca pasan del máximo, y si la parte variable no se puede
## validar queda la distribución de respaldo (solo la parte fija).
## Con los datos reales: el Colegio cuelga el aula o el depósito de la puerta libre de la
## biblioteca, el mapa se rearma igual al cargar la partida, y en el juego se llega a la sala
## opcional, la puerta que quedó libre está cerrada y una partida guardada ahí continúa ahí.
## Ejecutar: godot --headless --path . --script res://tests/test_generador.gd

const LIBRARY := "res://world/zones/zone0/biblioteca.tscn"
const CLASSROOM := "res://world/zones/zone0/aula.tscn"
const STORAGE := "res://world/zones/zone0/deposito.tscn"
const L := DoorSpec.Side.LEFT
const R := DoorSpec.Side.RIGHT
const U := DoorSpec.Side.UP
const D := DoorSpec.Side.DOWN

var _failures := 0
var world: Node


func _initialize() -> void:
	Engine.max_physics_steps_per_frame = 1
	Engine.physics_jitter_fix = 0.0
	_run.call_deferred()


func _run() -> void:
	world = root.get_node("World")
	_test_synthetic()
	_test_fallback()
	_test_real_school()
	await _test_in_game()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


# --- Con fichas de prueba ------------------------------------------------------------------------

## Fijo: inicio (0,0) → pasillo (1,0) con puertas libres al este y arriba. Opcionales: un cuarto
## de paso (oeste/este), un cuarto sin salida (oeste) y un hueco de escalera (abajo/arriba).
func _templates() -> Dictionary[StringName, RoomTemplate]:
	var t: Dictionary[StringName, RoomTemplate] = {}
	t[&"inicio"] = _template(&"inicio", true, [_door(&"este", R)])
	t[&"pasillo"] = _template(&"pasillo", true, [_door(&"oeste", L), _door(&"este", R), _door(&"arriba", U, DoorSpec.Kind.STAIRS)])
	t[&"cuarto"] = _template(&"cuarto", false, [_door(&"oeste", L), _door(&"este", R)], 2.0)
	t[&"cierre"] = _template(&"cierre", false, [_door(&"oeste", L)], 1.0)
	t[&"hueco"] = _template(&"hueco", false, [_door(&"abajo", D, DoorSpec.Kind.STAIRS), _door(&"arriba", U, DoorSpec.Kind.STAIRS)], 1.0)
	t[&"otro_distrito"] = _template(&"otro_distrito", false, [_door(&"oeste", L)], 50.0)
	t[&"otro_distrito"].district_id = &"otro"
	return t


func _layout(optional := 3) -> DistrictLayout:
	var layout := DistrictLayout.new()
	layout.id = &"prueba"
	layout.start_room = &"inicio"
	layout.optional_rooms = optional
	for data in [[&"inicio", Vector2i(0, 0)], [&"pasillo", Vector2i(1, 0)]]:
		var room := LayoutRoom.new()
		room.room_id = data[0]
		room.template_id = data[0]
		room.cell = data[1]
		layout.rooms.append(room)
	var link := LayoutLink.new()
	link.room_a = &"inicio"
	link.door_a = &"este"
	link.room_b = &"pasillo"
	link.door_b = &"oeste"
	layout.links.append(link)
	return layout


func _test_synthetic() -> void:
	var templates := _templates()
	var generator := DistrictGenerator.new()
	var fixed := generator.generate(_layout(0), templates, 7)
	_check(fixed != null and fixed.rooms.size() == 2 and fixed.open_doors().size() == 2, "sin salas opcionales queda la parte fija tal cual")
	var first := JSON.stringify(generator.generate(_layout(), templates, 1234).to_dict())
	var again := JSON.stringify(generator.generate(_layout(), templates, 1234).to_dict())
	_check(first == again, "la misma semilla da siempre el mismo mapa")
	var shapes := {}
	var problems: PackedStringArray = []
	for seed_value in range(1, 41):
		var graph := generator.generate(_layout(), templates, seed_value)
		var layout := _layout()
		problems.append_array(generator.validate(graph, layout))
		if generator.used_fallback:
			problems.append("semilla %d: respaldo" % seed_value)
		var optional := graph.rooms.size() - 2
		if optional < 1 or optional > 3:
			problems.append("semilla %d: %d salas opcionales" % [seed_value, optional])
		if not graph.rooms.has(&"inicio") or graph.target_of(&"inicio", &"este").get("room") != &"pasillo":
			problems.append("semilla %d: cambió la parte fija" % seed_value)
		for room_id: StringName in graph.rooms:
			if graph.template_of(room_id).district_id != &"prueba":
				problems.append("semilla %d: %s es de otro distrito" % [seed_value, room_id])
		var ids: Array = graph.rooms.keys()
		ids.sort()
		shapes[str(ids) + str(graph.rooms.values())] = true
	_check(problems.is_empty(), "40 semillas: todos los mapas son válidos, con 1 a 3 salas opcionales del distrito y la parte fija intacta %s" % [problems.slice(0, 4)])
	_check(shapes.size() >= 4, "semillas distintas dan mapas distintos (%d formas)" % shapes.size())
	# Por la escalera solo sube un hueco de escalera; por la puerta este, un cuarto o un cierre.
	var wrong: PackedStringArray = []
	for seed_value in range(1, 41):
		var graph := generator.generate(_layout(), templates, seed_value)
		var up: Dictionary = graph.target_of(&"pasillo", &"arriba")
		if not up.is_empty() and graph.template_of(up["room"]).id != &"hueco":
			wrong.append("arriba → %s" % up["room"])
		var east: Dictionary = graph.target_of(&"pasillo", &"este")
		if not east.is_empty() and graph.template_of(east["room"]).id == &"hueco":
			wrong.append("este → %s" % east["room"])
	_check(wrong.is_empty(), "las salas opcionales solo se cuelgan de puertas compatibles %s" % [wrong])


func _test_fallback() -> void:
	var templates := _templates()
	for id: StringName in [&"cuarto", &"cierre", &"hueco"]:
		templates[id].scene_path = ""
	var generator := DistrictGenerator.new()
	var graph := generator.generate(_layout(), templates, 99)
	_check(generator.used_fallback and generator.attempts_used == DistrictGenerator.ATTEMPTS and graph.rooms.size() == 2,
		"si la parte variable nunca pasa la validación, queda la distribución de respaldo (%d intentos)" % generator.attempts_used)
	var broken := _layout()
	broken.links[0].door_b = &"arriba"
	_check(generator.generate(broken, _templates(), 1) == null, "si la parte fija está mal, no se arma (error de datos)")


# --- Con los datos reales ------------------------------------------------------------------------

func _test_real_school() -> void:
	var kinds := {}
	var problems: PackedStringArray = []
	for seed_value in range(1, 31):
		world.new_world(seed_value)
		var school: RoomGraph = world.graph(&"colegio")
		var east: Dictionary = school.target_of(&"biblioteca", &"este")
		if east.is_empty():
			problems.append("semilla %d: la biblioteca no tiene sala al este" % seed_value)
			continue
		var names: PackedStringArray = []
		var room_id: StringName = east["room"]
		while room_id != &"":
			names.append(String(school.template_of(room_id).id))
			var next: Dictionary = school.target_of(room_id, &"este") if school.template_of(room_id).door(&"este") else {}
			room_id = next.get("room", &"")
		kinds[" → ".join(names)] = true
		if school.rooms.size() - 7 > 2:
			problems.append("semilla %d: demasiadas salas opcionales" % seed_value)
	_check(problems.is_empty(), "el Colegio siempre cuelga una sala opcional de la biblioteca, hasta 2 %s" % [problems])
	_check(kinds.size() >= 2, "según la semilla cambia lo que hay al este de la biblioteca: %s" % ", ".join(kinds.keys()))
	world.new_world(4242)
	var saved: Dictionary = world.to_dict()
	var graph_before := JSON.stringify(world.graph(&"colegio").to_dict())
	world.new_world(1)
	world.from_dict(saved)
	_check(JSON.stringify(world.graph(&"colegio").to_dict()) == graph_before, "al cargar la partida, el mapa se rearma igual (misma semilla)")


## Una semilla cuyo Colegio tenga dos aulas seguidas al lado de la biblioteca.
func _seed_with_two_classrooms() -> int:
	for seed_value in range(1, 200):
		world.new_world(seed_value)
		var school: RoomGraph = world.graph(&"colegio")
		var first: Dictionary = school.target_of(&"biblioteca", &"este")
		if first.is_empty() or world.template_of(first["room"]).id != &"aula":
			continue
		var second: Dictionary = school.target_of(first["room"], &"este")
		if not second.is_empty() and world.template_of(second["room"]).id == &"aula":
			return seed_value
	return -1


func _test_in_game() -> void:
	var saves := root.get_node("SaveManager")
	var state := root.get_node("GameState")
	saves.new_game(1)
	var seed_value := _seed_with_two_classrooms()
	_check(seed_value > 0, "hay semillas con dos aulas seguidas al lado de la biblioteca")
	world.new_world(seed_value)
	state.set_flag(&"tutorial_terminado")
	change_scene_to_file(LIBRARY)
	await _until(func() -> bool: return current_scene is Room)
	await _frames(8)
	var player := (current_scene as Room).player
	player.teleport_to(Vector2(880, 296))
	Input.action_press("move_right")
	await _until(func() -> bool: return current_scene != null and current_scene.scene_file_path == CLASSROOM and current_scene.is_node_ready())
	Input.action_release("move_right")
	await _frames(10)
	var classroom_id: StringName = world.current_room
	_check(world.template_of(classroom_id) != null and world.template_of(classroom_id).id == &"aula",
		"de la biblioteca se pasa al aula (%s)" % classroom_id)
	player = (current_scene as Room).player
	_check(player.global_position.distance_to(Vector2(40, 304)) < 2.0, "Kai aparece en la puerta oeste del aula")
	await _until(func() -> bool: return not root.get_node("SceneManager").is_changing())
	_check(saves.save_game(CLASSROOM, &"desde_oeste") and saves.slot_info(1)["meta"]["lugar"] == "Aula", "se guarda en el aula")
	# La misma escena, otra sala del mapa: la segunda aula.
	player.teleport_to(Vector2(560, 296))
	Input.action_press("move_right")
	await _until(func() -> bool: return world.current_room != classroom_id and current_scene.is_node_ready())
	Input.action_release("move_right")
	await _frames(10)
	var second_id: StringName = world.current_room
	_check(second_id != classroom_id and world.template_of(second_id).id == &"aula" and current_scene.scene_file_path == CLASSROOM,
		"la puerta este lleva a la segunda aula (%s, la misma escena)" % second_id)
	await _until(func() -> bool: return not root.get_node("SceneManager").is_changing())
	player = (current_scene as Room).player
	player.teleport_to(Vector2(600, 296))
	Input.action_press("move_right")
	await _frames(90)
	Input.action_release("move_right")
	_check(world.current_room == second_id and not root.get_node("SceneManager").is_changing(), "la puerta que el generador dejó libre está cerrada")
	var back: Dictionary = world.destination(second_id, &"oeste")
	_check(back.get("room") == classroom_id and back.get("entry") == &"desde_este", "y al volver se sale por la puerta este de la primera aula")
	change_scene_to_file(LIBRARY)
	await _until(func() -> bool: return current_scene != null and current_scene.scene_file_path == LIBRARY)
	await _frames(8)
	_check(saves.continue_game(1), "se continúa la partida")
	await _until(func() -> bool: return current_scene != null and current_scene.scene_file_path == CLASSROOM and current_scene.is_node_ready())
	await _frames(8)
	_check(world.current_room == classroom_id and world.world_seed == seed_value, "y se sigue en la misma aula del mismo mapa (%s)" % world.current_room)


# --- Ayudas ------------------------------------------------------------------------------------

func _template(id: StringName, fixed: bool, doors: Array[DoorSpec], weight := 1.0) -> RoomTemplate:
	var template := RoomTemplate.new()
	template.id = id
	template.display_name = String(id)
	template.scene_path = "res://%s.tscn" % id
	template.district_id = &"prueba"
	template.doors = doors
	template.fixed = fixed
	template.generation_weight = weight
	return template


func _door(id: StringName, side: DoorSpec.Side, kind := DoorSpec.Kind.DOOR) -> DoorSpec:
	var door := DoorSpec.new()
	door.id = id
	door.side = side
	door.kind = kind
	door.entry_id = StringName("desde_" + String(id))
	return door


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
