extends SceneTree
## Prueba automática: primera sala real (Zona 0: Pasillo + Laboratorio) con el arte de Ariel.
## Ejecutar: godot --headless --path . --script res://tests/test_zone0.gd

const MENU := "res://ui/menus/main_menu/main_menu.tscn"
const FLOOR_Y := 304.0
const TRAY_1 := Vector2(488, 304)  # Bajo la primera bandeja de cables (superficie en y=256)

var _failures := 0
var state: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	# Progreso de una partida anterior: "Jugar" debe empezar de cero.
	state.set_dash_level(2)
	state.unlock_double_jump()
	state.add_credits(300)

	change_scene_to_file(MENU)
	await _frames(20)
	current_scene.get_node("%PlayButton").pressed.emit()
	await create_timer(1.2, true, false, true).timeout
	var room := current_scene as Room
	_check(room != null and room.name == "PasilloLaboratorio", "Jugar abre el Pasillo + Laboratorio")
	if room == null:
		quit(1)
		return
	var player := room.player

	await _test_new_game(room, player)
	await _test_layout(room, player)
	await _test_back_to_menu()

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_new_game(room: Room, player: Player) -> void:
	_check(player.dash_level == 0 and not player.can_double_jump and not player.can_wall_jump,
		"partida nueva: Kai es un alumno común (sin dash, doble salto ni pared)")
	_check(not state.vision_unlocked and state.nullblade_stage == 0, "partida nueva: sin Visión Digital ni Nullblade")
	_check(state.credits == 0, "partida nueva: 0 créditos")
	_check(room.get_node("CombatHUD/Masks").get_child_count() == 4, "el HUD muestra 4 máscaras")
	_check(player.is_on_floor() and absf(player.global_position.y - FLOOR_Y) < 1.0, "Kai aparece de pie en el pasillo")
	var kai := player.get_node("Visual/Body/Kai") as KaiVisual
	_check(kai != null and kai.current_animation() == &"quieto", "Kai es el diseño de Ariel (animación quieto)")
	await _press("dash")
	await _frames(2)
	Input.action_release("dash")
	_check(not player.is_dashing, "sin dash adquirido, Shift no hace nada")


func _test_layout(room: Room, player: Player) -> void:
	var camera := room.camera
	_check(camera.limit_left == 0 and camera.limit_right == 960 and camera.limit_top == 0 and camera.limit_bottom == 368,
		"límites de cámara = sala (0, 0, %d, %d)" % [camera.limit_right, camera.limit_bottom])

	Input.action_press("move_right")
	await _frames(10)
	var kai := player.get_node("Visual/Body/Kai") as KaiVisual
	_check(kai.current_animation() == &"correr", "al correr usa la animación correr")
	var reached_lab := false
	for i in 600:
		await physics_frame
		if player.global_position.x > 760.0:
			reached_lab = true
			break
	Input.action_release("move_right")
	_check(reached_lab and player.is_on_floor(), "se puede caminar del pasillo al laboratorio (x=%.0f)" % player.global_position.x)

	player.teleport_to(TRAY_1)
	await _frames(5)
	await _press("jump")
	await _frames(40)
	Input.action_release("jump")
	for i in 120:
		await physics_frame
		if player.is_on_floor():
			break
	_check(absf(player.global_position.y - 256.0) < 1.0, "las bandejas de cables son plataformas (y=%.0f)" % player.global_position.y)


func _test_back_to_menu() -> void:
	var event := InputEventAction.new()
	event.action = &"pause"
	event.pressed = true
	Input.parse_input_event(event)
	await create_timer(1.2, true, false, true).timeout
	_check(current_scene != null and current_scene.name == "MainMenu", "Esc vuelve al menú principal")


func _press(action: String) -> void:
	await physics_frame
	Input.action_press(action)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
