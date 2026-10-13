extends SceneTree
## Prueba automática: guardado automático (T6, AutoSave). Guarda al avanzar una misión, al obtener una
## habilidad, al cobrar una recompensa única y al salir al menú; nunca en un momento inseguro (sin
## control, en el aire, durante una pelea o una transición), sino en cuanto vuelve a ser seguro; y
## siempre con un punto de reaparición válido (la entrada por la que llegó Kai o la computadora segura).
## Usa carpetas de prueba: nunca toca las partidas del jugador.
## Ejecutar: godot --headless --path . --script res://tests/test_autosave.gd

const ENTRADA := "res://world/zones/zone0/entrada.tscn"
const ROOT := "user://prueba_autoguardado"
const FLOOR_Y := 304.0

var _failures := 0
var state: Node
var economy: Node
var saves: Node
var auto: AutoSave


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	economy = root.get_node("Economy")
	saves = root.get_node("SaveManager")
	auto = saves.auto_save
	var identity := root.get_node("IdentityManager")
	_remove_dir(ProjectSettings.globalize_path(ROOT))
	identity.base_root = ROOT
	identity.use_provider(DevelopmentIdentityProvider.new(ROOT + "_identidad.cfg"))
	state.reset()
	state.start_quest(&"prologo")
	_check(auto.pending.is_empty() and saves.slot_info(1)["estado"] == "vacia", "sin ranura activa no se guarda nada solo")
	saves.new_game(1)
	state.start_quest(&"prologo")
	change_scene_to_file(ENTRADA)
	await _wait(0.6)
	var room := current_scene as Room
	var player := room.player
	await _until(func() -> bool: return player.is_on_floor())
	await _test_triggers(room, player)
	await _test_unsafe_moments(room, player)
	await _test_save_point_and_exit(room, player)
	_test_loading_is_quiet()
	_remove_dir(ProjectSettings.globalize_path(ROOT))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ROOT + "_identidad.cfg"))
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _revision() -> int:
	var info: Dictionary = saves.slot_info(1)
	return int(info["meta"]["revision"]) if info["estado"] == "ok" else 0


func _test_triggers(room: Room, player: Player) -> void:
	state.complete_step(&"prologo", &"hablar_profesor")
	await _frames(2)
	_check(_revision() == 1, "al avanzar la misión se guarda solo")
	var body: Dictionary = SaveSerializer.unpack(FileAccess.get_file_as_string(saves.slot_path(1)))["body"]
	_check(body["ubicacion"]["escena"] == ENTRADA and body["ubicacion"]["punto"] == "", "en la sala, en su punto de aparición (no en la posición exacta)")
	state.set_dash_level(1)
	await _frames(2)
	_check(_revision() == 2, "al obtener una habilidad se guarda solo")
	economy.claim_reward(&"terminal:prueba_autoguardado", 5)
	await _frames(2)
	_check(_revision() == 3, "al cobrar una recompensa única se guarda solo")
	economy.claim_reward(&"terminal:prueba_autoguardado", 5)
	state.set_dash_level(1)
	await _frames(2)
	_check(_revision() == 3, "repetir lo mismo no vuelve a guardar")


func _test_unsafe_moments(room: Room, player: Player) -> void:
	# Sin control (diálogo o cinemática): espera.
	player.controls_locked = true
	state.unlock_double_jump()
	await _frames(4)
	_check(_revision() == 3 and auto.pending == "habilidad" and auto.is_safe()["reason"] == "cinematica",
		"durante una cinemática no se guarda: queda pendiente")
	player.controls_locked = false
	await _until(func() -> bool: return _revision() == 4)
	_check(_revision() == 4 and auto.pending.is_empty(), "en cuanto Kai recupera el control, se guarda")
	# En el aire: espera a que Kai esté en el suelo.
	player.teleport_to(Vector2(player.global_position.x, FLOOR_Y - 120.0))
	await _frames(2)
	economy.claim_reward(&"terminal:prueba_aire", 5)
	await _frames(2)
	_check(_revision() == 4 and auto.is_safe()["reason"] == "en_el_aire", "en plena caída no se guarda")
	await _until(func() -> bool: return _revision() == 5)
	_check(_revision() == 5 and player.is_on_floor(), "al tocar el suelo, se guarda")
	# Una pelea (o cualquier cosa en el grupo «guardado_bloqueado»): espera.
	var fight := Node.new()
	room.add_child(fight)
	fight.add_to_group(AutoSave.BLOCK_GROUP)
	state.complete_step(&"prologo", &"revisar_computadora")
	await _frames(4)
	_check(_revision() == 5 and auto.is_safe()["reason"] == "bloqueado", "durante una pelea de jefe no se guarda")
	fight.queue_free()
	await _until(func() -> bool: return _revision() == 6)
	_check(_revision() == 6, "al terminar la pelea, se guarda")


func _test_save_point_and_exit(room: Room, player: Player) -> void:
	var save_point := room.get_node("SavePoint") as SavePoint
	room.checkpoint = save_point
	state.set_flag(&"marca_antes_de_salir")
	_check(room.save_point_id() == &"entrada", "con la computadora segura activa, el punto de reaparición es ella")
	var press := InputEventAction.new()
	press.action = &"pause"
	press.pressed = true
	Input.parse_input_event(press)
	await _until(func() -> bool: return _revision() == 7)
	_check(_revision() == 7, "al salir al menú se guarda")
	var body: Dictionary = SaveSerializer.unpack(FileAccess.get_file_as_string(saves.slot_path(1)))["body"]
	_check(body["ubicacion"]["punto"] == "entrada" and body["estado"]["flags"].has("marca_antes_de_salir"),
		"con el progreso y el punto de reaparición válido")
	await _until(func() -> bool: return current_scene != null and current_scene.name == "MainMenu")
	_check(not auto.is_safe()["ok"], "en el menú no hay nada que guardar automáticamente")


## Cargar o empezar una partida no dispara guardados (los cambios no son logros del jugador).
func _test_loading_is_quiet() -> void:
	var before := _revision()
	saves.load_slot(1)
	saves.new_game(2)
	saves.load_slot(1)
	_check(_revision() == before and saves.slot_info(2)["estado"] == "vacia" and auto.pending.is_empty(),
		"cargar o empezar una partida no guarda nada solo")


func _until(condition: Callable) -> void:
	for i in 600:
		if condition.call():
			return
		await process_frame
		await physics_frame


func _frames(count: int) -> void:
	for i in count:
		await process_frame
		await physics_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


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
