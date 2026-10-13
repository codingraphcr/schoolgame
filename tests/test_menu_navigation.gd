extends SceneTree
## Prueba automática: navegación del menú principal y la pantalla de inicio de sesión (crear un
## usuario con los campos sanitizados, el código de respaldo, cerrar sesión y volver a entrar).
## Prende su propio servidor de cuentas de prueba (necesita Python 3).
## Ejecutar: godot --headless --path . --script res://tests/test_menu_navigation.gd

const MAIN_MENU := "res://ui/menus/main_menu/main_menu.tscn"

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var profiles := root.get_node("Profiles")
	var server := await TestServer.start(self, "menu")
	if server == null:
		quit(1)
		return
	change_scene_to_file(MAIN_MENU)
	await _wait(0.5)
	_expect_scene("MainMenu")
	await _test_login(profiles)

	_press("CreditsButton")
	await _wait(0.2)
	_check(current_scene.get_node("%Credits").visible and not current_scene.get_node("%Buttons").visible, "Créditos se abre")
	_press("CreditsBackButton")
	await _wait(0.2)
	_check(not current_scene.get_node("%Credits").visible and current_scene.get_node("%Buttons").visible, "Volver cierra los créditos")

	_press("SettingsButton")
	await _wait(1.0)
	_expect_scene("SettingsScreen")

	_press("BackButton")
	await _wait(1.0)
	_expect_scene("MainMenu")

	_press("PlayButton")
	await _wait(1.0)
	_expect_not_scene("MainMenu")

	server.stop(self)
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_login(profiles: Node) -> void:
	var login := current_scene.get_node_or_null("Login") as LoginPanel
	_check(login != null and login.visible and not current_scene.get_node("%Buttons").visible,
		"sin sesión aparece INICIAR SESIÓN y las opciones del menú se ocultan")
	if login == null:
		return
	login.show_mode(LoginPanel.Mode.CREATE)
	_type(login._user, "Yo hann;11<b>")
	_check(login._user.text == "Yohann11b", "el nombre se sanitiza mientras se escribe (%s)" % login._user.text)
	_type(login._user, "Yohann11")
	await login.check_name()
	_check(login._message.text.contains("está libre"), "al salir del campo, avisa que el nombre está libre")
	_type(login._password, "faro cometa tambor mango 12")
	_type(login._repeat, "faro cometa tambor mango 13")
	await login.submit()
	_check(login.mode == LoginPanel.Mode.CREATE and login._message.text.contains("no coinciden"), "si las contraseñas no coinciden, avisa")
	_type(login._password, "faro cometa tambor mango 12")
	_type(login._repeat, "faro cometa tambor mango 12")
	await login.submit()
	_check(login.mode == LoginPanel.Mode.CODE and login._big_code.text.length() == 9, "al crear el usuario muestra el código de respaldo")
	login.submit()
	await _wait(0.3)
	_check(current_scene.get_node_or_null("Login") == null and current_scene.get_node("%Buttons").visible
		and current_scene.get_node("%UserLabel").text == "Usuario: Yohann11", "después aparece el menú con el usuario")
	_press("LogoutButton")
	await _wait(0.2)
	login = current_scene.get_node_or_null("Login") as LoginPanel
	_check(login != null and not profiles.is_logged_in() and not current_scene.get_node("%Buttons").visible, "Cerrar sesión vuelve a INICIAR SESIÓN")
	_type(login._user, "yohann11")
	_type(login._password, "una contraseña equivocada")
	await login.submit()
	_check(login._message.text == "Usuario o contraseña incorrectos.", "con la contraseña equivocada no entra")
	_type(login._password, "faro cometa tambor mango 12")
	await login.submit()
	await _wait(0.3)
	_check(profiles.is_logged_in() and current_scene.get_node("%Buttons").visible, "con la correcta entra (el nombre no distingue mayúsculas)")
	# Crear otra cuenta con el mismo nombre: avisa que ya existe.
	_press("LogoutButton")
	await _wait(0.2)
	login = current_scene.get_node_or_null("Login") as LoginPanel
	login.show_mode(LoginPanel.Mode.CREATE)
	_type(login._user, "YOHANN11")
	await login.check_name()
	_check(login._message.text == "Ese nombre de usuario ya existe.", "al crear «YOHANN11» avisa: «Ese nombre de usuario ya existe.»")
	_type(login._password, "nube cactus volcan linterna 7")
	_type(login._repeat, "nube cactus volcan linterna 7")
	await login.submit()
	_check(login.mode == LoginPanel.Mode.CREATE and login._message.text == "Ese nombre de usuario ya existe.", "y no la crea")
	login.show_mode(LoginPanel.Mode.LOGIN)
	_type(login._user, "Yohann11")
	_type(login._password, "faro cometa tambor mango 12")
	await login.submit()
	await _wait(0.3)


## Escribe en un campo como el jugador (dispara la sanitización).
func _type(field: LineEdit, text: String) -> void:
	field.text = text
	field.text_changed.emit(text)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _press(unique_name: String) -> void:
	var button: Button = current_scene.get_node("%" + unique_name)
	button.pressed.emit()


func _expect_scene(scene_name: String) -> void:
	var actual := String(current_scene.name) if current_scene else "null"
	_check(actual == scene_name, "escena esperada=%s actual=%s" % [scene_name, actual])


func _expect_not_scene(scene_name: String) -> void:
	var actual := String(current_scene.name) if current_scene else "null"
	_check(current_scene != null and actual != scene_name, "se salió de %s (actual=%s)" % [scene_name, actual])


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
