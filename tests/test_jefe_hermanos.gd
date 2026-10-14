extends SceneTree
## Prueba automática: Capítulo 1, etapas 7 a 11 (Glitch y Chip, diseño de Ariel). La arena registra el
## checkpoint y no tiene temporizador; los dos comparten una sola barra de vida; sus 8 ataques
## individuales y los 6 en conjunto avisan antes; cuando uno queda aturdido el otro deja su ataque y
## lo protege; las tres fases (el anillo y la segunda melodía en la Fase 2, la fase segura con la
## terminal al 35 % y el Protocolo Dual / Furia fraternal); con la vida en cero quedan neutralizados
## (no se borran); la recompensa se cobra una sola vez; si Kai pierde, la pelea vuelve a empezar; con
## la pelea ganada, la arena queda abierta.
## Ejecutar: godot --headless --path . --script res://tests/test_jefe_hermanos.gd

const ARENA := "res://world/zones/red_entrenamiento/arena_hermanos.tscn"
const QUEST := &"travesuras_en_el_sistema"

var _failures := 0
var state: Node
var room: Room
var fight: DualBossController
var chip: ChipBoss
var glitch: GlitchBoss
var events: Array = []


func _initialize() -> void:
	Engine.max_physics_steps_per_frame = 1
	Engine.physics_jitter_fix = 0.0
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	root.get_node("SaveManager").new_game(1)
	state.set_flag(&"tutorial_terminado")
	state.start_quest(QUEST)
	for step in [&"revisar_servidor", &"seguirlos_adentro"]:
		state.complete_step(QUEST, step)
	await _open()
	_test_start()
	fight.set_physics_process(false)  # Los ataques los lanza la prueba, uno por uno.
	room.player.damage.protected = true
	await _test_individual()
	await _test_joint()
	await _test_protect()
	fight.set_physics_process(true)
	await _test_phases()
	await _test_victory()
	await _test_player_loses()
	await _test_already_won()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_start() -> void:
	var saves := root.get_node("SaveManager")
	_check(state.get_current_step(QUEST) == &"vencer_hermanos" and saves.read_slot(1)["ubicacion"]["punto"] == "desde_persecucion",
		"al llegar a la arena se registra el checkpoint y la misión pide detener a los hermanos")
	_check(room.get_node_or_null("CombatHUD/ChaseTimer") == null, "el combate no tiene temporizador")
	_check(fight.phase == DualBossController.Phase.FIGHT and fight.gate.active and fight.fight_phase == 1, "empieza la pelea (Fase 1) con la puerta cerrada")
	_check(chip.health == glitch.health and chip.health == fight.health and fight.health.max_health == fight.config.shared_health,
		"Glitch y Chip comparten la vida (%.0f)" % fight.health.max_health)
	var bar := room.get_node("CombatHUD/BossBar") as BossBar
	_check(bar.title == "GLITCH & CHIP" and room.get_node_or_null("CombatHUD/BossBar2") == null, "una sola barra: «GLITCH & CHIP»")
	_check(is_equal_approx(bar.phase_mark, fight.config.phase2_at) and bar.phase_marks == [fight.config.phase3_at], "la barra marca las fases (70 % y 35 %)")
	var before := fight.health.current
	_hit(chip, 1.0)
	_hit(glitch, 1.0)
	_check(is_equal_approx(fight.health.current, before - 2.0) and bar.ratio() < 1.0, "pegarle a cualquiera de los dos baja la misma barra")
	fight.health.restore_full()
	_check(SiblingArt.texture(&"glitch") != null and SiblingArt.texture(&"chip") != null and SiblingArt.texture(&"disco") != null,
		"Glitch, Chip y el disco usan los sprites de la hoja de Ariel")


## Los 8 ataques individuales: cada uno avisa antes y hace lo suyo.
func _test_individual() -> void:
	# Glitch 1. Corte acelerado: aviso y después el dash rápido.
	await _ready_for_next()
	var fast := [-1.0]
	await _run_pattern(&"corte_acelerado", 2.5, func() -> void:
		if fast[0] < 0.0 and absf(glitch.velocity.x) >= glitch.config.glitch_cut_speed * 0.9:
			fast[0] = _now())
	_check(fast[0] >= 0.0 and fast[0] - _first_time(glitch, &"corte_acelerado") >= glitch.config.glitch_cut_telegraph - 0.05,
		"Glitch · Corte acelerado: dash rápido después del aviso (%.2f s)" % (fast[0] - _first_time(glitch, &"corte_acelerado")))
	# Glitch 2. Salto en picada: marca el piso y cae.
	await _ready_for_next()
	var marked := [false]
	var high := [INF]
	await _run_pattern(&"salto_en_picada", 3.5, func() -> void:
		high[0] = minf(high[0], glitch.global_position.y)
		if glitch._dive_mark != Vector2.INF:
			marked[0] = true)
	_check(marked[0] and high[0] < SiblingBoss.FLOOR_Y - 60.0 and glitch.is_on_floor(), "Glitch · Salto en picada: sube, marca dónde cae y cae")
	# Glitch 3. Embestida en cadena: varios avisos seguidos.
	await _ready_for_next()
	await _run_pattern(&"embestida_en_cadena", 4.0)
	_check(_count(glitch, &"embestida_en_cadena") == glitch.config.glitch_chain_dashes, "Glitch · Embestida en cadena: %d dashes" % _count(glitch, &"embestida_en_cadena"))
	# Glitch 4. Lanzamiento de fragmentos: cuchillas rosas en abanico.
	await _ready_for_next()
	var blades := _counter(func(n: Node) -> bool: return n is DataShot and n.blade)
	await _run_pattern(&"lanzamiento_de_fragmentos", 2.0)
	_check(blades.call() == glitch.config.glitch_fragments, "Glitch · Lanzamiento de fragmentos: %d cuchillas" % blades.call())
	# Chip 1. Discos orbitales: discos que vuelven.
	await _ready_for_next()
	var discs := _counter(func(n: Node) -> bool: return n is DiscShot)
	await _run_pattern(&"discos_orbitales", 1.2)
	_check(discs.call() >= 1, "Chip · Discos orbitales: lanza discos")
	await _until(func() -> bool: return _attacks(DiscShot).is_empty())
	_check(_attacks(DiscShot).is_empty(), "los discos vuelven a Chip y desaparecen")
	# Chip 2. Zona de control: ralentiza a Kai mientras está adentro.
	await _ready_for_next()
	await _run_pattern(&"zona_de_control", 0.6)
	var zones := _attacks(ControlZone)
	_check(zones.size() == 1, "Chip · Zona de control: aparece el campo")
	if zones.size() == 1:
		var zone := zones[0] as ControlZone
		await _until(func() -> bool: return zone.is_active())
		room.player.teleport_to(zone.global_position)
		await _frames(4)
		_check(room.player.speed_scale < 1.0, "adentro, Kai va más lento (%.2f)" % room.player.speed_scale)
		room.player.teleport_to(zone.global_position + Vector2(zone.width, 0))
		await _frames(4)
		_check(room.player.speed_scale == 1.0, "afuera, vuelve a su velocidad")
		zone.queue_free()
		room.player.teleport_to(Vector2(120, 304))
	# Chip 3. Proyecciones: copias que lanzan un disco; un golpe las deshace.
	await _ready_for_next()
	var copies_seen := _counter(func(n: Node) -> bool: return n is ChipCopy)
	await _run_pattern(&"proyecciones", 0.9)
	var copies := _attacks(ChipCopy)
	_check(copies_seen.call() == chip.config.chip_copies, "Chip · Proyecciones: %d copias" % copies_seen.call())
	if not copies.is_empty():
		(copies[0] as ChipCopy).pop()
		await _frames(2)
		_check(not is_instance_valid(copies[0]), "un golpe deshace una copia")
	await _play(2.5)
	# Chip 4. Rayo de sincronía: línea de aviso y después el rayo.
	await _ready_for_next()
	var beams := _counter(func(n: Node) -> bool: return n is SyncBeam)
	fight.start_pattern(&"rayo_de_sincronia")
	await _until(func() -> bool: return not _attacks(SyncBeam).is_empty())
	var beam := _attacks(SyncBeam)
	_check(beams.call() == 1 and not (beam[0] as SyncBeam).active, "Chip · Rayo de sincronía: primero solo la línea de aviso")
	await _until(func() -> bool: return not is_instance_valid(beam[0]) or (beam[0] as SyncBeam).active)
	_check(is_instance_valid(beam[0]) and (beam[0] as SyncBeam).active, "y después el rayo")
	await _until(func() -> bool: return not chip.busy)


## Los 6 ataques en conjunto: participan los dos.
func _test_joint() -> void:
	# 1. Intercepción cruzada: desde lados opuestos.
	await _ready_for_next()
	room.player.teleport_to(Vector2(320, 304))
	var opposite := [false]
	await _run_pattern(&"intercepcion_cruzada", 3.0, func() -> void:
		if glitch.is_telegraphing() and chip.is_telegraphing():
			opposite[0] = signf(glitch.global_position.x - 320.0) != signf(chip.global_position.x - 320.0))
	_check(opposite[0] and _kinds(glitch).has(&"corte_acelerado") and _kinds(chip).has(&"discos_orbitales"), "Intercepción cruzada: atacan desde lados opuestos")
	# 2. Corte y respuesta: Glitch inicia, Chip completa.
	await _ready_for_next()
	await _run_pattern(&"corte_y_respuesta", 4.0)
	_check(_first_time(glitch, &"corte_acelerado") >= 0.0 and _first_time(chip, &"rayo_de_sincronia") > _first_time(glitch, &"corte_acelerado"),
		"Corte y respuesta: Glitch corta y Chip completa con el rayo")
	# 3. Sincronización aérea: los dos saltan y atacan en el aire.
	await _ready_for_next()
	var both_up := [false]
	await _run_pattern(&"sincronizacion_aerea", 4.0, func() -> void:
		if glitch.global_position.y < SiblingBoss.FLOOR_Y - 20.0 and chip.global_position.y < SiblingBoss.FLOOR_Y - 20.0:
			both_up[0] = true)
	_check(both_up[0], "Sincronización aérea: los dos atacan desde el aire")
	# 4. Cambio de posición: se intercambian de lugar en plena secuencia.
	await _ready_for_next()
	var glitch_x := glitch.global_position.x
	var chip_x := chip.global_position.x
	var swapped := [false]
	await _run_pattern(&"cambio_de_posicion", 4.0, func() -> void:
		if not swapped[0] and absf(glitch.global_position.x - chip_x) < 30.0 and absf(chip.global_position.x - glitch_x) < 30.0:
			swapped[0] = true)
	_check(swapped[0], "Cambio de posición: se intercambian de lugar")
	# 5. Cadena de proyecciones: copias de Chip mientras Glitch presiona.
	await _ready_for_next()
	var copies := _counter(func(n: Node) -> bool: return n is ChipCopy)
	await _run_pattern(&"cadena_de_proyecciones", 4.0)
	_check(copies.call() >= 2 and _count(glitch, &"embestida_en_cadena") >= 2, "Cadena de proyecciones: copias de Chip y embestidas de Glitch")
	# 6. Campo Dual: el piso peligroso salvo un hueco, lejos de Kai.
	await _ready_for_next()
	room.player.teleport_to(Vector2(120, 304))
	var fields := _counter(func(n: Node) -> bool: return n is DualField)
	fight.start_pattern(&"campo_dual")
	await _until(func() -> bool: return not _attacks(DualField).is_empty())
	var field := _attacks(DualField)
	_check(fields.call() == 1 and not (field[0] as DualField).is_safe(120.0) and (field[0] as DualField).is_safe((field[0] as DualField).gap_x),
		"Campo Dual: todo el piso menos un hueco seguro, lejos de Kai")
	await _until(func() -> bool: return not glitch.busy and not chip.busy and not fight._running)


## El vínculo: si uno queda aturdido, el otro deja su ataque y lo protege.
func _test_protect() -> void:
	await _ready_for_next()
	fight.start_pattern(&"discos_orbitales")
	await _until(func() -> bool: return chip.is_telegraphing())
	for i in glitch.config.stagger_hits:
		_hit(glitch, 0.1)
		await _frames(1)
	_check(glitch.stunned, "%d golpes seguidos dejan a Glitch aturdido" % glitch.config.stagger_hits)
	await _frames(2)
	_check(chip.guarding == glitch and not chip.busy, "Chip abandona su ataque para proteger a Glitch")
	_check(chip.hurtbox.immune, "Chip lo cubre con su escudo de discos (los golpes rebotan)")
	await _play(0.6)
	_check(absf(chip.global_position.x - chip.guard_x()) < 12.0, "Chip se para entre Kai y Glitch")
	await _until(func() -> bool: return not glitch.stunned)
	await _frames(2)
	_check(not glitch.stunned and chip.guarding == null and not chip.hurtbox.immune, "Glitch se recupera y Chip deja de protegerlo")
	# Al revés: Chip aturdido, Glitch lo protege.
	await _ready_for_next()
	for i in chip.config.stagger_hits:
		_hit(chip, 0.1)
		await _frames(1)
	await _frames(2)
	_check(chip.stunned and glitch.guarding == chip, "si Chip queda aturdido, Glitch lo protege")
	await _until(func() -> bool: return not chip.stunned)
	await _frames(2)
	_check(glitch.guarding == null, "y lo suelta cuando Chip se recupera")
	fight.health.restore_full()


## Las tres fases.
func _test_phases() -> void:
	await _until(func() -> bool: return not fight._running)
	var first := fight.patterns_done.size()
	await _play(6.0)
	var started := fight.patterns_done.slice(first)
	_check(started.size() >= 2 and started[0] in DualBossController.PHASE1 and started[1] in DualBossController.PHASE1,
		"Fase 1 · Reconocimiento: sigue su secuencia (%s)" % [started])
	fight.health.take_damage(fight.health.current - fight.health.max_health * 0.69)
	await _frames(2)
	_check(fight.fight_phase == 2 and fight.chamber.active and Music.layer_on, "al 70 %: Fase 2 · Sincronización (se activa el anillo y la segunda melodía)")
	await _until(func() -> bool: return fight.patterns_done[-1] in DualBossController.PHASE2)
	_check(fight.patterns_done[-1] in DualBossController.PHASE2, "en la Fase 2 usan su secuencia (%s)" % fight.patterns_done[-1])
	fight.health.take_damage(fight.health.current - fight.health.max_health * 0.34)
	await _frames(4)
	_check(fight.phase == DualBossController.Phase.SAFE and chip.shielded and chip.frozen and glitch.frozen and room.player.damage.protected,
		"al 35 %: Chip levanta su escudo y empieza la fase segura")
	await _until(func() -> bool: return is_instance_valid(fight.terminal))
	_check(is_instance_valid(fight.terminal) and fight.terminal.challenge.id == &"cap1_escudo_chip", "aparece la terminal del escudo")
	var interpreter := fight.terminal.challenge.create_interpreter()
	_check(String(interpreter.execute("cat escudo.cfg")["output"]).contains("escritura para todos") and not interpreter.execute("rm escudo.cfg")["ok"],
		"la terminal muestra la configuración insegura (y solo deja leer)")
	fight.terminal.solved.emit()
	var window := await _window()
	_check(window != null and window.challenge.id == &"cap1_escudo_chip", "después hay que elegir la corrección")
	window.choose(_option(window, false))
	window.choose(_option(window, true))
	window.next()
	await _until(func() -> bool: return fight.phase == DualBossController.Phase.FIGHT)
	_check(not chip.shielded and not chip.frozen and fight.fight_phase == 3, "con el mínimo privilegio, el escudo se apaga y empieza la Fase 3")
	_check(chip.enraged and glitch.enraged and glitch.tempo > 1.0 and glitch.telegraph_scale < 1.0,
		"Fase 3 · Protocolo Dual (Furia fraternal): los dos juntos, más rápidos y con avisos más cortos")
	room.player.damage.protected = true
	await _until(func() -> bool: return fight.patterns_done[-1] in DualBossController.PHASE3)
	_check(fight.patterns_done[-1] in DualBossController.PHASE3, "en la Fase 3 usan su secuencia, con el Campo Dual")


func _test_victory() -> void:
	var ecos_before: int = root.get_node("Economy").ecos
	fight.health.take_damage(fight.health.current)
	await _frames(3)
	_check(glitch.is_dead and chip.is_dead and is_instance_valid(glitch) and glitch.visible, "con la vida en cero los dos quedan neutralizados (no se borran)")
	await _until(func() -> bool: return fight.phase == DualBossController.Phase.DONE)
	_check(fight.phase == DualBossController.Phase.DONE and state.has_flag(&"cap1_hermanos_vencidos") and state.has_flag(&"cap1_fragmento_leido"),
		"se gana el combate: cierre y lectura del Fragmento de Datos")
	_check(state.get_current_step(QUEST) == &"hablar_profesor", "la misión pide hablar con el profesor")
	_check(root.get_node("Economy").ecos > ecos_before and fight.exit_portal.visible and not Music.layer_on, "da Ecos, aparece la salida y se apaga la segunda melodía")
	# Ganar otra vez no vuelve a pagar.
	state.clear_flag(&"cap1_hermanos_vencidos")
	ecos_before = root.get_node("Economy").ecos
	await _open()
	fight.health.take_damage(fight.health.current)
	await _until(func() -> bool: return fight.phase == DualBossController.Phase.DONE)
	_check(root.get_node("Economy").ecos == ecos_before, "la recompensa no se cobra dos veces")


func _test_player_loses() -> void:
	state.clear_flag(&"cap1_hermanos_vencidos")
	await _open()
	fight.health.take_damage(fight.health.max_health * 0.4)
	await _frames(3)
	var player := room.player
	player.damage.protected = false
	player.health.take_damage(player.health.current - 0.5)
	var hit := HitData.new()
	hit.damage = 4.0
	player.damage._on_hit_received(hit)
	await _until(func() -> bool: return not player.damage.is_respawning and not player.controls_locked)
	await _frames(6)
	_check(fight.phase == DualBossController.Phase.FIGHT and fight.fight_phase == 1 and fight.health.current == fight.health.max_health
		and not chip.is_dead and not glitch.enraged and not fight.chamber.active and not Music.layer_on,
		"si Kai pierde, reaparece y la pelea vuelve a empezar desde la Fase 1 [fase %d, vida %.0f]" % [fight.fight_phase, fight.health.current])
	_check(room.get_node_or_null("CombatHUD/ChaseTimer") == null, "y sigue sin límite de tiempo")


func _test_already_won() -> void:
	state.set_flag(&"cap1_hermanos_vencidos")
	await _open()
	_check(fight.phase == DualBossController.Phase.DONE and not fight.gate.active and fight.exit_portal.visible,
		"con la pelea ganada, la arena queda abierta y con la salida")


## --- Ayudas de esta prueba ---

## Un golpe de la Nullblade a boss.
func _hit(boss: SiblingBoss, damage: float) -> void:
	var hit := HitData.new()
	hit.damage = damage
	boss.hurtbox.hit_received.emit(hit)


## Espera a que los dos estén libres y deja a Kai lejos (así los ataques no lo empujan).
func _ready_for_next() -> void:
	await _until(func() -> bool: return not glitch.busy and not chip.busy and not fight._running and not glitch.stunned and not chip.stunned)
	for attack in get_nodes_in_group(&"boss_attack"):
		attack.queue_free()
	room.player.teleport_to(Vector2(120, 304))
	await _frames(3)
	events.clear()


## Lanza un ataque y deja correr la pelea seconds segundos (llamando a each en cada cuadro).
func _run_pattern(pattern: StringName, seconds: float, each := Callable()) -> void:
	fight.start_pattern(pattern)
	await _play(seconds, each)


## Ataques en la arena de un tipo.
func _attacks(type: Variant) -> Array:
	return get_nodes_in_group(&"boss_attack").filter(func(n: Node) -> bool: return is_instance_of(n, type))


func _count(boss: SiblingBoss, kind: StringName) -> int:
	return events.filter(func(e: Array) -> bool: return e[0] == boss and e[1] == kind).size()


## Cuenta los nodos que se agregan y cumplen condition (devuelve una función que da la cuenta).
func _counter(condition: Callable) -> Callable:
	var total := [0]
	node_added.connect(func(node: Node) -> void:
		if condition.call(node):
			total[0] += 1)
	return func() -> int: return total[0]


## --- Ayudas ---

func _open() -> void:
	if current_scene:
		current_scene.queue_free()
	await process_frame
	var scene := (load(ARENA) as PackedScene).instantiate()
	(scene.get_node("Fight") as DualBossController).skip_cinematics = true
	root.add_child(scene)
	current_scene = scene
	await _frames(6)
	room = scene as Room
	fight = scene.get_node("Fight") as DualBossController
	chip = fight.chip
	glitch = fight.glitch
	room.player.health.max_health = 999.0
	room.player.health.restore_full()
	for boss: SiblingBoss in [chip, glitch]:
		boss.attack_started.connect(func(kind: StringName) -> void: events.append([boss, kind, _now()]))
	await _until(func() -> bool: return fight.phase == DualBossController.Phase.FIGHT or fight.phase == DualBossController.Phase.DONE)


func _kinds(boss: SiblingBoss) -> Array[StringName]:
	var kinds: Array[StringName] = []
	for e in events:
		if e[0] == boss and not kinds.has(e[1]):
			kinds.append(e[1])
	return kinds


func _first_time(boss: SiblingBoss, kind: StringName) -> float:
	for e in events:
		if e[0] == boss and e[1] == kind:
			return e[2]
	return -1.0


func _now() -> float:
	return Engine.get_physics_frames() / float(Engine.physics_ticks_per_second)


## Deja correr la pelea seconds segundos de juego (llamando a each en cada cuadro de física).
func _play(seconds: float, each := Callable()) -> void:
	var frames := int(seconds * Engine.physics_ticks_per_second)
	for i in frames:
		await physics_frame
		if each.is_valid():
			each.call()


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


func _until(condition: Callable) -> void:
	for i in 1200:
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
