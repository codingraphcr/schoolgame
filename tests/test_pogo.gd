extends SceneTree
## Prueba automática: ataque hacia abajo y rebote (pogo, como en Hollow Knight) y la cadencia de ataque.
## En el aire, abajo + J ataca hacia abajo; al golpear a un enemigo, unos pinchos o un nodo de rebote,
## Kai rebota hacia arriba y recupera el doble salto. En el suelo, abajo + J es un ataque normal.
## Ejecutar: godot --headless --path . --script res://tests/test_pogo.gd

const ROOM := "res://tests/fixtures/combat_test_room.tscn"
const NULLBLADE := "res://data/weapons/nullblade.tres"
const ENEMY := preload("res://characters/enemies/weak_password/weak_password.tscn")

var _failures := 0
var player: Player
var room: Room
var _pogos := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.reset()
	change_scene_to_file(ROOM)
	await _wait(0.5)
	room = current_scene as Room
	player = room.player
	await _until(func() -> bool: return player.is_on_floor())
	player.combat.weapon = load(NULLBLADE)
	player.can_double_jump = true
	player.face(1)
	player.combat.pogo.connect(func() -> void: _pogos += 1)

	# Cadencia: después de un ataque hay que esperar casi medio segundo para el siguiente.
	_check(is_equal_approx(player.combat.weapon.cooldown, 0.45), "el ataque tiene una cadencia pausada (0,45 s)")
	_check(player.combat.attack(), "Kai ataca")
	await _wait(0.3)
	_check(not player.combat.attack(), "a los 0,3 s todavía no puede volver a atacar")
	await _wait(0.2)
	_check(player.combat.attack(), "a los 0,5 s ya puede atacar otra vez")
	await _until(func() -> bool: return player.combat.can_attack())

	# En el suelo, abajo + J es un ataque normal (hacia adelante).
	Input.action_press("move_down")
	player.combat.attack()
	_check(not player.combat.is_down_attack(), "en el suelo, abajo + J ataca hacia adelante")
	Input.action_release("move_down")
	await _until(func() -> bool: return player.combat.can_attack())

	# Rebote en un enemigo: daña y Kai sale despedido hacia arriba con el doble salto recuperado.
	var enemy := ENEMY.instantiate() as EnemyBase
	enemy.ai_enabled = false
	room.add_child(enemy)
	enemy.global_position = player.global_position + Vector2(80, -4)
	await _until(func() -> bool: return enemy.is_on_floor())
	var enemy_health := enemy.health.current
	var bounce := await _down_attack_over(enemy.global_position + Vector2(0, -36))
	_check(bounce < -150.0, "al atacar hacia abajo sobre un enemigo, Kai rebota (%.0f px/s)" % bounce)
	_check(enemy.health.current < enemy_health, "el enemigo recibe el golpe")
	_check(_pogos == 1, "suena y avisa el rebote una sola vez")
	_check(player.air_jumps_left == player.max_air_jumps, "el rebote recupera el doble salto")
	enemy.queue_free()
	await _until(func() -> bool: return player.is_on_floor())

	# Rebote en los pinchos: no lastiman si se rebota a tiempo.
	var spikes := room.get_node("Hazards/SpikesFloor") as Spikes
	var health := player.health.current
	bounce = await _down_attack_over(spikes.global_position + Vector2(16, -26))
	_check(bounce < -150.0, "los pinchos sirven para rebotar (%.0f px/s)" % bounce)
	await _frames(4)
	_check(is_equal_approx(player.health.current, health), "rebotar en los pinchos no quita vida")
	await _until(func() -> bool: return player.is_on_floor())
	await _wait(1.0)

	# Rebote en un nodo de rebote flotante.
	var node := PogoNode.new()
	room.add_child(node)
	node.global_position = player.global_position + Vector2(0, -60)
	await _frames(2)
	bounce = await _down_attack_over(node.global_position + Vector2(0, -22))
	_check(bounce < -150.0, "el nodo de rebote sirve para rebotar (%.0f px/s)" % bounce)
	_check(is_instance_valid(node), "el nodo de rebote no se rompe")

	# Atacar hacia abajo en el aire sin nada debajo no rebota.
	var pogos := _pogos
	bounce = await _down_attack_over(player.global_position + Vector2(-200, -120), false)
	_check(_pogos == pogos and bounce > -50.0, "sin nada debajo, el ataque hacia abajo no rebota")

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


## Pone a Kai en el aire en "at", ataca hacia abajo (abajo + J) y devuelve la velocidad vertical
## más hacia arriba que tuvo durante el ataque.
func _down_attack_over(at: Vector2, expect_hit := true) -> float:
	await _until(func() -> bool: return player.combat.can_attack())
	player.teleport_to(at)
	player.velocity = Vector2.ZERO
	await _frames(1)
	Input.action_press("move_down")
	var attacked := player.combat.attack()
	_check(attacked and player.combat.is_down_attack(), "en el aire, abajo + J ataca hacia abajo")
	var best := 0.0
	for i in 20:
		await physics_frame
		best = minf(best, player.velocity.y)
		if expect_hit and best < -150.0:
			break
	Input.action_release("move_down")
	return best


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
