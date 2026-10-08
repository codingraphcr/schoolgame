extends SceneTree
## Prueba automática: movimiento del jugador en la sala de pruebas.
## Ejecutar: godot --headless --path . --script res://tests/test_player_movement.gd

const ROOM := "res://world/test/combat_test_room.tscn"
const FLOOR_Y := 480.0  # Superficie del suelo de la sala (fila 30 × 16 px)
const PIT_EDGE_X := 600.0  # Un poco antes del primer hueco (columna 40)
const ONE_WAY_X := 1024.0  # Bajo la primera plataforma de un sentido (superficie en y=416)
const HIGH_LEDGE := Vector2(1750, 192)  # Cima antes de la caída larga (borde derecho en x=1776)
const GAP6_START := Vector2(850, 480)  # Antes del hueco de 6 bloques (x 896–992)

var _failures := 0
var _jumps := 0
var room: Room
var player: Player


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file(ROOM)
	await _frames(30)
	room = current_scene as Room
	player = room.player
	# Esta prueba mide el movimiento base: sin doble salto ni salto de pared.
	player.can_double_jump = false
	player.can_wall_jump = false
	player.jumped.connect(func() -> void: _jumps += 1)

	await _test_ground_movement()
	await _test_jump_heights()
	await _test_coyote_time()
	await _test_jump_buffer()
	await _test_gap_six()
	await _test_one_way_platform()
	await _test_respawn_and_camera()

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_ground_movement() -> void:
	_check(player.is_on_floor(), "aparece sobre el suelo")
	_check(is_equal_approx(player.global_position.y, FLOOR_Y), "aparece en el punto de inicio (y=%.1f)" % player.global_position.y)
	var start_x := player.global_position.x
	await _press("move_right")
	await _frames(30)
	_check(is_equal_approx(player.velocity.x, player.max_speed), "alcanza la velocidad máxima (%.1f)" % player.velocity.x)
	_check(player.state == Player.State.RUN, "estado RUN al correr")
	Input.action_release("move_right")
	await _frames(15)
	_check(is_zero_approx(player.velocity.x), "se detiene al soltar (vx=%.1f)" % player.velocity.x)
	_check(player.global_position.x > start_x + 40.0, "avanzó hacia la derecha")
	_check(player.state == Player.State.IDLE, "estado IDLE al detenerse")


func _test_jump_heights() -> void:
	var full := await _measure_jump(-1)
	_check(full > player.jump_height - 4.0 and full < player.jump_height + 6.0,
		"salto completo ≈ %.0f px (medido %.1f)" % [player.jump_height, full])
	var short := await _measure_jump(1)
	_check(short > 5.0 and short < player.jump_height * 0.4, "salto corto al soltar rápido (medido %.1f)" % short)


func _test_coyote_time() -> void:
	player.teleport_to(Vector2(PIT_EDGE_X, FLOOR_Y))
	await _frames(5)
	var jumps_before := _jumps
	await _press("move_right")
	await _until_airborne()
	await _frames(3)  # 0,05 s después de salir del borde
	await _press("jump")
	await _frames(2)
	_check(_jumps == jumps_before + 1 and player.velocity.y < 0.0, "coyote time: salta 0,05 s después del borde")
	Input.action_release("jump")
	Input.action_release("move_right")
	await _until_on_floor()

	# En la caída larga, para que no toque el suelo (el jump buffer haría saltar al aterrizar).
	player.teleport_to(HIGH_LEDGE)
	await _frames(5)
	jumps_before = _jumps
	await _press("move_right")
	await _until_airborne()
	Input.action_release("move_right")
	await _frames(12)  # 0,2 s: ya pasó el coyote time
	await _press("jump")
	await _frames(2)
	_check(_jumps == jumps_before and player.velocity.y > 0.0, "coyote time: no salta 0,2 s después del borde")
	Input.action_release("jump")
	await _until_on_floor()


func _test_jump_buffer() -> void:
	player.teleport_to(room.spawn_point.global_position)
	await _frames(5)
	await _press("jump")
	await _frames(20)
	Input.action_release("jump")
	# Espera a estar cayendo y a ~0,08 s del suelo para pulsar de nuevo.
	for i in 120:
		await physics_frame
		if player.velocity.y > 0.0 and FLOOR_Y - player.global_position.y <= player.velocity.y * 0.08:
			break
	var jumps_before := _jumps
	_check(not player.is_on_floor(), "jump buffer: se pulsa antes de tocar el suelo")
	Input.action_press("jump")
	await _frames(12)
	_check(_jumps == jumps_before + 1, "jump buffer: salta al aterrizar sin volver a pulsar")
	Input.action_release("jump")
	await _until_on_floor()


func _test_gap_six() -> void:
	player.teleport_to(GAP6_START)
	await _frames(5)
	await _press("move_right")
	await _until_airborne()
	await _press("jump")  # Salto apurando el borde (coyote time)
	await _frames(10)
	await _until_on_floor()
	Input.action_release("jump")
	Input.action_release("move_right")
	_check(player.global_position.x > 992.0 and absf(player.global_position.y - FLOOR_Y) < 1.0,
		"cruza el hueco de 6 bloques saltando en el borde (x=%.0f, y=%.0f)" % [player.global_position.x, player.global_position.y])
	await _frames(15)


func _test_one_way_platform() -> void:
	player.teleport_to(Vector2(ONE_WAY_X, FLOOR_Y))
	await _frames(5)
	await _press("jump")
	await _frames(60)
	Input.action_release("jump")
	await _until_on_floor()
	_check(absf(player.global_position.y - 416.0) < 1.0,
		"atraviesa desde abajo y queda sobre la plataforma (y=%.1f)" % player.global_position.y)


func _test_respawn_and_camera() -> void:
	player.teleport_to(Vector2(200, room.bounds.end.y + 200))
	await _frames(3)
	_check(player.global_position.distance_to(room.spawn_point.global_position) < 2.0, "reaparece al caer fuera de la sala")
	var camera := room.camera
	_check(camera.limit_left == 0 and camera.limit_top == 0 and camera.limit_right == 2560 and camera.limit_bottom == 544,
		"límites de cámara = sala (%d, %d, %d, %d)" % [camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom])
	_check(camera.zoom == Vector2(2, 2), "zoom de cámara ×2")


## Salta y devuelve la altura alcanzada. hold_frames < 0 mantiene el botón todo el salto.
func _measure_jump(hold_frames: int) -> float:
	player.teleport_to(room.spawn_point.global_position)
	await _frames(5)
	var start_y := player.global_position.y
	var min_y := start_y
	await _press("jump")
	for i in 90:
		await physics_frame
		if hold_frames >= 0 and i == hold_frames:
			Input.action_release("jump")
		min_y = minf(min_y, player.global_position.y)
		if i > 5 and player.is_on_floor():
			break
	Input.action_release("jump")
	await _frames(5)
	return start_y - min_y


func _press(action: String) -> void:
	# Pulsar dentro del cuadro de física para que is_action_just_pressed lo detecte.
	await physics_frame
	Input.action_press(action)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _until_airborne() -> void:
	for i in 120:
		await physics_frame
		if not player.is_on_floor():
			return


func _until_on_floor() -> void:
	for i in 180:
		await physics_frame
		if player.is_on_floor():
			return


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
