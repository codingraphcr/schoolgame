extends SceneTree
## Prueba automática: nivel de SPAM dentro de la computadora del profesor. Pop-ups (fijos, que se
## cierran, que se mueven), anuncios trampa, correos que caen, que el nivel se pueda cruzar solo
## caminando y saltando, y la llegada a la cuenta del profesor.
## Ejecutar: godot --headless --path . --script res://tests/test_spam_level.gd

const PC := "res://world/zones/pc_profesor/escritorio.tscn"
const FLOOR_Y := 304.0

var _failures := 0
var _hurts := 0
var state: Node
var room: Room
var player: Player


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	state.reset()
	state.start_quest(&"prologo")
	for step in [&"hablar_profesor", &"revisar_computadora", &"volver_profesor"]:
		state.complete_step(&"prologo", step)
	change_scene_to_file(PC)
	await _wait(0.6)
	room = current_scene as Room
	player = room.player
	player.damage.hurt.connect(func(_hit: HitData) -> void: _hurts += 1)
	await _until(func() -> bool: return state.get_current_step(&"contrasena_profesor") == &"cruzar_spam")
	_check(state.get_current_step(&"contrasena_profesor") == &"cruzar_spam", "al entrar a la PC, la misión pide cruzar el SPAM")
	_check(room.camera.limit_right == 1600, "el nivel mide 1600 px")

	await _test_popups()
	await _test_traps_and_mail()
	await _test_route()
	await _test_account()

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_popups() -> void:
	# Fijo: se puede pisar.
	await _drop_on(Vector2(700, 190))
	_check(absf(player.global_position.y - 230.0) < 1.0 and player.is_on_floor(), "un pop-up fijo sostiene a Kai (y=%.0f)" % player.global_position.y)
	# Se cierra al pisarlo.
	var closing := room.get_node("SpamPopups/Popup3") as SpamPopup
	await _drop_on(Vector2(830, 200))
	_check(absf(player.global_position.y - 244.0) < 1.0, "Kai se para sobre el pop-up que se cierra")
	await _wait(1.0)
	_check(closing.is_closed() and player.global_position.y > 260.0, "el pop-up se cierra y Kai cae")
	await _wait(2.6)
	_check(not closing.is_closed(), "el pop-up vuelve a abrirse")
	await _wait(1.2)  # Invulnerabilidad del golpe por caer en las trampas
	# Se mueve y lleva a Kai.
	var moving := room.get_node("SpamPopups/Popup4") as SpamPopup
	await _drop_on(moving.global_position + Vector2(48, -30))
	var start_x := player.global_position.x
	var popup_start_x := moving.global_position.x
	await _frames(45)
	var player_moved := player.global_position.x - start_x
	var popup_moved := moving.global_position.x - popup_start_x
	_check(player.is_on_floor() and absf(popup_moved) > 1.0 and absf(player_moved - popup_moved) < 2.0,
		"un pop-up que se mueve lleva a Kai encima (Kai %.0f px, pop-up %.0f px)" % [player_moved, popup_moved])
	await _wait(1.2)


func _test_traps_and_mail() -> void:
	_stop_mail_rain()
	await _until_vulnerable()
	player.health.restore_full()
	var masks: float = player.health.current
	_hurts = 0
	await _drop_on(Vector2(700, 280))
	await _wait(1.2)
	_check(_hurts == 1 and player.health.current == masks - 1.0, "tocar un anuncio trampa quita 1 máscara")
	await _until(func() -> bool: return not player.damage.is_respawning)
	_check(not _touching_trap(), "y devuelve a Kai a un suelo seguro, fuera de las trampas")
	await _until_vulnerable()
	player.health.restore_full()
	# Un correo que cae encima de Kai lo daña y lo empuja (no lo hace reaparecer).
	await _drop_on(Vector2(300, 280))
	await _wait(0.4)
	var spawner := room.get_node("SpamMail/MailRainA") as SpamMailSpawner
	var mail := spawner.spawn_mail(player.global_position.x - spawner.global_position.x)
	mail.fall_speed = 260.0
	_hurts = 0
	var before := player.global_position
	for i in 120:
		await physics_frame
		if _hurts > 0:
			break
	await _frames(8)
	_check(_hurts == 1 and player.health.current == 3.0, "un correo SPAM que cae quita 1 máscara")
	_check(player.global_position.distance_to(before) < 80.0, "el correo empuja pero no hace reaparecer")
	await _until_vulnerable()
	player.health.restore_full()
	# Dificultad: los correos caen más rápido y apuntan a donde estaba Kai hace un instante.
	_check(spawner.fall_speed >= 140.0, "los correos caen rápido (%.0f px/s)" % spawner.fall_speed)
	await _drop_on(Vector2(320, 280))  # lejos del anuncio trampa de x=372
	spawner._timer = 99.0  # registra el rastro de Kai sin soltar correos
	spawner.set_process(true)
	spawner.aimed_ratio = 1.0
	await _frames(20)
	spawner.set_process(false)
	var target: float = spawner._next_x() + spawner.global_position.x
	_check(absf(target - player.global_position.x) <= spawner.aim_spread + 0.5,
		"si Kai se queda quieto, el correo apunta encima de él (cae en x=%.0f, Kai en x=%.0f)" % [target, player.global_position.x])
	for leftover in spawner.get_children():
		leftover.queue_free()


## El nivel se puede cruzar solo caminando y saltando: un "bot" salta de pop-up en pop-up.
func _test_route() -> void:
	# Sin lluvia de correos: aquí solo se comprueba que los saltos son posibles.
	_stop_mail_rain()
	await _until_vulnerable()
	_hurts = 0
	await _drop_on(Vector2(500, 280))
	await _hop(530.0, 250.0, "suelo → pop-up MineKraft")
	await _hop(624.0, 230.0, "MineKraft → Terrarya")
	await _hop(748.0, 244.0, "Terrarya → GTA 6 (se cierra)")
	await _hop(872.0, FLOOR_Y, "GTA 6 → suelo después de las trampas", 0.0)
	_check(player.global_position.x > 940.0 and _hurts == 0, "la primera zona de trampas se cruza sin daño (x=%.0f)" % player.global_position.x)
	# Zona de pop-ups que se mueven.
	var moving := room.get_node("SpamPopups/Popup4") as SpamPopup
	_hurts = 0
	await _drop_on(Vector2(990, 280))
	# Espera a que el pop-up esté cerca para saltar.
	for i in 400:
		await physics_frame
		if moving.global_position.x < 1016.0:
			break
	await _hop(992.0, 250.0, "suelo → Fortnait (se mueve)")
	# Corre sobre el pop-up mientras avanza y salta al siguiente desde la mitad del recorrido.
	await _hop(1110.0, 226.0, "Fortnait → Robucks")
	await _hop(1268.0, FLOOR_Y, "Robucks → suelo después de las trampas", 0.0)
	_check(player.global_position.x > 1300.0 and _hurts == 0, "la segunda zona de trampas se cruza sin daño (x=%.0f)" % player.global_position.x)


func _test_account() -> void:
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	player.teleport_to(Vector2(1320, FLOOR_Y))
	Input.action_press("move_right")
	for i in 120:
		await physics_frame
		if box.is_playing():
			break
	Input.action_release("move_right")
	_check(box.is_playing() and box.get_node("%Text").text.contains("aquí está el error"), "al llegar a la cuenta: «¡Profe, aquí está el error!»")
	for i in 30:
		if not box.is_playing():
			break
		_action("interact")
		await _frames(3)
	await _frames(5)
	_check(state.get_current_step(&"contrasena_profesor") == &"cambiar_contrasena", "la misión pide cambiar la contraseña")
	player.teleport_to(Vector2(1448, FLOOR_Y))
	await _frames(8)
	var tab := room.get_node("AccountTab") as Interactable
	_check(tab._prompt.visible and tab._prompt.text == "E: cambiar la contraseña", "la pestaña «Cambiar contraseña» se puede usar")


## Salta en jump_at_x corriendo a la derecha y comprueba que aterriza a la altura expected_y.
func _hop(jump_at_x: float, expected_y: float, description: String, tolerance := 1.0) -> void:
	Input.action_press("move_right")
	for i in 300:
		await physics_frame
		if player.global_position.x >= jump_at_x:
			break
	await _press("jump")
	await _frames(12)
	for i in 120:
		await physics_frame
		if player.is_on_floor():
			break
	Input.action_release("jump")
	Input.action_release("move_right")
	await _frames(2)
	var ok := absf(player.global_position.y - expected_y) <= maxf(tolerance, 1.0)
	_check(ok, "ruta: %s (y=%.0f)" % [description, player.global_position.y])


## Espera (en cuadros de física) a que se cumpla la condición, hasta unos 10 s de juego.
func _until(condition: Callable) -> void:
	for i in 600:
		if condition.call():
			return
		await physics_frame


func _until_vulnerable() -> void:
	await _until(func() -> bool: return not player.is_invulnerable())


func _drop_on(position: Vector2) -> void:
	for action in ["move_left", "move_right", "jump"]:
		Input.action_release(action)
	player.teleport_to(position)
	await _frames(2)
	for i in 120:
		await physics_frame
		if player.is_on_floor():
			break
	await _frames(2)


## Detiene la lluvia de correos al azar (las comprobaciones usan correos controlados).
func _stop_mail_rain() -> void:
	for spawner in room.get_node("SpamMail").get_children():
		spawner.set_process(false)
		for mail in spawner.get_children():
			mail.queue_free()


func _touching_trap() -> bool:
	for area in player.hurtbox.get_overlapping_areas():
		if area is TrapAd:
			return true
	return false


func _press(action: String) -> void:
	await physics_frame
	Input.action_press(action)


func _action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
