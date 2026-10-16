extends SceneTree
## Prueba automática: E2. Valores configurables (EconomyConfig), recompensas únicas que no se cobran
## dos veces (claim_reward / claim_drop) y se guardan, enemigos por rango, cofres y que los Ecos que
## quedan en el suelo no se pierden al salir de la sala.
## Ejecutar: godot --headless --path . --script res://tests/test_economy.gd

const ROOM := "res://tests/fixtures/combat_test_room.tscn"
const ENEMY := preload("res://characters/enemies/weak_password/weak_password.tscn")

var _failures := 0
var state: Node
var economy: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	economy = root.get_node("Economy")
	economy.rng.seed = 2026
	_test_config()
	_test_unique_rewards()
	change_scene_to_file(ROOM)
	await _wait(0.5)
	await _test_enemies()
	await _test_chest()
	await _test_shards_not_lost()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_config() -> void:
	var config: EconomyConfig = economy.config
	_check(config != null and config.resource_path == "res://data/economy/economia.tres", "los valores salen de data/economy/economia.tres")
	var expected := {
		EconomyConfig.Source.ENEMY_COMMON: Vector2i(1, 3), EconomyConfig.Source.ENEMY_SPECIAL: Vector2i(4, 8),
		EconomyConfig.Source.BOSS: Vector2i(60, 90), EconomyConfig.Source.TERMINAL: Vector2i(10, 20),
		EconomyConfig.Source.CHALLENGE: Vector2i(8, 15),
		EconomyConfig.Source.SIDE_QUEST: Vector2i(30, 50), EconomyConfig.Source.HIDDEN_DEPOSIT: Vector2i(10, 25),
	}
	var ok := true
	for source in expected:
		ok = ok and config.range_for(source) == expected[source]
	_check(ok, "rangos (equilibrados para el tope de 999): común 1–3, especial 4–8, jefe 60–90, terminal 10–20, desafío 8–15, misión 30–50, depósito 10–25")
	var inside := true
	for source in expected:
		for i in 40:
			var value: int = economy.roll(source)
			inside = inside and value >= expected[source].x and value <= expected[source].y
	_check(inside, "los valores sorteados quedan dentro de su rango")
	_check(economy.reward_for(EconomyConfig.Source.TERMINAL, 45) == 45, "una cantidad fija tiene prioridad sobre el sorteo")
	_check(config.death_penalty == 0.10 and config.death_penalty_max == 100, "la penalización (10 %, máximo 100) también es configurable")
	state.reset()
	economy.add_ecos(990)
	economy.add_ecos(50)
	_check(economy.ecos == Economy.MAX_ECOS and Economy.MAX_ECOS == 999, "la bolsa llega como máximo a 999 Ecos (lo que sobra se pierde)")
	state.reset()


func _test_unique_rewards() -> void:
	state.reset()
	_check(economy.claim_reward(&"terminal:prueba", 40) == 40 and economy.ecos == 40, "una recompensa única se paga la primera vez")
	_check(economy.claim_reward(&"terminal:prueba", 40) == 0 and economy.ecos == 40, "y no se puede cobrar dos veces")
	_check(economy.claim_reward(&"", 10) == 0 and economy.claim_reward(&"x", 0) == 0 and economy.ecos == 40, "ids vacíos o cantidades inválidas no pagan nada")
	_check(economy.claim_drop(&"cofre:a") and not economy.claim_drop(&"cofre:a"), "una recompensa que cae al suelo también se registra una sola vez")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	state.reset()
	_check(not economy.is_claimed(&"terminal:prueba") and economy.ecos == 0, "una partida nueva no tiene recompensas cobradas")
	state.from_dict(saved)
	_check(economy.is_claimed(&"terminal:prueba") and economy.is_claimed(&"cofre:a") and economy.ecos == 40,
		"las recompensas cobradas se guardan con la partida")
	_check(economy.claim_reward(&"terminal:prueba", 40) == 0, "después de cargar, sigue sin poder cobrarse dos veces")
	# Misiones: una sola vez.
	state.reset()
	state.start_quest(&"prologo")
	for step in [&"hablar_profesor", &"revisar_computadora", &"volver_profesor"]:
		state.complete_step(&"prologo", step)
	_check(economy.ecos == 15 and economy.is_claimed(&"mision:prologo"), "completar una misión paga su recompensa (prólogo: 15) y queda registrada")


func _test_enemies() -> void:
	var room := current_scene as Room
	var player := room.player
	state.reset()
	var ranges := [[EnemyBase.Rank.COMUN, 1, 3], [EnemyBase.Rank.ESPECIAL, 4, 8], [EnemyBase.Rank.JEFE, 60, 90]]
	for entry in ranges:
		var enemy := _enemy(room, Vector2(-500, 0))
		enemy.rank = entry[0]
		enemy.reward_id = &""
		var reward := enemy.get_ecos_reward()
		_check(reward >= entry[1] and reward <= entry[2] and enemy.get_ecos_reward() == reward,
			"enemigo %s: %d Ecos (entre %d y %d, siempre el mismo)" % [["común", "especial", "jefe"][entry[0]], reward, entry[1], entry[2]])
		enemy.queue_free()
	var first := _enemy(room, player.global_position + Vector2(200, -4))
	_check(first.rank == EnemyBase.Rank.ESPECIAL and first.reward_id == &"enemigo:contrasena_debil", "la «Contraseña débil» es especial y de la historia (recompensa única)")
	first.health.take_damage(first.max_health)
	await _frames(4)
	var dropped := _shards(room)
	_check(dropped.size() > 0 and economy.is_claimed(&"enemigo:contrasena_debil"), "la primera vez suelta sus Ecos")
	for shard in dropped:
		shard.discard()
	await _frames(2)
	var second := _enemy(room, player.global_position + Vector2(200, -4))
	second.health.take_damage(second.max_health)
	await _frames(4)
	_check(_shards(room).is_empty(), "vencerla otra vez no da Ecos de nuevo")
	await _frames(20)


func _test_chest() -> void:
	var room := current_scene as Room
	state.reset()
	var chest := EcoChest.new()
	chest.chest_id = &"prueba"
	chest.ecos = 12
	room.add_child(chest)
	chest.global_position = Vector2(-400, 0)
	await _frames(2)
	chest.open()
	await _frames(3)
	var value := 0
	for shard in _shards(room):
		value += shard.value
		shard.discard()
	_check(value == 12 and economy.is_claimed(&"cofre:prueba"), "el cofre suelta sus Ecos y queda registrado")
	chest.queue_free()
	state._flags.erase(chest.flag())  # Como si se perdiera la marca de «abierto».
	await _frames(2)
	var again := EcoChest.new()
	again.chest_id = &"prueba"
	again.ecos = 12
	room.add_child(again)
	await _frames(2)
	again.open()
	await _frames(3)
	_check(_shards(room).is_empty(), "aunque se perdiera la marca del cofre, sus Ecos no se cobran dos veces")
	again.queue_free()


func _test_shards_not_lost() -> void:
	var room := current_scene as Room
	state.reset()
	EcoShard.spawn_burst(room, Vector2(-600, -200), 12)
	await _frames(2)
	_check(economy.ecos == 0, "los Ecos en el suelo todavía no cuentan")
	change_scene_to_file(ROOM)
	await _wait(0.3)
	_check(economy.ecos == 12, "si Kai sale de la sala sin recogerlos, se suman solos (no se pierden)")


func _enemy(room: Node, at: Vector2) -> WeakPasswordEnemy:
	var enemy := ENEMY.instantiate() as WeakPasswordEnemy
	enemy.ai_enabled = false
	room.add_child(enemy)
	enemy.global_position = at
	return enemy


func _shards(room: Node) -> Array[EcoShard]:
	var result: Array[EcoShard] = []
	for node in room.get_children():
		if node is EcoShard and not node.is_queued_for_deletion():
			result.append(node)
	return result


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
