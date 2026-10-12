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
	_test_vault()
	await _test_window()
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
