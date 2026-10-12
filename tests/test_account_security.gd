extends SceneTree
## Prueba automática: H4d. El jugador crea la contraseña nueva (PasswordWindow; la ventana en sí se
## prueba en test_custom_password.gd) y elige el método de verificación en dos pasos (ChoiceWindow); al terminar: Visión Digital desbloqueada, misión completada con
## sus Ecos, el destello de la Nullblade se apaga y Kai vuelve al laboratorio.
## Ejecutar: godot --headless --path . --script res://tests/test_account_security.gd

const PC := "res://world/zones/pc_profesor/escritorio.tscn"
const CHALLENGE := "res://data/challenges/cuenta_profesor_seguridad.tres"
const NULLBLADE := "res://data/weapons/nullblade.tres"
const SECRET := "girasol-cohete-papaya-trueno-31"

var _failures := 0
var state: Node
var vision: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	vision = root.get_node("DigitalVision")
	_test_content()
	await _test_window()
	await _test_in_game()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_content() -> void:
	var challenge: ChoiceChallenge = load(CHALLENGE)
	_check(challenge.questions.size() == 1, "el desafío de elección es la verificación en dos pasos (la contraseña la crea el jugador)")
	var question := challenge.questions[0]
	var correct := question.options.filter(func(o: ChoiceOption) -> bool: return o.correct)
	_check(question.options.size() == 3 and correct.size() == 1, "3 opciones y una sola correcta")
	_check(question.options.all(func(o: ChoiceOption) -> bool: return not o.feedback.is_empty()), "cada opción explica por qué sí o por qué no")
	_check(question.options[question.correct_index()].text.contains("aplicación"), "el mejor segundo paso es una aplicación de autenticación")


func _test_window() -> void:
	change_scene_to_file("res://tests/fixtures/combat_test_room.tscn")
	await _wait(0.4)
	var challenge: ChoiceChallenge = load(CHALLENGE)
	var window := ChoiceWindow.open(current_scene, challenge, 1, 2)
	await _frames(2)
	_check(window._step.text.ends_with("PASO 2 DE 2"), "es el paso 2 de 2 (después de crear la contraseña)")
	var wrong := 2  # Pregunta de seguridad
	window.choose(wrong)
	_check(window._feedback.visible and window._feedback.text.contains("segundo factor"), "una opción incorrecta explica por qué no sirve")
	_check(window._buttons[wrong].disabled and not window._continue.visible and window.mistakes[0] == 1,
		"queda descartada y se puede volver a elegir")
	window.next()
	_check(window.question_index == 0 and is_instance_valid(window), "no se avanza sin la respuesta correcta")
	window.choose(0)  # SMS
	_check(window._feedback.text.contains("SIM"), "el SMS sirve, pero se explica por qué hay algo mejor")
	var result := [null]
	window.closed.connect(func(done: bool) -> void: result[0] = done)
	window.choose(challenge.questions[0].correct_index())
	_check(window._continue.visible and window._feedback.text.begins_with("✔"), "la correcta lo confirma y habilita «Terminar»")
	window.next()
	await _frames(2)
	_check(result[0] == true and not is_instance_valid(window), "al terminar, la ventana se cierra con el desafío completado")


func _test_in_game() -> void:
	state.reset()
	vision.reset()
	state.start_quest(&"contrasena_profesor")
	for step in [&"entrar_pc", &"cruzar_spam", &"revisar_configuracion", &"cambiar_contrasena"]:
		state.complete_step(&"contrasena_profesor", step)
	state.set_flag(&"nullblade_destello")
	change_scene_to_file(PC)
	await _wait(0.6)
	var room := current_scene as Room
	var player := room.player
	player.combat.weapon = load(NULLBLADE)  # Como queda después del combate.
	var tab := room.get_node("AccountTab") as Interactable
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	player.teleport_to(Vector2(3172, 304))
	await _frames(8)
	_check(tab._prompt.visible and tab._prompt.text == "E: elegir la nueva contraseña", "la pestaña ofrece elegir la nueva contraseña")
	_check(not state.vision_unlocked, "todavía no hay Visión Digital")

	# Esc cierra sin terminar; se puede volver a intentar.
	_action("interact")
	await _until(func() -> bool: return get_first_node_in_group(&"password_window") != null)
	_check(player.controls_locked, "con E se abre la ventana y Kai no se mueve")
	_action("ui_cancel")
	await _until(func() -> bool: return get_first_node_in_group(&"password_window") == null and not player.controls_locked)
	_check(state.get_current_step(&"contrasena_profesor") == &"elegir_seguridad" and current_scene == room,
		"Esc cierra sin completar y sin salir del juego")

	var ecos_before: int = root.get_node("Economy").ecos
	_action("interact")
	await _until(func() -> bool: return get_first_node_in_group(&"password_window") != null)
	var create := get_first_node_in_group(&"password_window") as PasswordWindow
	_check(create != null and player.controls_locked, "con E, primero se crea la contraseña nueva")
	create.set_text(SECRET)
	create.submit()
	create.set_text(SECRET)
	create.submit()
	create.submit()  # Ya anotó el código de respaldo.
	await _until(func() -> bool: return _window() != null)
	_check(state.check_password(&"profesor", SECRET), "la contraseña que creó el jugador queda guardada (como huella)")
	var window := _window()
	for question in window.challenge.questions:
		window.choose(question.correct_index())
		window.next()
		await _frames(2)
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing() and box.get_node("%Speaker").text == "Prof. Alvarado", "el profesor agradece")
	await _advance(box)
	await _frames(3)
	_check(state.vision_unlocked, "la Visión Digital queda desbloqueada")
	var gained: int = root.get_node("Economy").ecos - ecos_before
	_check(state.is_quest_completed(&"contrasena_profesor") and gained == 0,
		"en la PC, ni la misión ni el desafío dan Ecos: solo los da el villano (+%d)" % gained)
	_check(player.combat.weapon == null and state.nullblade_stage == 0, "el destello de la Nullblade se apaga")
	_check(state.has_flag(&"cuenta_profesor_segura"), "queda registrado que la cuenta está segura")

	# Kai vuelve al laboratorio y ya puede usar la Visión Digital.
	await _until(func() -> bool: return current_scene != null and current_scene.name == "Laboratorio")
	room = current_scene as Room
	_check(room != null and room.name == "Laboratorio", "Kai sale de la PC y vuelve al laboratorio")
	if room == null:
		return
	player = room.player
	_check(absf(player.global_position.x - 190.0) < 16.0, "aparece junto a la computadora")
	await _until(func() -> bool: return not player.controls_locked)
	_check(player.combat.weapon == null, "afuera de la PC Kai no tiene la Nullblade")
	_action("vision")
	await _until(func() -> bool: return vision.is_active())
	_check(vision.is_active() and not vision.involuntary, "Q enciende la Visión Digital")


func _window() -> ChoiceWindow:
	return get_first_node_in_group(&"choice_window") as ChoiceWindow


func _advance(box: DialogueBox) -> void:
	for i in 40:
		if not box.is_playing():
			return
		_action("interact")
		await _frames(3)


## Espera (en cuadros de física) a que se cumpla la condición, hasta unos 10 s de juego.
func _until(condition: Callable) -> void:
	for i in 600:
		if condition.call():
			return
		await process_frame
		await physics_frame


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
