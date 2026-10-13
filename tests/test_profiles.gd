extends SceneTree
## Prueba automática: cuentas en el servidor (Profiles + server/nullveil_server.py). Crear usuario
## (y que avise si el nombre ya existe en cualquier dispositivo), contraseñas con las reglas del
## juego, entrar y salir, la misma partida en dos dispositivos, que nadie pueda ver la partida de
## otro (ni el servidor puede leerla), el bloqueo tras varios intentos, recuperar con el código de
## respaldo sin perder la partida, la partida de antes del dispositivo y qué pasa sin conexión.
## Prende su propio servidor de prueba (necesita Python 3); nunca toca cuentas reales.
## Ejecutar: godot --headless --path . --script res://tests/test_profiles.gd

const ENTRADA := "res://world/zones/zone0/entrada.tscn"
const PASS_A := "faro cometa tambor mango 12"
const PASS_B := "nube cactus volcan linterna 7"

var _failures := 0
var profiles: Node
var saves: Node
var state: Node
var server: TestServer


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	profiles = root.get_node("Profiles")
	saves = root.get_node("SaveManager")
	state = root.get_node("GameState")
	_test_rules()
	server = await TestServer.start(self, "cuentas")
	if server:
		await _test_create_and_names()
		await _test_two_devices()
		await _test_privacy()
		await _test_lockout()
		await _test_recovery()
		await _test_offline()
		server.stop(self)
	else:
		_failures += 1
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_rules() -> void:
	_check(ProfileManager.name_error("Yohann11").is_empty() and ProfileManager.name_error("kai_2").is_empty(), "nombres válidos: letras, números y _")
	for bad in ["yo", "a".repeat(17), "Yohann 11", "../../etc", "ñandú", "x;rm -rf", "<b>hola</b>", "' OR 1=1 --"]:
		_check(not ProfileManager.name_error(bad).is_empty(), "nombre rechazado: %s" % bad)
	_check(ProfileManager.sanitize_name("Yo hann/../11;") == "Yohann11", "el campo de nombre quita lo que no se permite")
	_check(not ProfileManager.password_error("Debil", "123456").is_empty(), "una contraseña débil no sirve")
	_check(not ProfileManager.password_error("Tambor", "tambor nube faro mango 99").is_empty(), "la contraseña no puede contener el nombre de usuario")
	_check(not ApiClient.is_secure_url("http://ejemplo.com") and ApiClient.is_secure_url("https://ejemplo.com")
		and ApiClient.is_secure_url("http://127.0.0.1:8787"), "solo se habla con el servidor por HTTPS (o en esta computadora)")


## La partida de antes pasa a la cuenta nueva; un nombre repetido avisa que ya existe.
func _test_create_and_names() -> void:
	state.reset()
	state.set_flag(&"marca_vieja")
	saves.key = PackedByteArray()
	saves.path = profiles.legacy_save
	_check(saves.save_game(ENTRADA, &"entrada"), "hay una partida de antes de las cuentas en este dispositivo")
	_check((await profiles.is_available("Yohann11"))["available"], "«Yohann11» está libre")
	var created: Dictionary = await profiles.create("Yohann11", PASS_A)
	_check(created["ok"] and profiles.is_logged_in() and profiles.current_name == "Yohann11", "se crea Yohann11 y entra")
	_check(String(created.get("backup_code", "")).length() == 9, "recibe un código de respaldo")
	_check(created.get("migrated", false) and not FileAccess.file_exists(profiles.legacy_save), "la partida de antes pasa a Yohann11")
	_check(profiles.save_version == 1 and profiles.sync_state == "subida", "y se sube al servidor")
	var repeated: Dictionary = await profiles.create("yohann11", PASS_B)
	_check(not repeated["ok"] and repeated["error"] == "Ese nombre de usuario ya existe.", "otro «yohann11» → «Ese nombre de usuario ya existe.»")
	var check: Dictionary = await profiles.is_available("YOHANN11")
	_check(not check["available"] and check["error"] == "Ese nombre de usuario ya existe.", "al escribir el nombre ya avisa que existe")
	var weak: Dictionary = await profiles.create("Otra_1", "123456")
	_check(not weak["ok"] and weak["error"].contains("reglas"), "con una contraseña débil no se crea la cuenta")


## La misma cuenta en otro dispositivo baja la partida, y lo que se guarda en uno aparece en el otro.
func _test_two_devices() -> void:
	profiles.logout()
	_check(not profiles.is_logged_in() and saves.key.is_empty() and not state.has_flag(&"marca_vieja"), "al cerrar sesión se borra la clave y el progreso")
	var wrong: Dictionary = await profiles.login("Yohann11", PASS_B)
	var unknown: Dictionary = await profiles.login("NoExiste", PASS_A)
	_check(not wrong["ok"] and wrong["error"] == unknown["error"], "el mismo mensaje si el usuario no existe o la contraseña está mal")
	profiles.cache_root = server.folder.path_join("dispositivo_2")
	var login: Dictionary = await profiles.login("yohann11", PASS_A)
	_check(login["ok"] and profiles.current_name == "Yohann11", "en otro dispositivo entra (el nombre no distingue mayúsculas)")
	_check(saves.has_save() and saves.load_data()["game"]["flags"].has("marca_vieja"), "y baja su partida del servidor")
	state.from_dict(saves.load_data()["game"])
	state.set_flag(&"marca_dispositivo_2")
	saves.save_game(ENTRADA, &"entrada")
	await _until(func() -> bool: return profiles.save_version == 2)
	_check(profiles.save_version == 2, "lo que guarda en el dispositivo 2 se sube")
	profiles.logout()
	profiles.cache_root = server.folder.path_join("dispositivo_1")
	await profiles.login("Yohann11", PASS_A)
	_check(saves.load_data()["game"]["flags"].has("marca_dispositivo_2"), "y en el dispositivo 1 aparece lo que guardó en el 2")


## Nadie puede ver la partida de otro, ni el servidor puede leerla.
func _test_privacy() -> void:
	var yohann_key: PackedByteArray = saves.key
	var cache := FileAccess.get_file_as_bytes(saves.path).get_string_from_ascii()
	_check(not cache.contains("marca_vieja") and not cache.contains("flags"), "la copia de la partida en el dispositivo está cifrada")
	var database := FileAccess.get_file_as_bytes(server.folder.path_join("cuentas.db")).get_string_from_ascii()
	database += FileAccess.get_file_as_bytes(server.folder.path_join("cuentas.db-wal")).get_string_from_ascii()
	_check(not database.contains("marca_vieja") and not database.contains(PASS_A), "el servidor no puede leer la partida ni tiene la contraseña")
	profiles.logout()
	_check((await profiles.create("Ana_7", PASS_B))["ok"], "se crea otra cuenta (Ana_7)")
	_check(not saves.has_save(), "Ana_7 empieza sin partida: no ve la de Yohann11")
	var reply: Dictionary = await profiles.api.get_json("/api/partida", "token-inventado")
	_check(reply["status"] == 401, "sin una sesión válida el servidor no entrega ninguna partida")
	state.set_flag(&"marca_de_ana")
	saves.save_game(ENTRADA, &"entrada")
	var ana_key: PackedByteArray = saves.key
	saves.key = yohann_key
	_check(saves.load_data().is_empty(), "con la clave de Yohann11 no se abre la partida de Ana_7")
	saves.key = ana_key
	profiles.logout()


func _test_lockout() -> void:
	for i in 4:
		await profiles.login("Ana_7", "contraseña equivocada numero %d" % i)
	var blocked: Dictionary = await profiles.login("Ana_7", "otra equivocada mas")
	_check(not blocked["ok"] and blocked["wait"] > 0 and blocked["error"].begins_with("Demasiados intentos"),
		"tras 5 intentos fallidos hay que esperar (%d s)" % blocked["wait"])
	_check(not (await profiles.login("Ana_7", PASS_B))["ok"], "mientras tanto, ni la contraseña correcta entra")


## Olvidé mi contraseña: con el código de respaldo se pone una nueva y la partida sigue ahí.
func _test_recovery() -> void:
	var made: Dictionary = await profiles.create("Lia_3", PASS_A)
	state.set_flag(&"marca_de_lia")
	saves.save_game(ENTRADA, &"entrada")
	await _until(func() -> bool: return profiles.save_version == 1)
	profiles.logout()
	_check(not (await profiles.recover("Lia_3", "AAAA-BBBB", PASS_B))["ok"], "un código de respaldo equivocado no sirve")
	profiles.cache_root = server.folder.path_join("dispositivo_3")
	var recovered: Dictionary = await profiles.recover("Lia_3", String(made["backup_code"]).to_lower(), PASS_B)
	_check(recovered["ok"] and saves.load_data()["game"]["flags"].has("marca_de_lia"), "con el código pone otra contraseña y conserva su partida (en otro dispositivo)")
	_check(String(recovered.get("backup_code", "")) != String(made["backup_code"]), "recibe un código de respaldo nuevo")
	profiles.logout()
	_check(not (await profiles.login("Lia_3", PASS_A))["ok"] and (await profiles.login("Lia_3", PASS_B))["ok"], "la contraseña vieja ya no sirve; la nueva sí")
	profiles.logout()
	_check(not (await profiles.recover("Lia_3", String(made["backup_code"]), PASS_A))["ok"], "el código de respaldo usado ya no sirve")


func _test_offline() -> void:
	var url: String = profiles.api.base_url
	profiles.api.base_url = "http://127.0.0.1:1"
	var reply: Dictionary = await profiles.login("Lia_3", PASS_B)
	_check(not reply["ok"] and reply["error"] == ProfileManager.OFFLINE_ERROR, "sin conexión avisa que no se pudo conectar")
	profiles.api.base_url = "http://servidor-falso.com"
	_check((await profiles.login("Lia_3", PASS_B))["error"] == ProfileManager.OFFLINE_ERROR, "a una dirección sin HTTPS no se conecta")
	profiles.api.base_url = url


func _until(condition: Callable) -> void:
	for i in 600:
		if condition.call():
			return
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
