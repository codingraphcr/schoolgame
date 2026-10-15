extends SceneTree
## Prueba automática: Expansión Digital: Dominio Nulo I (Capítulo 2, después de Bucle). Sin obtenerlo no
## se ve ni se activa; después del combate el simulador se desestabiliza y un muro de procesos que se
## reconstruye bloquea la salida: sin el Dominio, ni golpeando lo más rápido posible se rompe; Kai
## obtiene el Dominio Nulo I con la carga llena y lo activa con R: las amenazas van al 80 % (sin tocar
## Engine.time_scale ni el HUD), la Nullblade pega un 10 % más, el muro se rompe y se abre la salida; a
## los 15 s se termina; la carga sube 10 por golpe a un enemigo. Todo con golpes reales de la Nullblade.
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
	await _open()
	await _test_locked_then_wall()
	await _test_domain()
	await _test_slowdown_and_charge()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_locked_then_wall() -> void:
	_check(not player.domain.is_unlocked() and not player.domain.can_activate() and not player.domain._hud.visible,
		"antes del capítulo 2 el Dominio Nulo no se ve ni se activa")
	await _until(func() -> bool: return fight.phase == BucleArenaController.Phase.COLLAPSE and fight.wall.is_enabled())
	_check(fight.wall.is_enabled() and player.damage.protected and is_equal_approx(fight.wall.global_position.x, 600.0),
		"el simulador se derrumba: un muro de procesos bloquea la salida (sin peligro)")
	# Sin el Dominio: golpes reales lo más rápido posible. Se reconstruye.
	var rebuilt := [0]
	fight.wall.rebuilt.connect(func() -> void: rebuilt[0] += 1)
	await _attack_wall(5.0)
	_check(is_instance_valid(fight.wall) and not fight.wall.is_dead and rebuilt[0] >= 1,
		"sin el Dominio, ni golpeando lo más rápido posible se rompe: se reconstruye (%d veces)" % rebuilt[0])


func _test_domain() -> void:
	await _until(func() -> bool: return state.domain_stage >= 1 and player.domain.charge() >= player.domain.cost())
	await _frames(2)
	_check(state.domain_stage == 1 and player.domain.is_unlocked() and player.domain._hud.visible,
		"por instinto, Kai obtiene EXPANSIÓN DIGITAL: DOMINIO NULO I (y aparece su barra)")
	_check(player.domain.can_activate() and is_instance_valid(fight._hint), "con la carga llena, se le pide activarlo (R)")
	await _action(&"ultimate")
	await _frames(2)
	_check(player.domain.active and is_equal_approx(CombatClock.threat_scale, 0.8) and Engine.time_scale == 1.0,
		"con R se activa: las amenazas van al 80 % (Engine.time_scale sigue en 1)")
	_check(is_equal_approx(player.domain.damage_multiplier(), 1.1) and is_equal_approx(player.domain.duration(), 15.0)
		and player.domain.charge() == 0.0, "15 s, +10 % de daño y gasta la carga")
	await _attack_wall(8.0)
	await _until(func() -> bool: return fight.phase == BucleArenaController.Phase.DONE)
	_check(fight.phase == BucleArenaController.Phase.DONE and state.has_flag(&"cap2_dominio_nulo") and not fight.gate.active,
		"con el Dominio, el muro se rompe y se abre la salida")
	_check(not player.damage.protected, "y Kai vuelve a poder recibir daño")
	var exit := room.get_node("Exits/Salida") as RoomExit
	_check(exit.resolve().get("scene", "") == "res://world/zones/zone0/laboratorio.tscn", "la salida lleva al laboratorio")
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

## Ataca el muro con la Nullblade, lo más rápido que deja su recarga, durante seconds (o hasta romperlo).
func _attack_wall(seconds: float) -> void:
	if is_instance_valid(fight.wall):
		player.teleport_to(fight.wall.global_position + Vector2(-24, 0))
	player.facing = 1
	await _frames(3)
	var elapsed := 0.0
	while elapsed < seconds and is_instance_valid(fight.wall) and not fight.wall.is_dead:
		await _action(&"attack")
		for i in 3:
			await physics_frame
		elapsed += 4.0 / Engine.physics_ticks_per_second
		player.facing = 1


func _open() -> void:
	if current_scene:
		current_scene.queue_free()
	await process_frame
	var scene := (load(ARENA) as PackedScene).instantiate()
	(scene.get_node("Fight") as BucleArenaController).skip_cinematics = true
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
