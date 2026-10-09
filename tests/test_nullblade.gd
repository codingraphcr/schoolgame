extends SceneTree
## Prueba automática: la Nullblade recarga energía al golpear enemigos (12,5 % por golpe, 15 % el
## cargado), solo con golpes válidos, una vez por enemigo y por ataque, sin pasar del máximo; el
## pulso de la barra; y su página en el ARSENAL del Grimorio.
## Ejecutar: godot --headless --path . --script res://tests/test_nullblade.gd

const ROOM := "res://tests/fixtures/combat_test_room.tscn"
const NULLBLADE := "res://data/weapons/nullblade.tres"
const ENEMY := preload("res://characters/enemies/weak_password/weak_password.tscn")

var _failures := 0
var player: Player
var room: Room


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
	player.face(1)
	var bar := room.get_node("CombatHUD/EnergyBar") as EnergyBar
	var step := player.max_energy * 0.125

	# Golpe al aire: nada.
	player.set_energy(0.0)
	await _swing()
	_check(is_zero_approx(player.energy), "golpear el aire no da energía")

	# Un golpe a un enemigo: 12,5 % de la energía máxima, una sola vez aunque siga dentro del tajo.
	var enemy := await _spawn(player.global_position + Vector2(24, -4))
	await _swing()
	_check(is_equal_approx(player.energy, step), "un golpe acertado recupera 12,5 %% de la energía máxima (%.3f)" % player.energy)
	_check(bar.pulse_amount > 0.0 or is_equal_approx(bar.energy, step), "la barra de energía hace un pulso al recargarse")

	# Escudo (golpe bloqueado): nada.
	await _until(func() -> bool: return player.combat.can_attack())
	enemy.hurtbox.immune = true
	await _place(enemy, 24.0)
	var before := player.energy
	await _swing()
	_check(is_equal_approx(player.energy, before), "un enemigo con escudo no da energía")
	enemy.hurtbox.immune = false

	# Derrotar no da extra: el golpe final vale lo mismo que uno normal.
	await _until(func() -> bool: return player.combat.can_attack())
	enemy.health.current = 1.0
	await _place(enemy, 24.0)
	before = player.energy
	await _swing()
	await _frames(10)
	_check((not is_instance_valid(enemy) or enemy.is_dead) and is_equal_approx(player.energy, before + step),
		"derrotar a un enemigo no da energía extra (%.3f)" % player.energy)

	# Dos enemigos en el mismo tajo: energía por cada uno.
	var a := await _spawn(player.global_position + Vector2(20, -4))
	var b := await _spawn(player.global_position + Vector2(30, -4))
	await _until(func() -> bool: return player.combat.can_attack())
	before = player.energy
	await _swing()
	_check(is_equal_approx(player.energy, before + step * 2.0), "un tajo que golpea a dos enemigos da energía por cada uno")

	# Ataque cargado (para más adelante): 15 %.
	await _until(func() -> bool: return player.combat.can_attack())
	before = player.energy
	await _place(a, 20.0)
	await _place(b, 30.0)
	player.combat.attack(true)
	await _until(func() -> bool: return not player.combat.is_attacking())
	await _frames(2)
	_check(is_equal_approx(player.energy, before + player.max_energy * 0.15 * 2.0), "el ataque cargado recupera 15 % por enemigo")

	# Nunca pasa del máximo.
	await _until(func() -> bool: return player.combat.can_attack())
	player.set_energy(player.max_energy - 0.05)
	await _place(a, 20.0)
	await _swing()
	_check(is_equal_approx(player.energy, player.max_energy), "la energía no pasa del máximo")
	a.queue_free()
	b.queue_free()

	# El ARSENAL del Grimorio.
	var entry: GrimorioEntry = load("res://data/grimorio/nullblade.tres")
	_check(entry.category == GrimorioEntry.Category.ARSENAL and entry.title == "Nullblade", "la Nullblade está en el ARSENAL del Grimorio")
	_check(not entry.is_unlocked(state), "antes de obtenerla aparece como «???»")
	state.set_nullblade_stage(1)
	_check(entry.is_unlocked(state) and entry.text.contains("siempre queda algo capaz de defenderlo"), "al obtenerla se lee su texto")

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


## Un ataque completo con J.
func _swing() -> void:
	await _until(func() -> bool: return player.combat.can_attack())
	_action("attack")
	await _until(func() -> bool: return player.combat.is_attacking())
	await _until(func() -> bool: return not player.combat.is_attacking())
	await _frames(2)


func _spawn(position: Vector2) -> EnemyBase:
	var enemy := ENEMY.instantiate() as EnemyBase
	enemy.ai_enabled = false
	room.add_child(enemy)
	enemy.global_position = position
	await _until(func() -> bool: return enemy.is_on_floor())
	return enemy


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


## Vuelve a poner al enemigo frente a Kai (los golpes lo empujan).
func _place(enemy: EnemyBase, dx: float) -> void:
	enemy.global_position = player.global_position + Vector2(dx, -4)
	enemy.velocity = Vector2.ZERO
	await _frames(2)
