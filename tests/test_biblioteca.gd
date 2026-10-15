extends SceneTree
## Prueba automática: M3. Las escaleras y la biblioteca del Colegio. Están en el mapa (fichas y
## conexiones); se abren recién en el Capítulo 1 (antes, la escalera del Pasillo avisa y no se usa);
## Kai sube los descansos saltando, con la física real y sin doble salto; la salida del segundo
## piso lleva a la biblioteca, las estanterías bajas sirven de plataforma y se vuelve por el mismo
## camino; y una partida guardada en la biblioteca continúa ahí.
## Las pruebas usan su propia carpeta de partidas (IdentityManager en modo prueba).
## Ejecutar: godot --headless --path . --script res://tests/test_biblioteca.gd

const PASILLO := "res://world/zones/zone0/pasillo.tscn"
const STAIRS := "res://world/zones/zone0/escaleras.tscn"
const LIBRARY := "res://world/zones/zone0/biblioteca.tscn"
const CORRIDOR := "res://world/zones/zone0/pasillo_segundo.tscn"
## Descansos de la escalera (arriba = donde pisa Kai), del piso de abajo al de arriba.
const LANDINGS := [Rect2(200, 246, 96, 10), Rect2(340, 188, 96, 10), Rect2(200, 130, 96, 10),
	Rect2(60, 72, 96, 10), Rect2(200, 14, 96, 10), Rect2(330, -48, 310, 16)]

var _failures := 0
var world: Node
var state: Node
var player: Player


func _initialize() -> void:
	# Un paso de física por cuadro: con la computadora cargada la prueba va más lenta, pero da igual.
	Engine.max_physics_steps_per_frame = 1
	Engine.physics_jitter_fix = 0.0
	_run.call_deferred()


func _run() -> void:
	world = root.get_node("World")
	state = root.get_node("GameState")
	_test_map()
	await _test_locked_before_chapter_1()
	state.set_flag(&"tutorial_terminado")
	_check(world.lock_reason(&"escaleras").is_empty() and world.lock_reason(&"biblioteca").is_empty(), "en el Capítulo 1 se abren")
	await _test_climb()
	await _test_library_and_back()
	await _test_save_in_library()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_map() -> void:
	var school: RoomGraph = world.graph(&"colegio")
	_check(school.rooms.has(&"escaleras") and school.rooms.has(&"biblioteca") and school.is_linked(&"pasillo", &"escalera")
		and school.is_linked(&"escaleras", &"este"), "el Colegio tiene las escaleras y la biblioteca, conectadas")
	var up: Dictionary = world.destination(&"pasillo", &"escalera")
	var corridor: Dictionary = world.destination(&"escaleras", &"este")
	var library: Dictionary = world.destination(&"pasillo_segundo", &"este")
	_check(up.get("scene") == STAIRS and up.get("entry") == &"desde_pasillo", "la escalera del Pasillo sube a las escaleras")
	_check(corridor.get("scene") == CORRIDOR and corridor.get("entry") == &"desde_escaleras"
		and library.get("scene") == LIBRARY and library.get("entry") == &"desde_escaleras",
		"el segundo piso lleva al pasillo del segundo piso, y ese pasillo a la biblioteca")
	_check(world.template_of(&"escaleras").size_cells == Vector2i(1, 2) and world.template_of(&"biblioteca").room_type == &"library",
		"las fichas: escaleras de 2 pisos y una biblioteca")
	_check(not world.lock_reason(&"escaleras").is_empty() and not world.lock_reason(&"biblioteca").is_empty()
		and world.lock_reason(&"laboratorio").is_empty(), "antes del Capítulo 1 están cerradas (el resto del prólogo no)")


## En el prólogo, la escalera del Pasillo avisa por qué no se puede subir y Kai se queda.
func _test_locked_before_chapter_1() -> void:
	await _open(PASILLO)
	var stairway := current_scene.get_node("Subida") as Stairway
	_check(stairway != null and stairway.door_id == &"escalera", "el Pasillo tiene la escalera que sube")
	await _drop_on(Vector2(330, 290))
	await _action(&"interact")
	await _frames(30)
	_check(current_scene.scene_file_path == PASILLO and not player.controls_locked, "antes del Capítulo 1 la escalera no se usa")


func _test_climb() -> void:
	await _action(&"interact")
	await _until(func() -> bool: return current_scene != null and current_scene.scene_file_path == STAIRS and current_scene.is_node_ready())
	await _frames(10)
	player = (current_scene as Room).player
	_check(world.current_room == &"escaleras" and player.global_position.distance_to(Vector2(72, 304)) < 2.0,
		"con E sube: llega a las escaleras, abajo (%s)" % player.global_position)
	_check(not player.can_double_jump, "Kai sube sin doble salto")
	# Del piso a cada descanso, saltando desde el borde que mira al siguiente.
	var from := Rect2(0, 304, 480, 0)
	var starts := [170.0, 286.0, 350.0, 210.0, 146.0, 286.0]
	for i in LANDINGS.size():
		var target: Rect2 = LANDINGS[i]
		var direction := 1 if target.get_center().x > starts[i] else -1
		await _drop_on(Vector2(starts[i], from.position.y - 8))
		await _hop_to(target, direction, "descanso %d" % (i + 1))
		from = target
	_walk(1)
	await _until(func() -> bool: return current_scene != null and current_scene.scene_file_path == CORRIDOR and current_scene.is_node_ready())
	_release_all()
	await _frames(10)
	player = (current_scene as Room).player
	_check(world.current_room == &"pasillo_segundo" and player.global_position.distance_to(Vector2(40, 304)) < 2.0,
		"arriba, la salida del segundo piso lleva al pasillo del segundo piso (%s)" % player.global_position)
	# Por el pasillo (largo) hasta la biblioteca.
	await _drop_on(Vector2(1800, 290))
	_walk(1)
	await _until(func() -> bool: return current_scene != null and current_scene.scene_file_path == LIBRARY and current_scene.is_node_ready())
	_release_all()
	await _frames(10)
	player = (current_scene as Room).player
	_check(world.current_room == &"biblioteca" and player.global_position.distance_to(Vector2(40, 304)) < 2.0,
		"y al final del pasillo está la biblioteca (%s)" % player.global_position)


func _test_library_and_back() -> void:
	await _drop_on(Vector2(195, 200))
	_check(absf(player.global_position.y - 240.0) <= 1.0, "una estantería baja sirve de plataforma (y=%.0f)" % player.global_position.y)
	await _drop_on(Vector2(40, 290))
	_walk(-1)
	await _until(func() -> bool: return current_scene != null and current_scene.scene_file_path == CORRIDOR and current_scene.is_node_ready())
	_release_all()
	await _frames(10)
	player = (current_scene as Room).player
	_check(player.global_position.distance_to(Vector2(1860, 304)) < 2.0, "de la biblioteca se vuelve al pasillo del segundo piso (%s)" % player.global_position)
	await _drop_on(Vector2(100, 290))
	_walk(-1)
	await _until(func() -> bool: return current_scene != null and current_scene.scene_file_path == STAIRS and current_scene.is_node_ready())
	_release_all()
	await _frames(10)
	player = (current_scene as Room).player
	_check(player.global_position.distance_to(Vector2(600, -48)) < 2.0, "y del pasillo, a las escaleras (%s)" % player.global_position)
	await _drop_on(Vector2(32, 290))
	await _action(&"interact")
	await _until(func() -> bool: return current_scene != null and current_scene.scene_file_path == PASILLO and current_scene.is_node_ready())
	await _frames(10)
	player = (current_scene as Room).player
	_check(world.current_room == &"pasillo" and player.global_position.distance_to(Vector2(330, 304)) < 2.0,
		"con E baja al Pasillo, junto a la escalera (%s)" % player.global_position)


func _test_save_in_library() -> void:
	var saves := root.get_node("SaveManager")
	saves.new_game(1)
	state.set_flag(&"tutorial_terminado")
	await _open(LIBRARY)
	_check(saves.save_game(LIBRARY, &"desde_escaleras") and saves.slot_info(1)["meta"]["lugar"] == "Biblioteca",
		"se guarda en la biblioteca (la tarjeta dice «Biblioteca»)")
	await _open(PASILLO)
	# Como al elegir «Continuar» en el menú: sin otro fundido en curso.
	await _until(func() -> bool: return not root.get_node("SceneManager").is_changing())
	_check(saves.continue_game(1), "se continúa la partida")
	await _until(func() -> bool: return current_scene != null and current_scene.scene_file_path == LIBRARY and current_scene.is_node_ready())
	await _frames(10)
	_check(current_scene.scene_file_path == LIBRARY and world.current_room == &"biblioteca", "y se sigue en la biblioteca")


## Salta hacia el descanso target (direction: 1 derecha, -1 izquierda) y comprueba que cae encima.
## Como un jugador: suelta la dirección cuando ya está sobre el descanso.
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
		"sube al %s (x=%.0f, y=%.0f)" % [description, pos.x, pos.y])


func _open(path: String) -> void:
	change_scene_to_file(path)
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
	# Unos pasos de física para que deje de contar el suelo de antes de moverlo.
	for i in 4:
		await physics_frame
	for i in 120:
		await physics_frame
		if player.is_on_floor():
			break
	await _frames(3)


func _press(action: String) -> void:
	await physics_frame
	Input.action_press(action)


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


## Espera (en cuadros) a que se cumpla la condición, hasta unos 10 s de juego.
func _until(condition: Callable) -> void:
	for i in 600:
		if condition.call():
			return
		await process_frame
		await physics_frame


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
