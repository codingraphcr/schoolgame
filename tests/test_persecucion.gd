extends SceneTree
## Prueba automática: la persecución digital del Capítulo 1 (versión 2: más larga, más difícil y con
## proyectiles). El camino principal se recorre con la física real y **solo salto y dash** (sin doble
## salto); la barrera de corrupción solo daña al contacto, quita 1 y da invulnerabilidad breve, nunca
## queda delante de Kai y en las zonas seguras se queda a una distancia segura; las caídas quitan
## exactamente 1,5 y Kai reaparece sobre una plataforma segura (nunca sobre una que se mueve o
## desaparece); los nodos corruptos disparan con aviso y solo mientras corre un tramo; los checkpoints
## detienen la barrera y el tiempo, bloquean el avance hasta responder bien, restan 15 s por respuesta
## incorrecta y guardan; el tiempo agotado y la muerte permiten reintentar; al cargar no se repiten
## los checkpoints; al terminar, la barrera se apaga y el temporizador desaparece.
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
	state.set_dash_level(1)
	state.start_quest(&"travesuras_en_el_sistema")
	state.complete_step(&"travesuras_en_el_sistema", &"revisar_servidor")
	await _open()
	_test_start()
	await _test_route()
	await _open()
	await _test_barrier()
	await _test_fall()
	await _test_emitters()
	await _test_checkpoint_1()
	await _test_time_up()
	await _test_death()
	await _test_reload_and_finish()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_start() -> void:
	_check(state.get_current_step(&"travesuras_en_el_sistema") == &"persecucion", "al llegar a la red de entrenamiento, la misión pide la persecución")
	_check(room.fall_damage == 1.5 and chase.time_left == 240.0 and not chase.running, "4:00 en el reloj, caídas de 1,5; nada corre hasta empezar el tramo")
	_check(not player.can_double_jump, "Kai no tiene doble salto (se consigue más adelante)")
	var timer := room.get_node("CombatHUD/ChaseTimer") as ChaseTimer
	_check(timer.visible and timer.text.contains("4:00"), "se ve el temporizador «⏱ 4:00»")
	var width := room.room_size.size.x
	_check(width > 6500.0, "la persecución es más larga (%d px)" % width)


## El camino principal, salto a salto, con la física real: solo salto y dash.
func _test_route() -> void:
	chase.set_physics_process(false)  # Sin barrera ni reloj: solo el recorrido.
	for checkpoint in chase.checkpoints:
		checkpoint.set_deferred(&"monitoring", false)  # Sin preguntas.
		if checkpoint.gate:
			checkpoint.gate.active = false
	for emitter in room.get_node("Emitters").get_children():
		emitter.set_physics_process(false)  # Sin disparos: solo el recorrido.
	var route: Array[DataPlatform] = []
	for node in room.get_node("Platforms").get_children():
		if node.has_meta(&"route"):
			route.append(node)
	route.sort_custom(func(a: DataPlatform, b: DataPlatform) -> bool: return int(a.get_meta(&"route")) < int(b.get_meta(&"route")))
	var failed := 0
	for i in range(1, route.size()):
		var source := route[i - 1]
		var target := route[i]
		if source.get_meta(&"moving"):
			# Ir hasta el final del recorrido y caminar al borde antes de saltar.
			var far_x := float(source.get_meta(&"origin_x")) + source.move_offset.x * 0.9
			await _until(func() -> bool: return source.global_position.x >= far_x)
			Input.action_press("move_right")
			for k in 60:
				await physics_frame
				if player.global_position.x >= source.global_position.x + source.width - 10.0:
					break
			Input.action_release("move_right")
		else:
			await _drop_on(Vector2(source.global_position.x + source.width - 10.0, source.global_position.y - 8.0))
		if target.get_meta(&"moving"):
			# Saltar cuando la plataforma está al principio de su recorrido (cerca).
			var origin_x := float(target.get_meta(&"origin_x"))
			await _until(func() -> bool: return absf(target.global_position.x - origin_x) < 6.0)
		var ok := await _hop_to(target, bool(target.get_meta(&"dash")))
		if not ok:
			failed += 1
			print("     recorrido: no llegó a la plataforma %d (x=%.0f, y=%.0f) desde la %d" % [i, target.global_position.x, target.global_position.y, i - 1])
		player.health.restore_full()
	_check(failed == 0 and route.size() > 25, "se recorre todo el camino (%d saltos) con salto y dash, sin doble salto" % (route.size() - 1))
	var temporary := room.get_node("Platforms").get_children().filter(func(n: Node) -> bool: return n is DataPlatform and n.kind == DataPlatform.Kind.TEMPORARY)
	var moving := room.get_node("Platforms").get_children().filter(func(n: Node) -> bool: return n is DataPlatform and n.kind == DataPlatform.Kind.MOVING)
	_check(temporary.size() >= 8 and moving.size() >= 2 and temporary.all(func(n: Node) -> bool: return n.is_in_group(&"unsafe_ground")),
		"hay plataformas temporales y que se mueven, y ninguna es suelo seguro")


func _test_barrier() -> void:
	await _drop_on(Vector2(400, FLOOR - 8))
	await _frames(4)
	_check(chase.running and chase.barrier.advancing and chase.barrier.position.x <= player.global_position.x - chase.config.barrier_start_gap + 1.0,
		"al cruzar el inicio del tramo 1, la barrera arranca detrás de Kai y el reloj corre")
	_check(chase.barrier.speed >= 80.0, "la barrera es más rápida (%.0f px/s)" % chase.barrier.speed)
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
	var gap := _first_gap()
	await _drop_on(Vector2(gap.x - 30.0, gap.y - 8.0))
	await _frames(20)
	chase.barrier.position.x = player.global_position.x - 600.0
	var before: float = player.health.current
	player.teleport_to(Vector2(gap.x + 20.0, gap.y - 4.0))  # Sobre el vacío.
	await _until(func() -> bool: return player.damage.is_respawning)
	await _until(func() -> bool: return not player.damage.is_respawning)
	await _frames(6)
	_check(is_equal_approx(player.health.current, before - 1.5), "caer al vacío quita exactamente 1,5 (%.1f → %.1f)" % [before, player.health.current])
	_check(player.is_on_floor() and player.global_position.x < gap.x and player.global_position.x > gap.x - 200.0,
		"y Kai reaparece sobre la última plataforma segura (x=%.0f)" % player.global_position.x)
	_check(chase.barrier.position.x <= player.global_position.x - chase.config.barrier_start_gap + 1.0, "y la barrera no le queda encima")
	player.health.restore_full()


func _test_emitters() -> void:
	var emitter := room.get_node("Emitters/Disparo1a") as CorruptEmitter
	await _drop_on(Vector2(emitter.global_position.x - 120.0, FLOOR - 8))
	chase.barrier.position.x = player.global_position.x - 1200.0
	var fired := emitter.shots_fired
	var shot_seen := [false, 0.0]
	var on_node := func(node: Node) -> void:
		if node is DataShot and not shot_seen[0]:
			shot_seen[0] = true
			shot_seen[1] = (node as DataShot).warning
	node_added.connect(on_node)
	await _frames(int(emitter.interval * 60.0) + 20)
	node_added.disconnect(on_node)
	_check(emitter.shots_fired > fired and shot_seen[0] and shot_seen[1] > 0.3, "los nodos corruptos disparan, siempre con aviso")
	var hits := [0]
	player.damage.hurt.connect(func(_hit: HitData) -> void: hits[0] += 1, CONNECT_ONE_SHOT)
	await _until(func() -> bool: return hits[0] > 0)
	_check(hits[0] > 0, "un disparo que toca a Kai le hace daño")
	await _until(func() -> bool: return not player.is_invulnerable() and not player.damage.is_respawning)
	player.health.restore_full()
	for shot in get_nodes_in_group(&"boss_attack"):
		shot.queue_free()


func _test_checkpoint_1() -> void:
	var checkpoint := chase.checkpoints[0]
	_check(checkpoint.gate.active, "la puerta del checkpoint 1 está cerrada")
	# La barrera viene pegada a Kai: al llegar a la zona segura retrocede a una distancia segura.
	await _drop_on(Vector2(checkpoint.safe_from_x + 15.0, FLOOR - 8))
	chase.barrier.position.x = player.global_position.x - 40.0
	await _frames(30)
	_check(chase.paused and not chase.barrier.advancing, "en la zona segura se detienen la barrera y el reloj")
	_check(chase.barrier.position.x <= player.global_position.x - chase.config.barrier_safe_gap + 1.0,
		"y la barrera se queda a una distancia segura detrás de Kai (%.0f px)" % (player.global_position.x - chase.barrier.position.x))
	for shot in get_nodes_in_group(&"boss_attack"):
		shot.queue_free()
	await _walk_to(checkpoint.global_position.x)
	var window := await _window()
	_check(window != null and paused, "al llegar se abre la pregunta y el juego queda en pausa (Kai no recibe daño)")
	var time_before := chase.time_left
	window.choose(_option(window, false))
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
	_check(saves.read_slot(1)["ubicacion"]["punto"] == "checkpoint_1", "se guarda el progreso en el checkpoint 1")
	await _frames(10)
	_check(chase.tramo == 1 and chase.barrier.position.x <= player.global_position.x - chase.config.barrier_safe_gap + 1.0,
		"para el tramo 2, la barrera queda detrás de Kai (nunca delante)")


func _test_time_up() -> void:
	await _drop_on(Vector2(chase.tramo_starts[1] + 30.0, FLOOR - 8))
	await _frames(4)
	_check(chase.running and chase.tramo == 1, "al cruzar el inicio del tramo 2, corre el reloj")
	_check(chase.barrier.position.x < player.global_position.x, "y la barrera está detrás de Kai")
	chase.time_left = 0.2
	var checkpoint_x := chase.checkpoints[0].global_position.x
	await _until(func() -> bool: return absf(player.global_position.x - checkpoint_x) < 40.0 and not player.controls_locked)
	await _frames(4)
	_check(absf(player.global_position.x - checkpoint_x) < 40.0 and chase.time_left >= 120.0 and not chase.running,
		"al agotarse el tiempo, Kai vuelve al checkpoint 1 con tiempo suficiente (%.0f s)" % chase.time_left)


func _test_death() -> void:
	await _drop_on(Vector2(chase.tramo_starts[1] + 30.0, FLOOR - 8))
	await _frames(4)
	chase.time_left = 50.0
	player.health.take_damage(player.health.current - 0.5)
	player.teleport_to(Vector2(chase.barrier.position.x - 10, FLOOR - 8))
	await _until(func() -> bool: return player.damage.is_respawning)
	await _until(func() -> bool: return not player.damage.is_respawning and not player.controls_locked)
	await _frames(6)
	var checkpoint_x := chase.checkpoints[0].global_position.x
	_check(absf(player.global_position.x - checkpoint_x) < 40.0 and chase.time_left >= 120.0 and is_equal_approx(player.health.current, player.health.max_health),
		"si se queda sin vida, reaparece en el checkpoint 1 con la vida llena y tiempo suficiente")


func _test_reload_and_finish() -> void:
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

## El primer hueco del tramo 1 entre dos plataformas del suelo: Vector2(x del borde, y).
func _first_gap() -> Vector2:
	var route: Array = room.get_node("Platforms").get_children().filter(func(n: Node) -> bool: return n.has_meta(&"route"))
	route.sort_custom(func(a: Node, b: Node) -> bool: return int(a.get_meta(&"route")) < int(b.get_meta(&"route")))
	for i in range(1, route.size()):
		var a: DataPlatform = route[i - 1]
		var b: DataPlatform = route[i]
		if a.kind == DataPlatform.Kind.FIXED and b.global_position.x - (a.global_position.x + a.width) >= 50.0 and a.global_position.x > 400.0:
			return Vector2(a.global_position.x + a.width, a.global_position.y)
	return Vector2(500, FLOOR)


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


## Salta hacia la plataforma target (a la derecha); con dash, lo usa en lo más alto del salto.
func _hop_to(target: DataPlatform, use_dash: bool) -> bool:
	Input.action_press("move_right")
	await _press("jump")
	var released := false
	var dashed := not use_dash
	for i in 300:
		await physics_frame
		var pos := player.global_position
		if not dashed and i > 4 and not player.is_on_floor() and player.velocity.y > -40.0:
			Input.action_press("dash")
			await physics_frame
			Input.action_release("dash")
			dashed = true
		var center := target.global_position.x + target.width / 2.0
		if not released and dashed and pos.y < target.global_position.y - 2.0 and pos.x >= center - minf(24.0, target.width / 2.0 - 4.0):
			Input.action_release("move_right")
			released = true
		if i > 6 and player.is_on_floor():
			break
	_release_all()
	await _frames(2)
	var pos := player.global_position
	return absf(pos.y - target.global_position.y) <= 1.0 and pos.x >= target.global_position.x - 8.0 and pos.x <= target.global_position.x + target.width + 8.0


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
