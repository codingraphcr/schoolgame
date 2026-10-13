extends SceneTree
## Prueba automática: partidas guardadas (T2–T4 del sistema de usuarios, ver
## docs/arquitectura/SISTEMA_USUARIOS_STEAM.md). Identidad de desarrollo y carpetas por identidad,
## 3 ranuras independientes, escritura segura con respaldo, recuperación tras un cierre inesperado,
## archivos dañados, alterados o de una versión futura, migración de la partida de antes, que las
## recompensas no se dupliquen, otra persona en el mismo equipo, la computadora segura y CONTINUAR.
## T5: el mapa (semilla y salas visitadas) igual al recargar, el tiempo jugado (solo en una sala y sin
## pausa), año / capítulo / nivel / % de historia y educativo, y la política de recursos al cargar.
## Usa carpetas de prueba: nunca toca las partidas del jugador.
## Ejecutar: godot --headless --path . --script res://tests/test_save.gd

const MENU := "res://ui/menus/main_menu/main_menu.tscn"
const ENTRADA := "res://world/zones/zone0/entrada.tscn"
const LAB := "res://world/zones/zone0/laboratorio.tscn"
const ROOT := "user://prueba_partidas"
const LEGACY := "user://prueba_partida_vieja.json"
const SECRET := "faro-cometa-tambor-mango-12"

var _failures := 0
var state: Node
var economy: Node
var saves: Node
var identity: Node
var world: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	economy = root.get_node("Economy")
	saves = root.get_node("SaveManager")
	identity = root.get_node("IdentityManager")
	world = root.get_node("World")
	_clean()
	identity.base_root = ROOT
	saves.legacy_path = LEGACY
	_test_identity()
	_test_legacy_migration()
	_test_three_slots()
	_test_backups_and_crash()
	_test_tampering()
	_test_other_person()
	_test_world_and_progress()
	await _test_play_time()
	await _test_save_point()
	await _test_menu_continue()
	_clean()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _use_identity(letter: String) -> void:
	identity.use_provider(DevelopmentIdentityProvider.new("user://prueba_identidad_%s.cfg" % letter))


func _test_identity() -> void:
	_use_identity("a")
	_check(identity.kind == "dev" and DevelopmentIdentityProvider.is_valid_id(identity.identity_id), "sin Steam se usa una identidad de desarrollo (%s)" % identity.identity_id)
	_check(identity.identity_id.begins_with("dev_") and not identity.is_steam(), "nunca se confunde con un Steam ID (empieza con dev_)")
	var first: String = identity.identity_id
	_use_identity("a")
	_check(identity.identity_id == first, "la identidad de desarrollo es estable en este equipo")
	_check(identity.saves_root() == ROOT.path_join(first), "cada identidad tiene su carpeta de partidas")
	_check(PlayerIdentity.is_valid_folder("76561198000000000"), "un Steam ID (solo dígitos) es una carpeta válida")
	for bad in ["../otro", "dev_zz", "abc", "-1234567", "7656119800000000000000", "dev_0123456789abcdeG", ""]:
		_check(not PlayerIdentity.is_valid_folder(bad), "carpeta de identidad rechazada: «%s»" % bad)


## La partida de antes (un solo archivo, versión 1) pasa a la ranura 1, con una copia del original.
func _test_legacy_migration() -> void:
	var v1 := {
		"version": 1, "saved_at": 1760000000,
		"location": { "scene": ENTRADA, "entry": "entrada" },
		"game": { "flags": ["marca_vieja"], "quests": {}, "economy": { "ecos": 42, "claimed": ["mision:prologo"] },
			"player": { "max_masks": 4, "dash_level": 0 } },
		"campo_raro": "se conserva",
	}
	var file := FileAccess.open(LEGACY, FileAccess.WRITE)
	file.store_string(JSON.stringify(v1))
	file.close()
	_check(saves.migrate_legacy(), "la partida de antes se migra")
	_check(not FileAccess.file_exists(LEGACY) and FileAccess.file_exists(saves.slot_path(1, "partida.v1.json")),
		"el archivo viejo se quita y queda una copia del original en la ranura 1")
	var info: Dictionary = saves.slot_info(1)
	_check(info["estado"] == "ok" and int(info["meta"]["revision"]) == 1, "ahora es la ranura 1")
	_check(saves.load_slot(1) and state.has_flag(&"marca_vieja") and economy.ecos == 42, "con su progreso y sus Ecos")
	var raw := FileAccess.get_file_as_string(saves.slot_path(1))
	_check(raw.begins_with("{\"formato\":\"nullveil-partida\"") and raw.contains("\"save_version\":2"), "en el formato nuevo (versión 2)")
	_check(raw.contains("campo_raro"), "sin perder campos que la versión nueva no usa")
	saves.delete_all()


## Tres partidas independientes: nada se mezcla entre ranuras.
func _test_three_slots() -> void:
	_check(not saves.save_game(ENTRADA, &"entrada") or saves.active_slot != 0, "sin ranura activa no se guarda")
	for slot in [1, 2, 3]:
		_check(saves.new_game(slot), "partida nueva en la ranura %d" % slot)
		economy.add_ecos(100 * slot)
		state.set_flag(StringName("marca_ranura_%d" % slot))
		state.learn_command(&"ls")
		if slot == 2:
			state.set_dash_level(1)
			state.unlock_double_jump()
			state.unlock_vision()
			state.set_nullblade_stage(1)
			state.set_password(&"profesor", SECRET, "K7QM-4XPR")
		economy.claim_reward(StringName("terminal:prueba_%d" % slot), 10)
		_check(saves.save_game(ENTRADA, &"entrada"), "se guarda la ranura %d" % slot)
	for slot in [1, 2, 3]:
		_check(saves.load_slot(slot), "se carga la ranura %d" % slot)
		_check(economy.ecos == 100 * slot + 10 and state.has_flag(StringName("marca_ranura_%d" % slot)),
			"ranura %d: sus Ecos (%d) y su progreso" % [slot, economy.ecos])
		var others := [1, 2, 3].filter(func(other: int) -> bool: return other != slot)
		_check(others.all(func(other: int) -> bool: return not state.has_flag(StringName("marca_ranura_%d" % other))),
			"ranura %d: nada de las otras ranuras" % slot)
		var skilled: bool = slot == 2
		_check(state.dash_level == (1 if skilled else 0) and state.can_double_jump == skilled and state.vision_unlocked == skilled
			and state.nullblade_stage == (1 if skilled else 0), "ranura %d: solo sus habilidades (sin adelantos)" % slot)
	saves.load_slot(2)
	_check(state.check_password(&"profesor", SECRET), "la huella de la contraseña del juego se conserva")
	_check(economy.claim_reward(&"terminal:prueba_2", 10) == 0, "una recompensa ya cobrada no se cobra otra vez al recargar")
	var id_before: String = saves.slot_info(2)["meta"]["partida_id"]
	saves.save_game(LAB, &"desde_pc")
	var info: Dictionary = saves.slot_info(2)
	_check(int(info["meta"]["revision"]) == 2 and info["meta"]["partida_id"] == id_before, "cada guardado sube la revisión y conserva el id de la partida")
	saves.new_game(2)
	_check(saves._meta["partida_id"] != id_before, "una partida nueva tiene otro id")
	saves.load_slot(2)
	saves.delete_slot(3)
	_check(saves.slot_info(3)["estado"] == "vacia" and saves.slot_info(1)["estado"] == "ok" and saves.slot_info(2)["estado"] == "ok",
		"borrar una ranura no toca las otras")
	_check(saves.first_empty_slot() == 3 and saves.last_slot() == 2, "primera ranura vacía y última usada")
	var size := FileAccess.get_file_as_bytes(saves.slot_path(2)).size()
	var start := Time.get_ticks_usec()
	saves.save_game(LAB, &"desde_pc")
	var micro := Time.get_ticks_usec() - start
	_check(size < 100_000 and micro < 500_000, "una partida pesa %.1f KB y guardar tarda %.1f ms" % [size / 1024.0, micro / 1000.0])


## Respaldo y cierre inesperado.
func _test_backups_and_crash() -> void:
	saves.load_slot(1)
	state.set_flag(&"marca_revision_2")
	saves.save_game(ENTRADA, &"entrada")
	_check(FileAccess.file_exists(saves.slot_path(1, saves.BACKUP_FILE)), "al guardar otra vez, el anterior queda como respaldo")
	_write(saves.slot_path(1), "{ roto")
	var info: Dictionary = saves.slot_info(1)
	_check(info["estado"] == "recuperada" and info["origen"] == "respaldo", "si la principal se daña, se usa el respaldo")
	_check(saves.load_slot(1) and not state.has_flag(&"marca_revision_2"), "y se carga la versión anterior")
	_check(saves.restore_backup(1) and saves.slot_info(1)["estado"] == "ok", "el respaldo puede volver a ser la principal")
	# Cierre entre «la principal pasa a respaldo» y «el temporal pasa a principal».
	saves.load_slot(1)
	state.set_flag(&"marca_temporal")
	var body: Dictionary = saves.build_body(ENTRADA, &"entrada")
	_write(saves.slot_path(1, saves.TEMP_FILE), SaveSerializer.pack(body))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(saves.slot_path(1)), ProjectSettings.globalize_path(saves.slot_path(1, saves.BACKUP_FILE)))
	info = saves.slot_info(1)
	_check(info["estado"] == "recuperada" and info["origen"] == "temporal", "si el juego se cerró a mitad del guardado, se usa el temporal (más nuevo)")
	_check(saves.load_slot(1) and state.has_flag(&"marca_temporal"), "sin perder lo último que se guardó")
	_check(saves.save_game(ENTRADA, &"entrada") and saves.slot_info(1)["estado"] == "ok", "el siguiente guardado deja todo en orden")
	# Los tres archivos dañados: la ranura queda marcada como dañada (no se borra).
	for file in [saves.MAIN_FILE, saves.BACKUP_FILE, saves.TEMP_FILE]:
		_write(saves.slot_path(1, file), "basura")
	_check(saves.slot_info(1)["estado"] == "danada" and FileAccess.file_exists(saves.slot_path(1)), "con todo dañado, la ranura se marca «dañada» y no se borra")
	saves.delete_slot(1)


## Archivos alterados: se rechazan sin cargar nada raro.
func _test_tampering() -> void:
	saves.load_slot(2)
	var good := FileAccess.get_file_as_string(saves.slot_path(2))
	var main: String = saves.slot_path(2)
	_remove(saves.slot_path(2, saves.BACKUP_FILE))
	_write(main, good.replace("\"ecos\": 210", "\"ecos\": 999999"))
	_check(saves.slot_info(2)["estado"] == "danada", "si se cambia el archivo a mano, la huella no coincide")
	var cases := {
		"Ecos negativos": func(b: Dictionary) -> void: b["estado"]["economy"]["ecos"] = -5,
		"cristales de más": func(b: Dictionary) -> void: b["estado"]["player"]["max_masks"] = 999,
		"escena fuera del juego": func(b: Dictionary) -> void: b["ubicacion"]["escena"] = "res://../../otra.tscn",
		"punto con código": func(b: Dictionary) -> void: b["ubicacion"]["punto"] = "entrada; rm -rf",
		"marca con código": func(b: Dictionary) -> void: b["estado"]["flags"].append("<script>"),
		"archivo de otra ranura": func(b: Dictionary) -> void: b["meta"]["ranura"] = 3,
		"id de partida inválido": func(b: Dictionary) -> void: b["meta"]["partida_id"] = "../../x",
	}
	var original: Dictionary = SaveSerializer.unpack(good)["body"]
	for name: String in cases:
		var body := original.duplicate(true)
		cases[name].call(body)
		_write(main, SaveSerializer.pack(body))
		_check(saves.slot_info(2)["estado"] == "danada", "partida rechazada: %s" % name)
	var future := "{\"formato\":\"nullveil-partida\",\"integridad\":\"%s\",\"save_version\":99}\n{}" % "{}".sha256_text()
	_write(main, future)
	_check(saves.slot_info(2)["estado"] == "incompatible" and FileAccess.get_file_as_string(main) == future,
		"una partida de una versión más nueva se marca «incompatible» y no se toca")
	_write(main, good)
	_check(saves.slot_info(2)["estado"] == "ok", "el archivo correcto vuelve a cargarse")


## Otra persona en el mismo equipo no ve ni carga las partidas de la primera.
func _test_other_person() -> void:
	var first: String = identity.identity_id
	_use_identity("b")
	_check(identity.identity_id != first and saves.active_slot == 0, "otra identidad en el mismo equipo")
	_check(not saves.has_save() and [1, 2, 3].all(func(s: int) -> bool: return saves.slot_info(s)["estado"] == "vacia"),
		"no ve ninguna partida de la otra persona")
	saves.new_game(1)
	state.set_flag(&"marca_de_b")
	saves.save_game(ENTRADA, &"entrada")
	_use_identity("a")
	_check(saves.load_slot(2) and not state.has_flag(&"marca_de_b"), "y al volver, la primera sigue con sus partidas")
	# Un conflicto: este equipo ya vio una revisión más nueva de la ranura 2 que la que hay ahora.
	var ledger: Dictionary = saves._ledger()
	ledger["revisiones"]["2"]["revision"] = 999
	saves._save_ledger(ledger)
	_check(saves.slot_info(2)["conflicto"], "si llega una revisión más vieja de la que vio este equipo, avisa «posible conflicto»")


## El mapa, el progreso y lo educativo se guardan y vuelven igual.
func _test_world_and_progress() -> void:
	saves.new_game(1)
	var seed_value: int = world.world_seed
	_check(world.visited.is_empty() and world.generator_version == world.GENERATOR_VERSION, "una partida nueva tiene su semilla y ninguna sala visitada")
	world.enter(ENTRADA)
	world.enter(LAB)
	state.play_time = 4321.7
	state.set_flag(&"tutorial_terminado")
	for quest in [&"prologo", &"contrasena_profesor", &"cuarto_viejo"]:
		state.start_quest(quest)
		for step: QuestStep in QuestDB.get_quest(quest).steps:
			state.complete_step(quest, step.id)
	economy.claim_reward(&"terminal:pc_profesor_cuenta", 0)
	state.learn_command(&"ls -a")
	state.current_masks = 1.0
	state.current_energy = 0.0
	_check(saves.save_game(LAB, &"desde_pc"), "se guarda la partida con mapa y progreso")
	var meta: Dictionary = saves.slot_info(1)["meta"]
	_check(int(meta["tiempo_jugado"]) == 4321, "la tarjeta tiene el tiempo jugado (%s s)" % meta["tiempo_jugado"])
	_check(meta["anio"] == "decimo" and int(meta["capitulo"]) == 1 and int(meta["nivel"]) == 1,
		"y el año, capítulo y nivel (décimo, cap. %s, nivel %s)" % [meta["capitulo"], meta["nivel"]])
	_check(int(meta["historia"]) == 4 and int(meta["educativo"]) > 0,
		"y los porcentajes: historia %s %% (prólogo completo = 1 de 25) y educativo %s %%" % [meta["historia"], meta["educativo"]])
	_check(meta["lugar"] == "Laboratorio", "y el lugar (%s)" % meta["lugar"])
	world.new_world()
	state.reset()
	_check(world.world_seed != seed_value or world.visited.is_empty(), "otra partida cambia el mapa")
	_check(saves.load_slot(1), "se vuelve a cargar")
	_check(world.world_seed == seed_value and world.visited.has(&"entrada") and world.visited.has(&"laboratorio"),
		"el mapa es el mismo: misma semilla (%d) y salas visitadas" % world.world_seed)
	_check(is_equal_approx(state.play_time, 4321.0), "el tiempo jugado sigue desde donde estaba")
	_check(state.current_masks < 0.0 and state.current_energy < 0.0, "al cargar, cristales y energía llenos (política de recursos)")
	var body: Dictionary = SaveSerializer.unpack(FileAccess.get_file_as_string(saves.slot_path(1)))["body"]
	_check(body["educativo"]["terminales"].has("pc_profesor_cuenta") and body["educativo"]["comandos"].has("ls -a"),
		"lo educativo queda registrado (terminales resueltas y comandos)")
	_check(body["mundo"]["semilla"] == str(seed_value), "la semilla va como texto (sin perder precisión)")


## El tiempo jugado solo avanza dentro de una sala y sin pausa.
func _test_play_time() -> void:
	saves.load_slot(1)
	change_scene_to_file(ENTRADA)
	await _wait(0.4)
	await _frames(20)
	var before: float = state.play_time
	var elapsed := 0.0
	for i in 60:
		await process_frame
		elapsed += root.get_process_delta_time()
	var playing: float = state.play_time - before
	_check(elapsed > 0.0 and absf(playing - elapsed) < elapsed * 0.1, "jugando, el tiempo avanza al ritmo del juego (%.3f s de %.3f s)" % [playing, elapsed])
	paused = true
	before = state.play_time
	for i in 30:
		await process_frame
	paused = false
	_check(is_equal_approx(state.play_time, before), "en pausa no avanza")


func _test_save_point() -> void:
	saves.new_game(3)
	change_scene_to_file(ENTRADA)
	await _wait(0.6)
	var room := current_scene as Room
	var player := room.player
	var save_point := room.get_node("SavePoint") as SavePoint
	player.teleport_to(save_point.global_position + Vector2(-60, 0))
	await _frames(4)
	Input.action_press("move_right")
	await _until(func() -> bool: return player.global_position.x >= save_point.global_position.x)
	Input.action_release("move_right")
	await _frames(4)
	_check(room.checkpoint == save_point and saves.slot_info(3)["estado"] == "vacia", "al pasar queda como punto de control, pero no guarda solo")
	player.health.take_damage(2.0)
	player.set_energy(0.0)
	_check(save_point._prompt.visible and save_point._prompt.text == "E: guardar partida", "aparece «E: guardar partida»")
	_action("interact")
	await _until(func() -> bool: return saves.slot_info(3)["estado"] == "ok")
	var info: Dictionary = saves.slot_info(3)
	_check(info["estado"] == "ok" and info["meta"]["lugar"] == "Entrada", "con E se guarda en la ranura activa (lugar: %s)" % info["meta"]["lugar"])
	_check(player.health.current == player.health.max_health and player.energy == player.max_energy, "y llena los cristales y la energía")


func _test_menu_continue() -> void:
	state.reset()
	change_scene_to_file(MENU)
	await _frames(10)
	var continue_button := current_scene.get_node("%ContinueButton") as Button
	_check(continue_button.visible, "con partidas guardadas aparece CONTINUAR")
	continue_button.pressed.emit()
	await _until(func() -> bool: return current_scene != null and current_scene.name == "Entrada")
	await _frames(10)
	_check(current_scene.name == "Entrada" and saves.active_slot == 3, "CONTINUAR abre la última ranura usada (la 3) donde se guardó")


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _clean() -> void:
	_remove_dir(ProjectSettings.globalize_path(ROOT))
	for file in ["user://prueba_identidad_a.cfg", "user://prueba_identidad_b.cfg", LEGACY]:
		_remove(file)


func _remove_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file in dir.get_files():
		dir.remove(file)
	for sub in dir.get_directories():
		_remove_dir(path.path_join(sub))
	DirAccess.remove_absolute(path)


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
		await process_frame
		await physics_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
