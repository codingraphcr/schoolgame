extends SceneTree
## Prueba automática: el jefe «Contraseña débil» (WeakPasswordBoss) y los fragmentos de vida.
## Se arma desde la ventanita, camina hacia Kai, avisa y embiste, choca y queda agachado (más bajo:
## ahí el pogo le quita el doble), lanza contraseñas comunes, pasa a la fase 2 con la mitad de la vida
## y al morir sus ventanas muestran "ACCESO DENEGADO" antes de desaparecer. Al tocar un fragmento de
## vida aparece una ventana para reclamarlo (se suma al reclamarlo); con 4 se forma una vida nueva.
## Ejecutar: godot --headless --path . --script res://tests/test_boss.gd

const ROOM := "res://tests/fixtures/combat_test_room.tscn"
const BOSS := preload("res://characters/enemies/weak_password_boss/weak_password_boss.tscn")

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.reset()
	change_scene_to_file(ROOM)
	await _wait(0.5)
	var room := current_scene as Room
	var player := room.player
	await _until(func() -> bool: return player.is_on_floor())
	player.hurtbox.immune = true
	player.combat.weapon = load("res://data/weapons/nullblade.tres")

	# Aparición.
	var boss := BOSS.instantiate() as WeakPasswordBoss
	boss.ai_enabled = false
	room.add_child(boss)
	boss.global_position = player.global_position + Vector2(260, -10)
	await _until(func() -> bool: return boss.is_on_floor())
	_check(boss.rank == EnemyBase.Rank.JEFE and boss.state == WeakPasswordBoss.State.HIDDEN, "es un jefe y al principio es solo una ventanita")
	_check(not boss.hurtbox.is_physics_processing(), "mientras es una ventanita no se le puede golpear")
	await boss.assemble(true)
	_check(boss.state == WeakPasswordBoss.State.WALK and boss.hurtbox.is_physics_processing(), "las ventanas se juntan: queda armado y se le puede golpear")

	# Camina hacia Kai para presionarlo.
	boss.ai_enabled = true
	var start_x := boss.global_position.x
	await _frames(20)
	_check(boss.global_position.x < start_x and boss.facing == -1, "camina hacia Kai")

	# Embestida: avisa, carga en línea recta, choca y queda agachado (más bajo).
	await _until(func() -> bool: return boss.state == WeakPasswordBoss.State.WINDUP)
	_check(boss.state == WeakPasswordBoss.State.WINDUP, "antes de embestir avisa (se prepara)")
	player.teleport_to(player.global_position + Vector2(0, -200))  # Fuera del camino.
	await _until(func() -> bool: return boss.state == WeakPasswordBoss.State.CHARGE)
	await _frames(18)  # Acelera durante unos 0,2 s.
	_check(absf(boss.velocity.x) > 150.0 or boss.state == WeakPasswordBoss.State.CROUCH, "embiste en línea recta (%.0f px/s)" % absf(boss.velocity.x))
	await _until(func() -> bool: return boss.state == WeakPasswordBoss.State.CROUCH)
	_check(boss.is_crouching() and boss.body_size.y < WeakPasswordBoss.STAND.y, "choca y queda agachado, más bajo (alcanzable con el pogo)")

	# Pogo sobre el jefe agachado: le quita el doble.
	await _until(func() -> bool: return player.is_on_floor() and player.combat.can_attack())
	var before := boss.health.current
	player.teleport_to(boss.global_position + Vector2(0, -boss.body_size.y - 18))
	await _frames(1)
	Input.action_press("move_down")
	player.combat.attack()
	Input.action_release("move_down")
	await _until(func() -> bool: return boss.health.current < before)
	_check(is_equal_approx(before - boss.health.current, 2.0), "el pogo sobre el jefe agachado le quita el doble (%.0f)" % (before - boss.health.current))

	# Proyectiles: contraseñas comunes que hay que saltar.
	await _until(func() -> bool: return not boss.is_crouching())
	await _until(func() -> bool: return room.find_children("*", "PasswordGuess", true, false).size() > 0)
	var shots := room.find_children("*", "PasswordGuess", true, false)
	_check(shots.size() > 0 and (shots[0] as PasswordGuess).text in WeakPasswordBoss.WEAK_PASSWORDS, "lanza contraseñas comunes")

	# Fase 2 con la mitad de la vida.
	_check(boss.phase == 1 and is_equal_approx(boss.speed_scale(), 1.0), "en la fase 1 va a velocidad normal")
	var phases: Array[int] = []
	boss.phase_changed.connect(func(p: int) -> void: phases.append(p))
	boss.health.take_damage(boss.health.current - boss.max_health * 0.5)
	var hit := HitData.new()
	hit.damage = 0.0
	boss._on_damaged(hit)
	_check(boss.phase == 2 and phases == [2] and boss.speed_scale() > 1.0, "con la mitad de la vida pasa a la fase 2 (más rápido)")

	# Muerte: "ACCESO DENEGADO" y desaparece.
	var finished := [false]
	boss.death_finished.connect(func() -> void: finished[0] = true)
	boss.health.take_damage(99.0)
	await _frames(3)
	_check(boss.is_dead and boss.state == WeakPasswordBoss.State.DYING and boss._denied, "al morir sus ventanas muestran «ACCESO DENEGADO»")
	await _until(func() -> bool: return finished[0])
	await _frames(3)
	_check(finished[0] and not is_instance_valid(boss), "explota en píxeles y desaparece")

	# Fragmentos de vida: al tocarlo aparece la ventana para reclamarlo.
	var fragment := LifeFragment.spawn(room, player.global_position + Vector2(60, -30), &"fragmento_prueba")
	fragment.attract()
	var got := [false]
	fragment.collected.connect(func(_completed: bool) -> void: got[0] = true)
	await _until(func() -> bool: return root.get_node_or_null("LifeFragmentLayer") != null)
	var window := root.get_node_or_null("LifeFragmentLayer/LifeFragmentWindow") as LifeFragmentWindow
	_check(window != null and paused and window._title.text.contains("Has obtenido un fragmento de vida"),
		"aparece la ventana «¡Has obtenido un fragmento de vida!» (el juego se pausa)")
	_check(state.life_fragments == 0, "todavía no se suma: hay que reclamarlo")
	await _wait(0.7)
	_action("interact")
	await _frames(2)
	_check(state.life_fragments == 1 and window._body.text.contains("4 fragmentos"), "al reclamarlo se suma y explica que con 4 se forma una vida")
	await _wait(0.7)
	_action("interact")
	await _until(func() -> bool: return got[0])
	_check(got[0] and not paused and state.has_flag(&"fragmento_prueba"), "al continuar la ventana se cierra y el juego sigue")
	_check(room.get_node("CombatHUD").get_node_or_null("LifeFragments") == null, "el fragmento no aparece junto a las vidas")
	var entry: GrimorioEntry = load("res://data/grimorio/fragmento_vida.tres")
	_check(entry.is_unlocked(state) and entry.inventory_kind == GrimorioEntry.InventoryKind.FRAGMENTO_VIDA, "aparece en el INVENTARIO del Grimorio (el símbolo que se llena)")
	var masks: int = state.max_masks
	state.add_life_fragment()
	state.add_life_fragment()
	var completed: bool = state.add_life_fragment()
	_check(completed and state.max_masks == masks + 1 and state.life_fragments == 0, "con 4 fragmentos se forma una vida nueva")

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


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


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])


func _action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
