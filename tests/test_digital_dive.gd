extends SceneTree
## Prueba automática: Kai es absorbido por la computadora del laboratorio (DigitalDive), pasa por la
## pantalla de carga, se materializa dentro de la PC del profesor y puede volver al laboratorio.
## Ejecutar: godot --headless --path . --script res://tests/test_digital_dive.gd

const PASILLO := "res://world/zones/zone0/pasillo_laboratorio.tscn"
const COMPUTER := Vector2(716, 304)

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.reset()
	state.start_quest(&"prologo")
	for step in [&"hablar_profesor", &"revisar_computadora", &"volver_profesor"]:
		state.complete_step(&"prologo", step)
	_check(state.get_current_step(&"contrasena_profesor") == &"entrar_pc", "preparación: misión del profesor en curso")

	change_scene_to_file(PASILLO)
	await _wait(0.5)
	var room := current_scene as Room
	var player := room.player
	player.teleport_to(COMPUTER)
	await _frames(8)
	var computer := room.get_node("LabComputer") as Interactable
	_check(computer._prompt.visible and computer._prompt.text == "E: revisar la cuenta del profesor", "la computadora ofrece revisar la cuenta")
	_action("interact")
	await _frames(3)
	_check(player.controls_locked, "Kai queda inmóvil mientras la pantalla lo absorbe")
	await _wait(1.0)
	_check(room.camera.zoom.x > 2.3, "la cámara se acerca a la pantalla (zoom %.1f)" % room.camera.zoom.x)
	await _wait(1.3)
	_check(not player.get_node("Visual/Body").visible, "Kai desaparece dentro de la pantalla")
	_check(get_nodes_in_group(&"loading_screen").size() == 1, "aparece la pantalla de carga")

	for i in 600:
		await physics_frame
		if current_scene and current_scene.name == "EscritorioProfesor":
			break
	room = current_scene as Room
	_check(room != null and room.name == "EscritorioProfesor", "Kai llega al escritorio de la computadora del profesor")
	if room == null:
		quit(1)
		return
	player = room.player
	_check(player.controls_locked, "al llegar, Kai se está materializando")
	await _wait(1.5)
	_check(get_nodes_in_group(&"loading_screen").is_empty(), "la pantalla de carga se cierra")
	var body := player.get_node("Visual/Body") as Node2D
	_check(body.visible and body.scale.is_equal_approx(Vector2.ONE), "Kai termina de materializarse")
	_check(not player.controls_locked, "y recupera los controles")
	var visual := player.get_node("Visual") as CanvasItem
	_check(visual.modulate.b > visual.modulate.r, "dentro de la PC, Kai es un alma digital (brillo celeste)")
	_check(room.camera.limit_right == 3360, "la sala de la PC tiene sus límites (3360 px)")
	_check(room.get_node("CombatHUD/Objective")._text.text.contains("cuenta del profesor"), "el objetivo sigue a la vista")

	Input.action_press("move_left")
	for i in 300:
		await physics_frame
		if current_scene == null or current_scene.name != "EscritorioProfesor":
			break
	Input.action_release("move_left")
	await _wait(1.0)
	room = current_scene as Room
	_check(room != null and room.name == "PasilloLaboratorio", "la salida izquierda vuelve al laboratorio")
	if room:
		_check(absf(room.player.global_position.x - 686.0) < 16.0, "Kai aparece junto a la computadora (x=%.0f)" % room.player.global_position.x)
		await _wait(1.2)
		_check(not room.player.controls_locked, "tras materializarse en el laboratorio, recupera los controles")

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


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
