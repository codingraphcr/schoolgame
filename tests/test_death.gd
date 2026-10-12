extends SceneTree
## Prueba automática: muerte y reaparición de Kai (hoja de Ariel). Al perder la última máscara:
## aturdido (daño) → de rodillas → desplomado (muerte) → se desintegra en píxeles → pantalla
## "CONEXIÓN PERDIDA..." → reaparece en el punto de control: se rearma, se levanta y recupera el
## control con la vida llena. Pogo: el ataque hacia abajo tiene su propia pose (no la de salto).
## Ejecutar: godot --headless --path . --script res://tests/test_death.gd

const ROOM := "res://tests/fixtures/combat_test_room.tscn"

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
	var kai := player.get_node("Visual/Body/Kai") as KaiVisual
	await _until(func() -> bool: return player.is_on_floor())
	var spawn := player.global_position
	player.teleport_to(spawn + Vector2(150, -2))
	await _until(func() -> bool: return player.is_on_floor())

	# Pogo con su propia pose.
	player.combat.weapon = load("res://data/weapons/nullblade.tres")
	player.teleport_to(player.global_position + Vector2(0, -60))
	await _frames(2)
	Input.action_press("move_down")
	player.combat.attack()
	Input.action_release("move_down")
	await _frames(2)
	_check(kai.current_animation() == &"caer", "el ataque hacia abajo tiene su propia pose (no la de salto)")
	await _until(func() -> bool: return player.is_on_floor() and player.combat.can_attack())
	await _wait(0.3)

	# Muerte.
	var seen: Array[StringName] = []
	var lost_screen := [false]
	player.health.current = 0.5
	var hit := HitData.new()
	hit.damage = 1.0
	player.damage._on_hit_received(hit)
	_check(player.controls_locked and player.damage.is_respawning, "al morir, Kai pierde el control")
	for i in 600:
		var anim := kai.current_animation()
		if seen.is_empty() or seen[-1] != anim:
			seen.append(anim)
		if root.find_children("*", "ConnectionLostScreen", true, false).size() > 0:
			lost_screen[0] = true
		if not player.controls_locked:
			break
		await process_frame
		await physics_frame
	var order := [&"dano", &"curar_suelo_inicio", &"muerte"]
	var found := 0
	for anim in seen:
		if found < order.size() and anim == order[found]:
			found += 1
	_check(found == order.size(), "aturdido, de rodillas y desplomado, en ese orden (%s)" % str(seen))
	_check(lost_screen[0], "aparece la pantalla «CONEXIÓN PERDIDA...»")
	_check(player.global_position.distance_to(spawn) < 24.0, "reaparece en el punto de control")
	_check(not player.controls_locked and not player.damage.is_respawning, "al terminar recupera el control")
	_check(is_equal_approx(player.health.current, player.health.max_health), "reaparece con la vida llena")
	var sprites := kai.find_children("*", "AnimatedSprite2D", false, false)
	var sprite: AnimatedSprite2D = sprites[0] if not sprites.is_empty() else null
	_check(sprite == null or sprite.material == null, "Kai queda entero (sin el efecto de disolverse)")
	_check(root.find_children("*", "DeathSequence", true, false).is_empty(), "la animación de muerte se borra al terminar")

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


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
