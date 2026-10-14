extends SceneTree
## Prueba automática: Capítulo 1, etapas 3 a 6 (la persecución digital). Los tres tramos se recorren
## con la física real y solo las habilidades del capítulo 1 (salto, doble salto); la barrera de
## corrupción solo daña al contacto, quita 1 y da invulnerabilidad breve; las caídas quitan
## exactamente 1,5 y Kai reaparece sobre una plataforma segura (nunca sobre una que se mueve); los
## checkpoints detienen la barrera y el tiempo, bloquean el avance hasta responder bien, las
## respuestas incorrectas restan 15 s y lo hecho se guarda; el tiempo agotado y la muerte permiten
## reintentar desde el último checkpoint; al cargar no se repiten los checkpoints; al terminar, la
## barrera se apaga y el temporizador desaparece.
## Ejecutar: godot --headless --path . --script res://tests/test_persecucion.gd

const ROOM := "res://world/zones/red_entrenamiento/persecucion.tscn"
const FLOOR := 304.0

var _failures := 0
var state: Node
var room: Room
var player: Player
var chase: DigitalChaseController


func _initialize() -> void:
	Engine.max_physics_steps_per_frame = 1
	Engine.physics_jitter_fix = 0.0
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	var saves := root.get_node("SaveManager")
	saves.new_game(1)
	state.set_flag(&"tutorial_terminado")
	state.unlock_vision()
	state.unlock_immersion()
	state.unlock_double_jump()
	state.set_dash_level(1)
	state.start_quest(&"travesuras_en_el_sistema")
	state.complete_step(&"travesuras_en_el_sistema", &"revisar_servidor")
	await _open()
	_test_start()
	await _test_route()
	await _test_barrier()
	await _test_fall()
	await _test_checkpoint_1()
	await _test_time_up()
	await _test_death()
	await _test_reload_and_finish()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_start() -> void:
	_check(state.get_current_step(&"travesuras_en_el_sistema") == &"persecucion", "al llegar a la red de entrenamiento, la misión pide la persecución")
	_check(room.fall_damage == 1.5 and chase.time_left == 240.0 and not chase.running, "4:00 en el reloj, caídas de 1,5; nada corre hasta empezar el tramo")
	var timer := room.get_node("CombatHUD/ChaseTimer") as ChaseTimer
	_check(timer.visible and timer.text.contains("4:00"), "se ve el temporizador «⏱ 4:00»")


## Cada salto del camino, con la física real, de plataforma en plataforma (solo salto y doble salto).
func _test_route() -> void:
	chase.set_physics_process(false)  # Sin barrera ni reloj: solo el recorrido.
	for checkpoint in chase.checkpoints:
		checkpoint.set_deferred(&"monitoring", false)  # Sin preguntas: solo el recorrido.
	var hops := [
		# [desde x, desde y, destino (Rect2 de la parte de arriba), doble salto]
		[250, FLOOR, Rect2(300, 304, 220, 1), false], [500, FLOOR, Rect2(580, 272, 120, 1), false],
		[690, 272, Rect2(760, 240, 140, 1), false], [890, 240, Rect2(960, 304, 180, 1), false],
		[1130, FLOOR, Rect2(1200, 272, 120, 1), false], [1310, 272, Rect2(1380, 304, 260, 1), false],
		# Tramo 2, ruta de abajo: salto simple sobre los datos corruptos y al siguiente suelo.
		[1905, FLOOR, Rect2(2000, 304, 100, 1), false], [2090, FLOOR, Rect2(2160, 304, 160, 1), false],
		# Ruta de arriba: dos plataformas (la segunda con doble salto).
		[1800, FLOOR, Rect2(1840, 264, 80, 1), false], [1910, 264, Rect2(1980, 212, 70, 1), true],
		[2310, FLOOR, Rect2(2380, 260, 70, 1), false], [2440, 260, Rect2(2510, 228, 70, 1), false],
		[2570, 228, Rect2(2640, 260, 80, 1), false], [2710, 260, Rect2(2780, 304, 360, 1), false],
		# Tramo 3: plataformas temporales (hay que seguir sin parar).
		[3270, FLOOR, Rect2(3340, 280, 90, 1), false], [3420, 280, Rect2(3490, 256, 90, 1), false],
		[3570, 256, Rect2(3640, 280, 90, 1), false], [3720, 280, Rect2(3790, 248, 80, 1), false],
	]
	for hop in hops:
		await _drop_on(Vector2(hop[0], hop[1] - 8))
		await _hop_to(hop[2], 1, hop[3], "salto a x=%d" % hop[2].position.x)
	# La plataforma que se mueve del tramo 2 (ruta de arriba): subirse y bajar al suelo de abajo.
	var upper := room.get_node("Platforms/Platform12") as DataPlatform
	await _until(func() -> bool: return absf(upper.global_position.x - 2100.0) < 6.0)
	await _drop_on(Vector2(2040, 204))
	await _hop_to(Rect2(upper.global_position.x, 220, 72, 1), 1, false, "subirse a la plataforma que se mueve del tramo 2")
	# La plataforma que se mueve del tramo 3: subirse cerca del principio y bajarse cerca del final.
	var moving := room.get_node("Platforms/Platform23") as DataPlatform
	var origin_x := 3900.0
	await _until(func() -> bool: return absf(moving.global_position.x - origin_x) < 6.0)
	await _drop_on(Vector2(3860, 240))
	await _hop_to(Rect2(moving.global_position.x, 248, 76, 1), 1, false, "subirse a la plataforma que se mueve")
	await _until(func() -> bool: return moving.global_position.x > origin_x + 95.0)
	# Como un jugador: camina hasta el borde de la plataforma y salta.
	Input.action_press("move_right")
	for i in 60:
		await physics_frame
		if player.global_position.x >= moving.global_position.x + 64.0:
			break
	await _hop_to(Rect2(4120, 272, 90, 1), 1, false, "bajarse de la plataforma que se mueve")
	for hop in [[4200, 272, Rect2(4270, 288, 80, 1)], [4340, 288, Rect2(4400, 304, 360, 1)]]:
		await _drop_on(Vector2(hop[0], hop[1] - 8))
		await _hop_to(hop[2], 1, false, "salto a x=%d" % hop[2].position.x)
	_check(moving.is_in_group(&"unsafe_ground") and (room.get_node("Platforms/Platform21") as DataPlatform).is_in_group(&"unsafe_ground"),
		"las que se mueven y las temporales nunca son suelo seguro")
	chase.set_physics_process(true)
	for checkpoint in chase.checkpoints:
		checkpoint.set_deferred(&"monitoring", true)


func _test_barrier() -> void:
	await _open()
	await _drop_on(Vector2(400, FLOOR - 8))
	await _frames(4)
	_check(chase.running and chase.barrier.advancing, "al cruzar el inicio del tramo 1, la barrera avanza y el reloj corre")
	var before: float = player.health.current
	player.teleport_to(Vector2(chase.barrier.position.x - 10, FLOOR - 8))
	await _frames(3)
	_check(is_equal_approx(player.health.current, before - 1.0), "tocar la barrera quita 1 (%.1f → %.1f), sin derrota instantánea" % [before, player.health.current])
	_check(player.is_invulnerable(), "y da invulnerabilidad breve")
	var after_hit: float = player.health.current
	player.teleport_to(Vector2(chase.barrier.position.x - 10, FLOOR - 8))
	await _frames(10)
	_check(player.health.current == after_hit, "no hace daño en cada cuadro mientras dura la invulnerabilidad")
	await _until(func() -> bool: return not player.is_invulnerable())
	player.health.restore_full()


func _test_fall() -> void:
	await _drop_on(Vector2(1000, FLOOR - 8))
	await _frames(20)
	var before: float = player.health.current
	player.teleport_to(Vector2(930, 300))  # Sobre el vacío entre dos plataformas.
	await _until(func() -> bool: return player.damage.is_respawning)
	await _until(func() -> bool: return not player.damage.is_respawning)
	await _frames(6)
	_check(is_equal_approx(player.health.current, before - 1.5), "caer al vacío quita exactamente 1,5 (%.1f → %.1f)" % [before, player.health.current])
	_check(player.is_on_floor() and absf(player.global_position.y - FLOOR) < 1.0 and player.global_position.x >= 960.0,
		"y Kai reaparece sobre la última plataforma segura (x=%.0f)" % player.global_position.x)
	# Sobre una plataforma que se mueve, el suelo seguro no cambia.
	var safe := player.damage.last_safe_position
	await _drop_on(Vector2(2140, 228))
	await _frames(30)
	_check(player.damage.last_safe_position == safe, "parado sobre una plataforma que se mueve, el suelo seguro no cambia")
	player.health.restore_full()


func _test_checkpoint_1() -> void:
	var checkpoint := chase.checkpoints[0]
	_check(checkpoint.gate.active, "la puerta del checkpoint 1 está cerrada")
	await _drop_on(Vector2(1395, FLOOR - 8))
	await _frames(4)
	_check(chase.paused and not chase.barrier.advancing, "en la zona segura se detienen la barrera y el reloj")
	await _walk_to(1450.0)
	var window := await _window()
	_check(window != null and paused, "al llegar se abre la pregunta y el juego queda en pausa (Kai no recibe daño)")
	var time_before := chase.time_left
	var wrong := _option(window, false)
	window.choose(wrong)
	_check(is_equal_approx(chase.time_left, time_before - 15.0) and window.mistakes[0] == 1, "una respuesta incorrecta resta 15 s y explica por qué")
	window.close()
	await _frames(3)
	_check(checkpoint.gate.active and not checkpoint.done, "sin responder bien, la puerta no se abre")
	await _action(&"interact")
	window = await _window()
	_check(window != null, "con E se vuelve a abrir la pregunta")
	window.choose(_option(window, true))
	window.next()
	await _frames(3)
	_check(checkpoint.done and not checkpoint.gate.active and state.has_flag(&"cap1_checkpoint_1"), "al responder bien se abre la puerta y queda marcado")
	var saves := root.get_node("SaveManager")
	_check(saves.slot_info(1)["estado"] == "ok" and saves.read_slot(1)["ubicacion"]["punto"] == "checkpoint_1", "se guarda el progreso en el checkpoint 1")
	_check(chase.tramo == 1 and room.checkpoint == checkpoint, "empieza a prepararse el tramo 2")


func _test_time_up() -> void:
	await _drop_on(Vector2(1700, FLOOR - 8))
	await _frames(4)
	_check(chase.running and chase.tramo == 1, "al cruzar el inicio del tramo 2, corre el reloj")
	chase.time_left = 0.2
	await _until(func() -> bool: return player.global_position.x < 1600.0 and not player.controls_locked)
	await _frames(4)
	_check(player.global_position.x < 1600.0 and chase.time_left >= 100.0 and not chase.running,
		"al agotarse el tiempo, Kai vuelve al checkpoint 1 con tiempo suficiente (%.0f s)" % chase.time_left)


func _test_death() -> void:
	await _drop_on(Vector2(1700, FLOOR - 8))
	await _frames(4)
	chase.time_left = 50.0
	player.health.take_damage(player.health.current - 0.5)
	player.teleport_to(Vector2(chase.barrier.position.x - 10, FLOOR - 8))
	await _until(func() -> bool: return player.damage.is_respawning)
	await _until(func() -> bool: return not player.damage.is_respawning and not player.controls_locked)
	await _frames(6)
	_check(player.global_position.x < 1600.0 and chase.time_left >= 100.0 and is_equal_approx(player.health.current, player.health.max_health),
		"si se queda sin vida, reaparece en el checkpoint 1 con la vida llena y tiempo suficiente")


func _test_reload_and_finish() -> void:
	# Cargar: el checkpoint 1 ya hecho no se repite.
	await _open()
	_check(chase.tramo == 1 and chase.checkpoints[0].done and not chase.checkpoints[0].gate.active and chase.checkpoints[1].gate.active,
		"al volver a cargar, el checkpoint 1 no se repite (la puerta sigue abierta)")
	for i in [1, 2]:
		var checkpoint := chase.checkpoints[i]
		await _drop_on(Vector2(checkpoint.safe_from_x + 15.0, FLOOR - 8))
		await _walk_to(checkpoint.global_position.x)
		var window := await _window()
		window.choose(_option(window, true))
		window.next()
		await _frames(3)
	var timer := room.get_node("CombatHUD/ChaseTimer") as ChaseTimer
	_check(chase.tramo == 3 and chase.barrier.disabled and not timer.visible, "después del tercer checkpoint, la barrera se apaga y el temporizador desaparece")


## --- Ayudas ---

func get_tree_reset() -> void:
	player.health.restore_full()


func _open() -> void:
	change_scene_to_file(ROOM)
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == ROOM and current_scene.is_node_ready())
	await _frames(8)
	room = current_scene as Room
	player = room.player
	chase = room.get_node("Chase") as DigitalChaseController
	# La primera vez, Chip y Glitch se dan cuenta de que Kai los siguió (diálogo de inicio).
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	await _frames(4)
	for i in 60:
		if not box.is_playing():
			break
		await _action(&"interact")
		await _frames(3)


func _window() -> ChoiceWindow:
	for i in 60:
		var window := get_first_node_in_group(&"choice_window") as ChoiceWindow
		if window:
			return window
		await process_frame
	return null


func _option(window: ChoiceWindow, correct: bool) -> int:
	var options := window.challenge.questions[window.question_index].options
	for i in options.size():
		if options[i].correct == correct:
			return i
	return 0


func _hop_to(target: Rect2, direction: int, use_double: bool, description: String) -> void:
	var action := "move_right" if direction > 0 else "move_left"
	Input.action_press(action)
	await _press("jump")
	var released := false
	var doubled := not use_double
	for i in 300:
		await physics_frame
		var pos := player.global_position
		if not doubled and i > 4 and not player.is_on_floor() and player.velocity.y > -20.0:
			Input.action_release("jump")
			await physics_frame
			Input.action_press("jump")
			doubled = true
		if not released and pos.y < target.position.y - 2.0 and (pos.x - target.get_center().x) * direction >= -minf(24.0, target.size.x / 2.0 - 4.0):
			Input.action_release(action)
			released = true
		if i > 6 and player.is_on_floor():
			break
	_release_all()
	await _frames(2)
	var pos := player.global_position
	if absf(pos.y - target.position.y) > 1.0:
		print("     (depuración: vel=%s, en el suelo=%s, reapareciendo=%s, vida=%.1f)" % [player.velocity, player.is_on_floor(), player.damage.is_respawning, player.health.current])
	_check(absf(pos.y - target.position.y) <= 1.0 and pos.x >= target.position.x - 8.0 and pos.x <= target.end.x + 8.0,
		"recorrido: %s (x=%.0f, y=%.0f)" % [description, pos.x, pos.y])


func _walk_to(x: float) -> void:
	Input.action_press("move_right" if x > player.global_position.x else "move_left")
	for i in 300:
		await physics_frame
		if absf(player.global_position.x - x) < 6.0 or get_first_node_in_group(&"choice_window"):
			break
	_release_all()
	await _frames(2)


func _release_all() -> void:
	for action in ["move_left", "move_right", "jump", "dash"]:
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


func _until(condition: Callable) -> void:
	for i in 900:
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
