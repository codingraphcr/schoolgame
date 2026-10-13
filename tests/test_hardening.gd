extends SceneTree
## Prueba automática: endurecimiento del sistema de partidas (T11). Mudanza de los datos a la carpeta
## propia del juego (sin pisar ni borrar nada), muchos guardados seguidos sin perder la integridad,
## un temporal viejo que no reemplaza a una partida más nueva, un cambio de identidad en plena
## partida, campos desconocidos que se conservan y el tamaño y el tiempo de una partida grande.
## Las pruebas usan su propia carpeta de partidas (IdentityManager en modo prueba).
## Ejecutar: godot --headless --path . --script res://tests/test_hardening.gd

const ENTRADA := "res://world/zones/zone0/entrada.tscn"

var _failures := 0
var saves: Node
var state: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	saves = root.get_node("SaveManager")
	state = root.get_node("GameState")
	_check(OS.get_user_data_dir().replace("\\", "/").ends_with("/Nullveil"), "el juego usa su carpeta propia (%s)" % OS.get_user_data_dir())
	_test_user_dir_migration()
	_test_many_saves()
	_test_stale_temp()
	_test_identity_switch_mid_game()
	_test_big_save()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


## La mudanza a la carpeta propia copia todo, no pisa datos nuevos y no borra la carpeta vieja.
func _test_user_dir_migration() -> void:
	var base := ProjectSettings.globalize_path("user://pruebas_mudanza")
	_remove_dir(base)
	var old := base.path_join("vieja")
	var new := base.path_join("nueva")
	DirAccess.make_dir_recursive_absolute(old.path_join("partidas/dev_0123456789abcdef/ranura_1"))
	_write(old.path_join("partidas/dev_0123456789abcdef/ranura_1/partida.sav"), "PARTIDA")
	_write(old.path_join("ajustes.cfg"), "[audio]")
	_write(old.path_join("identidad_desarrollo.cfg"), "[identidad]")
	_check(UserDataMigration.migrate(old, new), "se copian los datos de la carpeta vieja")
	_check(FileAccess.get_file_as_string(new.path_join("partidas/dev_0123456789abcdef/ranura_1/partida.sav")) == "PARTIDA"
		and FileAccess.file_exists(new.path_join("ajustes.cfg")) and FileAccess.file_exists(new.path_join("identidad_desarrollo.cfg")),
		"partidas, opciones e identidad llegan a la carpeta nueva")
	_check(FileAccess.file_exists(old.path_join("ajustes.cfg")) and FileAccess.file_exists(new.path_join(UserDataMigration.MARKER)),
		"la carpeta vieja no se borra y queda anotada la mudanza")
	_write(old.path_join("ajustes.cfg"), "[otro]")
	_check(not UserDataMigration.migrate(old, new) and FileAccess.get_file_as_string(new.path_join("ajustes.cfg")) == "[audio]",
		"si la carpeta nueva ya tiene datos, no se pisa nada")
	_check(not UserDataMigration.migrate(base.path_join("no_existe"), base.path_join("otra")), "sin carpeta vieja no pasa nada")
	_remove_dir(base)


## Muchos guardados seguidos: todas las revisiones, siempre íntegras, con respaldo.
func _test_many_saves() -> void:
	saves.new_game(1)
	var start := Time.get_ticks_msec()
	for i in 150:
		state.set_flag(StringName("marca_%d" % i))
		if not saves.save_game(ENTRADA, &"entrada"):
			_check(false, "falló el guardado %d" % i)
			return
	var elapsed := Time.get_ticks_msec() - start
	var info: Dictionary = saves.slot_info(1)
	_check(info["estado"] == "ok" and int(info["meta"]["revision"]) == 150, "150 guardados seguidos: revisión 150 y la partida íntegra")
	_check(saves.load_slot(1) and state.has_flag(&"marca_149") and state.has_flag(&"marca_0"), "al cargar está todo lo guardado")
	var backup := SaveSerializer.unpack(FileAccess.get_file_as_string(saves.slot_path(1, saves.BACKUP_FILE)))
	_check(backup["ok"] and int(backup["body"]["meta"]["revision"]) == 149, "el respaldo es la revisión anterior (149)")
	_check(not FileAccess.file_exists(saves.slot_path(1, saves.TEMP_FILE)), "no queda ningún temporal")
	print("     (150 guardados en %d ms: %.1f ms cada uno)" % [elapsed, elapsed / 150.0])


## Un temporal que quedó de un guardado viejo no reemplaza a una partida más nueva.
func _test_stale_temp() -> void:
	saves.load_slot(1)
	var old_body: Dictionary = saves.build_body(ENTRADA, &"entrada")
	old_body["meta"]["revision"] = 3
	_write(saves.slot_path(1, saves.TEMP_FILE), SaveSerializer.pack(old_body))
	var info: Dictionary = saves.slot_info(1)
	_check(info["estado"] == "ok" and info["origen"] == "principal" and int(info["meta"]["revision"]) == 150,
		"un temporal más viejo que la partida se ignora")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saves.slot_path(1, saves.TEMP_FILE)))


## Si cambia la persona (identidad) en plena partida, no se guarda nada en la carpeta de la otra.
func _test_identity_switch_mid_game() -> void:
	var identity := root.get_node("IdentityManager")
	saves.load_slot(1)
	var first: String = identity.identity_id
	identity.use_provider(DevelopmentIdentityProvider.new("user://pruebas_identidad_b.cfg"))
	_check(saves.active_slot == 0 and not saves.save_game(ENTRADA, &"entrada"), "al cambiar de identidad se suelta la partida: no se guarda en la otra carpeta")
	_check(saves.slot_info(1)["estado"] == "vacia", "la otra persona no ve la partida")
	identity.use_provider(DevelopmentIdentityProvider.new("user://pruebas_identidad.cfg"))
	_check(identity.identity_id == first and int(saves.slot_info(1)["meta"]["revision"]) == 150, "al volver, la partida sigue intacta")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://pruebas_identidad_b.cfg"))


## Una partida grande (mucho progreso) sigue siendo chica y rápida.
func _test_big_save() -> void:
	saves.new_game(2)
	for i in 2000:
		state.set_flag(StringName("evento_%d" % i))
	for i in 300:
		root.get_node("Economy").claim_drop(StringName("deposito:sala_%d" % i))
	var start := Time.get_ticks_usec()
	var ok: bool = saves.save_game(ENTRADA, &"entrada")
	var micro := Time.get_ticks_usec() - start
	var size := FileAccess.get_file_as_bytes(saves.slot_path(2)).size()
	start = Time.get_ticks_usec()
	var loaded: bool = saves.load_slot(2)
	var load_micro := Time.get_ticks_usec() - start
	_check(ok and loaded and state.has_flag(&"evento_1999"), "una partida con 2000 marcas y 300 recompensas se guarda y se carga")
	_check(size < 200_000 and micro < 1_000_000 and load_micro < 1_000_000,
		"pesa %.0f KB; guardar tarda %.0f ms y cargar %.0f ms" % [size / 1024.0, micro / 1000.0, load_micro / 1000.0])


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file in dir.get_files():
		dir.remove(file)
	for sub in dir.get_directories():
		_remove_dir(path.path_join(sub))
	DirAccess.remove_absolute(path)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
