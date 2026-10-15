extends SceneTree
## Prueba automática: Bucle Infinito (Capítulo 2, nivel 4). Las 20 validaciones de
## docs/jefes/BUCLE_INFINITO.md (A.13): ciclo 1 al empezar; un impacto válido suma exactamente 1; no hay
## dos en el mismo ciclo; se puede golpear atacando (golpe arriesgado: energía) y cansado; la fatiga llega
## al terminar el patrón; sin golpe repite el ciclo; cada impacto sube la dificultad; los ataques se
## cancelan al cambiar de estado; siempre hay rutas seguras (una plataforma apagada como mucho y la
## lluvia deja carriles libres); todos los ataques avisan; la colisión del anillo es la que se ve; el
## séptimo termina el combate sin octava transformación; recompensa única; el jefe no sigue activo; el
## fondo queda detrás; la arena entra en la pantalla; reinicio desde el checkpoint; el progreso queda
## marcado; los estados no se traban; y todo funciona con arte provisional (sin texturas).
## Ejecutar: godot --headless --path . --script res://tests/test_bucle.gd

const ARENA := "res://world/zones/simulador/arena_bucle.tscn"
const S := BucleBoss.State

var _failures := 0
var state: Node
var room: Room
var fight: BucleArenaController
var boss: BucleBoss
var hits: Array = []
var transformations := 0
var ignored := 0


func _initialize() -> void:
	Engine.max_physics_steps_per_frame = 1
	Engine.physics_jitter_fix = 0.0
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	root.get_node("SaveManager").new_game(1)
	state.set_flag(&"tutorial_terminado")
	state.set_nullblade_stage(1)  # En el capítulo 2 Kai ya tiene la Nullblade.
	_test_data()
	await _open()
	_test_start()
	await _test_fatigue_and_repeat()
	await _test_key_hits()
	await _test_real_sword()
	await _test_attacks()
	await _test_safe_routes()
	await _test_finish()
	await _test_player_loses()
	await _test_already_won()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


## Los siete ciclos: más ataques, más rápidos y menos descanso; nunca imposibles.
func _test_data() -> void:
	var config := load("res://data/bosses/bucle.tres") as BucleConfig
	_check(config.cycles.size() == 7 and config.key_hits == 7, "siete ciclos y siete impactos clave")
	var harder := true
	for n in range(1, 7):
		var a := config.cycle(n)
		var b := config.cycle(n + 1)
		harder = harder and b.speed > a.speed and b.fatigue_time <= a.fatigue_time and b.attacks.size() >= a.attacks.size() \
			and b.telegraph <= a.telegraph
	_check(harder, "cada ciclo es más difícil: más rápido, menos descanso, igual o más ataques y avisos más cortos")
	var readable := true
	for n in range(1, 8):
		readable = readable and maxf(config.cycle(n).telegraph, config.min_telegraph) >= 0.4 and config.cycle(n).fatigue_time >= 1.5
	_check(readable, "pero siempre con aviso de 0,4 s o más y por lo menos 1,5 s de descanso")
	_check(config.cycle(1).attacks == [&"pulso", &"lluvia"] and config.cycle(7).attacks.size() == 5,
		"las secuencias de la especificación (ciclo 1: pulso y lluvia; ciclo 7: cinco ataques)")
	# La lluvia nunca tapa todos los carriles y siempre deja libre un vecino del carril de Kai.
	var rng := RandomNumberGenerator.new()
	var ok := true
	for seed_value in 300:
		rng.seed = seed_value
		for blocks in range(1, config.rain_lanes + 2):
			var target := seed_value % config.rain_lanes
			var lanes := BucleAttacks.rain_lanes(blocks, config.rain_lanes, config.min_free_lanes, target, rng)
			var free := config.rain_lanes - lanes.size()
			var neighbor_free := false
			for lane in [target - 1, target + 1]:
				if lane >= 0 and lane < config.rain_lanes and not lanes.has(lane):
					neighbor_free = true
			ok = ok and free >= config.min_free_lanes and neighbor_free
	_check(ok, "la lluvia siempre deja %d carriles libres o más (y uno al lado de Kai)" % config.min_free_lanes)


func _test_start() -> void:
	_check(boss.state == S.PREPARE_PATTERN and boss.cycle() == 1 and boss.impacts == 0 and boss.stage == 1,
		"Bucle empieza en el ciclo 1 (anuncia su secuencia)")
	var bar := room.get_node("CombatHUD/BossBar") as BossBar
	_check(bar.title == "BUCLE" and bar.segments == 7 and boss.health.max_health == 7.0,
		"la barra «BUCLE» tiene siete segmentos de integridad")
	var saves := root.get_node("SaveManager")
	_check(fight.gate.active and saves.read_slot(1)["ubicacion"]["punto"] == "inicio",
		"al llegar se cierra la puerta y se registra el checkpoint")
	_check(fight.background.get_index() == 0 and room.room_size.size.x <= 640.0,
		"el fondo queda detrás de todo y la arena entra entera en la pantalla (los peligros siempre se ven)")


## Sin golpes: termina el patrón, se cansa y repite el mismo ciclo.
func _test_fatigue_and_repeat() -> void:
	await _until(func() -> bool: return boss.state == S.EXECUTE_PATTERN)
	_check(boss.state == S.EXECUTE_PATTERN and boss.current_attack == &"pulso", "ejecuta su secuencia (empieza con el Pulso)")
	await _until(func() -> bool: return boss.state == S.FATIGUE)
	_check(boss.state == S.FATIGUE and not boss.contact.active, "al terminar la secuencia queda cansado (y su contacto no daña)")
	await _until(func() -> bool: return boss.state == S.PREPARE_PATTERN)
	_check(boss.cycle() == 1 and boss.repeats == 1 and boss.impacts == 0,
		"si nadie lo golpea, se recupera y repite el mismo ciclo (no sube la dificultad)")


func _test_key_hits() -> void:
	# Golpe mientras ataca: cuenta y es arriesgado (energía).
	await _until(func() -> bool: return boss.state == S.EXECUTE_PATTERN)
	await _frames(20)
	var energy_before: float = room.player.energy
	room.player.set_energy(0.0)
	energy_before = room.player.energy
	_hit()
	await _frames(2)
	_check(boss.impacts == 1 and hits[-1] == [1, true] and is_equal_approx(boss.health.current, 6.0),
		"un golpe mientras ataca cuenta exactamente 1 impacto (golpe arriesgado)")
	_check(room.player.energy > energy_before, "el golpe arriesgado da energía (%.2f → %.2f)" % [energy_before, room.player.energy])
	_check(boss.state == S.HIT_REACTION and get_nodes_in_group(&"boss_attack").all(func(n: Node) -> bool: return n.is_queued_for_deletion()),
		"reacciona y se cancelan sus ataques en curso")
	# Otro golpe en la reacción o la transformación no cuenta.
	_hit()
	await _until(func() -> bool: return boss.state == S.TRANSFORMATION)
	_hit()
	await _frames(2)
	_check(boss.impacts == 1 and ignored >= 2 and boss.stage == 2, "no se registran dos impactos en el mismo ciclo (y se transforma: etapa 2)")
	await _until(func() -> bool: return boss.state == S.PREPARE_PATTERN)
	_check(boss.cycle() == 2 and boss.cycle_data().speed > 1.0 and boss.repeats == 0, "empieza el ciclo 2, más rápido")
	# Golpe cansado: cuenta, sin ser arriesgado.
	await _until(func() -> bool: return boss.state == S.FATIGUE)
	_hit()
	await _frames(2)
	_check(boss.impacts == 2 and hits[-1] == [2, false], "también se le puede golpear cansado")


## Con la Nullblade de verdad (J): parado al lado de Bucle cansado, un tajo cuenta como impacto.
func _test_real_sword() -> void:
	await _until(func() -> bool: return boss.state == S.FATIGUE)
	var player := room.player
	var before := boss.impacts
	player.teleport_to(boss.global_position + Vector2(-22, 8))
	player.facing = 1
	await _frames(3)
	await _action(&"attack")
	await _frames(12)
	_check(boss.impacts == before + 1, "un tajo real de la Nullblade (J) cuenta como impacto clave (%d → %d)" % [before, boss.impacts])
	player.teleport_to(Vector2(80, 296))
	await _frames(2)


func _test_attacks() -> void:
	# Todos los ataques avisan antes de dañar.
	var parent := boss.get_parent()
	var config := boss.config
	var waves := BucleAttacks.pulse(parent, Vector2(320, 304), boss.arena, 200.0, 0.5, 1.0)
	var blocks := BucleAttacks.rain(parent, boss.arena, [1, 4] as Array[int], config.rain_lanes, 300.0, 0.5, 1.0)
	var ring := BucleAttacks.ring(parent, Vector2(320, 282), 150.0, 10.0, 80.0, 0.0, 0.0, 0.5, 1.0)
	await _frames(2)
	var warned := waves.all(func(n: LoopPulse) -> bool: return not n.is_live() and not n.active) \
		and blocks.all(func(n: InstructionBlock) -> bool: return not n.is_live() and not n.active) and not ring.is_live()
	_check(warned, "el Pulso, la Lluvia y el Anillo avisan antes de dañar")
	await _frames(40)
	_check(waves.all(func(n: LoopPulse) -> bool: return not is_instance_valid(n) or n.is_live()) and ring.is_live(), "y después salen")
	# La colisión del anillo es la que se ve: fuera de los huecos golpea, en un hueco no.
	ring.radius = 100.0
	var player := room.player
	player.teleport_to(Vector2(320, 282) + Vector2.from_angle(deg_to_rad(90.0)) * 100.0 + Vector2(0, 11))
	await _frames(2)
	ring._place_shape()
	var in_band := not ring._shape.disabled
	player.teleport_to(Vector2(320, 282) + Vector2(100, 11))
	await _frames(2)
	ring._place_shape()
	var in_gap := ring._shape.disabled
	player.teleport_to(Vector2(320, 282) + Vector2.from_angle(deg_to_rad(90.0)) * 180.0 + Vector2(0, 11))
	await _frames(2)
	ring._place_shape()
	var outside := ring._shape.disabled
	_check(in_band and in_gap and outside, "la colisión del anillo coincide con lo dibujado (golpea en el anillo, no en el hueco ni fuera)")
	BucleAttacks.clear(self)
	player.teleport_to(Vector2(80, 296))
	await _frames(2)


## Error de ejecución: una sola plataforma apagada a la vez.
func _test_safe_routes() -> void:
	var worst := 0
	for k in 3:
		fight._on_execution_error(4)
		await _frames(30)
		var closed := fight.platforms.filter(func(p: DataPlatform) -> bool: return p.is_in_group(&"unsafe_ground") or p.is_closed()).size()
		worst = maxi(worst, closed)
		await _until(func() -> bool: return fight.platforms.all(func(p: DataPlatform) -> bool: return not p.is_closed() and not p.is_in_group(&"unsafe_ground")))
	_check(worst == 1, "el Error de ejecución apaga una sola plataforma por vez (siempre quedan rutas)")


func _test_finish() -> void:
	var ecos_before: int = root.get_node("Economy").ecos
	await _hit_until(7)
	await _until(func() -> bool: return boss.state == S.DEFEATED)
	_check(boss.impacts == 7 and boss.state == S.DEFEATED and is_equal_approx(boss.health.current, 0.0),
		"el séptimo impacto termina el combate")
	_check(transformations == 6 and boss.stage == 7, "sin octava transformación (%d transformaciones)" % transformations)
	_check(is_instance_valid(boss) and boss.visible and state.has_flag(&"cap2_bucle_liberado"), "Bucle no muere: queda en la arena, liberado")
	await _leave_simulator()
	_check(state.has_flag(&"cap2_bucle_vencido") and state.has_flag(&"cap2_condicion_corregida") and state.has_flag(&"cap2_dominio_nulo")
		and state.domain_stage == 1 and not fight.gate.active,
		"queda guardado: jefe vencido, condición de salida corregida, Dominio Nulo I y la puerta abierta")
	_check(root.get_node("Economy").ecos > ecos_before, "da su recompensa")
	await _frames(240)
	_check(boss.state == S.DEFEATED and get_nodes_in_group(&"boss_attack").is_empty(), "y ya no ataca: el jefe no sigue activo")
	# Ganar otra vez no vuelve a pagar.
	state.clear_flag(&"cap2_bucle_vencido")
	await _open()
	ecos_before = root.get_node("Economy").ecos
	await _hit_until(7)
	await _leave_simulator()
	_check(root.get_node("Economy").ecos == ecos_before, "la recompensa no se cobra dos veces")


func _test_player_loses() -> void:
	state.clear_flag(&"cap2_bucle_vencido")
	await _open()
	await _hit_until(3)
	var player := room.player
	player.health.take_damage(player.health.current - 0.5)
	var hit := HitData.new()
	hit.damage = 4.0
	player.damage._on_hit_received(hit)
	await _until(func() -> bool: return not player.damage.is_respawning and not player.controls_locked and boss.state == S.PREPARE_PATTERN)
	await _frames(4)
	_check(boss.impacts == 0 and boss.cycle() == 1 and boss.stage == 1 and fight.phase == BucleArenaController.Phase.FIGHT,
		"si Kai pierde, vuelve al checkpoint y el combate empieza de nuevo en el ciclo 1")
	# Golpes en cualquier momento: el combate nunca se traba.
	var stuck := false
	for i in 6:
		_hit()
		await _frames(7)
		var before := boss.state
		await _until(func() -> bool: return boss.state != before or boss.state == S.DEFEATED)
		stuck = stuck or (boss.state == before and before != S.DEFEATED)
	_check(not stuck, "golpes en cualquier estado no traban la máquina de estados")


func _test_already_won() -> void:
	state.set_flag(&"cap2_bucle_vencido")
	await _open()
	await _frames(10)
	_check(fight.phase == BucleArenaController.Phase.DONE and boss.state == S.DEFEATED and not fight.gate.active
		and room.get_node_or_null("CombatHUD/BossBar") == null, "con el combate ganado, Bucle descansa y la arena queda abierta")


## --- Ayudas ---

## Después del combate el simulador se derrumba (lo prueba test_dominio_nulo): aquí se rompe el muro rápido.
func _leave_simulator() -> void:
	await _until(func() -> bool: return fight.phase == BucleArenaController.Phase.COLLAPSE and state.domain_stage >= 1)
	room.player.domain.activate(true)
	if is_instance_valid(fight.wall):
		fight.wall.health.take_damage(99.0)
	await _until(func() -> bool: return fight.phase == BucleArenaController.Phase.DONE)


func _open() -> void:
	if current_scene:
		current_scene.queue_free()
	await process_frame
	var scene := (load(ARENA) as PackedScene).instantiate()
	(scene.get_node("Fight") as BucleArenaController).skip_cinematics = true
	root.add_child(scene)
	current_scene = scene
	await _frames(6)
	room = scene as Room
	fight = scene.get_node("Fight") as BucleArenaController
	boss = fight.boss
	hits.clear()
	transformations = 0
	ignored = 0
	boss.key_hit.connect(func(count: int, risky: bool) -> void: hits.append([count, risky]))
	boss.transformed.connect(func(_stage: int) -> void: transformations += 1)
	boss.hit_ignored.connect(func() -> void: ignored += 1)
	room.player.health.max_health = 999.0
	room.player.health.restore_full()


## Un toque de la acción (como el teclado): pulsar y soltar.
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


func _hit() -> void:
	boss.hurtbox.hit_received.emit(HitData.new())


## Golpea cada vez que puede hasta llegar a count impactos.
func _hit_until(count: int) -> void:
	while boss.impacts < count:
		await _until(func() -> bool: return boss.is_vulnerable())
		_hit()
		await _frames(2)


func _until(condition: Callable) -> void:
	for i in 1500:
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
