extends SceneTree
## Prueba automática: contraseña creada por el jugador. Reglas y medidor (PasswordRules), frases
## sugeridas, código de respaldo, guardado de solo la huella (GameState) y la ventana para crearla
## (PasswordWindow: reglas en vivo, confirmar, código de respaldo).
## Ejecutar: godot --headless --path . --script res://tests/test_custom_password.gd

const SECRET := "tortuga-satelite-mango-faro-58"

var _failures := 0
var state: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	_test_rules()
	_test_sanitize()
	_test_vault()
	await _test_window()
	await _test_safe_input()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _failed(password: String) -> Array:
	var result := PasswordRules.evaluate(password)
	return (result["rules"] as Array).filter(func(r: Dictionary) -> bool: return not r["ok"]).map(func(r: Dictionary) -> String: return r["id"])


func _test_rules() -> void:
	_check(not PasswordRules.evaluate("")["valid"], "vacía no sirve")
	_check(_failed("123456").has("comun") and _failed("123456").has("largo") and _failed("123456").has("patron"),
		"«123456»: corta, de las más usadas y una secuencia")
	_check(_failed("P@ssw0rd!").has("comun"), "«P@ssw0rd!»: cambiar letras por símbolos no engaña")
	_check(_failed("password2024!").has("comun"), "«password2024!»: agregar números al final tampoco")
	_check(_failed("Alvarado1985segura").has("personal"), "«Alvarado1985…»: tiene datos personales")
	_check(_failed("kaikaikaikai2026x").has("personal"), "el nombre de Kai también cuenta como dato personal")
	_check(_failed("zzzzqwmnbvcxlkj").has("patron"), "«zzzz…»: repeticiones")
	_check(_failed("Mi perro").has("largo"), "una frase corta no alcanza")
	var good := PasswordRules.evaluate("tiza-ventana-cometa-mango-27")
	_check(good["valid"] and good["level"] >= 3, "una frase de 4 palabras al azar es válida y fuerte (%s, %s)" % [PasswordRules.LEVEL_NAMES[good["level"]], good["time"]])
	var weak := PasswordRules.evaluate("Alvarado1985")
	_check(weak["level"] <= 1 and String(weak["time"]) == "al instante", "una débil se adivina «al instante»")
	_check(PasswordRules.evaluate("Xk9#mPq2$vLr7!wT")["level"] == 4, "una larga y variada es muy fuerte")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var all_valid := true
	for i in 30:
		all_valid = all_valid and PasswordRules.evaluate(PasswordRules.suggest(rng))["valid"]
	_check(all_valid, "«Sugerir frase» siempre propone una contraseña válida")
	var code := PasswordRules.backup_code(rng)
	_check(code.length() == 9 and code[4] == "-" and not code.contains("O") and not code.contains("0"),
		"el código de respaldo es legible (%s, sin letras que se confunden)" % code)


func _test_sanitize() -> void:
	_check(PasswordRules.sanitize("hola<script>alert(1)</script>") == "holascriptalert(1)/script", "se quitan las etiquetas (< >)")
	_check(PasswordRules.sanitize("[b]negrita[/b]{x}\"'`|\\") == "bnegrita/bx", "se quitan corchetes, llaves, comillas y barras invertidas")
	_check(PasswordRules.sanitize("linea1" + char(10) + "linea2" + char(9) + "fin" + char(0) + char(127)) == "linea1linea2fin", "se quitan saltos de línea, tabulaciones y caracteres invisibles")
	_check(PasswordRules.sanitize("Ñandú-Ácido-pingüino 2!") == "Ñandú-Ácido-pingüino 2!", "se conservan letras con tilde, ñ, números, espacios y símbolos simples")
	_check(PasswordRules.sanitize("a".repeat(200)).length() == PasswordRules.MAX_LENGTH, "como máximo %d caracteres" % PasswordRules.MAX_LENGTH)
	_check(not PasswordRules.is_clean("OS.execute(\"rm\")") and PasswordRules.is_clean("tiza-ventana-cometa-mango-27"),
		"un texto con código no es una contraseña aceptable")


func _test_vault() -> void:
	state.reset()
	_check(not state.has_password(&"profesor"), "partida nueva: sin contraseña")
	state.set_password(&"profesor", SECRET, "K7QM-4XPR")
	_check(state.check_password(&"profesor", SECRET), "la contraseña correcta se reconoce")
	_check(not state.check_password(&"profesor", SECRET.to_upper()) and not state.check_password(&"profesor", "otra"),
		"una incorrecta no (y distingue mayúsculas)")
	_check(state.check_backup_code(&"profesor", "k7qm-4xpr ") and not state.check_backup_code(&"profesor", "AAAA-BBBB"),
		"el código de respaldo funciona (sin importar mayúsculas ni espacios)")
	var saved := JSON.stringify(state.to_dict())
	_check(not saved.contains(SECRET) and not saved.contains("K7QM"), "el guardado NO contiene la contraseña ni el código, solo su huella")
	state.reset()
	state.from_dict(JSON.parse_string(saved))
	_check(state.check_password(&"profesor", SECRET), "después de cargar la partida, la sigue reconociendo")
	state.set_password(&"otra_cuenta", SECRET)
	var before := JSON.stringify(state.to_dict())
	_check(not state.set_password(&"mala", "tiza<script>ventana") and not state.set_password(&"mala", "")
		and not state.set_password(&"mala", "x".repeat(100)) and not state.has_password(&"mala"),
		"GameState rechaza contraseñas vacías, muy largas o con caracteres no permitidos")
	_check(JSON.stringify(state.to_dict()) == before, "un intento rechazado no cambia nada de la partida")
	var data: Dictionary = state.to_dict()["passwords"]
	_check(data["profesor"]["hash"] != data["otra_cuenta"]["hash"], "con la sal, la misma contraseña tiene huellas distintas")


func _test_window() -> void:
	state.reset()
	change_scene_to_file("res://tests/fixtures/combat_test_room.tscn")
	await _wait(0.4)
	var window := PasswordWindow.open(current_scene, &"profesor", "Prueba · Paso 1 de 2")
	await _frames(2)
	_check(window._line.secret, "lo que se escribe aparece oculto")
	window.set_text("Alvarado1985")
	_check(window._next_button.disabled and window._rule_labels[2].text.begins_with("✖"), "con una débil, «Guardar» queda bloqueado y el medidor dice por qué")
	window.submit()
	_check(window.step == PasswordWindow.Step.CREATE, "no se puede guardar una débil")
	window.suggest()
	_check(not window._next_button.disabled and not window._line.secret, "«Sugerir frase» propone una válida y la muestra")
	window.set_text(SECRET)
	window.submit()
	_check(window.step == PasswordWindow.Step.CONFIRM and window._line.text.is_empty(), "pide escribirla otra vez")
	window.set_text("tortuga-satelite-mango-faro-59")
	window.submit()
	_check(window.step == PasswordWindow.Step.CONFIRM and window._message.text.contains("No coincide"), "si no coincide, lo avisa")
	window.set_text(SECRET)
	window.submit()
	_check(window.step == PasswordWindow.Step.BACKUP and window._code_label.text == window.backup, "muestra el código de respaldo para anotarlo")
	var code := window.backup
	_check(not state.has_password(&"profesor"), "hasta terminar no se guarda nada")
	var result := [null]
	window.closed.connect(func(done: bool) -> void: result[0] = done)
	window.submit()
	await _frames(2)
	_check(result[0] == true and not is_instance_valid(window), "al terminar, la ventana se cierra")
	_check(state.check_password(&"profesor", SECRET) and state.check_backup_code(&"profesor", code), "quedan guardadas la contraseña y el código (como huella)")


func _test_safe_input() -> void:
	state.reset()
	var window := PasswordWindow.open(current_scene, &"profesor", "Prueba")
	await _frames(2)
	_check(paused, "con la ventana abierta el juego queda en pausa (nada más reacciona a las teclas)")
	_check(not window._line.shortcut_keys_enabled and not window._line.context_menu_enabled
		and not window._line.drag_and_drop_selection_enabled, "el campo no permite copiar, pegar ni arrastrar")
	_check(window._line.virtual_keyboard_type == LineEdit.KEYBOARD_TYPE_PASSWORD, "en el celular usa el teclado de contraseñas (sin sugerencias)")
	# Tecleado de verdad: un carácter prohibido no entra.
	window._line.grab_focus()
	await _frames(1)
	for character in "mango<":
		_type(character)
	await _frames(2)
	_check(window._line.text == "mango" and window._message.text.begins_with("Solo letras"), "al escribir un carácter prohibido se quita y se explica")
	# Flechas: se mueven entre el campo y los botones, no por el texto.
	_key(KEY_DOWN)
	await _frames(2)
	var focused := window.get_viewport().gui_get_focus_owner()
	_check(focused is Button and focused != null, "la flecha ↓ pasa del campo a un botón (%s)" % (focused.text if focused is Button else "nada"))
	_key(KEY_UP)
	await _frames(2)
	_check(window.get_viewport().gui_get_focus_owner() != focused, "la flecha ↑ vuelve a moverse por la pantalla")
	var button_count := _all_buttons(window).filter(func(b: Button) -> bool: return b.focus_mode == Control.FOCUS_ALL).size()
	_check(button_count == _all_buttons(window).size(), "todos los botones se pueden elegir con las flechas")
	window.close()
	await _frames(2)
	_check(not paused, "al cerrar, el juego sigue")


func _all_buttons(node: Node) -> Array:
	var result := []
	for child in node.get_children():
		if child is Button:
			result.append(child)
		result.append_array(_all_buttons(child))
	return result


## Teclea un carácter como lo haría el jugador (evento de teclado con su letra).
func _type(character: String) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.unicode = character.unicode_at(0)
		event.pressed = pressed
		Input.parse_input_event(event)


func _key(keycode: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		event.pressed = pressed
		Input.parse_input_event(event)


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
