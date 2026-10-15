extends SceneTree
## Prueba automática: Capítulo 1, etapas 7 a 11 (Glitch y Chip, diseño de Ariel). La arena registra el
## checkpoint y no tiene temporizador; cada uno tiene su barra hasta la Fase 3 y hay que vencer a los
## dos (el vencido queda aturdido y el otro sigue solo); sus 8 ataques individuales y los 10 en conjunto
## (también a la vez) avisan antes, con las poses de su sprite; cuando uno queda aturdido el otro deja
## su ataque y lo protege; las tres fases (el anillo y la segunda melodía en la Fase 2, la fase segura
## con la terminal al vencer a los dos y el Protocolo Dual / Furia fraternal, con una sola barra); con
## la vida en cero quedan neutralizados (no se borran); la recompensa se cobra una sola
## vez; si Kai pierde, la pelea vuelve a empezar; con la pelea ganada, la arena queda abierta.
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
## Quién entró en Furia fraternal (&"glitch" o &"chip").
var rages: Array[StringName] = []


func _initialize() -> void:
	Engine.max_physics_steps_per_frame = 1
	Engine.physics_jitter_fix = 0.0
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	root.get_node("SaveManager").new_game(1)
	state.set_flag(&"tutorial_terminado")
	state.set_dash_level(1)  # La Nullblade (prólogo) trae el dash.
	state.start_quest(QUEST)
	for step in [&"revisar_servidor", &"seguirlos_adentro"]:
		state.complete_step(QUEST, step)
	await _open()
	await _test_start()
	fight.set_physics_process(false)  # Los ataques los lanza la prueba, uno por uno.
	room.player.damage.protected = true
	await _test_platforms()
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
	_check(chip.health != glitch.health and not fight.merged and chip.health.max_health + glitch.health.max_health == fight.config.shared_health,
		"hasta la Fase 3 cada uno tiene su vida (%.0f + %.0f)" % [glitch.health.max_health, chip.health.max_health])
	var glitch_bar := room.get_node("CombatHUD/BossBar") as BossBar
	var chip_bar := room.get_node("CombatHUD/BossBar2") as BossBar
	_check(glitch_bar.boss == glitch and chip_bar.boss == chip and glitch_bar.title == "GLITCH" and chip_bar.title == "CHIP", "una barra para cada uno: Glitch arriba y Chip abajo")
	_hit(glitch, 2.0)
	_check(glitch_bar.ratio() < 1.0 and chip_bar.ratio() == 1.0, "pegarle a Glitch baja solo su barra")
	_hit(chip, 30.0)
	await _frames(2)
	_check(chip.downed and not chip.is_dead and chip.hurtbox.immune and chip.current_pose() == &"aturdido" and fight.phase == DualBossController.Phase.FIGHT,
		"sin vida, Chip queda vencido: aturdido en el piso y sin recibir golpes")
	_check(fight._sequence() == DualBossController.GLITCH_SOLO and glitch.guarding == null, "Glitch sigue peleando solo, con sus ataques")
	_check(glitch.enraged and glitch.tempo >= fight.config.rage_speed_scale and glitch.telegraph_scale <= fight.config.rage_telegraph_scale
		and is_equal_approx(fight._pause(), fight.config.rage_pause) and rages.has(&"glitch"),
		"¡Furia fraternal! Al ver vencido a Chip, Glitch se vuelve más fuerte (más rápido, avisos más cortos, sin respiro)")
	await _play(3.0)
	_check(chip.downed and chip.begin_attack() < 0, "Chip sigue en el piso mientras no venzan a Glitch")
	# Esos golpes bajaron la vida de los dos (pasó a la Fase 2): la arena vuelve a empezar.
	await _open()
	_check(SiblingArt.texture(&"glitch", &"corte") != null and SiblingArt.texture(&"chip", &"lanzar") != null and SiblingArt.texture(&"disco") != null,
		"Glitch, Chip y el disco usan los sprites de la hoja de Ariel")


## Las plataformas se alcanzan sin doble salto, con la física real: del piso a la de la izquierda con un
## salto, y de ahí a la del centro con salto + dash.
func _test_platforms() -> void:
	var side := await _jump_from(Vector2(40, SiblingBoss.FLOOR_Y), 1)
	_check(absf(side.y - 232.0) < 2.0, "del piso se sube de un salto a la plataforma del costado (y=%.0f)" % side.y)
	var center := await _jump_from(Vector2(184, 232), 1, 0.3)
	_check(absf(center.y - 172.0) < 2.0, "de la del costado se sube a la del centro con salto + dash (y=%.0f)" % center.y)
	room.player.teleport_to(Vector2(120, SiblingBoss.FLOOR_Y))
	await _frames(3)


## Salta desde at hacia dir (manteniendo el salto; con dash a los dash_at segundos si es >= 0) y devuelve
## dónde cayó.
func _jump_from(at: Vector2, dir: int, dash_at := -1.0) -> Vector2:
	var player := room.player
	player.teleport_to(at)
	player.velocity = Vector2.ZERO
	await _frames(6)
	var action := "move_right" if dir > 0 else "move_left"
	Input.action_press(action)
	Input.action_press("jump")
	var left_ground := false
	var elapsed := 0.0
	for i in 150:
		await physics_frame
		elapsed += 1.0 / Engine.physics_ticks_per_second
		if dash_at >= 0.0 and elapsed >= dash_at:
			dash_at = -1.0
			var press := InputEventAction.new()
			press.action = &"dash"
			press.pressed = true
			Input.parse_input_event(press)
			var release := InputEventAction.new()
			release.action = &"dash"
			Input.parse_input_event(release)
		if not player.is_on_floor():
			left_ground = true
		elif left_ground:
			break
	Input.action_release("jump")
	Input.action_release(action)
	await _frames(2)
	return player.global_position


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
	# 7. Danza espejo: desde paredes opuestas, Glitch por el piso y Chip volando, a la vez.
	await _ready_for_next()
	var crossing := [false]
	var chip_high := [false]
	await _run_pattern(&"danza_espejo", 4.0, func() -> void:
		if absf(glitch.velocity.x) > 200.0 and absf(chip.velocity.x) > 200.0 and signf(glitch.velocity.x) != signf(chip.velocity.x):
			crossing[0] = true
			chip_high[0] = chip_high[0] or (chip.global_position.y < SiblingBoss.FLOOR_Y - 50.0 and glitch.global_position.y > SiblingBoss.FLOOR_Y - 4.0))
	_check(crossing[0] and chip_high[0], "Danza espejo: cruzan la arena a la vez, Glitch por el piso y Chip volando")
	# 8. Picadas alternas: los dos caen sobre Kai por turnos.
	await _ready_for_next()
	await _run_pattern(&"picada_alterna", 5.0)
	_check(_count(glitch, &"salto_en_picada") >= 2 and _count(chip, &"salto_en_picada") >= 1, "Picadas alternas: los dos caen por turnos")
	# 9. Discos cruzados: Chip lanza discos mientras Glitch embiste.
	await _ready_for_next()
	await _run_pattern(&"discos_cruzados", 4.0)
	_check(_kinds(chip).has(&"discos_orbitales") and _kinds(glitch).has(&"embestida_en_cadena"), "Discos cruzados: discos de Chip y embestidas de Glitch")
	# 10. Remolino doble: giran en el aire y disparan.
	await _ready_for_next()
	var both_air := [false]
	var shots := _counter(func(n: Node) -> bool: return n is DataShot or n is DiscShot)
	await _run_pattern(&"remolino_doble", 4.5, func() -> void:
		if glitch.global_position.y < SiblingBoss.FLOOR_Y - 50.0 and chip.global_position.y < SiblingBoss.FLOOR_Y - 50.0:
			both_air[0] = true)
	_check(both_air[0] and shots.call() >= 4, "Remolino doble: giran en el aire y disparan (%d disparos)" % shots.call())
	await _until(func() -> bool: return not glitch.busy and not chip.busy and not fight._running)
	# Como las Mantis Lords: el barrido sigue a Kai hasta su plataforma y la caída cae sobre él.
	await _ready_for_next()
	room.player.teleport_to(Vector2(510, 232))
	await _frames(3)
	var line := [INF]
	await _run_pattern(&"barrido_glitch", 2.2, func() -> void:
		if glitch.sweep_line != INF:
			line[0] = glitch.sweep_line)
	_check(absf(line[0] - 232.0) < 3.0, "Barrido: aparece en la pared y cruza a la altura de Kai (en la plataforma, y=%.0f)" % line[0])
	await _ready_for_next()
	room.player.teleport_to(Vector2(400, SiblingBoss.FLOOR_Y))
	var landed := [INF]
	start_and_watch(&"caida_chip")
	await _until(func() -> bool: return chip.is_telegraphing())
	room.player.teleport_to(Vector2(330, SiblingBoss.FLOOR_Y))
	await _until(func() -> bool: return chip._dive_mark == Vector2.INF and not chip.is_telegraphing() and chip.is_on_floor())
	landed[0] = chip.global_position.x
	_check(absf(landed[0] - 330.0) < 6.0, "Caída: sigue a Kai mientras avisa y cae sobre él (x=%.0f)" % landed[0])
	await _until(func() -> bool: return not chip.busy and not fight._running)
	# Con Kai debajo de la plataforma del centro, la caída la atraviesa y llega hasta él.
	await _ready_for_next()
	room.player.teleport_to(Vector2(320, SiblingBoss.FLOOR_Y))
	await _frames(3)
	fight.start_pattern(&"caida_glitch")
	await _until(func() -> bool: return glitch.is_telegraphing())
	await _until(func() -> bool: return not glitch.is_telegraphing() and glitch._dive_mark == Vector2.INF)
	_check(absf(glitch.global_position.y - SiblingBoss.FLOOR_Y) < 2.0, "Caída: atraviesa la plataforma y llega hasta Kai, debajo (y=%.0f)" % glitch.global_position.y)
	await _until(func() -> bool: return not glitch.busy and not fight._running)
	# Tijera: barren a la vez desde paredes opuestas, uno por el piso y el otro por arriba.
	await _ready_for_next()
	var lines := {}
	await _run_pattern(&"tijera", 3.5, func() -> void:
		if glitch.sweep_line != INF:
			lines["glitch"] = [glitch.sweep_line, signf(glitch.velocity.x)]
		if chip.sweep_line != INF:
			lines["chip"] = [chip.sweep_line, signf(chip.velocity.x)])
	_check(lines.has("glitch") and lines.has("chip") and lines.glitch[1] != lines.chip[1] and lines.glitch[0] > lines.chip[0] + 30.0,
		"Tijera: cruzan desde paredes opuestas, Glitch por abajo y Chip por arriba")
	await _until(func() -> bool: return not glitch.busy and not chip.busy and not fight._running)
	# Doble caída: los dos caen a la vez a los lados de Kai.
	await _ready_for_next()
	var both_marks := [false]
	await _run_pattern(&"doble_caida", 3.0, func() -> void:
		if glitch._dive_mark != Vector2.INF and chip._dive_mark != Vector2.INF:
			both_marks[0] = glitch._dive_mark.x < 120.0 and chip._dive_mark.x > 120.0)
	_check(both_marks[0], "Doble caída: aparecen los dos sobre Kai, uno a cada lado, y caen a la vez")
	await _until(func() -> bool: return not glitch.busy and not chip.busy and not fight._running)
	# Caída y barrido: Chip cae y Glitch ya está cruzando.
	await _ready_for_next()
	var overlap := [false]
	await _run_pattern(&"caida_y_barrido", 3.5, func() -> void:
		if glitch.sweep_line != INF and chip.is_on_floor() and _count(chip, &"caida") > 0:
			overlap[0] = true)
	_check(overlap[0], "Caída y barrido: cuando Chip aterriza, Glitch ya cruza por el piso")
	await _until(func() -> bool: return not glitch.busy and not chip.busy and not fight._running)
	# Los dos a la vez («a+b»).
	await _ready_for_next()
	await _run_pattern(&"corte_acelerado+discos_orbitales", 2.0)
	_check(_kinds(glitch).has(&"corte_acelerado") and _kinds(chip).has(&"discos_orbitales") and absf(_first_time(chip, &"discos_orbitales") - _first_time(glitch, &"corte_acelerado")) < 0.5,
		"los dos atacan a la vez (Glitch corta mientras Chip lanza discos)")
	await _until(func() -> bool: return not glitch.busy and not chip.busy and not fight._running)
	# Las poses del sprite de Ariel.
	await _ready_for_next()
	var poses := {}
	await _run_pattern(&"corte_acelerado", 1.6, func() -> void: poses[glitch.current_pose()] = true)
	_check(poses.has(&"corte_aviso") and poses.has(&"corte") and poses.has(&"corte_fin"),
		"Glitch anima el Corte acelerado como en la hoja de Ariel: aviso, corte y recuperación (%s)" % [poses.keys()])
	var corte := SiblingArt.pose_info(&"glitch_corte")
	_check(int(corte.frames) > 1 and not corte.loop, "el corte es cuadro por cuadro (%d cuadros) y no se repite" % int(corte.frames))
	await _ready_for_next()
	poses.clear()
	await _run_pattern(&"discos_orbitales", 1.2, func() -> void: poses[chip.current_pose()] = true)
	_check(poses.has(&"discos_aviso") and poses.has(&"lanzar") and poses.has(&"discos_fin"),
		"Chip anima los Discos orbitales: aviso, lanzar y recuperación (%s)" % [poses.keys()])
	await _ready_for_next()
	poses.clear()
	await _run_pattern(&"caida_glitch", 2.0, func() -> void: poses[glitch.current_pose()] = true)
	_check(poses.has(&"caida_aviso") and poses.has(&"caida_caer") and poses.has(&"caida_fin"),
		"la Caída también: aviso arriba de Kai, caer y el impacto (%s)" % [poses.keys()])
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
	for i in 150:
		if absf(chip.global_position.x - chip.guard_x()) < 12.0:
			break
		await physics_frame
	_check(absf(chip.global_position.x - chip.guard_x()) < 12.0, "Chip corre a pararse entre Kai y Glitch")
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
	_restore_health()


## Las tres fases.
func _test_phases() -> void:
	await _until(func() -> bool: return not fight._running)
	var first := fight.patterns_done.size()
	await _play(6.0)
	var started := fight.patterns_done.slice(first)
	_check(started.size() >= 2 and started[0] in DualBossController.PHASE1 and started[1] in DualBossController.PHASE1,
		"Fase 1 · Reconocimiento: sigue su secuencia (%s)" % [started])
	_damage_to(0.69)
	await _frames(2)
	_check(fight.fight_phase == 2 and fight.chamber.active and Music.layer_on, "al 70 %: Fase 2 · Sincronización (se activa el anillo y la segunda melodía)")
	await _until(func() -> bool: return fight.patterns_done[-1] in DualBossController.PHASE2)
	_check(fight.patterns_done[-1] in DualBossController.PHASE2, "en la Fase 2 usan su secuencia (%s)" % fight.patterns_done[-1])
	_damage_to(0.1)
	await _frames(4)
	_check(fight.phase == DualBossController.Phase.FIGHT and fight.fight_phase == 2, "con poca vida sigue la Fase 2: hay que vencer a cada uno")
	var glitch_before := glitch.health.current
	_hit(chip, 99.0)
	await _frames(4)
	_check(chip.downed and not glitch.downed and fight.phase == DualBossController.Phase.FIGHT, "Chip vencido: Glitch sigue solo")
	_check(glitch.enraged and glitch.health.current > glitch_before, "y enfurecido recupera vida (%.1f → %.1f)" % [glitch_before, glitch.health.current])
	await _until(func() -> bool: return fight.patterns_done[-1] in DualBossController.GLITCH_SOLO)
	_check(fight.patterns_done[-1] in DualBossController.GLITCH_SOLO, "solo, Glitch usa sus ataques (%s)" % fight.patterns_done[-1])
	_hit(glitch, 99.0)
	await _until(func() -> bool: return fight.phase == DualBossController.Phase.SAFE and chip.shielded)
	_check(fight.phase == DualBossController.Phase.SAFE and chip.shielded and chip.frozen and glitch.frozen and room.player.damage.protected
		and not chip.downed and not glitch.downed and fight.fight_phase == 2,
		"con los dos vencidos se levantan, Chip levanta su escudo y empieza la fase segura")
	_check(fight.both_down_dialogue != null and fight.both_down_dialogue.script_text.contains("Interesante enfoque"), "y Chip dice «Interesante enfoque...»")
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
	_check(fight.merged and chip.health == glitch.health and chip.health == fight.health and fight._bars.size() == 1 and fight._bars[0].title == "GLITCH & CHIP"
		and fight.health.max_health == fight.config.phase3_health and fight.health.current == fight.health.max_health,
		"en la Fase 3 las barras se unen en una sola, nueva y llena (%.0f)" % fight.health.current)
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
	fight.merge_health()
	fight.health.take_damage(fight.health.current)
	await _until(func() -> bool: return fight.phase == DualBossController.Phase.DONE)
	_check(root.get_node("Economy").ecos == ecos_before, "la recompensa no se cobra dos veces")


func _test_player_loses() -> void:
	state.clear_flag(&"cap1_hermanos_vencidos")
	await _open()
	_damage_to(0.6)
	await _frames(3)
	var player := room.player
	player.damage.protected = false
	player.health.take_damage(player.health.current - 0.5)
	var hit := HitData.new()
	hit.damage = 4.0
	player.damage._on_hit_received(hit)
	await _until(func() -> bool: return not player.damage.is_respawning and not player.controls_locked)
	await _frames(6)
	_check(fight.phase == DualBossController.Phase.FIGHT and fight.fight_phase == 1 and not fight.merged and fight.total_health() == fight.total_max()
		and not chip.is_dead and not chip.downed and not glitch.enraged and not fight.chamber.active and not Music.layer_on,
		"si Kai pierde, reaparece y la pelea vuelve a empezar desde la Fase 1 [fase %d, vida %.0f]" % [fight.fight_phase, fight.total_health()])
	_check(room.get_node_or_null("CombatHUD/ChaseTimer") == null, "y sigue sin límite de tiempo")


func _test_already_won() -> void:
	state.set_flag(&"cap1_hermanos_vencidos")
	await _open()
	_check(fight.phase == DualBossController.Phase.DONE and not fight.gate.active and fight.exit_portal.visible,
		"con la pelea ganada, la arena queda abierta y con la salida")


## --- Ayudas de esta prueba ---

## Deja a los dos con la vida llena.
func _restore_health() -> void:
	for boss: SiblingBoss in [chip, glitch]:
		boss.health.restore_full()


## Baja la vida de los dos (a cada uno lo mismo) hasta que entre los dos les quede ratio de la vida.
func _damage_to(ratio: float) -> void:
	for boss: SiblingBoss in [chip, glitch]:
		boss.health.take_damage(boss.health.current - boss.health.max_health * ratio)

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


## Lanza un ataque sin esperar a que termine.
func start_and_watch(pattern: StringName) -> void:
	fight.start_pattern(pattern)


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
	fight.rage_started.connect(func(who: StringName) -> void: rages.append(who))
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
