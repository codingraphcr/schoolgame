extends SceneTree
## Prueba automática: E4. Guardar y continuar la partida (SaveManager): todo el progreso, la
## escritura segura con copia de respaldo, archivos dañados o inválidos, la computadora segura
## (punto de control al pasar; con E guarda y cura) y el botón CONTINUAR del menú (con un usuario:
## su partida va cifrada en su carpeta).
## Usa un archivo de prueba: nunca toca la partida del jugador.
## Ejecutar: godot --headless --path . --script res://tests/test_save.gd

const MENU := "res://ui/menus/main_menu/main_menu.tscn"
const ENTRADA := "res://world/zones/zone0/entrada.tscn"
const SECRET := "faro-cometa-tambor-mango-12"

var _failures := 0
var state: Node
var economy: Node
var saves: Node
var server: TestServer


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	economy = root.get_node("Economy")
	saves = root.get_node("SaveManager")
	saves.path = "user://partida_prueba.json"
	saves.delete_save()
	_test_files()
	await _test_menu_and_continue()
	await _test_save_point()
	saves.delete_save()
	if server:
		server.stop(self)
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _prepare_progress() -> void:
	state.reset()
	state.start_quest(&"prologo")
	state.complete_step(&"prologo", &"hablar_profesor")
	state.set_flag(&"marca_de_prueba")
	state.learn_command(&"ls")
	state.set_password(&"profesor", SECRET, "K7QM-4XPR")
	state.set_dash_level(1)
	state.unlock_vision()
	economy.add_ecos(123)
	economy.claim_reward(&"terminal:prueba", 10)


func _test_files() -> void:
	_check(not saves.has_save(), "sin partida guardada al principio")
	_check(not saves.save_game("res://no/existe.tscn", &"x") and not saves.has_save(), "no guarda con una escena inválida")
	_prepare_progress()
	_check(saves.save_game(ENTRADA, &"entrada") and saves.has_save(), "guarda la partida")
	var text := FileAccess.get_file_as_string(saves.path)
	_check(not text.contains(SECRET), "el archivo no contiene la contraseña (solo su huella)")
	_check(not FileAccess.file_exists(saves.path + ".tmp"), "no queda el archivo temporal")
	saves.save_game(ENTRADA, &"entrada")
	_check(FileAccess.file_exists(saves.backup_path()), "al volver a guardar, el anterior queda como copia de respaldo")
	# Archivo principal dañado: se usa la copia.
	var file := FileAccess.open(saves.path, FileAccess.WRITE)
	file.store_string("{ roto")
	file.close()
	_check(saves.has_save() and saves.load_data()["game"]["flags"].has("marca_de_prueba"), "si el guardado se daña, se usa la copia de respaldo")
	# Ambos dañados o inválidos: no hay partida.
	for bad in ["{ roto", JSON.stringify({ "version": 99, "location": { "scene": ENTRADA, "entry": "x" }, "game": {} }),
			JSON.stringify({ "version": 1, "location": { "scene": "res://no.tscn", "entry": "x" }, "game": {} })]:
		for target in [saves.path, saves.backup_path()]:
			var f := FileAccess.open(target, FileAccess.WRITE)
			f.store_string(bad)
			f.close()
	_check(not saves.has_save(), "un guardado dañado, de una versión futura o con una sala inexistente no se usa")
	saves.delete_save()
	_check(not saves.has_save(), "borrar la partida quita también la copia")


func _test_menu_and_continue() -> void:
	var profiles := root.get_node("Profiles")
	server = await TestServer.start(self, "guardado")
	if server == null:
		_failures += 1
		return
	change_scene_to_file(MENU)
	await _frames(10)
	_check(current_scene.get_node_or_null("Login") != null and not current_scene.get_node("%Buttons").visible,
		"sin sesión, el menú pide iniciar sesión")
	_check((await profiles.create("Prueba_1", "faro cometa tambor mango 12"))["ok"], "se crea una cuenta de prueba")
	_check(saves.key.size() == 32 and saves.path.begins_with(server.folder), "su partida va cifrada en su carpeta")
	saves.delete_save()
	change_scene_to_file(MENU)
	await _frames(10)
	_check(current_scene.get_node_or_null("Login") == null and current_scene.get_node("%Buttons").visible, "con sesión, aparecen las opciones")
	_check(not current_scene.get_node("%ContinueButton").visible, "sin partida, el menú no muestra CONTINUAR")
	_prepare_progress()
	saves.save_game(ENTRADA, &"entrada")
	state.reset()
	change_scene_to_file(MENU)
	await _frames(10)
	var continue_button := current_scene.get_node("%ContinueButton") as Button
	_check(continue_button.visible, "con una partida guardada, aparece CONTINUAR")
	continue_button.pressed.emit()
	await _until(func() -> bool: return current_scene != null and current_scene.name == "Entrada")
	await _frames(10)
	var room := current_scene as Room
	_check(room != null and room.name == "Entrada", "CONTINUAR lleva a la sala donde se guardó")
	if room == null:
		return
	var save_point := room.get_node("SavePoint") as SavePoint
	_check(absf(room.player.global_position.x - save_point.global_position.x) < 2.0 and room.checkpoint == save_point,
		"Kai aparece en la computadora segura (y queda como punto de control)")
	_check(state.get_current_step(&"prologo") == &"revisar_computadora" and state.has_flag(&"marca_de_prueba")
		and state.has_learned_command(&"ls") and state.check_password(&"profesor", SECRET) and state.dash_level == 1
		and state.vision_unlocked, "se recupera el progreso: misión, marcas, comandos, contraseña y habilidades")
	_check(economy.ecos == 123 + 10 and economy.is_claimed(&"terminal:prueba"), "se recuperan los Ecos y las recompensas cobradas")


func _test_save_point() -> void:
	saves.delete_save()
	state.reset()
	change_scene_to_file(ENTRADA)
	await _wait(0.6)
	var room := current_scene as Room
	var player := room.player
	var save_point := room.get_node("SavePoint") as SavePoint
	_check(room.checkpoint != save_point, "antes de pasar, no es el punto de control")
	player.teleport_to(save_point.global_position + Vector2(-60, 0))
	await _frames(4)
	Input.action_press("move_right")
	await _until(func() -> bool: return player.global_position.x >= save_point.global_position.x)
	Input.action_release("move_right")
	await _frames(4)
	_check(room.checkpoint == save_point and not saves.has_save(), "al pasar queda como punto de control, pero no guarda solo")
	player.health.take_damage(2.0)
	player.set_energy(0.0)
	_check(save_point._prompt.visible and save_point._prompt.text == "E: guardar partida", "aparece «E: guardar partida»")
	_action("interact")
	await _until(func() -> bool: return saves.has_save())
	_check(saves.has_save() and saves.load_data()["location"]["entry"] == "entrada", "con E se guarda la partida en esa computadora")
	_check(player.health.current == player.health.max_health and player.energy == player.max_energy, "y llena los cristales y la energía")


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
