extends SceneTree
## Prueba automática: diálogos (formato, caja de diálogo) e interacción con el profesor del pasillo.
## Ejecutar: godot --headless --path . --script res://tests/test_dialogue.gd

const PASILLO := "res://world/zones/zone0/pasillo_laboratorio.tscn"
const NEAR_PROFESOR := Vector2(170, 304)  # El profesor está en x=196

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# Velocidad normal del texto, sin importar lo que el jugador eligió en Opciones (no se guarda).
	GameSettings.ensure_loaded()
	GameSettings.text_speed = 1
	_test_format()
	var state := root.get_node("GameState")
	state.reset()
	state.start_quest(&"prologo")
	change_scene_to_file(PASILLO)
	await _wait(0.5)
	var room := current_scene as Room
	await _test_first_talk(room, state)
	await _test_repeat_talk(room)

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_format() -> void:
	var dialogue := Dialogue.new()
	dialogue.script_text = "# comentario\nProfesor: Hola, Kai.\n\nKai: Hola: ¿qué pasó?\n(La pantalla parpadea.)"
	var lines := dialogue.get_lines()
	_check(lines.size() == 3, "formato: ignora comentarios y líneas vacías (%d líneas)" % lines.size())
	_check(lines[0]["speaker"] == "Profesor" and lines[0]["text"] == "Hola, Kai.", "formato: «Nombre: texto»")
	_check(lines[1]["speaker"] == "Kai" and lines[1]["text"] == "Hola: ¿qué pasó?", "formato: los «:» dentro del texto se conservan")
	_check(lines[2]["speaker"] == "" and lines[2]["text"] == "(La pantalla parpadea.)", "formato: líneas sin orador (narración)")
	dialogue.script_text = "Prof. Alvarado [serio]: Escucha."
	lines = dialogue.get_lines()
	_check(lines[0]["speaker"] == "Prof. Alvarado" and lines[0]["expression"] == "serio" and lines[0]["text"] == "Escucha.",
		"formato: «Nombre [expresión]: texto»")
	var profesor: DialogueCharacter = load("res://data/characters/profesor.tres")
	_check(profesor.matches("Prof. Alvarado") and profesor.matches("Profesor"), "el profesor responde a su nombre y a «Profesor»")
	var serio := PlaceholderTexture2D.new()
	var con_expresiones := DialogueCharacter.new()
	con_expresiones.portrait = PlaceholderTexture2D.new()
	con_expresiones.expressions = { "serio": serio }
	_check(con_expresiones.portrait_for("serio") == serio and con_expresiones.portrait_for("") == con_expresiones.portrait
		and profesor.portrait_for("sonriente") == profesor.portrait, "las expresiones cambian el retrato (si no existe, queda el normal)")
	var desconocido: DialogueCharacter = load("res://data/characters/desconocido.tres")
	_check(desconocido.display_name == "???" and desconocido.matches("Pantalla") and desconocido.text_color.a > 0.0,
		"la presencia de la computadora se llama «???» y habla en otro color")
	var pedido: Dialogue = load("res://data/dialogues/prologo/profesor_pedido.tres")
	_check(pedido.get_lines().size() == 6, "el pedido del profesor tiene 6 líneas")


func _test_first_talk(room: Room, state: Node) -> void:
	var player := room.player
	var profesor := room.get_node("Npcs/Profesor") as Npc
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	_check(profesor != null and box != null, "el pasillo tiene al profesor y el HUD la caja de diálogo")
	player.teleport_to(NEAR_PROFESOR)
	await _frames(10)
	var prompt: Label = profesor.get_node("Interactable")._prompt
	_check(prompt.visible and prompt.text == "E: hablar", "junto al profesor aparece «E: hablar»")
	_action("interact")
	await _frames(3)
	_check(box.is_playing() and box.visible, "E abre el diálogo")
	_check(player.controls_locked, "Kai no se mueve mientras habla")
	_check(box.get_node("%Speaker").text == "Prof. Alvarado", "habla el profesor primero")
	_check((box.get_node("%Text") as Label).visible_ratio < 1.0, "el texto aparece letra por letra")
	_check(profesor.get_node("Sprite").flip_h and profesor.get_node("Sprite").animation == &"talk", "el profesor mira a Kai y gesticula")
	_check(not prompt.visible, "el aviso se oculta durante el diálogo")
	_action("interact")
	await _frames(2)
	_check((box.get_node("%Text") as Label).visible_ratio >= 1.0, "E completa la línea que se está escribiendo")
	_action("interact")
	await _frames(2)
	_check(box.get_node("%Speaker").text == "Kai", "E pasa a la siguiente línea (responde Kai)")
	for i in 30:
		if not box.is_playing():
			break
		_action("interact")
		await _frames(3)
	_check(not box.is_playing() and not box.visible, "el diálogo termina y la caja se cierra")
	await _frames(3)
	_check(not player.controls_locked, "Kai recupera los controles")
	_check(state.get_current_step(&"prologo") == &"revisar_computadora", "hablar con el profesor avanza la misión (ahora: revisar la computadora)")
	_check(not box.is_playing(), "la tecla que cerró el diálogo no lo vuelve a abrir")


func _test_repeat_talk(room: Room) -> void:
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	_action("interact")
	await _frames(3)
	_check(box.is_playing() and (box.get_node("%Text") as Label).text.contains("laboratorio"),
		"la segunda vez el profesor solo recuerda dónde está la computadora")
	for i in 6:
		if not box.is_playing():
			break
		_action("interact")
		await _frames(3)
	_check(not box.is_playing(), "el recordatorio es breve")


func _action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


## Espera cuadros de proceso: las teclas simuladas se entregan una vez por cuadro de proceso, y en
## modo headless puede haber varios cuadros de física por cada uno.
func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
