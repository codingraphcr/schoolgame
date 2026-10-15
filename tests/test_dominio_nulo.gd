extends SceneTree
## Prueba automática: el final del Capítulo 2 sin Dominio Nulo y la Expansión Digital: Dominio Nulo I como sistema.
## (Decisión del 15 de octubre de 2026: Dominio Nulo I llega en el Capítulo 3, «Contagio digital».)
## - El derrumbe del simulador después de Bucle: un muro de procesos que se reconstruye bloquea la salida; ni
##   golpeando lo más rápido posible se rompe; Kai atrapa el error en la terminal del muro (try/catch, el desafío
##   «Atrapar el error»), los procesos se detienen y se abre la salida. Kai no obtiene el Dominio Nulo.
## - El Dominio como sistema (cuando la historia lo dé): sin obtenerlo no se ve ni se activa; con él, R lo activa:
##   las amenazas van al 80 % (sin tocar Engine.time_scale ni el HUD), la Nullblade pega un 10 % más y rompe un
##   muro de procesos; a los 15 s se termina; la carga sube 10 por golpe. Todo con golpes reales de la Nullblade.
## Ejecutar: godot --headless --path . --script res://tests/test_dominio_nulo.gd

const ARENA := "res://world/zones/simulador/arena_bucle.tscn"

var _failures := 0
var state: Node
var room: Room
var fight: BucleArenaController
var player: Player


func _initialize() -> void:
	Engine.max_physics_steps_per_frame = 1
	Engine.physics_jitter_fix = 0.0
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	root.get_node("SaveManager").new_game(1)
	state.set_flag(&"tutorial_terminado")
	state.set_nullblade_stage(1)
	# El combate ya se ganó, pero Kai no salió: empieza el derrumbe.
	state.set_flag(&"cap2_bucle_vencido")
	await _open(false)
	await _test_wall_and_escape()
	await _open(true)
	await _test_domain()
	await _test_slowdown_and_charge()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_wall_and_escape() -> void:
	_check(not player.domain.is_unlocked() and not player.domain.can_activate() and not player.domain._hud.visible,
		"en el Capítulo 2 el Dominio Nulo no se ve ni se activa")
	await _until(func() -> bool: return fight.phase == BucleArenaController.Phase.COLLAPSE and fight.wall.is_enabled())
	_check(fight.wall.is_enabled() and player.damage.protected and is_equal_approx(fight.wall.global_position.x, 600.0),
		"el simulador se derrumba: un muro de procesos bloquea la salida (sin peligro)")
	await _advance_dialogues()
	# Golpes reales lo más rápido posible: se reconstruye.
	var rebuilt := [0]
	fight.wall.rebuilt.connect(func() -> void: rebuilt[0] += 1)
	await _attack_wall(5.0)
	_check(is_instance_valid(fight.wall) and not fight.wall.is_dead and rebuilt[0] >= 1,
		"ni golpeando lo más rápido posible se rompe: se reconstruye (%d veces)" % rebuilt[0])
	# La idea de Kai y la terminal del muro.
	var window: ChoiceWindow = null
	for i in 1200:
		window = get_first_node_in_group(&"choice_window") as ChoiceWindow
		if window:
			break
		await _advance_dialogues()
		await _frames(1)
	_check(window != null and window.challenge.id == &"cap2_atrapar_error", "Kai usa la terminal del muro: el desafío «Atrapar el error» (try/catch)")
	if window:
		for q in window.challenge.questions.size():
			var options := window.challenge.questions[window.question_index].options
			for i in options.size():
				if options[i].correct:
					window.choose(i)
			window.next()
	# El mensaje del Grimorio (la pista del capítulo) y el diálogo final.
	for i in 1200:
		if fight.phase == BucleArenaController.Phase.DONE and not DialogueBox.find(room).is_playing():
			break
		var reading := get_first_node_in_group(&"fragment_reading") as FragmentReading
		if reading:
			reading.finish_writing()
			reading.close()
		await _advance_dialogues()
		await _frames(1)
	_check(fight.phase == BucleArenaController.Phase.DONE and state.has_flag(&"cap2_error_atrapado") and not fight.gate.active
		and (not is_instance_valid(fight.wall) or fight.wall.is_dead), "con el error atrapado, los procesos se detienen y se abre la salida")
	_check(state.domain_stage == 0 and not player.domain.is_unlocked(), "Kai no obtiene el Dominio Nulo (llega en el Capítulo 3)")
	_check(state.has_flag(&"cap2_anomalia_vista"), "queda la pista: «arquitectura reconocida»")
	_check(not player.damage.protected, "y Kai vuelve a poder recibir daño")
	var exit := room.get_node("Exits/Salida") as RoomExit
	_check(exit.resolve().get("scene", "") == "res://world/zones/zone0/laboratorio.tscn", "la salida lleva al laboratorio")


func _test_domain() -> void:
	# Cuando la historia lo dé (Capítulo 3), el sistema funciona igual.
	state.set_domain_stage(1)
	await _frames(2)
	_check(player.domain.is_unlocked() and player.domain._hud.visible, "con el Dominio Nulo I obtenido aparece su barra")
	var wall := ProcessWall.new()
	wall.max_health = 4.4  # Como el muro de la arena (calibrado para el Dominio).
	room.add_child(wall)
	wall.global_position = Vector2(600, 304)
	wall.set_enabled(true)
	var rebuilt := [0]
	wall.rebuilt.connect(func() -> void: rebuilt[0] += 1)
	await _attack(wall, 5.0)
	_check(is_instance_valid(wall) and not wall.is_dead and rebuilt[0] >= 1, "sin activarlo, un muro de procesos se reconstruye")
	player.domain.set_charge(player.domain.cost())
	await _frames(2)
	_check(player.domain.can_activate(), "con la carga llena se puede activar")
	await _action(&"ultimate")
	await _frames(2)
	_check(player.domain.active and is_equal_approx(CombatClock.threat_scale, 0.8) and Engine.time_scale == 1.0,
		"con R se activa: las amenazas van al 80 % (Engine.time_scale sigue en 1)")
	_check(is_equal_approx(player.domain.damage_multiplier(), 1.1) and is_equal_approx(player.domain.duration(), 15.0)
		and player.domain.charge() == 0.0, "15 s, +10 % de daño y gasta la carga")
	await _attack(wall, 8.0)
	_check(not is_instance_valid(wall) or wall.is_dead, "con el Dominio, el muro se rompe")
	await _until(func() -> bool: return not player.domain.active)
	_check(not player.domain.active and is_equal_approx(CombatClock.threat_scale, 1.0), "a los 15 s se termina y todo vuelve a su velocidad")


func _test_slowdown_and_charge() -> void:
	# Un proyectil compatible recorre el 80 % con el Dominio.
	var normal := LoopPulse.new()
	normal.telegraph = 0.0
	normal.speed = 200.0
	normal.limit_x = 99999.0
	room.add_child(normal)
	normal.global_position = Vector2(100, 200)
	await _frames(30)
	var moved_normal := normal.global_position.x - 100.0
	normal.queue_free()
	player.domain.set_charge(player.domain.cost())
	player.domain.activate()
	var slow := LoopPulse.new()
	slow.telegraph = 0.0
	slow.speed = 200.0
	slow.limit_x = 99999.0
	room.add_child(slow)
	slow.global_position = Vector2(100, 200)
	var timer_done := [false]
	create_timer(0.4, false, true).timeout.connect(func() -> void: timer_done[0] = true)
	await _frames(30)
	var moved_slow := slow.global_position.x - 100.0
	slow.queue_free()
	_check(absf(moved_slow / moved_normal - 0.8) < 0.03, "los proyectiles compatibles van al 80 %% (%.0f px contra %.0f)" % [moved_slow, moved_normal])
	_check(timer_done[0], "y los temporizadores del juego y la interfaz no se ralentizan")
	player.domain.end()
	# La carga: 10 por golpe de la Nullblade a un enemigo.
	var target := ProcessWall.new()
	target.max_health = 99.0
	room.add_child(target)
	target.global_position = Vector2(300, 304)
	target.set_enabled(true)
	player.domain.set_charge(0.0)
	player.teleport_to(Vector2(278, 304))
	player.facing = 1
	await _frames(4)
	await _action(&"attack")
	await _frames(15)
	_check(is_equal_approx(player.domain.charge(), PlayerDomain.CHARGE_PER_HIT), "cada golpe a un enemigo carga el Dominio (%.0f)" % player.domain.charge())


## --- Ayudas ---

func _attack_wall(seconds: float) -> void:
	if is_instance_valid(fight.wall):
		await _attack(fight.wall, seconds)


## Ataca con la Nullblade, lo más rápido que deja su recarga, durante seconds (o hasta romperlo).
func _attack(target: ProcessWall, seconds: float) -> void:
	player.teleport_to(target.global_position + Vector2(-24, 0))
	player.facing = 1
	await _frames(3)
	var elapsed := 0.0
	while elapsed < seconds and is_instance_valid(target) and not target.is_dead:
		if player.controls_locked:
			await _advance_dialogues()
		await _action(&"attack")
		for i in 3:
			await physics_frame
		elapsed += 4.0 / Engine.physics_ticks_per_second
		player.facing = 1


## Si hay un diálogo, lo pasa entero.
func _advance_dialogues() -> void:
	var box := DialogueBox.find(room)
	for i in 80:
		if box == null or not box.is_playing():
			return
		await _action(&"interact")
		await _frames(3)


func _open(skip: bool) -> void:
	if current_scene:
		current_scene.queue_free()
	await process_frame
	var scene := (load(ARENA) as PackedScene).instantiate()
	(scene.get_node("Fight") as BucleArenaController).skip_cinematics = skip
	(scene.get_node("Fight") as BucleArenaController).try_time = 4.0
	root.add_child(scene)
	current_scene = scene
	await _frames(6)
	room = scene as Room
	fight = scene.get_node("Fight") as BucleArenaController
	player = room.player


func _action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventAction.new()
	release.action = action
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
