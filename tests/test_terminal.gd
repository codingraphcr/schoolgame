extends SceneTree
## Prueba automática: terminal simulada. Sistema de archivos ficticio, comandos (pwd, ls, cd, cat,
## clear, history, help), errores, autocompletado, comandos permitidos, que no toque el sistema real,
## y la primera terminal del juego en la PC del profesor (misión «La contraseña del profesor»).
## Ejecutar: godot --headless --path . --script res://tests/test_terminal.gd

const PC := "res://world/zones/pc_profesor/escritorio.tscn"
const CHALLENGE := "res://data/terminals/pc_profesor_cuenta.tres"

var _failures := 0
var state: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	state.reset()
	_check(not (load("res://data/grimorio/comando_cd.tres") as GrimorioEntry).is_unlocked(state), "partida nueva: la página de cd está bloqueada")
	_test_file_system()
	_test_commands()
	_test_completion_and_limits()
	_test_safety()
	await _test_in_game()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_file_system() -> void:
	var fs := VirtualFileSystem.from_files({ "cuenta/configuracion.txt": "hola", "imagenes/": "" }, "/home/kai")
	_check(fs.cwd == "/home/kai" and fs.is_dir("~") and fs.is_dir("imagenes"), "sistema de archivos: carpeta personal y carpetas vacías")
	_check(fs.resolve("cuenta/../imagenes/.") == "/home/kai/imagenes" and fs.resolve("/../..") == "/",
		"sistema de archivos: rutas con . y .. (sin salir de la raíz)")
	_check(fs.read("~/cuenta/configuracion.txt") == "hola" and fs.read("cuenta") == "", "sistema de archivos: leer archivos")
	_check(fs.display_path("/home/kai/cuenta") == "~/cuenta" and fs.display_path("/home") == "/home", "sistema de archivos: ~ en el prompt")


func _test_commands() -> void:
	var t := _new_terminal()
	_check(t.prompt() == "alvarado@pc-laboratorio:~$", "prompt como en Linux (%s)" % t.prompt())
	_check(_out(t, "pwd") == "/home/alvarado", "pwd muestra la carpeta actual")
	_check(_out(t, "ls") == "cuenta/  descargas/  documentos/  imagenes/", "ls lista las carpetas (con /)")
	_check(_out(t, "ls cuenta") == "configuracion.txt  foto_perfil.png", "ls de otra carpeta")
	var error := t.execute("cd noexiste")
	_check(not error["ok"] and String(error["output"]).contains("No existe"), "cd a una carpeta que no existe da error")
	_check(not t.execute("cd cuenta/configuracion.txt")["ok"], "cd a un archivo da error («No es un directorio»)")
	_check(String(t.execute("cat documentos")["output"]).contains("Es un directorio"), "cat de una carpeta da error")
	_check(not t.execute("cat")["ok"], "cat sin archivo explica cómo usarlo")
	_check(t.execute("cd cuenta")["ok"] and t.prompt() == "alvarado@pc-laboratorio:~/cuenta$", "cd entra a la carpeta (el prompt cambia)")
	_check(_out(t, "cat configuracion.txt").contains("contraseña: 123456"), "cat muestra el archivo")
	t.execute("cd ..")
	_check(t.fs.cwd == "/home/alvarado", "cd .. vuelve atrás")
	t.execute("cd /home/alvarado/documentos")
	t.execute("cd")
	_check(t.fs.cwd == "/home/alvarado", "cd con ruta absoluta y cd solo (vuelve a ~)")
	_check(String(t.execute("rm -rf /")["output"]).contains("orden no encontrada") and t.fs.is_dir("cuenta"),
		"un comando desconocido no hace nada (rm -rf /)")
	_check(_out(t, "history").contains("rm -rf /") and _out(t, "help").contains("cat"), "history y help")
	_check(t.execute("clear")["clear"], "clear limpia la pantalla")
	var ran: Array[String] = []
	var record := func(command: String, _args: PackedStringArray, _target: String) -> void: ran.append(command)
	t.command_run.connect(record)
	t.execute("cd noexiste")
	t.execute("ls")
	t.command_run.disconnect(record)
	_check(ran == ["ls"], "solo los comandos que funcionan cuentan (para objetivos y el Grimorio)")


func _test_completion_and_limits() -> void:
	var t := _new_terminal()
	_check(t.complete("pw") == "pwd " and t.complete("c") == "c", "autocompletar comandos (y no adivina si hay varios)")
	_check(t.complete("cd cu") == "cd cuenta/" and t.complete("cat cuenta/con") == "cat cuenta/configuracion.txt ",
		"autocompletar carpetas y archivos")
	t.allowed = PackedStringArray(["ls", "help"])
	_check(String(t.execute("cd cuenta")["output"]).contains("todavía no") and t.fs.cwd == "/home/alvarado",
		"una terminal puede limitar los comandos")
	var challenge: TerminalChallenge = load(CHALLENGE)
	var c := challenge.create_interpreter()
	c.execute("cd documentos")
	var goal_hit := [false]
	var watch := func(command: String, _args: PackedStringArray, target: String) -> void:
		goal_hit[0] = goal_hit[0] or challenge.is_goal(c, command, target)
	c.command_run.connect(watch)
	c.execute("cat ../cuenta/foto_perfil.png")
	_check(not goal_hit[0], "leer otro archivo no cumple el objetivo")
	c.execute("cat ~/cuenta/configuracion.txt")
	c.command_run.disconnect(watch)
	_check(goal_hit[0], "el objetivo se cumple leyendo el archivo con cualquier ruta válida")


## La terminal es una simulación: el intérprete y el sistema de archivos no tocan el dispositivo.
func _test_safety() -> void:
	for path in ["res://systems/terminal/command_interpreter.gd", "res://systems/terminal/virtual_file_system.gd", "res://ui/terminal/terminal_window.gd"]:
		var source := (load(path) as GDScript).source_code
		var forbidden := ["OS.execute", "OS.create_process", "OS.shell", "FileAccess", "DirAccess"].filter(
			func(word: String) -> bool: return source.contains(word))
		_check(forbidden.is_empty(), "%s no ejecuta ni lee nada real %s" % [path.get_file(), forbidden])


func _test_in_game() -> void:
	state.reset()
	state.start_quest(&"contrasena_profesor")
	state.complete_step(&"contrasena_profesor", &"entrar_pc")
	state.complete_step(&"contrasena_profesor", &"cruzar_spam")
	change_scene_to_file(PC)
	await _wait(0.6)
	var room := current_scene as Room
	var player := room.player
	var station := room.get_node("TerminalStation") as TerminalStation
	var tab := room.get_node("AccountTab") as Interactable
	_check(state.get_objective_text().contains("terminal"), "el objetivo pide usar la terminal")
	_check(not room.get_node("AccountWindow").revealed, "la cuenta todavía no muestra la contraseña")
	player.teleport_to(station.global_position)
	await _frames(8)
	_check(station._prompt.visible and station._prompt.text == "E: abrir la terminal", "junto a la terminal aparece «E: abrir la terminal»")
	_check(not tab.enabled, "la pestaña «Cambiar contraseña» espera a que se revise la configuración")

	# Esc cierra sin resolver.
	_action("interact")
	await _until(func() -> bool: return _window() != null)
	_check(_window() != null and player.controls_locked, "con E se abre la terminal y Kai no se mueve")
	_action("ui_cancel")
	await _until(func() -> bool: return _window() == null and not player.controls_locked)
	_check(_window() == null and state.get_current_step(&"contrasena_profesor") == &"revisar_configuracion",
		"Esc cierra la terminal sin completar el paso")
	_check(current_scene == room, "Esc no saca del juego mientras la terminal está abierta")

	_action("interact")
	await _until(func() -> bool: return _window() != null)
	var window := _window()
	window._line.text = "pwd"
	window._line.text_submitted.emit("pwd")
	_check(window._output.get_parsed_text().contains("/home/alvarado"), "escribir un comando y pulsar Enter lo ejecuta")
	window.show_hint()
	_check(window._output.get_parsed_text().contains("Pista: Escribe ls"), "el botón Pista da la primera pista")
	window.submit("cd cuenta")
	_check(window._prompt.text.ends_with("~/cuenta$"), "el prompt muestra la carpeta actual")
	window.submit("cat configuracion.txt")
	await _frames(2)
	_check(window.is_solved and window._continue.visible, "leer configuracion.txt cumple el objetivo")
	_check(window._output.get_parsed_text().contains("verificacion_en_dos_pasos: desactivada")
		and window._output.get_parsed_text().contains("Objetivo cumplido"), "muestra el archivo y la retroalimentación")
	window._continue.pressed.emit()
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing() and box.get_node("%Text").text.contains("123456"), "Kai le cuenta al profesor lo que encontró")
	for i in 30:
		if not box.is_playing():
			break
		_action("interact")
		await _frames(3)
	await _frames(5)
	_check(state.get_current_step(&"contrasena_profesor") == &"cambiar_contrasena" and not player.controls_locked,
		"la misión avanza: cambiar la contraseña")
	_check(state.has_learned_command(&"pwd") and state.has_learned_command(&"cd") and state.has_learned_command(&"cat"),
		"los comandos usados quedan aprendidos (%s)" % ", ".join(state.get_learned_commands()))
	var page_cat: GrimorioEntry = load("res://data/grimorio/comando_cat.tres")
	var page_ls: GrimorioEntry = load("res://data/grimorio/comando_ls.tres")
	_check(page_cat.is_unlocked(state) and not page_ls.is_unlocked(state),
		"en el Grimorio se desbloquean las páginas de los comandos usados (cat sí; ls no, porque no se usó)")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	state.reset()
	state.from_dict(saved)
	_check(state.has_learned_command(&"cat"), "los comandos aprendidos se guardan")
	await _frames(3)
	_check(room.get_node("AccountWindow").revealed and tab.enabled, "ahora la cuenta muestra el problema y la pestaña se puede usar")
	player.teleport_to(station.global_position)
	await _frames(8)
	_check(not station._prompt.visible, "la terminal ya no se usa en este paso")


func _new_terminal() -> CommandInterpreter:
	return (load(CHALLENGE) as TerminalChallenge).create_interpreter()


func _out(t: CommandInterpreter, line: String) -> String:
	return String(t.execute(line)["output"])


func _window() -> TerminalWindow:
	return get_first_node_in_group(&"terminal_window") as TerminalWindow


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
		await process_frame  # Teclas y HUD se procesan en cuadros de dibujo.
		await physics_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
