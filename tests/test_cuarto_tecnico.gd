extends SceneTree
## Prueba automática: Capítulo 1, etapa 3 (el cuarto técnico). Está en el mapa (2° piso, a la izquierda
## de las escaleras); Kai llega al descanso nuevo saltando con la física real; la puerta está cerrada
## con llave hasta que el profesor da permiso (empieza «Travesuras en el sistema»); la conexión del
## monitor aparece con la Visión Digital solo cuando la historia lo pide; se vuelve a las escaleras y
## una partida guardada ahí continúa ahí.
## Ejecutar: godot --headless --path . --script res://tests/test_cuarto_tecnico.gd

const STAIRS := "res://world/zones/zone0/escaleras.tscn"
const ROOM := "res://world/zones/zone0/cuarto_tecnico.tscn"
const QUEST := &"travesuras_en_el_sistema"
const LAST_LANDING := Rect2(200, 14, 96, 10)
const LEFT_LEDGE := Rect2(0, -48, 160, 16)

var _failures := 0
var world: Node
var state: Node
var player: Player


func _initialize() -> void:
	Engine.max_physics_steps_per_frame = 1
	Engine.physics_jitter_fix = 0.0
	_run.call_deferred()


func _run() -> void:
	world = root.get_node("World")
	state = root.get_node("GameState")
	state.reset()
	state.unlock_vision()
	state.set_flag(&"tutorial_terminado")
	_test_map()
	await _test_locked_door()
	await _test_inside()
	await _test_save()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_map() -> void:
	var school: RoomGraph = world.graph(&"colegio")
	_check(school.rooms.has(&"cuarto_tecnico") and school.rooms[&"cuarto_tecnico"]["cell"] == Vector2i(0, -2),
		"el cuarto técnico está en el mapa: 2° piso, a la izquierda de las escaleras")
	var go: Dictionary = world.destination(&"escaleras", &"oeste")
	var back: Dictionary = world.destination(&"cuarto_tecnico", &"este")
	_check(go.get("scene") == ROOM and go.get("entry") == &"desde_escaleras" and back.get("scene") == STAIRS
		and back.get("entry") == &"desde_cuarto_tecnico", "la puerta oeste de las escaleras lleva al cuarto técnico y vuelve")
	_check(world.template_of(&"cuarto_tecnico").room_type == &"technical_room" and world.template_of(&"cuarto_tecnico").chapter_requirement == 1,
		"es una sala técnica del Capítulo 1")


func _test_locked_door() -> void:
	await _open(STAIRS)
	await _drop_on(Vector2(LAST_LANDING.position.x + 10, LAST_LANDING.position.y - 8))
	await _hop_to(LEFT_LEDGE, -1, "el descanso nuevo del 2° piso")
	_walk(-1)
	await _frames(90)
	_release_all()
	_check(current_scene.scene_file_path == STAIRS and not player.controls_locked,
		"sin el permiso del profesor la puerta está cerrada con llave")
	state.start_quest(QUEST)
	_walk(-1)
	await _until(func() -> bool: return current_scene != null and current_scene.scene_file_path == ROOM and current_scene.is_node_ready())
	_release_all()
	await _frames(10)
	player = (current_scene as Room).player
	_check(world.current_room == &"cuarto_tecnico" and player.global_position.distance_to(Vector2(596, 304)) < 2.0,
		"con el permiso (empieza «Travesuras en el sistema») Kai entra al cuarto técnico")


func _test_inside() -> void:
	var portal := current_scene.get_node("ImmersionPortal") as ImmersionPortal
	var vision := root.get_node("DigitalVision")
	vision.activate(true)
	await _frames(3)
	_check(portal != null and not portal.enabled, "con la Visión, la conexión todavía no aparece (Chip y Glitch no se metieron)")
	# Escena del servidor: se ríen desde el monitor y se meten en la computadora.
	var box := current_scene.get_node("CombatHUD/DialogueBox") as DialogueBox
	await _until(func() -> bool: return box.is_playing())
	await _advance(box)
	await _until(func() -> bool: return state.get_current_step(QUEST) == &"seguirlos_adentro")
	await _frames(3)
	_check(portal.enabled and portal.first_dialogue != null, "cuando se meten en la computadora, la conexión aparece en el monitor")
	vision.deactivate()
	await _frames(3)
	_check(not portal.enabled, "y sin la Visión no se ve")
	await _until(func() -> bool: return not root.get_node("SceneManager").is_changing())
	_walk(1)
	await _until(func() -> bool: return current_scene != null and current_scene.scene_file_path == STAIRS and current_scene.is_node_ready())
	_release_all()
	await _frames(10)
	player = (current_scene as Room).player
	_check(world.current_room == &"escaleras" and player.global_position.distance_to(Vector2(40, -48)) < 2.0,
		"por la puerta se vuelve al descanso del 2° piso")


func _test_save() -> void:
	var saves := root.get_node("SaveManager")
	saves.new_game(1)
	state.set_flag(&"tutorial_terminado")
	state.start_quest(QUEST)
	await _open(ROOM)
	_check(saves.save_game(ROOM, &"desde_escaleras") and saves.slot_info(1)["meta"]["lugar"] == "Cuarto técnico",
		"se guarda en el cuarto técnico (la tarjeta dice «Cuarto técnico»)")
	await _open(STAIRS)
	await _until(func() -> bool: return not root.get_node("SceneManager").is_changing())
	_check(saves.continue_game(1), "se continúa la partida")
	await _until(func() -> bool: return current_scene != null and current_scene.scene_file_path == ROOM and current_scene.is_node_ready())
	await _frames(8)
	_check(world.current_room == &"cuarto_tecnico", "y se sigue en el cuarto técnico")


## Salta hacia el descanso target (direction: 1 derecha, -1 izquierda) y comprueba que cae encima.
func _hop_to(target: Rect2, direction: int, description: String) -> void:
	var action := "move_right" if direction > 0 else "move_left"
	Input.action_press(action)
	await _press("jump")
	var released := false
	for i in 240:
		await physics_frame
		var pos := player.global_position
		if not released and pos.y < target.position.y - 2.0 and (pos.x - target.get_center().x) * direction >= -24.0:
			Input.action_release(action)
			released = true
		if i > 6 and player.is_on_floor():
			break
	_release_all()
	await _frames(2)
	var pos := player.global_position
	_check(absf(pos.y - target.position.y) <= 1.0 and pos.x >= target.position.x - 8.0 and pos.x <= target.end.x + 8.0,
		"Kai salta a %s (x=%.0f, y=%.0f)" % [description, pos.x, pos.y])


func _open(path: String) -> void:
	change_scene_to_file(path)
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == path and current_scene.is_node_ready())
	await _frames(8)
	player = (current_scene as Room).player


func _walk(direction: int) -> void:
	Input.action_press("move_right" if direction > 0 else "move_left")


func _release_all() -> void:
	for action in ["move_left", "move_right", "jump"]:
		Input.action_release(action)


func _drop_on(position: Vector2) -> void:
	_release_all()
	player.teleport_to(position)
	for i in 4:
		await physics_frame
	for i in 120:
		await physics_frame
		if player.is_on_floor():
			break
	await _frames(3)


func _advance(box: DialogueBox) -> void:
	for i in 60:
		if not box.is_playing():
			return
		var press := InputEventAction.new()
		press.action = &"interact"
		press.pressed = true
		Input.parse_input_event(press)
		await process_frame
		var release := InputEventAction.new()
		release.action = &"interact"
		release.pressed = false
		Input.parse_input_event(release)
		await _frames(3)


func _press(action: String) -> void:
	await physics_frame
	Input.action_press(action)


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
