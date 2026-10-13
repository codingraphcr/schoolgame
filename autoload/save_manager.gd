extends Node
## Partidas guardadas: 3 ranuras independientes por identidad (IdentityManager), en
## user://partidas/<identidad>/ranura_N/. Ver docs/arquitectura/SISTEMA_USUARIOS_STEAM.md.
##
## Cada ranura guarda todo el progreso (GameState.to_dict: misiones, Ecos y recompensas cobradas,
## habilidades, comandos, marcas…), dónde continuar (sala y punto de guardado) y sus metadatos
## (id único de la partida, revisión, tiempo jugado, año, capítulo, nivel, lugar). Formato:
## SaveSerializer (texto JSON con huella de integridad), revisado por SaveValidator y adaptado
## desde versiones viejas por SaveMigrator. Nunca se cargan objetos ni código del archivo.
##
## Escritura segura (en Windows, renombrar borra el destino antes de mover: no es atómico, así que
## siempre se deja al menos una copia válida):
##   1. se escribe partida.sav.tmp  2. se vuelve a leer y se valida
##   3. la principal pasa a partida.respaldo.sav  4. el temporal pasa a ser partida.sav
## Al cargar se usa la principal; si falta o está dañada, el temporal (si es de una revisión más
## nueva: el juego se cerró entre 3 y 4) o el respaldo. Un error en una ranura nunca toca las otras.
##
## Uso: SaveManager.new_game(ranura) · SaveManager.save_game(escena, punto) ·
##      SaveManager.slot_info(ranura) · SaveManager.continue_game() · SaveManager.delete_slot(ranura)

## Se guardó la partida de esa ranura.
signal saved(slot: int)
## No se pudo guardar (la partida anterior sigue intacta).
signal save_failed(slot: int, reason: String)
## Cambió algo en las ranuras (para refrescar el menú).
signal slots_changed

const SLOTS := SaveValidator.SLOTS
const MAIN_FILE := "partida.sav"
const BACKUP_FILE := "partida.respaldo.sav"
const TEMP_FILE := "partida.sav.tmp"
## Registro de este equipo (no se sincroniza): última ranura usada y revisiones vistas.
const LEDGER_FILE := "registro_local.dat"
const LEGACY_PATH := "user://partida.json"

## La partida de antes de las ranuras (las pruebas usan otra).
var legacy_path := LEGACY_PATH
## Ranura de la partida en juego (0 = ninguna).
var active_slot := 0

## Metadatos de la partida en juego: partida_id, revision, tiempo_jugado.
var _meta := {}
## Campos del archivo que esta versión no conoce: se conservan al volver a guardar.
var _extra := {}
## Guardado automático (misiones, habilidades, recompensas, al salir).
var auto_save: AutoSave


func _ready() -> void:
	# En las pruebas automáticas nunca se migra la partida vieja real del equipo.
	if PlayerIdentity.is_test_run():
		legacy_path = "user://pruebas_partida_vieja.json"
	auto_save = AutoSave.new()
	auto_save.name = "AutoSave"
	add_child(auto_save)
	get_node("/root/IdentityManager").identity_changed.connect(_on_identity_changed)
	migrate_legacy()


func _on_identity_changed() -> void:
	active_slot = 0
	_meta = {}
	_extra = {}
	migrate_legacy()
	slots_changed.emit()


# --- Rutas ---

func slots_root() -> String:
	return get_node("/root/IdentityManager").saves_root()


func slot_dir(slot: int) -> String:
	return slots_root().path_join("ranura_%d" % slot)


func slot_path(slot: int, file := MAIN_FILE) -> String:
	return slot_dir(slot).path_join(file)


static func is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SLOTS


# --- Consultas ---

## Resumen de una ranura para el menú: { slot, estado, origen, meta, conflicto }.
## estado: "vacia", "ok", "recuperada" (se usó el respaldo o el temporal), "danada" (hay archivos
## pero ninguno sirve) o "incompatible" (de una versión más nueva del juego: no se toca).
func slot_info(slot: int) -> Dictionary:
	var best := _best(slot)
	var info := { "slot": slot, "estado": best["estado"], "origen": best["origen"], "meta": {}, "conflicto": false }
	if best["estado"] in ["ok", "recuperada"]:
		info["meta"] = best["body"]["meta"]
		info["conflicto"] = _is_conflict(slot, best["body"]["meta"])
	return info


## El contenido de una ranura usable (solo para leer, p. ej. «Mi perfil»); {} si no hay.
func read_slot(slot: int) -> Dictionary:
	var best := _best(slot)
	return (best["body"] as Dictionary).duplicate(true) if best["estado"] in ["ok", "recuperada"] else {}


func has_save() -> bool:
	for slot in range(1, SLOTS + 1):
		if slot_info(slot)["estado"] in ["ok", "recuperada"]:
			return true
	return false


## La primera ranura vacía (0 si están las 3 ocupadas).
func first_empty_slot() -> int:
	for slot in range(1, SLOTS + 1):
		if slot_info(slot)["estado"] == "vacia":
			return slot
	return 0


## La última ranura usada en este equipo, o la guardada más recientemente (0 si no hay ninguna).
func last_slot() -> int:
	var remembered := int(_ledger().get("ultima_ranura", 0))
	if is_valid_slot(remembered) and slot_info(remembered)["estado"] in ["ok", "recuperada"]:
		return remembered
	var newest := 0
	var newest_time := -1
	for slot in range(1, SLOTS + 1):
		var info := slot_info(slot)
		if info["estado"] in ["ok", "recuperada"] and int(info["meta"]["guardada"]) > newest_time:
			newest = slot
			newest_time = int(info["meta"]["guardada"])
	return newest


# --- Partida en juego ---

## Empieza una partida nueva en esa ranura (no escribe nada hasta el primer guardado).
func new_game(slot: int) -> bool:
	if not is_valid_slot(slot):
		return false
	auto_save.quiet(true)
	get_node("/root/GameState").reset()
	get_node("/root/DigitalVision").reset()
	get_node("/root/World").new_world()
	active_slot = slot
	_meta = { "partida_id": Crypto.new().generate_random_bytes(16).hex_encode(), "revision": 0 }
	_extra = {}
	auto_save.quiet(false)
	return true


## Carga una ranura en GameState (sin cambiar de escena). false si no hay una partida usable.
func load_slot(slot: int) -> bool:
	var best := _best(slot)
	if not best["estado"] in ["ok", "recuperada"]:
		return false
	var body: Dictionary = best["body"]
	var game_state := get_node("/root/GameState")
	auto_save.quiet(true)
	game_state.reset()
	game_state.from_dict(body["estado"])
	# Política de recursos: al cargar, Kai aparece en su punto de guardado con los cristales y la
	# energía llenos (como en un banco); no se restaura la vida exacta del momento.
	game_state.current_masks = -1.0
	game_state.current_energy = -1.0
	get_node("/root/World").from_dict(body["mundo"])
	get_node("/root/DigitalVision").reset()
	active_slot = slot
	_meta = { "partida_id": body["meta"]["partida_id"], "revision": int(body["meta"]["revision"]) }
	_extra = {}
	for key: String in body:
		if not key in ["meta", "ubicacion", "estado", "mundo", "educativo"]:
			_extra[key] = body[key]
	_remember(slot, body["meta"])
	auto_save.quiet(false)
	return true


## Carga la ranura (o la última usada) y lleva a Kai al punto donde guardó.
func continue_game(slot := 0) -> bool:
	if slot == 0:
		slot = last_slot()
	if not is_valid_slot(slot) or not load_slot(slot):
		return false
	var location: Dictionary = _best(slot)["body"]["ubicacion"]
	get_node("/root/SceneManager").go_to_room(location["escena"], StringName(location["punto"]))
	return true


## Guarda la partida en juego en su ranura. false (sin tocar el guardado anterior) si algo falla.
func save_game(scene_path: String, entry: StringName) -> bool:
	if not is_valid_slot(active_slot):
		push_warning("SaveManager: no hay una ranura activa para guardar.")
		return false
	var body := build_body(scene_path, entry)
	var error := SaveValidator.validate(body)
	if not error.is_empty():
		push_warning("SaveManager: la partida no pasó la validación (%s)." % error)
		save_failed.emit(active_slot, error)
		return false
	if not _write_slot(active_slot, body):
		save_failed.emit(active_slot, "escritura")
		return false
	_meta["revision"] = body["meta"]["revision"]
	_remember(active_slot, body["meta"])
	saved.emit(active_slot)
	slots_changed.emit()
	return true


## Arma el cuerpo de la partida en juego (versión actual del formato).
func build_body(scene_path: String, entry: StringName) -> Dictionary:
	var game_state := get_node("/root/GameState")
	var economy := get_node("/root/Economy")
	var progress := ProgressTracker.summary(game_state, economy)
	var body := {
		"meta": {
			"ranura": active_slot,
			"partida_id": String(_meta.get("partida_id", Crypto.new().generate_random_bytes(16).hex_encode())),
			"revision": int(_meta.get("revision", 0)) + 1,
			"guardada": int(Time.get_unix_time_from_system()),
			"tiempo_jugado": int(game_state.play_time),
			"version_juego": String(ProjectSettings.get_setting("application/config/version", "")),
			"lugar": _place_name(),
			"anio": progress["anio"],
			"capitulo": progress["capitulo"],
			"nivel": progress["nivel"],
			"historia": progress["historia"],
			"educativo": progress["educativo"],
		},
		"ubicacion": { "escena": scene_path, "punto": String(entry) },
		"estado": game_state.to_dict(),
		"mundo": get_node("/root/World").to_dict(),
		"educativo": ProgressTracker.education(game_state, economy),
	}
	for key: String in _extra:
		body[key] = _extra[key]
	return body


## Borra una ranura (sus tres archivos). Solo esa ranura.
func delete_slot(slot: int) -> void:
	if not is_valid_slot(slot):
		return
	for file in [MAIN_FILE, BACKUP_FILE, TEMP_FILE]:
		_remove(slot_path(slot, file))
	if active_slot == slot:
		active_slot = 0
	var ledger := _ledger()
	(ledger.get("revisiones", {}) as Dictionary).erase(str(slot))
	_save_ledger(ledger)
	slots_changed.emit()


## Vuelve a la copia de respaldo de una ranura (cuando la principal está dañada o se prefiere la
## anterior). La principal actual queda como respaldo. false si el respaldo no sirve.
func restore_backup(slot: int) -> bool:
	if not is_valid_slot(slot):
		return false
	var backup := _read(slot_path(slot, BACKUP_FILE), slot)
	if not backup["ok"]:
		return false
	var ok := _write_slot(slot, backup["body"])
	slots_changed.emit()
	return ok


## Borra todas las ranuras de la identidad actual (solo para pruebas y herramientas).
func delete_all() -> void:
	for slot in range(1, SLOTS + 1):
		delete_slot(slot)
	_remove(slots_root().path_join(LEDGER_FILE))


## La partida de antes de las ranuras (user://partida.json) pasa a la ranura 1 de la primera
## identidad que abre el juego en este equipo (si esa ranura está vacía). Antes se guarda una copia
## del archivo original en la ranura. Devuelve true si migró.
func migrate_legacy() -> bool:
	if not FileAccess.file_exists(legacy_path) or slots_root().is_empty() or slot_info(1)["estado"] != "vacia":
		return false
	var legacy := _read(legacy_path, 1)
	if not legacy["ok"]:
		var fallback := _read(legacy_path.get_basename() + ".respaldo.json", 1)
		if not fallback["ok"]:
			return false
		legacy = fallback
	DirAccess.make_dir_recursive_absolute(slot_dir(1))
	DirAccess.copy_absolute(_absolute(legacy_path), _absolute(slot_path(1, "partida.v1.json")))
	if not _write_slot(1, legacy["body"]):
		return false
	for file in [legacy_path, legacy_path.get_basename() + ".respaldo.json", legacy_path + ".tmp"]:
		_remove(file)
	slots_changed.emit()
	return true


# --- Interno ---

## La mejor copia de una ranura: { estado, origen, body }.
func _best(slot: int) -> Dictionary:
	var empty := { "estado": "vacia", "origen": "", "body": {} }
	if not is_valid_slot(slot) or slots_root().is_empty():
		return empty
	var main := _read(slot_path(slot, MAIN_FILE), slot)
	var temp := _read(slot_path(slot, TEMP_FILE), slot)
	var backup := _read(slot_path(slot, BACKUP_FILE), slot)
	if main["ok"]:
		# El juego se cerró justo antes de reemplazar la principal: el temporal es más nuevo.
		if temp["ok"] and _revision(temp) > _revision(main):
			return { "estado": "recuperada", "origen": "temporal", "body": temp["body"] }
		return { "estado": "ok", "origen": "principal", "body": main["body"] }
	if temp["ok"]:
		return { "estado": "recuperada", "origen": "temporal", "body": temp["body"] }
	if backup["ok"]:
		return { "estado": "recuperada", "origen": "respaldo", "body": backup["body"] }
	for result: Dictionary in [main, backup, temp]:
		if result["error"] == "incompatible":
			return { "estado": "incompatible", "origen": "", "body": {} }
	for result: Dictionary in [main, backup, temp]:
		if result["error"] != "falta":
			return { "estado": "danada", "origen": "", "body": {} }
	return empty


## Lee, migra y valida un archivo. { ok, body, error } (error: "falta", "danado" o "incompatible").
func _read(file_path: String, slot: int) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return { "ok": false, "body": {}, "error": "falta" }
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null or file.get_length() > SaveSerializer.MAX_BYTES:
		return { "ok": false, "body": {}, "error": "danado" }
	var unpacked := SaveSerializer.unpack(file.get_as_text())
	if not unpacked["ok"]:
		return { "ok": false, "body": {}, "error": "danado" }
	var migrated := SaveMigrator.migrate(unpacked["version"], unpacked["body"], slot)
	if not migrated["ok"]:
		return { "ok": false, "body": {}, "error": migrated["error"] }
	var body: Dictionary = migrated["body"]
	# El archivo de una ranura dice a qué ranura pertenece (no se acepta uno movido de otra).
	if body.get("meta") is Dictionary and body["meta"].get("ranura") is float:
		body["meta"]["ranura"] = int(body["meta"]["ranura"])
	if not SaveValidator.validate(body).is_empty() or int(body["meta"]["ranura"]) != slot:
		return { "ok": false, "body": {}, "error": "danado" }
	return { "ok": true, "body": body, "error": "" }


## Escritura segura (ver arriba). Solo toca la carpeta de esa ranura.
func _write_slot(slot: int, body: Dictionary) -> bool:
	var dir := slot_dir(slot)
	DirAccess.make_dir_recursive_absolute(dir)
	var temp := slot_path(slot, TEMP_FILE)
	var main := slot_path(slot, MAIN_FILE)
	var backup := slot_path(slot, BACKUP_FILE)
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: no se pudo escribir (%s)." % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(SaveSerializer.pack(body))
	file.close()
	if not _read(temp, slot)["ok"]:
		_remove(temp)
		return false
	if FileAccess.file_exists(main):
		_remove(backup)
		if DirAccess.rename_absolute(_absolute(main), _absolute(backup)) != OK:
			return false
	return DirAccess.rename_absolute(_absolute(temp), _absolute(main)) == OK


func _revision(result: Dictionary) -> int:
	return int(result["body"]["meta"]["revision"])


func _place_name() -> String:
	var world := get_node_or_null("/root/World")
	if world == null or world.current_room == &"":
		return ""
	var template: RoomTemplate = world.template_of(world.current_room)
	return template.display_name if template else ""


## Posible conflicto: en este equipo ya se vio una revisión más nueva de esta partida, o en la
## ranura hay otra partida distinta de la que este equipo conocía (llegó otra desde la nube).
func _is_conflict(slot: int, meta: Dictionary) -> bool:
	var seen: Variant = (_ledger().get("revisiones", {}) as Dictionary).get(str(slot))
	if not seen is Dictionary:
		return false
	return seen.get("partida_id") != meta["partida_id"] or int(seen.get("revision", 0)) > int(meta["revision"])


func _remember(slot: int, meta: Dictionary) -> void:
	var ledger := _ledger()
	ledger["ultima_ranura"] = slot
	if not ledger.get("revisiones") is Dictionary:
		ledger["revisiones"] = {}
	ledger["revisiones"][str(slot)] = { "partida_id": meta["partida_id"], "revision": int(meta["revision"]) }
	_save_ledger(ledger)


func _ledger() -> Dictionary:
	var path := slots_root().path_join(LEDGER_FILE)
	if slots_root().is_empty() or not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return {}
	return json.data


func _save_ledger(ledger: Dictionary) -> void:
	if slots_root().is_empty():
		return
	DirAccess.make_dir_recursive_absolute(slots_root())
	var file := FileAccess.open(slots_root().path_join(LEDGER_FILE), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(ledger))


func _remove(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(_absolute(file_path))


func _absolute(file_path: String) -> String:
	return ProjectSettings.globalize_path(file_path)
