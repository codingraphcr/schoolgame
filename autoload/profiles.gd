class_name ProfileManager
extends Node
## Cuentas de jugador en el servidor (server/nullveil_server.py): un apodo único para todos los
## dispositivos, su contraseña y su partida, que se puede seguir desde cualquier dispositivo.
## Nadie puede ver ni cargar la partida de otro.
##
## Cómo se protege:
##   · La contraseña nunca sale del juego. De ella se derivan (PBKDF2, KeyDerivation) dos cosas:
##     la «clave de acceso» que se manda al servidor (que la vuelve a «hashear» con scrypt) y la
##     clave que envuelve la clave de datos, que nunca se manda.
##   · Cada cuenta tiene una clave de datos al azar que cifra su partida (AES-256) ANTES de subirla:
##     el servidor guarda algo que no puede leer. La clave de datos viaja envuelta dos veces: con la
##     contraseña y con el código de respaldo (para recuperar la cuenta sin perder la partida).
##   · El servidor exige una sesión (token) para leer o escribir la partida, y solo la de esa cuenta.
##   · En el dispositivo queda una copia cifrada de la partida (para no perderla si se corta la
##     conexión al guardar); se sube en cuanto se puede.
##
## Uso (todas se esperan con await): Profiles.create(nombre, contraseña) · Profiles.login(…) ·
## Profiles.recover(nombre, código, contraseña_nueva) · Profiles.logout() · Profiles.is_available(nombre)

signal logged_in(display_name: String)
signal logged_out
## Cambió el estado de la subida de la partida: "subida", "pendiente" o "error".
signal sync_changed(state: String)

const NAME_MIN := 3
const NAME_MAX := 16
const NAME_CHARS := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
const OFFLINE_ERROR := "No se pudo conectar con el servidor. Revisa tu conexión a internet."

## Copias locales cifradas de la partida de cada cuenta (las pruebas usan otra carpeta).
var cache_root := "user://cuentas"
## Partida de antes de las cuentas (sin cifrar): la recibe la cuenta que se cree en este dispositivo.
var legacy_save := "user://partida.json"
var api: ApiClient

var current_name := ""
var account_id := ""
var save_version := 0
var sync_state := ""

var _token := ""
var _dev_server := -1


func _ready() -> void:
	api = ApiClient.new()
	api.name = "Api"
	add_child(api)
	get_node("/root/SaveManager").saved.connect(_on_saved)
	# Jugando desde el editor (depuración), con el servidor en esta computadora: si no está prendido, se
	# prende solo. En el juego publicado no pasa (no es depuración y el servidor está en internet).
	if OS.is_debug_build() and api.is_local() and not OS.get_cmdline_args().has("--script"):
		_ensure_dev_server.call_deferred()


## Si ya había un servidor prendido, el nuevo no puede usar el puerto y se cierra solo.
func _ensure_dev_server() -> void:
	var port := int(api.base_url.get_slice(":", 2))
	_dev_server = LocalServer.start(port, ProjectSettings.globalize_path("user://servidor_desarrollo/nullveil.db"))
	if _dev_server < 0:
		push_warning("Profiles: no se pudo prender el servidor local (¿está instalado Python 3?).")


func _exit_tree() -> void:
	LocalServer.stop(_dev_server)


func is_logged_in() -> bool:
	return not _token.is_empty()


## Por qué un nombre de usuario no sirve ("" si sirve). Las mismas reglas que el servidor.
static func name_error(username: String) -> String:
	if username.length() < NAME_MIN or username.length() > NAME_MAX:
		return "El nombre debe tener entre %d y %d caracteres." % [NAME_MIN, NAME_MAX]
	for i in username.length():
		if not NAME_CHARS.contains(username[i]):
			return "Solo letras sin tilde, números y _ (sin espacios)."
	return ""


## Deja solo los caracteres permitidos en un nombre (para el campo de texto).
static func sanitize_name(text: String) -> String:
	var result := ""
	for i in text.length():
		if NAME_CHARS.contains(text[i]):
			result += text[i]
	return result.substr(0, NAME_MAX)


## Por qué una contraseña no sirve para esa cuenta ("" si sirve): las reglas del juego.
static func password_error(username: String, password: String) -> String:
	if not PasswordRules.is_clean(password):
		return "La contraseña tiene caracteres no permitidos."
	if not PasswordRules.evaluate(password, PackedStringArray([username.to_lower()]))["valid"]:
		return "La contraseña no cumple las reglas."
	return ""


## Si un nombre está libre. Devuelve { ok, available, error }.
func is_available(username: String) -> Dictionary:
	var error := name_error(username)
	if not error.is_empty():
		return { "ok": false, "available": false, "error": error }
	var reply: Dictionary = await api.post_json("/api/usuarios/disponible", { "usuario": username })
	if reply["status"] != 200:
		return { "ok": false, "available": false, "error": _error_text(reply) }
	var available := bool(reply["data"].get("disponible", false))
	return { "ok": true, "available": available, "error": "" if available else "Ese nombre de usuario ya existe." }


## Crea la cuenta y entra. Devuelve { ok, error, backup_code, migrated }.
func create(username: String, password: String) -> Dictionary:
	var error := name_error(username)
	if error.is_empty():
		error = password_error(username, password)
	if not error.is_empty():
		return { "ok": false, "error": error }
	var data_key := KeyDerivation.random_bytes(32)
	var backup := PasswordRules.backup_code()
	var access := _derive(username, password, "clave")
	var recovery := _derive(username, backup, "respaldo")
	var reply: Dictionary = await api.post_json("/api/registro", {
		"usuario": username, "clave": access["auth"], "respaldo": recovery["auth"],
		"envoltorios": { "clave": _wrap(data_key, access["wrap"]), "respaldo": _wrap(data_key, recovery["wrap"]) },
	})
	if reply["status"] == 409:
		return { "ok": false, "error": "Ese nombre de usuario ya existe." }
	if reply["status"] != 201:
		return { "ok": false, "error": _error_text(reply) }
	_open_session(reply["data"], username, data_key)
	save_version = 0
	var migrated := await _import_legacy()
	return { "ok": true, "error": "", "backup_code": backup, "migrated": migrated }


## Entra con una cuenta y baja su partida. Devuelve { ok, error, wait }.
func login(username: String, password: String) -> Dictionary:
	if not name_error(username).is_empty() or password.is_empty() or not PasswordRules.is_clean(password):
		return { "ok": false, "error": "Usuario o contraseña incorrectos.", "wait": 0 }
	var access := _derive(username, password, "clave")
	var reply: Dictionary = await api.post_json("/api/sesion", { "usuario": username, "clave": access["auth"] })
	if reply["status"] != 200:
		return { "ok": false, "error": _error_text(reply), "wait": int(reply["data"].get("espera", 0)) }
	var data_key := _unwrap(reply["data"].get("envoltorio", {}), access["wrap"])
	if data_key.size() != 32:
		return { "ok": false, "error": "La cuenta tiene datos dañados.", "wait": 0 }
	_open_session(reply["data"], String(reply["data"].get("nombre", username)), data_key)
	await download_save()
	return { "ok": true, "error": "", "wait": 0 }


## Olvidé mi contraseña: con el código de respaldo se pone una nueva y la partida se conserva.
## Devuelve { ok, error, backup_code } con un código de respaldo nuevo (el anterior deja de servir).
func recover(username: String, backup_code: String, new_password: String) -> Dictionary:
	var error := name_error(username)
	if error.is_empty():
		error = password_error(username, new_password)
	if not error.is_empty():
		return { "ok": false, "error": error }
	var old_recovery := _derive(username, backup_code.strip_edges().to_upper(), "respaldo")
	var start: Dictionary = await api.post_json("/api/recuperar/inicio", { "usuario": username, "respaldo": old_recovery["auth"] })
	if start["status"] != 200:
		return { "ok": false, "error": _error_text(start, "Usuario o código de respaldo incorrectos.") }
	var data_key := _unwrap(start["data"].get("envoltorio_respaldo", {}), old_recovery["wrap"])
	if data_key.size() != 32:
		return { "ok": false, "error": "La cuenta tiene datos dañados." }
	var backup := PasswordRules.backup_code()
	var access := _derive(username, new_password, "clave")
	var recovery := _derive(username, backup, "respaldo")
	var finish: Dictionary = await api.post_json("/api/recuperar/fin", {
		"permiso": start["data"].get("permiso", ""), "clave": access["auth"], "respaldo": recovery["auth"],
		"envoltorios": { "clave": _wrap(data_key, access["wrap"]), "respaldo": _wrap(data_key, recovery["wrap"]) },
	})
	if finish["status"] != 200:
		return { "ok": false, "error": _error_text(finish) }
	_open_session(finish["data"], String(finish["data"].get("nombre", username)), data_key)
	await download_save()
	return { "ok": true, "error": "", "backup_code": backup }


## Cierra la sesión (también en el servidor): la clave se borra de la memoria y el progreso vuelve a cero.
func logout() -> void:
	if not _token.is_empty():
		api.post_json("/api/sesion/cerrar", {}, _token)
	_token = ""
	account_id = ""
	current_name = ""
	save_version = 0
	var saves := _save_manager()
	saves.key = PackedByteArray()
	saves.path = saves.DEFAULT_PATH
	get_node("/root/GameState").reset()
	logged_out.emit()


## Baja la partida del servidor a la copia local. true si había una.
func download_save() -> bool:
	var reply: Dictionary = await api.get_json("/api/partida", _token)
	var saves := _save_manager()
	if reply["status"] == 404:
		save_version = 0
		return false
	if reply["status"] != 200:
		# Sin conexión: se usa la copia local de este dispositivo (si hay).
		_set_sync("pendiente")
		return false
	var raw := Marshalls.base64_to_raw(String(reply["data"].get("partida", "")))
	save_version = int(reply["data"].get("version", 0))
	DirAccess.make_dir_recursive_absolute(saves.path.get_base_dir())
	var file := FileAccess.open(saves.path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(raw)
	file.close()
	return true


## Sube la copia local (cifrada) al servidor. Si otro dispositivo guardó antes, gana esta partida,
## que es la más nueva (se juega en un dispositivo a la vez).
func upload_save() -> bool:
	var saves := _save_manager()
	if _token.is_empty() or not FileAccess.file_exists(saves.path):
		return false
	var body := { "partida": Marshalls.raw_to_base64(FileAccess.get_file_as_bytes(saves.path)), "version_base": save_version }
	var reply: Dictionary = await api.put_json("/api/partida", body, _token)
	if reply["status"] == 409:
		body["version_base"] = int(reply["data"].get("version", 0))
		reply = await api.put_json("/api/partida", body, _token)
	if reply["status"] != 200:
		_set_sync("pendiente" if reply["status"] == 0 else "error")
		return false
	save_version = int(reply["data"].get("version", save_version))
	_set_sync("subida")
	return true


# --- Interno ---

func _on_saved() -> void:
	if is_logged_in():
		upload_save()


func _open_session(data: Dictionary, username: String, data_key: PackedByteArray) -> void:
	_token = String(data.get("token", ""))
	account_id = String(data.get("cuenta", ""))
	current_name = username
	var saves := _save_manager()
	saves.key = data_key
	# La carpeta lleva el código de la cuenta, no el nombre.
	saves.path = cache_root.path_join(account_id).path_join("partida.sav")
	get_node("/root/GameState").reset()
	logged_in.emit(username)


## De un secreto (contraseña o código de respaldo) salen la clave de acceso (se manda al servidor)
## y la clave para envolver (nunca sale del juego).
func _derive(username: String, secret: String, purpose: String) -> Dictionary:
	var salt := ("nullveil:%s:%s" % [purpose, username.strip_edges().to_lower()]).sha256_buffer()
	var master := KeyDerivation.pbkdf2(secret, salt)
	return { "auth": KeyDerivation.subkey(master, "servidor").hex_encode(), "wrap": KeyDerivation.subkey(master, "envolver") }


func _wrap(data_key: PackedByteArray, wrap_key: PackedByteArray) -> Dictionary:
	var iv := KeyDerivation.random_bytes(16)
	return { "iv": iv.hex_encode(), "datos": KeyDerivation.wrap(data_key, wrap_key, iv).hex_encode() }


func _unwrap(wrapper: Variant, wrap_key: PackedByteArray) -> PackedByteArray:
	if not wrapper is Dictionary or not wrapper.has("iv") or not wrapper.has("datos"):
		return PackedByteArray()
	var iv := String(wrapper["iv"]).hex_decode()
	var data := String(wrapper["datos"]).hex_decode()
	if iv.size() != 16 or data.size() != 32:
		return PackedByteArray()
	return KeyDerivation.unwrap(data, wrap_key, iv)


## La partida de antes de las cuentas pasa (cifrada) a la cuenta nueva y se sube.
func _import_legacy() -> bool:
	var saves := _save_manager()
	var data: Dictionary = saves.read_plain(legacy_save)
	if data.is_empty() or not saves.write_data(data):
		return false
	for file in [legacy_save, legacy_save.get_basename() + ".respaldo.json", legacy_save + ".tmp"]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	await upload_save()
	return true


func _error_text(reply: Dictionary, wrong := "Usuario o contraseña incorrectos.") -> String:
	var code := String(reply["data"].get("error", ""))
	match int(reply["status"]):
		0:
			return OFFLINE_ERROR
		401:
			return wrong
		409:
			return "Ese nombre de usuario ya existe."
		429:
			if code == "bloqueada":
				return "Demasiados intentos. Espera %d s." % int(reply["data"].get("espera", 0))
			return "Demasiados intentos seguidos. Espera un minuto."
		400:
			return "Los datos no son válidos."
	return "El servidor tuvo un problema. Intenta de nuevo."


func _set_sync(state: String) -> void:
	sync_state = state
	sync_changed.emit(state)


func _save_manager() -> Node:
	return get_node("/root/SaveManager")
