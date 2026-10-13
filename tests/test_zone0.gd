extends SceneTree
## Prueba automática: salas del prólogo (Entrada y Pasillo + Laboratorio) con el arte de Ariel,
## partida nueva, transiciones entre salas y máscaras que se conservan al cambiar de sala.
## Ejecutar: godot --headless --path . --script res://tests/test_zone0.gd

const MENU := "res://ui/menus/main_menu/main_menu.tscn"
const FLOOR_Y := 304.0
const TRAY_1 := Vector2(488, 304)  # Bajo la primera bandeja de cables (superficie en y=256)
const OBSTACLE_LEFT := 424.0  # Casilleros de la entrada que hay que saltar

var _failures := 0
var state: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	# Progreso de una partida anterior: "Jugar" debe empezar de cero.
	state.set_dash_level(2)
	state.unlock_double_jump()
	root.get_node("Economy").add_ecos(300)

	change_scene_to_file(MENU)
	await _frames(20)
	current_scene.get_node("%PlayButton").pressed.emit()
	await process_frame
	(current_scene.get_node("SlotSelect") as SlotSelect).pick(1)
	await create_timer(1.2, true, false, true).timeout
	var room := current_scene as Room
	_check(room != null and room.name == "Entrada", "Jugar abre la Entrada del colegio")
	if room == null:
		quit(1)
		return
	var player := room.player

	await _test_new_game(room, player)
	await _test_entrada(room, player)
	room = current_scene as Room
	_check(room != null and room.name == "Pasillo", "la salida derecha lleva al Pasillo")
	if room == null:
		quit(1)
		return
	player = room.player
	_check(absf(player.global_position.x - 40.0) < 16.0 and player.facing == 1, "Kai aparece por la entrada del pasillo, mirando a la derecha (x=%.0f)" % player.global_position.x)
	_check(player.health.current == 3.0, "las máscaras se conservan al cambiar de sala (quedan %d)" % player.health.current)
	await _test_layout(room, player)
	player = await _test_lab_to_pasillo()
	if player == null:
		quit(1)
		return
	await _test_back_to_entrada(player)
	await _test_back_to_menu()

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_new_game(room: Room, player: Player) -> void:
	_check(player.dash_level == 0 and not player.can_double_jump and not player.can_wall_jump,
		"partida nueva: Kai es un alumno común (sin dash, doble salto ni pared)")
	_check(not state.vision_unlocked and state.nullblade_stage == 0, "partida nueva: sin Visión Digital ni Nullblade")
	_check(root.get_node("Economy").ecos == 0, "partida nueva: 0 Ecos")
	_check(room.get_node("CombatHUD/Masks").get_child_count() == 4, "el HUD muestra 4 máscaras")
	await _until(func() -> bool: return player.is_on_floor())
	_check(player.is_on_floor() and absf(player.global_position.y - FLOOR_Y) < 1.0, "Kai aparece de pie en la entrada")
	var kai := player.get_node("Visual/Body/Kai") as KaiVisual
	_check(kai != null and kai.current_animation() == &"quieto", "Kai es el diseño de Ariel (animación quieto)")
	await _press("dash")
	await _frames(2)
	Input.action_release("dash")
	_check(not player.is_dashing, "sin dash adquirido, Shift no hace nada")


func _test_entrada(room: Room, player: Player) -> void:
	var camera := room.camera
	_check(camera.limit_right == 800 and camera.limit_bottom == 368, "límites de cámara de la entrada (0, 0, %d, %d)" % [camera.limit_right, camera.limit_bottom])
	Input.action_press("move_right")
	# Camina hasta quedar frenado contra los casilleros.
	await _frames(30)
	for i in 300:
		await physics_frame
		if player.global_position.x > OBSTACLE_LEFT - 40.0 and is_zero_approx(player.get_real_velocity().x):
			break
	_check(player.global_position.x < OBSTACLE_LEFT and player.global_position.x > OBSTACLE_LEFT - 12.0,
		"los casilleros bloquean el paso caminando (x=%.0f)" % player.global_position.x)
	await _press("jump")
	await _frames(45)
	Input.action_release("jump")
	await _frames(30)
	_check(player.global_position.x > OBSTACLE_LEFT + 40.0, "saltando se pasan los casilleros (x=%.0f)" % player.global_position.x)
	player.health.take_damage(1.0)
	for i in 300:
		await physics_frame
		if current_scene == null or current_scene.name != "Entrada":
			break
	Input.action_release("move_right")
	await create_timer(1.0, true, false, true).timeout


func _test_back_to_entrada(player: Player) -> void:
	player.teleport_to(Vector2(60, FLOOR_Y))
	Input.action_press("move_left")
	for i in 200:
		await physics_frame
		if current_scene == null or current_scene.name != "Pasillo":
			break
	Input.action_release("move_left")
	await create_timer(1.0, true, false, true).timeout
	var room := current_scene as Room
	_check(room != null and room.name == "Entrada", "la salida izquierda del pasillo vuelve a la entrada")
	if room:
		_check(absf(room.player.global_position.x - 760.0) < 16.0 and room.player.facing == -1,
			"Kai aparece junto a la salida, mirando a la izquierda (x=%.0f)" % room.player.global_position.x)


func _test_layout(room: Room, player: Player) -> void:
	var camera := room.camera
	_check(camera.limit_left == 0 and camera.limit_right == 688 and camera.limit_top == 0 and camera.limit_bottom == 368,
		"límites de cámara = sala (0, 0, %d, %d)" % [camera.limit_right, camera.limit_bottom])

	player.teleport_to(TRAY_1)
	await _frames(5)
	await _press("jump")
	await _frames(40)
	Input.action_release("jump")
	for i in 120:
		await physics_frame
		if player.is_on_floor():
			break
	_check(absf(player.global_position.y - 256.0) < 1.0, "las bandejas de cables son plataformas (y=%.0f)" % player.global_position.y)

	player.teleport_to(Vector2(300, FLOOR_Y))
	await _frames(5)
	Input.action_press("move_right")
	await _frames(10)
	var kai := player.get_node("Visual/Body/Kai") as KaiVisual
	_check(kai.current_animation() == &"caminar", "al desplazarse usa la animación de caminar (correr llega más adelante)")
	player.can_run = true
	await _frames(20)
	_check(kai.current_animation() == &"correr" and is_equal_approx(absf(player.velocity.x), player.max_speed), "cuando puede correr, corre más rápido con la animación correr")
	player.can_run = false
	for i in 600:
		await physics_frame
		if current_scene == null or current_scene.name != "Pasillo":
			break
	Input.action_release("move_right")
	await create_timer(1.0, true, false, true).timeout
	var lab := current_scene as Room
	_check(lab != null and lab.name == "Laboratorio", "caminando a la derecha, el pasillo lleva al Laboratorio (otra sala)")
	if lab:
		_check(absf(lab.player.global_position.x - 40.0) < 16.0 and lab.player.facing == 1 and lab.camera.limit_right == 720,
			"Kai entra al laboratorio por la izquierda; el laboratorio mide 720 px (x=%.0f)" % lab.player.global_position.x)


## Del laboratorio se vuelve al pasillo por la izquierda.
func _test_lab_to_pasillo() -> Player:
	var lab := current_scene as Room
	if lab == null or lab.name != "Laboratorio":
		return null
	lab.player.teleport_to(Vector2(60, FLOOR_Y))
	Input.action_press("move_left")
	for i in 200:
		await physics_frame
		if current_scene == null or current_scene.name != "Laboratorio":
			break
	Input.action_release("move_left")
	await create_timer(1.0, true, false, true).timeout
	var room := current_scene as Room
	_check(room != null and room.name == "Pasillo", "la salida izquierda del laboratorio vuelve al pasillo")
	if room == null:
		return null
	_check(absf(room.player.global_position.x - 648.0) < 16.0 and room.player.facing == -1,
		"Kai aparece al final del pasillo, mirando a la izquierda (x=%.0f)" % room.player.global_position.x)
	return room.player


func _test_back_to_menu() -> void:
	var event := InputEventAction.new()
	event.action = &"pause"
	event.pressed = true
	Input.parse_input_event(event)
	await create_timer(1.2, true, false, true).timeout
	_check(current_scene != null and current_scene.name == "MainMenu", "Esc vuelve al menú principal")


func _press(action: String) -> void:
	await physics_frame
	Input.action_press(action)


## Espera (en cuadros de física) a que se cumpla la condición, hasta unos 10 s de juego.
func _until(condition: Callable) -> void:
	for i in 600:
		if condition.call():
			return
		await process_frame
		await physics_frame


func _frames(count: int) -> void:
	for i in count:
		await process_frame  # Teclas y HUD se procesan en cuadros de dibujo.
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
