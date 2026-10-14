extends SceneTree
## Prueba automática: Capítulo 1, etapas 7 a 11 (Chip y Glitch). La arena registra el checkpoint y no
## tiene temporizador; cada hermano tiene su barra y su máquina de estados, y sus ataques avisan antes;
## los tres ataques combinados; el escudo de Chip abre una fase segura con terminal; la Furia fraternal
## cambia según quién sobrevive y los dos órdenes de derrota permiten ganar; los hermanos quedan
## neutralizados (no se borran); la recompensa se cobra una sola vez; si Kai pierde, la pelea vuelve a
## empezar; con la pelea ganada, la arena queda abierta.
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
	state.unlock_double_jump()
	state.start_quest(QUEST)
	for step in [&"revisar_servidor", &"seguirlos_adentro"]:
		state.complete_step(QUEST, step)
	await _open()
	_test_start()
	await _test_attacks()
	await _test_combos()
	await _test_shield()
	await _test_order_glitch_first()
	await _test_order_chip_first()
	await _test_player_loses()
	await _test_already_won()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_start() -> void:
	var saves := root.get_node("SaveManager")
	_check(state.get_current_step(QUEST) == &"vencer_hermanos" and saves.read_slot(1)["ubicacion"]["punto"] == "desde_persecucion",
		"al llegar a la arena se registra el checkpoint y la misión pide detener a los hermanos")
	_check(room.get_node_or_null("CombatHUD/ChaseTimer") == null, "el combate no tiene temporizador")
	_check(fight.phase == DualBossController.Phase.FIGHT and fight.gate.active, "empieza la pelea con la puerta cerrada")
	_check(chip.health.max_health == chip.config.chip_health and glitch.health.max_health == glitch.config.glitch_health
		and chip.health.current == chip.health.max_health, "Chip empieza con %.0f de vida y Glitch con %.0f (los valores del config)" % [chip.health.max_health, glitch.health.max_health])
	var bar_chip := room.get_node("CombatHUD/BossBar") as BossBar
	var bar_glitch := room.get_node("CombatHUD/BossBar2") as BossBar
	chip.health.take_damage(2.0)
	_check(bar_chip.boss == chip and bar_glitch.boss == glitch and bar_chip.ratio() < 1.0 and bar_glitch.ratio() == 1.0,
		"Chip y Glitch tienen barras de vida independientes")
	chip.health.restore_full()


## Cada uno ataca solo (máquina de estados propia) y siempre avisa antes de atacar.
func _test_attacks() -> void:
	events.clear()
	fight.set_physics_process(false)  # Sin ataques combinados: cada uno por su cuenta.
	var shot_time := [-1.0]
	var charge_time := [-1.0]
	var on_node := func(node: Node) -> void:
		if node is DataShot and shot_time[0] < 0.0:
			shot_time[0] = _now()
	node_added.connect(on_node)
	await _play(9.0, func() -> void:
		if charge_time[0] < 0.0 and absf(glitch.velocity.x) >= glitch.config.glitch_charge_speed * 0.9:
			charge_time[0] = _now())
	node_added.disconnect(on_node)
	var chip_kinds := _kinds(chip)
	var glitch_kinds := _kinds(glitch)
	_check(chip_kinds.has(&"disparo") and (chip_kinds.has(&"trampa") or chip_kinds.has(&"plataforma")), "Chip ataca por su cuenta: %s" % [chip_kinds])
	_check(glitch_kinds.size() >= 1, "Glitch ataca por su cuenta: %s" % [glitch_kinds])
	var first_shot_warning := _first_time(chip, &"disparo")
	_check(shot_time[0] >= 0.0 and shot_time[0] - first_shot_warning >= chip.config.chip_shot_telegraph - 0.05,
		"el disparo de Chip sale después de su aviso (%.2f s)" % (shot_time[0] - first_shot_warning))
	if charge_time[0] >= 0.0:
		_check(charge_time[0] - _first_time(glitch, &"embestida") >= glitch.config.glitch_charge_telegraph - 0.05, "la embestida de Glitch sale después de su aviso")
	fight.set_physics_process(true)


func _test_combos() -> void:
	for kind: StringName in [&"camino_cerrado", &"distraccion", &"trampa_sincronizada"]:
		await _until(func() -> bool: return not chip.busy and not glitch.busy)
		events.clear()
		var before_walls := get_nodes_in_group(&"boss_attack").filter(func(n: Node) -> bool: return n is ChipWall).size()
		fight.start_combo(kind)
		await _play(1.6)
		var chip_kinds := _kinds(chip)
		var glitch_kinds := _kinds(glitch)
		match kind:
			&"camino_cerrado":
				var walls := get_nodes_in_group(&"boss_attack").filter(func(n: Node) -> bool: return n is ChipWall).size()
				_check(chip_kinds.has(&"barrera") and walls > before_walls and glitch_kinds.has(&"embestida"), "combo «Camino cerrado»: Chip cierra el paso y Glitch embiste")
			&"distraccion":
				_check(glitch_kinds.has(&"combo") and chip_kinds.has(&"disparo_grande"), "combo «Distracción»: Glitch presiona y Chip prepara un disparo grande")
			&"trampa_sincronizada":
				var traps := get_nodes_in_group(&"boss_attack").filter(func(n: Node) -> bool: return n is DataTrap).size()
				_check(chip_kinds.has(&"trampa") and traps >= 2 and glitch_kinds.has(&"salto"), "combo «Trampa sincronizada»: trampas a los costados y Glitch salta")
	await _play(3.0)


func _test_shield() -> void:
	await _until(func() -> bool: return not chip.busy)
	var hit := HitData.new()
	hit.damage = chip.health.current - chip.health.max_health * 0.45
	chip.hurtbox.hit_received.emit(hit)
	await _frames(4)
	_check(fight.phase == DualBossController.Phase.SAFE and chip.shielded and chip.hurtbox.immune, "a la mitad de su vida, Chip activa el escudo y empieza la fase segura")
	_check(chip.frozen and glitch.frozen and get_nodes_in_group(&"boss_attack").is_empty() and room.player.damage.protected,
		"fase segura: los dos se quedan quietos, se borran los ataques y Kai no recibe daño")
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
	_check(not chip.shielded and not chip.frozen and not room.player.damage.protected, "con el mínimo privilegio, el escudo se apaga y sigue la pelea")
	room.player.damage.protected = true


## Orden 1: Glitch cae primero → Chip en furia (abanico de disparos).
func _test_order_glitch_first() -> void:
	glitch.health.take_damage(glitch.health.current)
	await _frames(3)
	_check(glitch.is_dead and is_instance_valid(glitch) and glitch.visible, "Glitch queda neutralizado (no se borra: sobrevive)")
	_check(chip.enraged and fight.rage_survivor == &"chip", "Glitch cae primero: Chip entra en Furia fraternal")
	events.clear()
	var shots := [0]
	var count_shots := func(node: Node) -> void:
		if node is DataShot:
			shots[0] += 1
	node_added.connect(count_shots)
	await _until(func() -> bool: return _kinds(chip).has(&"disparo") and not chip.is_telegraphing() and shots[0] > 0)
	await _frames(2)
	node_added.disconnect(count_shots)
	_check(shots[0] >= chip.config.rage_chip_spread, "en furia, Chip dispara en abanico (%d disparos)" % shots[0])
	var ecos_before: int = root.get_node("Economy").ecos
	chip.health.take_damage(chip.health.current)
	await _until(func() -> bool: return fight.phase == DualBossController.Phase.DONE)
	_check(fight.phase == DualBossController.Phase.DONE and state.has_flag(&"cap1_hermanos_vencidos") and state.has_flag(&"cap1_fragmento_leido"),
		"con los dos neutralizados se gana el combate (orden: Glitch y después Chip)")
	_check(state.get_current_step(QUEST) == &"hablar_profesor", "la misión pide hablar con el profesor")
	_check(root.get_node("Economy").ecos > ecos_before and fight.exit_portal.visible, "da Ecos y aparece la salida")
	_check(is_instance_valid(chip) and is_instance_valid(glitch), "los hermanos no se borran: se van, pero siguen existiendo")


## Orden 2: Chip cae primero → Glitch en furia (más rápido, embestidas encadenadas).
func _test_order_chip_first() -> void:
	state.clear_flag(&"cap1_hermanos_vencidos")
	var ecos_before: int = root.get_node("Economy").ecos
	await _open()
	room.player.damage.protected = true
	chip.health.take_damage(chip.health.current)
	await _frames(3)
	_check(glitch.enraged and fight.rage_survivor == &"glitch" and is_equal_approx(glitch.speed_scale(), glitch.config.rage_glitch_speed_scale),
		"Chip cae primero: Glitch entra en furia y corre más rápido")
	_check(fight.rage_survivor != &"chip", "la furia es distinta según quién sobrevive")
	events.clear()
	await _until(func() -> bool: return not glitch.busy)
	glitch.charge()
	await _until(func() -> bool: return not glitch.busy)
	var charges := events.filter(func(e: Array) -> bool: return e[0] == glitch and e[1] == &"embestida").size()
	_check(charges == glitch.config.rage_glitch_chain, "en furia, Glitch encadena %d embestidas" % charges)
	glitch.health.take_damage(glitch.health.current)
	await _until(func() -> bool: return fight.phase == DualBossController.Phase.DONE)
	_check(fight.phase == DualBossController.Phase.DONE, "también se gana en el otro orden (Chip y después Glitch)")
	_check(root.get_node("Economy").ecos == ecos_before, "la recompensa no se cobra dos veces")


func _test_player_loses() -> void:
	state.clear_flag(&"cap1_hermanos_vencidos")
	await _open()
	chip.health.take_damage(5.0)
	glitch.health.take_damage(glitch.health.current)
	await _frames(3)
	var player := room.player
	player.damage.protected = false
	player.health.take_damage(player.health.current - 0.5)
	var hit := HitData.new()
	hit.damage = 4.0
	player.damage._on_hit_received(hit)
	await _until(func() -> bool: return not player.damage.is_respawning and not player.controls_locked)
	await _frames(6)
	_check(fight.phase == DualBossController.Phase.FIGHT and not chip.is_dead and not glitch.is_dead and chip.health.current == chip.health.max_health
		and not chip.enraged and fight.rage_survivor == &"", "si Kai pierde, reaparece y la pelea vuelve a empezar (sin furia) [fase %s, chip %s/%.0f, glitch %s, furia %s, vida Kai %.1f]" % [fight.phase, chip.is_dead, chip.health.current, glitch.is_dead, fight.rage_survivor, player.health.current])
	_check(room.get_node_or_null("CombatHUD/ChaseTimer") == null, "y sigue sin límite de tiempo")


func _test_already_won() -> void:
	state.set_flag(&"cap1_hermanos_vencidos")
	await _open()
	_check(fight.phase == DualBossController.Phase.DONE and not fight.gate.active and fight.exit_portal.visible,
		"con la pelea ganada, la arena queda abierta y con la salida")


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
