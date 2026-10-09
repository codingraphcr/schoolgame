extends SceneTree
## Prueba automática: dash, doble salto y deslizamiento/salto de pared.
## Ejecutar: godot --headless --path . --script res://tests/test_player_abilities.gd

const ROOM := "res://tests/fixtures/combat_test_room.tscn"
const FLOOR_Y := 480.0
const NEAR_LEFT_WALL := Vector2(40, 300)  # En el aire, junto a la pared izquierda (cara interior en x=16)

var _failures := 0
var _double_jumps := 0
var _wall_jumps := 0
var room: Room
var player: Player


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.reset()
	state.set_dash_level(2)
	state.unlock_double_jump()
	state.unlock_wall_jump()
	change_scene_to_file(ROOM)
	await _frames(30)
	room = current_scene as Room
	player = room.player
	player.double_jumped.connect(func() -> void: _double_jumps += 1)
	player.wall_jumped.connect(func() -> void: _wall_jumps += 1)

	await _test_ground_dash()
	await _test_air_dash()
	await _test_double_jump()
	await _test_wall_slide_and_jump()

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_ground_dash() -> void:
	await _reset_at(room.spawn_point.global_position)
	await _face_right()
	var start := player.global_position
	await _press("dash")
	await _frames(2)
	_check(player.is_dashing and player.state == Player.State.DASH, "dash en el suelo: estado DASH")
	_check(is_equal_approx(player.velocity.x, player.dash_speed), "dash: velocidad %.0f px/s" % player.velocity.x)
	_check(player.is_invulnerable(), "dash: invulnerable durante el dash")
	await _until_dash_ends()
	var distance := player.global_position.x - start.x
	var expected := player.dash_speed * player.dash_duration
	_check(absf(distance - expected) < 8.0, "dash: recorre ≈ %.0f px (medido %.1f)" % [expected, distance])
	_check(absf(player.global_position.y - start.y) < 0.5, "dash: no cambia la altura")
	_check(not player.is_invulnerable(), "dash: deja de ser invulnerable al terminar")

	Input.action_release("dash")
	await _press("dash")
	await _frames(2)
	_check(not player.is_dashing, "dash: respeta el tiempo de reutilización")
	Input.action_release("dash")
	await _frames(int(player.dash_cooldown * 60.0) + 2)
	await _press("dash")
	await _frames(2)
	_check(player.is_dashing, "dash: disponible de nuevo tras el tiempo de reutilización")
	Input.action_release("dash")
	await _until_dash_ends()


func _test_air_dash() -> void:
	var original_cooldown := player.dash_cooldown
	player.dash_cooldown = 0.0  # Para comprobar solo el límite de un dash en el aire
	await _reset_at(room.spawn_point.global_position)
	await _face_right()
	await _press("jump")
	await _frames(10)
	await _press("dash")
	await _frames(2)
	var dash_y := player.global_position.y
	await _frames(3)
	_check(player.is_dashing and absf(player.global_position.y - dash_y) < 0.5, "dash aéreo: mantiene la altura durante el dash")
	await _until_dash_ends()
	Input.action_release("dash")
	await _press("dash")
	await _frames(2)
	_check(not player.is_dashing, "dash aéreo: solo uno por salto")
	Input.action_release("dash")
	Input.action_release("jump")
	await _until_on_floor()
	await _frames(2)
	await _press("dash")
	await _frames(2)
	_check(player.is_dashing, "dash aéreo: se recupera al tocar el suelo")
	Input.action_release("dash")
	await _until_dash_ends()
	player.dash_cooldown = original_cooldown


func _test_double_jump() -> void:
	player.can_double_jump = false
	await _reset_at(room.spawn_point.global_position)
	var before := _double_jumps
	await _jump_then_press_again_at_apex()
	_check(_double_jumps == before, "doble salto bloqueado: no salta en el aire si no está desbloqueado")
	await _until_on_floor()

	player.can_double_jump = true
	await _reset_at(room.spawn_point.global_position)
	var start_y := player.global_position.y
	before = _double_jumps
	var min_y := await _jump_then_press_again_at_apex()
	_check(_double_jumps == before + 1, "doble salto: salta una vez en el aire")
	var height := start_y - min_y
	_check(height > player.jump_height + 40.0, "doble salto: alcanza más altura (%.0f px)" % height)
	Input.action_release("jump")
	await _press("jump")
	await _frames(2)
	_check(_double_jumps == before + 1, "doble salto: no hay un tercer salto")
	Input.action_release("jump")
	await _until_on_floor()
	_check(player.air_jumps_left == player.max_air_jumps, "doble salto: se recupera al tocar el suelo")


func _test_wall_slide_and_jump() -> void:
	player.can_wall_jump = false
	await _reset_at(NEAR_LEFT_WALL)
	Input.action_press("move_left")
	await _frames(20)
	_check(not player.is_wall_sliding and player.velocity.y > 100.0, "pared bloqueada: cae normalmente si no está desbloqueado")
	Input.action_release("move_left")
	await _until_on_floor()

	player.can_wall_jump = true
	await _reset_at(NEAR_LEFT_WALL)
	player.air_jumps_left = 0  # Simula que ya gastó el doble salto
	Input.action_press("move_left")
	for i in 60:
		await physics_frame
		if player.is_wall_sliding:
			break
	await _frames(10)
	_check(player.state == Player.State.WALL_SLIDE, "pared: se desliza al empujar contra ella")
	_check(player.velocity.y <= player.wall_slide_speed + 0.1, "pared: cae despacio (%.0f px/s)" % player.velocity.y)
	_check(player.air_jumps_left == player.max_air_jumps, "pared: recupera el doble salto")
	_check(player.facing == 1, "pared: mira hacia el lado contrario a la pared")
	var before := _wall_jumps
	await _press("jump")
	await _frames(2)
	_check(_wall_jumps == before + 1 and player.velocity.x > 0.0 and player.velocity.y < 0.0,
		"pared: el salto de pared impulsa hacia arriba y lejos de la pared")
	Input.action_release("jump")
	Input.action_release("move_left")
	await _until_on_floor()


## Salta, y en el punto más alto vuelve a pulsar. Devuelve la menor altura (y) alcanzada.
func _jump_then_press_again_at_apex() -> float:
	var min_y := player.global_position.y
	await _press("jump")
	for i in 120:
		await physics_frame
		min_y = minf(min_y, player.global_position.y)
		if i == 22:
			Input.action_release("jump")
		elif i == 23:
			Input.action_press("jump")
		if i > 30 and player.is_on_floor():
			break
	return min_y


func _reset_at(position: Vector2) -> void:
	for action in ["move_left", "move_right", "jump", "dash"]:
		Input.action_release(action)
	player.teleport_to(position)
	await _frames(5)


func _face_right() -> void:
	await _press("move_right")
	await _frames(2)
	Input.action_release("move_right")
	await _frames(20)


## Pulsa una acción dentro del cuadro de física. El jugador la detecta en el cuadro
## de física siguiente, por eso las comprobaciones esperan 2 cuadros tras pulsar.
func _press(action: String) -> void:
	await physics_frame
	Input.action_press(action)


func _frames(count: int) -> void:
	for i in count:
		await process_frame  # Teclas y HUD se procesan en cuadros de dibujo.
		await physics_frame


func _until_dash_ends() -> void:
	for i in 60:
		if not player.is_dashing:
			return
		await physics_frame


func _until_on_floor() -> void:
	for i in 180:
		await physics_frame
		if player.is_on_floor():
			return


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
