extends SceneTree
## Prueba automática: ataque de Kai (PlayerCombat + WeaponData), enemigo base y la «Contraseña
## débil», y el combate de la cuenta del profesor (H4c): diálogo, aparición de la Nullblade, barrera, perder y
## reintentar, ganar y avanzar la misión.
## Ejecutar: godot --headless --path . --script res://tests/test_combat.gd

const ROOM := "res://tests/fixtures/combat_test_room.tscn"
const PC := "res://world/zones/pc_profesor/escritorio.tscn"
const SWORD := "res://data/weapons/mini_espada.tres"
const ENEMY := preload("res://characters/enemies/weak_password/weak_password.tscn")

var _failures := 0
var state: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	state.reset()
	change_scene_to_file(ROOM)
	await _wait(0.5)
	await _test_attack()
	await _test_enemy()
	await _test_fight()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_attack() -> void:
	var room := current_scene as Room
	var player := room.player
	await _until(func() -> bool: return player.is_on_floor())
	var combat := player.combat
	_action("attack")
	await _frames(3)
	_check(not combat.is_attacking() and not combat.hitbox.active, "sin arma, J no hace nada")

	combat.weapon = load(SWORD)
	var enemy := _spawn_enemy(room, player.global_position + Vector2(24, -4))
	await _until(func() -> bool: return enemy.is_on_floor())
	player.face(1)
	_action("attack")
	await _until(func() -> bool: return combat.hitbox.active)
	_check(combat.hitbox.active and combat.hitbox.position.x > 0.0, "con la mini espada, J ataca hacia donde mira Kai")
	await _frames(2)
	_check(player.get_node("Visual/Body/Kai").current_animation() == &"ataque_2", "cuando el golpe hace daño, Kai muestra el tajo de Ariel (ataque_2)")
	_check(not combat.attack(), "no se puede atacar otra vez hasta que termina el golpe")
	await _until(func() -> bool: return combat.can_attack())
	player.heal.active = true
	_check(not combat.can_attack(), "no se puede atacar mientras Kai se cura")
	player.heal.active = false
	var start_x := enemy.global_position.x
	await _until(func() -> bool: return not combat.is_attacking())
	await _frames(6)
	_check(enemy.health.current == enemy.max_health - 1.0, "un tajo quita 1 punto de vida, una sola vez (%.0f/%.0f)" % [enemy.health.current, enemy.max_health])
	_check(enemy.global_position.x > start_x, "el golpe empuja al enemigo")
	_check(_labels_with(room, "123456") > 0, "al golpearla suelta una contraseña débil («123456»)")
	player.face(-1)
	await _until(func() -> bool: return combat.can_attack())
	combat.attack()
	await _until(func() -> bool: return combat.hitbox.active)
	_check(combat.hitbox.position.x < 0.0, "mirando a la izquierda, el golpe sale a la izquierda")
	await _until(func() -> bool: return not combat.is_attacking())
	enemy.queue_free()
	await _frames(2)


func _test_enemy() -> void:
	var room := current_scene as Room
	var player := room.player
	var combat := player.combat
	player.teleport_to(Vector2(200, player.global_position.y))
	await _frames(4)
	# Matarla con la espada: se enoja a la mitad y al final se deshace en números.
	var enemy := _spawn_enemy(room, player.global_position + Vector2(24, -4))
	var died := [false]
	enemy.died.connect(func() -> void: died[0] = true)
	for i in 8:
		if died[0]:
			break
		await _until(func() -> bool: return combat.can_attack() and enemy.is_on_floor())
		player.teleport_to(Vector2(enemy.global_position.x - 22, player.global_position.y))
		player.face(1)
		await _frames(2)
		combat.attack()
		await _until(func() -> bool: return not combat.is_attacking())
		await _frames(2)
		if i == 2:
			_check(enemy.brute_force, "con la mitad de la vida entra en «fuerza bruta»")
	_check(died[0], "6 tajos la derrotan")
	var enemy_id := enemy.get_instance_id()
	await _until(func() -> bool: return not is_instance_id_valid(enemy_id))
	_check(not is_instance_id_valid(enemy_id), "al morir desaparece")

	# Tocarla hace daño: medio cristal (regla de Ariel para golpes enemigos).
	player.damage.revive()
	await _frames(2)
	var toucher := _spawn_enemy(room, player.global_position + Vector2(0, -4))
	await _until(func() -> bool: return player.health.current < player.health.max_health)
	_check(player.health.current == player.health.max_health - 0.5, "tocarla quita medio cristal")
	toucher.queue_free()
	await _until(func() -> bool: return not player.is_invulnerable())

	# Inteligencia: se agacha avisando y salta hacia Kai.
	player.health.restore_full()
	player.teleport_to(Vector2(80, player.global_position.y))
	var hopper := _spawn_enemy(room, Vector2(230, player.global_position.y - 4))
	await _until(func() -> bool: return hopper.is_on_floor())
	hopper.ai_enabled = true
	var saw_telegraph := [false]
	var left_floor := [false]
	var start_x := hopper.global_position.x
	await _until(func() -> bool:
		saw_telegraph[0] = saw_telegraph[0] or hopper.phase == WeakPasswordEnemy.Phase.TELEGRAPH
		left_floor[0] = left_floor[0] or (saw_telegraph[0] and not hopper.is_on_floor())
		return left_floor[0] and hopper.is_on_floor())
	_check(saw_telegraph[0] and left_floor[0], "avisa agachándose y luego salta")
	_check(hopper.global_position.x < start_x - 20.0, "salta hacia Kai (%.0f → %.0f)" % [start_x, hopper.global_position.x])
	hopper.queue_free()
	await _frames(2)


func _test_fight() -> void:
	state.reset()
	state.start_quest(&"contrasena_profesor")
	for step in [&"entrar_pc", &"cruzar_spam", &"revisar_configuracion"]:
		state.complete_step(&"contrasena_profesor", step)
	change_scene_to_file(PC)
	await _wait(0.6)
	var room := current_scene as Room
	var player := room.player
	var fight := room.get_node("PasswordFight") as PasswordFight
	var barrier := room.get_node("ArenaBarrier") as ArenaBarrier
	var tab := room.get_node("AccountTab") as Interactable
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	_check(player.combat.weapon == null, "antes del combate Kai no tiene arma")
	# Kai llega caminando (pasa por el punto de restauración del final).
	player.teleport_to(Vector2(2940, 304))
	await _walk_to(player, 3172.0)
	_check(room.checkpoint == room.get_node("RestorePointFinal"), "hay un punto de restauración justo antes del combate")
	_check(tab._prompt.visible and tab._prompt.text == "E: cambiar la contraseña", "la pestaña ofrece «E: cambiar la contraseña»")

	_action("interact")
	await _until(func() -> bool: return box.is_playing())
	_check(fight.running and fight.enemy != null and not fight.enemy.ai_enabled, "aparece la «Contraseña débil» (quieta mientras habla)")
	_check(await _dialogue_contains(box, "no deberías poder vernos"), "dice «Tú no deberías poder vernos»")
	await _advance(box)
	# La Nullblade se materializa y aparece la tarjeta de equipamiento (el juego queda en pausa).
	await _until(func() -> bool: return root.get_node_or_null("EquipmentCardLayer") != null)
	var card := root.get_node_or_null("EquipmentCardLayer/EquipmentCard")
	_check(card != null and paused and card.get_node("%Title").text == "NULLBLADE", "aparece la tarjeta «NULLBLADE» y el juego se pausa")
	_check(state.nullblade_stage == 0 and player.controls_locked, "mientras tanto Kai no se mueve")
	await _wait(0.9)
	_action("interact")
	await _until(func() -> bool: return root.get_node_or_null("EquipmentCardLayer") == null)
	await _frames(3)
	_check(not paused and state.nullblade_stage == 1, "al cerrar la tarjeta, Kai tiene la Nullblade")
	_check(player.combat.weapon != null and player.combat.weapon.id == &"nullblade", "Kai pelea con la Nullblade")
	_check(barrier.active and fight.enemy.ai_enabled and not player.controls_locked, "se cierra la barrera y empieza el combate")
	_check(not tab._prompt.visible, "durante el combate la pestaña no se puede usar")

	# Perder: el combate se cancela y se puede repetir.
	player.health.take_damage(99.0)
	await _until(func() -> bool: return not fight.running and not barrier.active)
	await _until(func() -> bool: return not player.health.is_dead() and not player.controls_locked)
	_check(not fight.running and not barrier.active and not is_instance_valid(fight.enemy), "si Kai muere, el combate se cancela")
	_check(absf(player.global_position.x - 2975.0) < 2.0, "Kai reaparece en el punto de restauración (x=%.0f)" % player.global_position.x)
	_check(state.get_current_step(&"contrasena_profesor") == &"cambiar_contrasena", "la misión sigue en «cambiar la contraseña»")

	# Reintentar y ganar.
	await _walk_to(player, 3172.0)
	_action("interact")
	await _until(func() -> bool: return box.is_playing())
	_check(await _dialogue_contains(box, "Otra vez"), "al reintentar, el diálogo es corto")
	await _advance(box)
	await _until(func() -> bool: return fight.enemy.ai_enabled)
	var enemy := fight.enemy
	enemy.ai_enabled = false  # Quieta, para que la prueba no dependa de los saltos.
	for i in 10:
		if enemy.is_dead:
			break
		await _until(func() -> bool: return player.combat.can_attack() and enemy.is_on_floor())
		player.teleport_to(Vector2(enemy.global_position.x - 22, 304))
		player.face(1)
		await _frames(2)
		_action("attack")
		await _until(func() -> bool: return player.combat.is_attacking())
		await _until(func() -> bool: return not player.combat.is_attacking())
		await _frames(2)
	_check(enemy.is_dead, "la Nullblade derrota a la «Contraseña débil»")
	await _until(func() -> bool: return box.is_playing())
	_check(await _dialogue_contains(box, "1... 2... 3"), "se deshace en números y Kai le cuenta al profesor")
	await _advance(box)
	await _frames(5)
	_check(state.get_current_step(&"contrasena_profesor") == &"elegir_seguridad", "la misión avanza: elegir la nueva contraseña")
	_check(not barrier.active and not player.controls_locked, "la barrera se abre")
	player.teleport_to(Vector2(3172, 304))
	await _frames(8)
	_check(tab._prompt.visible and tab._prompt.text == "E: elegir la nueva contraseña", "la pestaña ofrece elegir la nueva contraseña (H4d)")


func _spawn_enemy(room: Node, position: Vector2) -> WeakPasswordEnemy:
	var enemy := ENEMY.instantiate() as WeakPasswordEnemy
	enemy.ai_enabled = false
	room.add_child(enemy)
	enemy.global_position = position
	return enemy


func _labels_with(room: Node, text: String) -> int:
	return room.get_children().filter(func(node: Node) -> bool: return node is Label and node.text == text).size()


func _walk_to(player: Player, x: float) -> void:
	Input.action_press("move_right")
	for i in 400:
		await physics_frame
		if player.global_position.x >= x:
			break
	Input.action_release("move_right")
	await _until(func() -> bool: return player.is_on_floor())
	await _frames(4)


## Recorre el diálogo buscando un texto (sin avanzarlo más allá de donde lo encuentra).
func _dialogue_contains(box: DialogueBox, text: String) -> bool:
	for i in 30:
		if not box.is_playing():
			return false
		if box.get_node("%Text").text.contains(text):
			return true
		_action("interact")
		await _frames(3)
	return false


func _advance(box: DialogueBox) -> void:
	for i in 40:
		if not box.is_playing():
			return
		_action("interact")
		await _frames(3)


## Espera (en cuadros de física) a que se cumpla la condición, hasta unos 10 s de juego.
func _until(condition: Callable) -> void:
	for i in 600:
		if condition.call():
			return
		await process_frame
		await physics_frame


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
		await process_frame  # Teclas y HUD se procesan en cuadros de dibujo.
		await physics_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
