extends SceneTree
## Prueba automática: Expansión Digital: Dominio Nulo I (la habilidad; dónde se obtiene está por definir: ya no
## en la pelea con Bucle, que lo comprueba test_bucle). Sin obtenerlo no se ve ni se activa; obtenido y con la
## carga llena, R lo activa: las amenazas van al 80 % (sin tocar Engine.time_scale ni el HUD), la Nullblade pega
## un 10 % más y gasta la carga; a los 15 s se termina; la carga sube 10 por golpe a un enemigo. Con golpes reales.
## Ejecutar: godot --headless --path . --script res://tests/test_dominio_nulo.gd

const ROOM := "res://tests/fixtures/combat_test_room.tscn"
const ENEMY := preload("res://characters/enemies/weak_password/weak_password.tscn")

var _failures := 0
var state: Node
var room: Room
var player: Player


func _initialize() -> void:
	Engine.max_physics_steps_per_frame = 1
	Engine.physics_jitter_fix = 0.0
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	state.reset()
	state.set_flag(&"tutorial_terminado")
	state.set_nullblade_stage(1)
	change_scene_to_file(ROOM)
	await _until(func() -> bool: return current_scene is Room and current_scene.is_node_ready())
	await _frames(6)
	room = current_scene as Room
	player = room.player
	player.damage.protected = true
	await _test_locked()
	await _test_domain()
	await _test_slowdown_and_charge()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_locked() -> void:
	player.domain.set_charge(player.domain.cost())
	await _action(&"ultimate")
	await _frames(2)
	_check(not player.domain.is_unlocked() and not player.domain.can_activate() and not player.domain.active and not player.domain._hud.visible,
		"sin obtenerlo, el Dominio Nulo no se ve ni se activa")


func _test_domain() -> void:
	state.set_domain_stage(1)
	player.domain.set_charge(player.domain.cost())
	await _frames(2)
	_check(player.domain.is_unlocked() and player.domain._hud.visible and player.domain.can_activate(),
		"obtenido (Dominio Nulo I) aparece su barra y, con la carga llena, se puede activar")
	await _action(&"ultimate")
	await _frames(2)
	_check(player.domain.active and is_equal_approx(CombatClock.threat_scale, 0.8) and Engine.time_scale == 1.0,
		"con R se activa: las amenazas van al 80 % (Engine.time_scale sigue en 1)")
	_check(is_equal_approx(player.domain.damage_multiplier(), 1.1) and is_equal_approx(player.domain.duration(), 15.0)
		and player.domain.charge() == 0.0, "15 s, +10 % de daño y gasta la carga")
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
	var target := ENEMY.instantiate() as EnemyBase
	target.ai_enabled = false
	target.gravity = 0.0
	target.max_health = 99.0
	room.add_child(target)
	target.global_position = Vector2(300, 304)
	player.domain.set_charge(0.0)
	player.teleport_to(Vector2(278, 304))
	player.facing = 1
	await _frames(4)
	await _action(&"attack")
	await _frames(15)
	_check(is_equal_approx(player.domain.charge(), PlayerDomain.CHARGE_PER_HIT), "cada golpe a un enemigo carga el Dominio (%.0f)" % player.domain.charge())



## --- Ayudas ---

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
