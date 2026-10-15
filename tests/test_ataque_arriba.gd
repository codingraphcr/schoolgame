extends SceneTree
## Prueba automática: ataque hacia arriba con la Nullblade (arriba + J), en el piso y en el aire. Golpea
## a un enemigo que está sobre la cabeza de Kai (y no a uno que está delante), usa la pose del pogo con la
## espada hacia arriba y no empuja a Kai hacia atrás. Sin arriba, el ataque sigue siendo hacia adelante.
## Ejecutar: godot --headless --path . --script res://tests/test_ataque_arriba.gd

const ROOM := "res://tests/fixtures/combat_test_room.tscn"
const NULLBLADE := "res://data/weapons/nullblade.tres"
const ENEMY := preload("res://characters/enemies/weak_password/weak_password.tscn")

var _failures := 0
var player: Player
var room: Room


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.get_node("GameState").reset()
	change_scene_to_file(ROOM)
	await _wait(0.5)
	room = current_scene as Room
	player = room.player
	await _until(func() -> bool: return player.is_on_floor())
	player.combat.weapon = load(NULLBLADE)
	player.face(1)

	# Un enemigo flotando justo sobre la cabeza de Kai y otro delante, a su altura.
	var above := _enemy(player.global_position + Vector2(0, -58))
	var ahead := _enemy(player.global_position + Vector2(24, 0))
	await _frames(3)
	var above_health := above.health.current
	var ahead_health := ahead.health.current
	Input.action_press("move_up")
	_check(player.combat.attack(), "arriba + J: Kai ataca")
	_check(player.combat.is_up_attack(), "el ataque es hacia arriba")
	var visual := player.get_node_or_null("Visual/Body/Kai")
	_check(visual == null or visual.get("_override") == &"arriba_cortar", "usa la pose del pogo (las manos en el mango)")
	_check(player.find_child("UpSlash", false, false) != null, "la Nullblade sale hacia arriba")
	Input.action_release("move_up")
	await _wait(0.3)
	_check(above.health.current < above_health, "golpea al enemigo que está sobre la cabeza")
	_check(is_equal_approx(ahead.health.current, ahead_health), "no golpea al que está delante a su altura")
	_check(absf(player.velocity.x) < 1.0, "no empuja a Kai hacia atrás")
	above.queue_free()
	ahead.queue_free()
	await _until(func() -> bool: return player.combat.can_attack())

	# En el aire también.
	var high := _enemy(player.global_position + Vector2(0, -120))
	await _frames(3)
	var high_health := high.health.current
	Input.action_press("jump")
	await _wait(0.2)
	Input.action_press("move_up")
	player.combat.attack()
	_check(player.combat.is_up_attack() and not player.is_on_floor(), "en el aire, arriba + J también ataca hacia arriba")
	Input.action_release("move_up")
	Input.action_release("jump")
	await _wait(0.3)
	_check(high.health.current < high_health, "saltando, alcanza al enemigo de arriba")
	high.queue_free()
	await _until(func() -> bool: return player.is_on_floor() and player.combat.can_attack())

	# Sin arriba: el ataque de siempre, hacia adelante.
	player.combat.attack()
	_check(not player.combat.is_up_attack() and not player.combat.is_down_attack(), "sin arriba, J ataca hacia adelante")

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


## Un enemigo quieto y flotando en at (no se cae ni se mueve).
func _enemy(at: Vector2) -> EnemyBase:
	var enemy := ENEMY.instantiate() as EnemyBase
	enemy.ai_enabled = false
	enemy.gravity = 0.0
	enemy.max_health = 20.0
	room.add_child(enemy)
	enemy.global_position = at
	return enemy


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _frames(count: int) -> void:
	for i in count:
		await process_frame
		await physics_frame


func _until(condition: Callable) -> void:
	for i in 600:
		if condition.call():
			return
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
