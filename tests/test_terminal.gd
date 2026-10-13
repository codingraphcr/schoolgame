extends SceneTree
## Prueba automática: terminal simulada. Sistema de archivos ficticio, comandos (pwd, ls, cd, cat,
## clear, history, help), errores, autocompletado, comandos permitidos («comando inejecutable»), la
## sanitización de la entrada (ataques de quien sabe Linux), que no toque el sistema real,
## y la primera terminal del juego en la PC del profesor (misión «La contraseña del profesor»).
## También archivos ocultos (ls -a) y carpetas protegidas con contraseña (terminal del LAB 2, H5).
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
	_test_sanitization()
	_test_hidden_and_password()
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
	var t := _full_terminal()
	_check(t.prompt() == "alvarado@pc-laboratorio:~$", "prompt como en Linux (%s)" % t.prompt())
	_check(_out(t, "pwd") == "/home/alvarado", "pwd muestra la carpeta actual")
	_check(_out(t, "ls") == "cuenta/  documentos/  imagenes/", "ls lista las carpetas (con /)")
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
	_check(String(t.execute("rm -rf /")["output"]).contains("comando inejecutable") and t.fs.is_dir("cuenta"),
		"un comando que no existe en la terminal es inejecutable (rm -rf / no hace nada)")
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
	var t := _full_terminal()
	_check(t.complete("pw") == "pwd " and t.complete("c") == "c", "autocompletar comandos (y no adivina si hay varios)")
	_check(t.complete("cd cu") == "cd cuenta/" and t.complete("cat cuenta/con") == "cat cuenta/configuracion.txt ",
		"autocompletar carpetas y archivos")
	t.allowed = PackedStringArray(["ls", "help"])
	_check(String(t.execute("cd cuenta")["output"]) == "cd: comando inejecutable" and t.fs.cwd == "/home/alvarado",
		"un comando que esta terminal no permite responde «comando inejecutable»")
	_check(t.complete("c") == "c" and not _out(t, "help").contains("cd"), "Tab y help solo muestran los comandos permitidos")
	_check(_out(t, "ls -a") == "ls -a: comando inejecutable", "una opción que no se necesita (ls -a) también es inejecutable")
	# Cada terminal del juego tiene solo lo que pide su misión.
	var challenge: TerminalChallenge = load(CHALLENGE)
	var c := challenge.create_interpreter()
	_check(Array(challenge.allowed_commands) == ["help", "ls", "cd", "cat"], "la terminal de la PC solo permite help, ls, cd y cat")
	for command in ["pwd", "history", "clear", "rm -rf /", "sudo ls", "whoami", "ls -a", "python", "nano notas.txt"]:
		_check(String(c.execute(command)["output"]).ends_with("comando inejecutable"), "PC: «%s» es inejecutable" % command)
	_check(_out(c, "ls") == "cuenta/" and _out(c, "ls cuenta") == "configuracion.txt",
		"la PC solo tiene los datos de la misión (la configuración de la cuenta)")
	var lab2: TerminalChallenge = load("res://data/terminals/puerta_lab2.tres")
	_check(Array(lab2.allowed_commands) == ["help", "ls", "ls -a", "cd", "cat"], "la terminal del LAB 2 solo permite help, ls, ls -a, cd y cat")
	c.execute("cd cuenta")
	var goal_hit := [false]
	var watch := func(command: String, _args: PackedStringArray, target: String) -> void:
		goal_hit[0] = goal_hit[0] or challenge.is_goal(c, command, target)
	c.command_run.connect(watch)
	c.execute("cat ../cuenta/noexiste.txt")
	_check(not goal_hit[0], "leer otro archivo no cumple el objetivo")
	c.execute("cat ~/cuenta/configuracion.txt")
	c.command_run.disconnect(watch)
	_check(goal_hit[0], "el objetivo se cumple leyendo el archivo con cualquier ruta válida")


## Lo que probaría alguien que sabe usar Linux: nada de esto ejecuta algo ni muestra datos de más.
func _test_sanitization() -> void:
	var attacks := [
		"ls; rm -rf /", "ls && cat cuenta/configuracion.txt", "ls || whoami", "ls | grep cuenta", "cat $(whoami)",
		"cat `id`", "ls > salida.txt", "cat < cuenta/configuracion.txt", "ls *", "cat cuenta/?onfig*", "echo $HOME",
		"cat 'cuenta/configuracion.txt'", "cat \"x\"", "ls\ncat cuenta/configuracion.txt", "ls\tcuenta", "ls\u0000",
		"[color=red]x[/color]", "ls #comentario", "ls !!", "ｌｓ", "cat cuenta/configuración.txt", "ls\u200b",
	]
	for attack: String in attacks:
		var t := _full_terminal()
		var ran := [false]
		t.command_run.connect(func(_c: String, _a: PackedStringArray, _t: String) -> void: ran[0] = true)
		var result := t.execute(attack)
		var output := String(result["output"])
		_check(not result["ok"] and not ran[0] and output.begins_with("Entrada rechazada") and t.history.is_empty(),
			"se rechaza sin ejecutar nada: %s" % attack.c_escape())
	var long := _full_terminal()
	_check(String(long.execute("ls " + "a".repeat(200))["output"]).contains("demasiado larga"), "una línea demasiado larga se rechaza")
	# Rutas: el sistema de archivos solo tiene los datos de la terminal; no hay nada «más allá».
	var t := _full_terminal()
	for path in ["/etc/passwd", "../../../../etc/shadow", "~/../../root", "~root", "/root/.ssh/id_rsa", "/proc/self/environ"]:
		_check(String(t.execute("cat " + path)["output"]).contains("No existe"), "no existe nada fuera de la terminal: %s" % path)
	_check(String(t.execute("cat C:/Windows/win.ini")["output"]).begins_with("Entrada rechazada"), "rutas de Windows: rechazadas (los : no se aceptan)")
	t.execute("cd /")
	_check(_out(t, "ls") == "home/" and _out(t, "ls /home") == "alvarado/", "en la raíz solo está el camino a los datos de la terminal")
	t.execute("cd ../../../..")
	_check(t.fs.cwd == "/", "cd .. no sale de la raíz de la terminal")


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
	window._line.text = "help"
	window._line.text_submitted.emit("help")
	_check(window._output.get_parsed_text().contains("Comandos disponibles"), "escribir un comando y pulsar Enter lo ejecuta")
	window._line.text = "pwd"
	window._line.text_submitted.emit("pwd")
	_check(window._output.get_parsed_text().contains("pwd: comando inejecutable"), "en esta terminal, pwd es inejecutable")
	_check(window._line.max_length == CommandInterpreter.MAX_LINE, "la línea no admite más de %d caracteres" % CommandInterpreter.MAX_LINE)
	var labels: Array = window._quick_row.get_children().map(func(b: Button) -> String: return b.text)
	_check(labels.has("ls") and labels.has("cd ..") and not labels.has("pwd") and not labels.has("ls -a"), "solo hay botones de los comandos permitidos (sin pwd ni ls -a)")
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
	_check(root.get_node("Economy").ecos == 0, "en la PC, la terminal no da Ecos (solo los da el villano)")
	_check(not state.has_learned_command(&"pwd") and state.has_learned_command(&"cd") and state.has_learned_command(&"cat"),
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


## Archivos ocultos y la carpeta protegida de la terminal del LAB 2 (H5).
func _test_hidden_and_password() -> void:
	var challenge: TerminalChallenge = load("res://data/terminals/puerta_lab2.tres")
	var t := challenge.create_interpreter()
	_check(t.prompt() == "invitado@lab2-puerta:~$" and _out(t, "ls").contains("LEEME.txt"), "LAB 2: sesión de invitado con LEEME.txt")
	t.execute("cd /home/alvarado")
	var listing := _out(t, "ls")
	_check(listing.contains("notas.txt") and not listing.contains(".puerta"), "ls no muestra los archivos ocultos (los que empiezan con punto)")
	var asked := t.execute("ls -a")
	_check(not asked["ok"] and asked["password"] and String(asked["output"]).contains("contraseña"), "ls -a en la carpeta protegida pide la contraseña")
	_check(t.pending_line == "ls -a", "recuerda qué comando pidió la contraseña")
	_check(t.execute("cd .puerta")["password"] and t.execute("cat .puerta/codigo.txt")["password"],
		"tampoco se entra ni se lee lo oculto sin la contraseña (aunque se adivine el nombre)")
	_check(not t.execute("ls -x")["ok"] and _out(t, "ls -x") == "ls -x: comando inejecutable", "una opción que no se necesita es inejecutable")
	_check(t.complete("cd .p") == "cd .p" and t.complete("cat no") == "cat notas.txt ", "Tab no completa lo oculto hasta que se da la contraseña")
	t.unlock()
	listing = _out(t, "ls -a")
	_check(listing.begins_with(".  ..") and listing.contains(".puerta/") and listing.contains("notas.txt"),
		"con la contraseña, ls -a muestra . .. y los ocultos")
	t.execute("cd .puerta")
	_check(t.fs.cwd == "/home/alvarado/.puerta" and challenge.is_goal(t, "cat", t.fs.resolve("codigo.txt")),
		"el objetivo es leer el código dentro de la carpeta oculta (ruta absoluta)")
	var correct := challenge.password_options.filter(func(o: ChoiceOption) -> bool: return o.correct)
	_check(challenge.password_options.size() == 3 and correct.size() == 1 and correct[0].text == "123456",
		"3 contraseñas para elegir; la correcta es la vieja del profe (123456)")
	_check(challenge.password_options.all(func(o: ChoiceOption) -> bool: return not o.feedback.is_empty()), "cada contraseña explica por qué sí o por qué no")
	_check(challenge.password_options.any(func(o: ChoiceOption) -> bool: return o.text.contains("••••")),
		"la contraseña nueva del jugador no se muestra (solo se guarda su huella)")
	var other := _full_terminal()
	_check(not _out(other, "ls -a").contains("password") and _out(other, "ls -a").begins_with(".  .."), "en una terminal sin carpetas protegidas, ls -a funciona directo")


func _new_terminal() -> CommandInterpreter:
	return (load(CHALLENGE) as TerminalChallenge).create_interpreter()


## Terminal de prueba con más archivos y todos los comandos (las del juego tienen solo lo de su misión).
func _full_terminal() -> CommandInterpreter:
	var files := { "cuenta/configuracion.txt": "usuario: alvarado\ncontraseña: 123456\n", "cuenta/foto_perfil.png": "(imagen)",
		"documentos/notas.txt": "notas", "imagenes/": "" }
	var t := CommandInterpreter.new(VirtualFileSystem.from_files(files, "/home/alvarado"))
	t.user = "alvarado"
	t.host = "pc-laboratorio"
	return t


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
