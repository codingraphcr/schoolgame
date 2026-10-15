extends SceneTree
## Prueba automática: Bucle Infinito (Capítulo 2, nivel 4). Las 20 validaciones de
## docs/jefes/BUCLE_INFINITO.md (A.13): ciclo 1 al empezar; un impacto válido suma exactamente 1; no hay
## dos en el mismo ciclo; se puede golpear atacando (golpe arriesgado: energía) y cansado; la fatiga llega
## al terminar el patrón; sin golpe repite el ciclo (ciclo infinito: ×2, más rápido y con un ataque más);
## cada impacto sube la dificultad; los ataques se cancelan al cambiar de estado; siempre hay rutas seguras
## (los Errores de ejecución nunca apagan las dos plataformas de los costados y la lluvia, aun desbordada,
## deja carriles libres); todos los ataques avisan (también la Iteración, la Recursión y los mini anillos);
## la colisión del anillo y la del rayo son las que se ven; las tareas pendientes (romperlas todas lo cansa
## antes y por más tiempo); se cansa en distintos lugares; las copias del proceso no reciben golpes; los
## ataques combinados; los ciclos 6 y 7 sin descanso; el séptimo termina el combate sin octava
## transformación; recompensa única; el jefe no sigue activo; el fondo queda detrás; la arena entra en la
## pantalla; reinicio desde el checkpoint; el progreso queda marcado; los estados no se traban; y todo
## funciona con arte provisional (sin texturas).
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
	await _test_no_escape()
	await _test_key_hits()
	await _test_real_sword()
	await _test_no_spam()
	await _test_condition()
	await _test_attacks()
	await _test_safe_routes()
	await _test_high_cycles()
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
	# Con el Desbordamiento: los apilados cuentan como tapados (entre los dos siempre quedan libres).
	ok = true
	var most := config.rain_lanes - config.min_free_lanes
	for seed_value in 300:
		rng.seed = seed_value
		var taken: Array[int] = []
		for i in rng.randi_range(0, most):
			var lane := rng.randi_range(0, config.rain_lanes - 1)
			if not taken.has(lane):
				taken.append(lane)
		var target := rng.randi_range(0, config.rain_lanes - 1)
		var lanes := BucleAttacks.rain_lanes(rng.randi_range(1, config.rain_lanes), config.rain_lanes, config.min_free_lanes, target, rng, taken)
		var covered := taken.duplicate()
		for lane in lanes:
			if not covered.has(lane):
				covered.append(lane)
		var neighbor_was_free := BucleAttacks._free_neighbors(taken, target, config.rain_lanes) > 0
		ok = ok and config.rain_lanes - covered.size() >= config.min_free_lanes \
			and (not neighbor_was_free or BucleAttacks._free_neighbors(covered, target, config.rain_lanes) > 0)
	_check(ok, "con el Desbordamiento, entre los bloques apilados y los que caen siempre quedan carriles libres")
	# Cada ciclo suma algo nuevo (las ideas de Yohann).
	var c := func(n: int) -> BucleCycle: return config.cycle(n)
	_check(c.call(2).attacks.has(&"iteracion") and c.call(3).overflow and c.call(3).condition_nodes >= 2 and c.call(3).roam_fatigue
		and c.call(4).ring_split and c.call(4).iteration_beams == 2 and c.call(5).copies and c.call(5).iteration_split
		and c.call(5).attacks.any(func(a: StringName) -> bool: return String(a).contains("+")),
		"cada ciclo suma algo: Iteración (2), Desbordamiento, tareas y descanso en otro lugar (3), Recursión (4), copias y combinados (5)")
	_check(c.call(6).no_fatigue and c.call(7).no_fatigue and not c.call(5).no_fatigue and c.call(6).error_platforms == 2
		and c.call(7).error_platforms == 2 and c.call(5).error_platforms == 1,
		"los ciclos 6 y 7 no descansan y su Error de ejecución apaga dos plataformas")


func _test_start() -> void:
	_check(boss.state == S.PREPARE_PATTERN and boss.cycle() == 1 and boss.impacts == 0 and boss.stage == 1,
		"Bucle empieza en el ciclo 1 (anuncia su secuencia)")
	var bar := room.get_node("CombatHUD/BossBar") as BossBar
	_check(bar.title == "BUCLE" and bar.segments == 7 and boss.health.max_health == 7.0,
		"la barra «BUCLE» tiene siete segmentos de integridad")
	var saves := root.get_node("SaveManager")
	_check(fight.gate.active and fight.exit_gate.active and saves.read_slot(1)["ubicacion"]["punto"] == "inicio",
		"al llegar se cierra la puerta y se registra el checkpoint")
	_check(fight.background.get_index() == 0 and room.room_size.size.x <= 640.0,
		"el fondo queda detrás de todo y la arena entra entera en la pantalla (los peligros siempre se ven)")
	# El fondo de Ariel: sus cinco plataformas pintadas se pisan, y Bucle está sobre el puente de arriba.
	var platforms := room.get_node("Platforms").get_children().filter(func(p: Node) -> bool: return p is DataPlatform and p.name != "FloorVisual")
	var bridge := room.get_node("Platforms/PlataformaCentral") as DataPlatform
	_check(fight.background.get("picture") != null and platforms.size() == 5 and platforms.all(func(p: DataPlatform) -> bool: return not p.drawn),
		"el fondo es el dibujo de Ariel y sus cinco plataformas se pisan (%d)" % platforms.size())
	_check(absf(boss.global_position.y - (bridge.global_position.y - 5.0)) < 1.0 and boss.global_position.x > bridge.global_position.x
		and boss.global_position.x < bridge.global_position.x + bridge.width and not fight.platforms.has(bridge),
		"Bucle está sobre el puente (el más alto) y el Error de ejecución nunca apaga ese")
	# La hoja de sprites de Ariel: una animación por estado, el color de la etapa y su retrato en los diálogos.
	var anims := ["quieto", "preparar", "onda", "lluvia", "anillo", "dano", "aturdido", "recarga", "derrota"]
	_check(anims.all(func(a: String) -> bool: return not BucleArt.animation("bucle_" + a).is_empty())
		and int(BucleArt.animation("bucle_quieto").frames) == 8 and boss.current_anim() == "preparar",
		"Bucle usa las animaciones de la hoja de Ariel (al anunciar la secuencia: preparar)")
	var bucle_character := load("res://data/characters/bucle.tres") as DialogueCharacter
	_check(bucle_character.portrait != null and boss.get_node("Cuerpo").material is ShaderMaterial,
		"tiene su retrato en los diálogos y el color de cada etapa (shader)")
	var final_text: String = (load("res://data/dialogues/capitulo2/bucle_final.tres") as Dialogue).script_text
	_check(["triste", "preocupado", "asustado"].all(func(e: String) -> bool: return bucle_character.expressions.has(e))
		and final_text.contains("Bucle [triste]"), "sus caras en los diálogos: al perder se pone triste (y al final vuelve a estar feliz)")


## Sin golpes: termina el patrón, se cansa y repite el ciclo (ciclo infinito: ×2, más rápido y con un ataque más).
func _test_fatigue_and_repeat() -> void:
	await _until(func() -> bool: return boss.state == S.EXECUTE_PATTERN)
	_check(boss.state == S.EXECUTE_PATTERN and boss.current_attack == &"pulso", "ejecuta su secuencia (empieza con el Pulso)")
	var base_speed := boss.attack_speed()
	var base_steps := boss.sequence().size()
	await _until(func() -> bool: return boss.state == S.FATIGUE)
	_check(boss.state == S.FATIGUE and not boss.contact.active, "al terminar la secuencia queda cansado (y su contacto no daña)")
	await _until(func() -> bool: return boss.state == S.PREPARE_PATTERN)
	_check(boss.cycle() == 1 and boss.repeats == 1 and boss.impacts == 0 and boss.attack_speed() > base_speed
		and boss.sequence().size() == base_steps + 1,
		"si nadie lo golpea repite el ciclo ×2: más rápido (%.2f → %.2f) y con un ataque más" % [base_speed, boss.attack_speed()])


func _test_key_hits() -> void:
	# Golpe mientras ataca: cuenta y es arriesgado (energía).
	await _until(func() -> bool: return boss.state == S.EXECUTE_PATTERN)
	await _until(func() -> bool: return boss.is_vulnerable())  # Llegó arriba: sin escudo.
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
	# Ciclo 3: se cansa en uno de sus lugares (el puente o una plataforma de los costados).
	await _until(func() -> bool: return boss.is_resting())
	_check(boss.cycle() == 3 and boss.fatigue_spots.has(boss.rest_spot()) and boss.global_position.distance_to(boss.rest_spot()) < 2.0,
		"desde el ciclo 3 se cansa en distintos lugares (ahora en %s)" % boss.rest_spot())
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


## Quedarse pegado a Bucle y pegarle sin parar no lo vence: mientras anuncia tiene escudo (el golpe rebota y
## empuja a Kai), mientras ataca está arriba (un tajo desde el puente no lo alcanza) y solo baja cansado.
func _test_no_spam() -> void:
	var player := room.player
	await _until(func() -> bool: return boss.state == S.PREPARE_PATTERN)
	var before := boss.impacts
	var ignored_before := ignored
	player.teleport_to(boss.global_position + Vector2(-20, 5))
	await _frames(2)
	_hit()
	await _frames(2)
	_check(boss.impacts == before and ignored > ignored_before and player.velocity.x < -100.0,
		"mientras anuncia la secuencia tiene escudo: el golpe no cuenta y Kai sale despedido")
	player.teleport_to(boss.global_position + Vector2(-20, 5))
	await _frames(4)
	var bursts := get_nodes_in_group(&"boss_attack").filter(func(n: Node) -> bool: return n is RepulseBurst)
	_check(not bursts.is_empty() and not (bursts[0] as RepulseBurst).is_live(),
		"si Kai se queda pegado mientras anuncia, Bucle suelta una repulsión (con aviso antes de dañar)")
	await _until(func() -> bool: return boss.state == S.EXECUTE_PATTERN)
	await _frames(40)
	_check(boss.global_position.y <= boss.hover_y - boss.rise + 4.0, "mientras ataca sube (y=%.0f): hay que saltar para alcanzarlo" % boss.global_position.y)
	var bridge := room.get_node("Platforms/PlataformaCentral") as DataPlatform
	player.teleport_to(Vector2(boss.global_position.x - 20.0, bridge.global_position.y))
	player.facing = 1
	await _frames(3)
	await _action(&"attack")
	await _frames(12)
	_check(boss.impacts == before, "un tajo parado en el puente, al lado, no lo alcanza mientras ataca")
	await _until(func() -> bool: return boss.is_resting())
	_check(boss.global_position.y > boss.hover_y - 2.0 and boss.global_position.distance_to(boss.rest_spot()) < 2.0,
		"cansado baja (al puente o a una plataforma de un costado): la ventana para golpearlo")
	# Nunca se cansa dos veces seguidas en el mismo lugar ni en una plataforma apagada.
	var spots: Array[Vector2] = []
	var repeated := false
	for i in 20:
		var spot := boss._pick_rest()
		repeated = repeated or (not spots.is_empty() and spots[-1] == spot)
		spots.append(spot)
	var distinct := {}
	for spot in spots:
		distinct[spot] = true
	_check(not repeated and distinct.size() >= 3, "el lugar donde se cansa va cambiando (%d lugares distintos)" % distinct.size())
	player.teleport_to(Vector2(80, 296))
	await _frames(2)


## Romper la condición: las tareas pendientes aparecen sobre plataformas encendidas; rotas todas, la secuencia
## se corta y se cansa por más tiempo; si no, descansa muy poco.
func _test_condition() -> void:
	await _until(func() -> bool: return boss.state == S.PREPARE_PATTERN)
	_check(boss.cycle() == 4 and boss.repeats >= 1, "ciclo infinito: el contador sube (×%d)" % (boss.repeats + 1))
	await _until(func() -> bool: return boss.state == S.EXECUTE_PATTERN)
	await _frames(2)
	var tasks := boss.tasks.duplicate()
	_check(tasks.size() == boss.cycle_data().condition_nodes and tasks.all(func(t: PendingTask) -> bool:
		return boss.task_spots.has(t.global_position) and boss._ground_open(t.global_position)),
		"aparecen %d tareas pendientes, sobre plataformas encendidas" % tasks.size())
	for task: PendingTask in tasks:
		task._hurt.hit_received.emit(HitData.new())
		await _frames(2)
	_check(boss.state == S.FATIGUE and boss.condition_met
		and boss._state_left > boss.cycle_data().fatigue_time + boss.config.condition_bonus - 0.1
		and get_nodes_in_group(&"boss_attack").all(func(n: Node) -> bool: return n.is_queued_for_deletion()),
		"rotas todas: la condición se cumple, la secuencia se corta y se cansa por más tiempo")
	await _until(func() -> bool: return boss.state == S.EXECUTE_PATTERN)
	await _until(func() -> bool: return boss.state == S.FATIGUE)
	_check(not boss.condition_met and boss._state_left <= boss.config.unbroken_fatigue + 0.01,
		"si no las rompe, descansa muy poco (%.1f s)" % boss.config.unbroken_fatigue)


func _test_attacks() -> void:
	# Bucle queda quieto (su secuencia se corta) para que sus ataques no se mezclen.
	await _freeze_boss()
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
	# Iteración: avisa, y su colisión deja libre justo el hueco (abajo al salir, arriba pasada la mitad).
	var beam := BucleAttacks.iteration(parent, -6.0, 646.0, 0.0, 304.0, 200.0, 280.0, 178.0, config.iteration_gap, 0.5, 1.0)
	await _frames(2)
	var beam_warned := not beam.is_live() and not beam.active
	await _frames(40)
	var top := beam._top
	var top_edge := top.global_position.y + (top.shape as RectangleShape2D).size.y / 2.0
	_check(beam_warned and beam.is_live() and not top.disabled and beam._bottom.disabled
		and absf(top_edge - (280.0 - config.iteration_gap / 2.0)) < 1.0 and is_equal_approx(beam.gap_at(-6.0), 280.0)
		and is_equal_approx(beam.gap_at(646.0), 178.0),
		"la Iteración avisa y deja libre el hueco (abajo en la primera mitad, a la altura del puente en la segunda)")
	BucleAttacks.clear(self)
	await _frames(2)
	# Desbordamiento: el bloque se queda apilado (y sigue dañando); el siguiente cae encima.
	var first := BucleAttacks.rain(parent, boss.arena, [2] as Array[int], config.rain_lanes, 600.0, 0.4, 1.0, 1.5, 2)
	await _until(func() -> bool: return first[0].is_landed())
	var second := BucleAttacks.rain(parent, boss.arena, [2] as Array[int], config.rain_lanes, 600.0, 0.4, 1.0, 1.5, 2)
	_check(first[0].active and BucleAttacks.stacked_lanes(self).has(2)
		and is_equal_approx(second[0].floor_y, boss.arena.end.y - InstructionBlock.HEIGHT),
		"Desbordamiento: los bloques se quedan apilados en el suelo (dañan) y el siguiente cae encima")
	await _frames(150)
	_check(not is_instance_valid(first[0]) and BucleAttacks.stacked_lanes(self).is_empty(), "y al rato se rompen")
	# Recursión: el anillo, lejos, se divide en anillos chicos que vuelven (con aviso).
	var split := BucleAttacks.ring(parent, Vector2(320, 150), 300.0, 10.0, 80.0, 0.0, 0.0, 0.4, 1.0)
	split.split_radius = 60.0
	split.split_count = config.split_count
	var split_ref: WeakRef = weakref(split)
	await _until(func() -> bool: return split_ref.get_ref() == null)
	var shards := get_nodes_in_group(&"boss_attack").filter(func(n: Node) -> bool: return n is MiniLoop and (n as Node2D).global_position.distance_to(Vector2(320, 150)) < 80.0)
	var returning := func(s: MiniLoop) -> bool: return not s.is_live() and s.direction.dot(Vector2(320, 150) - s.global_position) > 0.0
	_check(shards.size() == config.split_count and shards.all(returning),
		"Recursión: el anillo se divide en %d anillos chicos que avisan y vuelven hacia Bucle" % shards.size())
	BucleAttacks.clear(self)
	await _frames(2)
	_resume_boss()


## Error de ejecución: una plataforma (ciclos 4 y 5) o dos (6 y 7), nunca las dos de los costados (la ruta al
## puente). Bucle queda quieto mientras tanto (sus propios errores no se mezclan).
func _test_safe_routes() -> void:
	boss.ai_enabled = false
	var all_open := func() -> bool: return fight.platforms.all(func(p: DataPlatform) -> bool: return fight._is_open(p))
	var exact := true
	var route := true
	for count in [1, 2]:
		for k in 4:
			await _until(all_open)
			for i in count:
				fight._close_one()
			await _frames(30)
			var closed := fight.platforms.filter(func(p: DataPlatform) -> bool: return not fight._is_open(p)).size()
			exact = exact and closed == count
			route = route and fight.essential.any(func(p: DataPlatform) -> bool: return fight._is_open(p))
	await _until(all_open)
	_check(exact and route, "el Error de ejecución apaga una o dos plataformas, pero nunca las dos de los costados (siempre hay ruta al puente)")
	boss.ai_enabled = true


## Ciclos altos: copias del proceso (solo el verdadero recibe golpes), ataques combinados y, en el 6 y el 7,
## sin descanso y con dos plataformas apagadas.
func _test_high_cycles() -> void:
	await _hit_until(4)
	await _until(func() -> bool: return boss.state == S.EXECUTE_PATTERN and boss.cycle() == 5)
	await _frames(2)
	var copies := boss.clones.duplicate()
	var apart := func(k: BucleClone) -> bool: return is_instance_valid(k) and absf(k.global_position.x - boss.global_position.x) > 40.0
	_check(copies.size() == 2 and copies.all(apart), "ciclo 5: aparecen dos copias del proceso, lejos del verdadero")
	await _until(func() -> bool: return boss.current_attack == &"lluvia" or boss.state != S.EXECUTE_PATTERN)
	await _frames(3)
	var live := get_nodes_in_group(&"boss_attack")
	_check(live.any(func(n: Node) -> bool: return n is InstructionBlock) and live.any(func(n: Node) -> bool: return n is LoopPulse)
		and live.any(func(n: Node) -> bool: return n is MiniLoop), "ataques combinados: la lluvia y el pulso a la vez (y las copias tiran mini anillos)")
	await _until(func() -> bool: return boss.is_vulnerable())
	var before := boss.impacts
	var ignored_before := ignored
	var copy: BucleClone = boss.clones[0]
	var copy_hurtbox: HurtboxComponent = copy.get_children().filter(func(n: Node) -> bool: return n is HurtboxComponent)[0]
	copy_hurtbox.hit_received.emit(HitData.new())
	await _frames(2)
	_check(boss.impacts == before and ignored > ignored_before and boss.state == S.EXECUTE_PATTERN,
		"golpear a una copia no cuenta (solo el verdadero recibe golpes)")
	_hit()
	await _frames(2)
	_check(boss.impacts == before + 1 and boss.clones.is_empty(), "al verdadero sí, y las copias desaparecen")
	# Ciclo 6: sin descanso y dos plataformas apagadas.
	await _until(func() -> bool: return boss.state == S.EXECUTE_PATTERN and boss.cycle() == 6)
	await _frames(2)
	var closed := fight.platforms.filter(func(p: DataPlatform) -> bool: return not fight._is_open(p)).size()
	_check(closed >= 2 and fight.essential.any(func(p: DataPlatform) -> bool: return fight._is_open(p)),
		"ciclo 6: el Error de ejecución apaga dos plataformas (pero queda ruta al puente)")
	var seen := [false]
	var watch := func(next: int) -> void:
		if next == S.FATIGUE:
			seen[0] = true
	boss.state_changed.connect(watch)
	await _until(func() -> bool: return boss.state == S.PREPARE_PATTERN)
	boss.state_changed.disconnect(watch)
	_check(not seen[0] and boss.cycle() == 6 and boss.repeats == 1,
		"ciclos 6 y 7 sin descanso: al terminar la secuencia empieza otra (×2); solo se le gana con golpes arriesgados")


func _test_finish() -> void:
	var ecos_before: int = root.get_node("Economy").ecos
	await _hit_until(7)
	await _until(func() -> bool: return boss.state == S.DEFEATED)
	_check(boss.impacts == 7 and boss.state == S.DEFEATED and is_equal_approx(boss.health.current, 0.0),
		"el séptimo impacto termina el combate")
	_check(transformations == 6 and boss.stage == 7, "sin octava transformación (%d transformaciones)" % transformations)
	_check(is_instance_valid(boss) and boss.visible and state.has_flag(&"cap2_bucle_liberado"), "Bucle no muere: queda en la arena, liberado")
	await _leave_simulator()
	_check(state.has_flag(&"cap2_bucle_vencido") and state.has_flag(&"cap2_condicion_corregida") and state.has_flag(&"cap2_simulador_terminado")
		and not fight.gate.active and not fight.exit_gate.active and not fight.has_node("../MuroDeProcesos"),
		"queda guardado: jefe vencido, condición de salida corregida y la puerta abierta (sin derrumbe ni muro)")
	_check(state.domain_stage == 0 and not room.player.domain.is_unlocked(), "vencer a Bucle no da el Dominio Nulo I (se consigue más adelante)")
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
	_check(fight.phase == BucleArenaController.Phase.DONE and boss.state == S.DEFEATED and not fight.gate.active and not fight.exit_gate.active
		and room.get_node_or_null("CombatHUD/BossBar") == null, "con el combate ganado, Bucle descansa y la arena queda abierta")


## --- Ayudas ---

## Después del combate: el puzle (salteado en las pruebas), la pista y la salida abierta.
func _leave_simulator() -> void:
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


## Corta la secuencia de Bucle y lo deja quieto (para probar ataques sueltos sin que se mezclen los suyos).
func _freeze_boss() -> void:
	boss.ai_enabled = false
	boss._epoch += 1
	BucleAttacks.clear(self)
	await _frames(1)


## Vuelve a empezar desde el anuncio de su secuencia.
func _resume_boss() -> void:
	boss.ai_enabled = true
	boss._enter(S.PREPARE_PATTERN)


## Durante la pelea no se puede salir de la arena: ni caminando por la derecha (la salida al laboratorio) ni
## saltando desde los pilares por encima de las barreras.
func _test_no_escape() -> void:
	var player := room.player
	var escaped := false
	for side: Array in [[Vector2(600, 196), &"move_right"], [Vector2(36, 196), &"move_left"]]:
		player.teleport_to(side[0])
		await _frames(3)
		Input.action_press(side[1])
		for i in 90:
			if i % 20 == 0:
				Input.action_press(&"jump")
			elif i % 20 == 12:
				Input.action_release(&"jump")
			await _frames(1)
			escaped = escaped or current_scene != room or player.global_position.x > 628.0 or player.global_position.x < 12.0
		Input.action_release(side[1])
		Input.action_release(&"jump")
	_check(not escaped and current_scene == room, "durante la pelea no se puede salir por ningún lado (ni saltando desde los pilares)")
	player.teleport_to(Vector2(80, 296))
	await _frames(2)
