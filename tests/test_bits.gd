extends SceneTree
## Prueba automática: BITS. Los enemigos se desintegran y sueltan BITS según su fuerza; las monedas
## rebotan y quedan en el suelo; Kai las recoge al acercarse; los cofres y las misiones también dan
## BITS; el HUD y la página del Grimorio.
## Ejecutar: godot --headless --path . --script res://tests/test_bits.gd

const ROOM := "res://tests/fixtures/combat_test_room.tscn"
const ENEMY := preload("res://characters/enemies/weak_password/weak_password.tscn")

var _failures := 0
var state: Node
var room: Room
var player: Player


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	state.reset()
	_test_split()
	change_scene_to_file(ROOM)
	await _wait(0.5)
	room = current_scene as Room
	player = room.player
	await _until(func() -> bool: return player.is_on_floor())
	await _test_enemy_drop()
	await _test_chest()
	_test_quest_reward()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_split() -> void:
	var holder := Node2D.new()
	root.add_child(holder)
	for amount in [3, 18, 200]:
		var coins := BitCoin.spawn_burst(holder, Vector2.ZERO, amount)
		var total := 0
		for coin in coins:
			total += coin.value
		_check(total == amount and (amount <= BitCoin.MAX_COINS or coins.size() <= BitCoin.MAX_COINS or amount > 70),
			"%d BITS se reparten en %d monedas que suman lo mismo" % [amount, coins.size()])
	holder.queue_free()
	var enemy := ENEMY.instantiate() as EnemyBase
	_check(enemy.get_bits_reward() == roundi(enemy.max_health * 3.0), "un enemigo suelta más BITS cuanto más fuerte es (%d)" % enemy.get_bits_reward())
	enemy.bits_reward = 5
	_check(enemy.get_bits_reward() == 5, "cada enemigo puede fijar su propia cantidad")
	enemy.free()


func _test_enemy_drop() -> void:
	# Lejos de Kai, para ver cómo caen y rebotan sin que las recoja.
	var enemy := ENEMY.instantiate() as EnemyBase
	enemy.ai_enabled = false
	room.add_child(enemy)
	enemy.global_position = player.global_position + Vector2(160, -4)
	await _until(func() -> bool: return enemy.is_on_floor())
	var reward := enemy.get_bits_reward()
	enemy.health.take_damage(enemy.max_health)
	await _frames(3)
	_check(_count(PixelBurst) > 0, "al morir, el cuerpo se desintegra en píxeles")
	var coins := _coins()
	_check(_value(coins) == reward, "suelta %d BITS (%d monedas)" % [_value(coins), coins.size()])
	await _wait(0.12)
	_check(coins.any(func(c: BitCoin) -> bool: return c.velocity.y < 0.0 or not c.is_on_floor()), "las monedas saltan al salir")
	await _wait(2.0)
	_check(_coins().all(func(c: BitCoin) -> bool: return c.is_on_floor() and absf(c.velocity.y) < 1.0), "rebotan y quedan en el suelo")
	_check(state.credits == 0, "no se recogen solas si Kai está lejos")
	# Kai camina hasta ellas y las recoge.
	await _collect_all()
	await _wait(0.3)
	await _frames(3)
	_check(state.credits == reward, "Kai recoge los BITS al acercarse (%d)" % state.credits)
	_check(room.get_node("CombatHUD/Credits")._amount.text == str(reward), "el HUD muestra los BITS")
	_check(CreditsDisplay.format_bits(1250) == "1,250", "el HUD separa los miles (1,250)")
	var entry: GrimorioEntry = load("res://data/grimorio/bits.tres")
	_check(state.has_flag(BitCoin.DISCOVERED_FLAG) and entry.is_unlocked(state), "al recoger el primer BIT se desbloquea su página del Grimorio")
	_check(entry.text.contains("Incluso los datos corruptos pueden conservar algo de valor"), "la página tiene el texto de Ariel")


func _test_chest() -> void:
	var before: int = state.credits
	var chest := BitChest.new()
	chest.name = "CofrePrueba"
	chest.bits = 30
	room.add_child(chest)
	chest.global_position = player.global_position + Vector2(40, 0)
	await _frames(3)
	player.teleport_to(chest.global_position + Vector2(-6, 0))
	await _frames(8)
	_action("interact")
	await _frames(3)
	_check(chest.opened and state.has_flag(chest.flag()), "con E se abre el cofre")
	await _wait(0.5)
	await _collect_all()
	await _wait(0.3)
	await _frames(3)
	_check(state.credits == before + 30, "el cofre suelta sus BITS y Kai los recoge (+%d)" % (state.credits - before))
	_action("interact")
	await _frames(3)
	_check(_coins().is_empty() and state.credits == before + 30, "un cofre abierto no vuelve a dar BITS")
	chest.queue_free()
	await _frames(2)
	var again := BitChest.new()
	again.name = "CofrePrueba"
	room.add_child(again)
	await _frames(2)
	_check(again.opened and not again.enabled, "al volver, el cofre sigue abierto")
	again.queue_free()


func _test_quest_reward() -> void:
	var before: int = state.credits
	state.start_quest(&"prologo")
	for step in [&"hablar_profesor", &"revisar_computadora", &"volver_profesor"]:
		state.complete_step(&"prologo", step)
	var quest := QuestDB.get_quest(&"prologo")
	_check(quest.bits_reward > 0 and state.credits == before + quest.bits_reward, "completar una misión da BITS (+%d)" % (state.credits - before))


func _coins() -> Array[BitCoin]:
	var result: Array[BitCoin] = []
	for node in room.get_children():
		if node is BitCoin and not node.is_queued_for_deletion():
			result.append(node)
	return result


func _value(coins: Array[BitCoin]) -> int:
	var total := 0
	for coin in coins:
		total += coin.value
	return total


func _count(type: Variant) -> int:
	var total := 0
	for node in room.get_children():
		if is_instance_of(node, type):
			total += 1
	return total


func _action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


func _until(condition: Callable) -> void:
	for i in 600:
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


## Kai pasa por encima de cada moneda (como al caminar por la zona).
func _collect_all() -> void:
	for i in 30:
		var coins := _coins()
		if coins.is_empty():
			return
		player.teleport_to(coins[0].global_position + Vector2(0, 2))
		await _frames(6)
