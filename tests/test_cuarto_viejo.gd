extends SceneTree
## Prueba automática: H5, el cuarto viejo. Al asegurar la cuenta del profesor empieza la misión
## «El cuarto viejo»; el profesor invita a Kai al pasillo viejo y, si se le vuelve a hablar, solo
## recuerda dónde queda. La puerta del fondo del Laboratorio está cerrada hasta la invitación; el
## pasillo viejo tiene una nota que solo se ve con la Visión Digital, y la terminal de la puerta pide
## la contraseña vieja del profe para ver los archivos ocultos. El cuarto viejo está a oscuras: con la
## Visión se ven la Nullblade (dash) y el Grimorio (desde entonces G lo abre); con las dos
## el piso se corrompe y cae un armario; al salir, «EL DESPERTAR», el Capítulo 1 y fin del tutorial.
## Ejecutar: godot --headless --path . --script res://tests/test_cuarto_viejo.gd

const PASILLO := "res://world/zones/zone0/pasillo.tscn"
const LAB := "res://world/zones/zone0/laboratorio.tscn"
const FLOOR_Y := 304.0
const NEAR_PROFESOR := Vector2(170, 304)
const QUEST := &"cuarto_viejo"

var _failures := 0
var state: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	GameSettings.text_speed = 1
	_test_quest_chain()
	await _test_locked_door()
	await _test_invitation()
	await _test_old_hallway()
	await _test_door_terminal()
	await _test_old_room()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


## Kai llega al final de la misión del profesor (como en el juego, paso a paso).
func _finish_password_quest() -> void:
	state.reset()
	state.start_quest(&"prologo")
	for step in [&"hablar_profesor", &"revisar_computadora", &"volver_profesor"]:
		state.complete_step(&"prologo", step)
	for step in [&"entrar_pc", &"cruzar_spam", &"revisar_configuracion", &"cambiar_contrasena", &"elegir_seguridad"]:
		state.complete_step(&"contrasena_profesor", step)
	state.unlock_vision()  # Lo hace la seguridad de la cuenta (H4d).


func _test_quest_chain() -> void:
	_finish_password_quest()
	_check(state.is_quest_completed(&"contrasena_profesor"), "la misión de la contraseña queda completa")
	_check(state.active_quest == QUEST and state.get_current_step(QUEST) == &"hablar_profesor",
		"empieza «El cuarto viejo»: hablar con el profesor")
	var quest := QuestDB.get_quest(QUEST)
	_check(quest != null and quest.steps.size() == 5 and quest.steps.all(func(s: QuestStep) -> bool: return not s.objective.is_empty()),
		"la misión tiene sus 5 pasos con su objetivo")


func _test_invitation() -> void:
	_finish_password_quest()
	change_scene_to_file(PASILLO)
	await _wait(0.6)
	var room := current_scene as Room
	var objective: Label = room.get_node("CombatHUD/Objective")._text
	_check(objective.text == "Habla con el profesor en el pasillo.", "el objetivo pide hablar con el profesor")
	room.player.teleport_to(NEAR_PROFESOR)
	await _frames(8)
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	_action("interact")
	await _frames(3)
	_check(box.is_playing() and box.get_node("%Speaker").text == "Prof. Alvarado", "el profesor habla")
	var heard := ""
	for i in 40:
		if not box.is_playing():
			break
		heard += (box.get_node("%Text") as Label).text + " "
		_action("interact")
		await _frames(3)
	_check(heard.contains("pasillo viejo"), "invita a Kai al pasillo viejo")
	await _frames(5)
	_check(state.get_current_step(QUEST) == &"ir_pasillo_viejo", "la misión avanza: buscar el pasillo viejo")
	_check(objective.text.contains("pasillo viejo"), "el objetivo cambia")
	_action("interact")
	await _frames(3)
	_check(box.is_playing() and (box.get_node("%Text") as Label).text.contains("al fondo del laboratorio"),
		"la segunda vez solo recuerda dónde queda")
	for i in 20:
		if not box.is_playing():
			break
		_action("interact")
		await _frames(3)
	_check(state.get_current_step(QUEST) == &"ir_pasillo_viejo", "repetir la charla no adelanta la misión")


## Antes de la invitación, la puerta del fondo del Laboratorio no se abre.
func _test_locked_door() -> void:
	_finish_password_quest()
	change_scene_to_file(LAB)
	await _wait(0.6)
	var room := current_scene as Room
	room.player.teleport_to(Vector2(640, FLOOR_Y))
	await _frames(4)
	Input.action_press("move_right")
	await _wait(1.2)
	Input.action_release("move_right")
	_check(current_scene == room and room.player.global_position.x > 690.0, "antes de la invitación, la puerta del fondo no se abre")
	_check(room.get_node("CombatHUD/Toast").text.contains("cerrada"), "avisa que está cerrada con llave")


## Después de la invitación: el pasillo viejo, su llegada y la nota de la Visión Digital.
func _test_old_hallway() -> void:
	change_scene_to_file(LAB)
	await _wait(0.6)
	var room := current_scene as Room
	room.player.teleport_to(Vector2(640, FLOOR_Y))
	await _frames(4)
	Input.action_press("move_right")
	await _until(func() -> bool: return current_scene != null and current_scene.name == "PasilloViejo")
	Input.action_release("move_right")
	await _wait(0.8)
	room = current_scene as Room
	_check(room != null and room.name == "PasilloViejo" and root.get_node("World").current_room == &"pasillo_viejo",
		"con la invitación, la puerta lleva al pasillo viejo")
	if room == null or room.name != "PasilloViejo":
		return
	_check(absf(room.player.global_position.x - 40.0) < 16.0, "Kai entra por la izquierda")
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing() and room.player.controls_locked, "al llegar, Kai comenta dónde está")
	for i in 20:
		if not box.is_playing():
			break
		_action("interact")
		await _frames(3)
	await _frames(5)
	_check(state.get_current_step(QUEST) == &"abrir_puerta" and not room.player.controls_locked,
		"la misión avanza: descubrir cómo abrir la puerta")
	var note := room.get_node("DigitalLayer/VisionNote") as Node2D
	_check(not note.visible, "la nota no se ve a simple vista")
	_check(state.vision_unlocked, "Kai ya tiene la Visión Digital")
	_action("vision")
	await _until(func() -> bool: return note.visible)
	_check(note.visible, "con la Visión Digital aparece la nota con la pista")
	_check(Array(note.lines).has("> ls -a"), "la pista nombra el comando sin resolver el desafío")
	room.player.teleport_to(Vector2(60, FLOOR_Y))
	Input.action_press("move_left")
	await _until(func() -> bool: return current_scene != null and current_scene.name == "Laboratorio")
	Input.action_release("move_left")
	await _wait(0.8)
	room = current_scene as Room
	_check(room != null and room.name == "Laboratorio" and absf(room.player.global_position.x - 680.0) < 16.0,
		"la salida izquierda vuelve al fondo del laboratorio")


## La terminal de la puerta: ls -a pide la contraseña; las incorrectas explican por qué; la vieja abre.
func _test_door_terminal() -> void:
	change_scene_to_file("res://world/zones/zone0/pasillo_viejo.tscn")
	await _wait(0.6)
	var room := current_scene as Room
	var station := room.get_node("DoorTerminal") as TerminalStation
	var props := room.get_node("Props")
	_check(state.get_current_step(QUEST) == &"abrir_puerta" and station.is_usable(), "la terminal de la puerta se puede usar")
	_check(not props.is_door_open(), "la puerta del LAB 2 sigue cerrada")
	room.player.teleport_to(station.global_position + Vector2(-10, 0))
	await _frames(8)
	_action("interact")
	await _until(func() -> bool: return get_first_node_in_group(&"terminal_window") != null)
	var window := get_first_node_in_group(&"terminal_window") as TerminalWindow
	_check(window != null, "con E se abre la terminal")
	if window == null:
		return
	window.submit("cd /home/alvarado")
	window.submit("ls -a")
	_check(window.is_asking_password(), "ls -a pide la contraseña con las opciones")
	var text := (window._output as RichTextLabel).get_parsed_text()
	window.choose_password(0)
	text = (window._output as RichTextLabel).get_parsed_text()
	_check(not window.is_asking_password() and not window.interpreter.unlocked and text.contains("nunca se enteró"),
		"la contraseña nueva no sirve aquí y explica por qué")
	window.submit("ls -a")
	window.choose_password(2)
	_check(not window.interpreter.unlocked and (window._output as RichTextLabel).get_parsed_text().contains("nombre"),
		"«PAlvarado» tampoco, y explica por qué")
	window.submit("ls -a")
	window.choose_password(1)
	text = (window._output as RichTextLabel).get_parsed_text()
	_check(window.interpreter.unlocked and text.contains("Acceso concedido") and text.contains(".puerta/"),
		"123456 abre la carpeta y se repite ls -a: aparece .puerta/")
	window.submit("cd .puerta")
	window.submit("cat codigo.txt")
	_check(window.is_solved, "leer el código cumple el objetivo")
	_check(state.has_learned_command(&"ls -a") and (load("res://data/grimorio/comando_ls_a.tres") as GrimorioEntry).is_unlocked(state),
		"ls -a queda aprendido, con su página del Grimorio")
	window.close()
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing(), "Kai comenta que la puerta se abrió")
	for i in 20:
		if not box.is_playing():
			break
		_action("interact")
		await _frames(3)
	await _frames(5)
	_check(state.get_current_step(QUEST) == &"explorar_cuarto", "la misión avanza: explorar el cuarto viejo")
	_check(props.is_door_open(), "la puerta del LAB 2 queda entreabierta")


## El cuarto viejo: oscuridad, las dos reliquias con la Visión, el derrumbe y la salida.
func _test_old_room() -> void:
	var hall := current_scene as Room
	hall.player.teleport_to(Vector2(900, FLOOR_Y))
	await _frames(4)
	Input.action_press("move_right")
	await _until(func() -> bool: return current_scene != null and current_scene.name == "CuartoViejo")
	Input.action_release("move_right")
	await _wait(0.8)
	var room := current_scene as Room
	_check(room != null and room.name == "CuartoViejo" and root.get_node("World").current_room == &"cuarto_viejo",
		"la puerta abierta del LAB 2 lleva al cuarto viejo")
	if room == null or room.name != "CuartoViejo":
		return
	var player := room.player
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing(), "al entrar, Kai comenta que no se ve nada")
	await _advance(box)
	var vision := root.get_node("DigitalVision")
	await _vision_off(vision)
	var grimorio := room.get_node("Grimorio") as HiddenRelic
	var blade := room.get_node("Nullblade") as HiddenRelic
	player.teleport_to(grimorio.global_position + Vector2(-8, 0))
	await _frames(6)
	_check(not grimorio._can_interact(), "a oscuras no se puede tomar nada: no se ve")
	_action("grimorio")
	await _frames(3)
	_check(root.get_node_or_null("GrimorioLayer") == null, "todavía no hay Grimorio: G no hace nada")
	await _vision_on(vision)
	_check(grimorio._can_interact() and grimorio._canvas.visible, "con la Visión Digital aparece el libro y se puede tomar")
	_action("interact")
	await _until(func() -> bool: return box.is_playing())
	_check(state.has_grimorio(), "Kai toma el Grimorio")
	await _advance(box)
	await _frames(4)
	_check(state.get_current_step(QUEST) == &"explorar_cuarto", "falta la espada: la misión no avanza")
	await _vision_on(vision)
	player.teleport_to(blade.global_position + Vector2(-8, 0))
	await _frames(6)
	_check(blade._can_interact(), "con la Visión se distingue la espada")
	_action("interact")
	await _until(func() -> bool: return root.get_node_or_null("EquipmentCardLayer") != null)
	_check(root.get_node_or_null("EquipmentCardLayer") != null, "la Nullblade oficial se materializa y aparece su tarjeta")
	for i in 30:
		if root.get_node_or_null("EquipmentCardLayer") == null:
			break
		await _wait(0.3)
		_action("interact")
	await _until(func() -> bool: return box.is_playing())
	_check(state.nullblade_stage == 1 and player.combat.weapon != null, "la Nullblade queda equipada para siempre")
	_check(state.dash_level >= 1 and player.dash_level >= 1 and not state.can_double_jump and not player.can_double_jump,
		"con ella, Kai obtiene el dash (el doble salto se consigue más adelante)")
	await _advance(box)
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing(), "con las dos, el cuarto se derrumba y Kai lo nota")
	await _advance(box)
	await _frames(5)
	_check(state.get_current_step(QUEST) == &"salir_cuarto", "la misión avanza: salir del cuarto viejo")
	var spikes := room.get_node("CorruptFloor") as Spikes
	var cabinet := room.get_node("FallenCabinet") as StaticBody2D
	_check(spikes.visible and spikes.monitorable and cabinet.visible and not (cabinet.get_node("Shape") as CollisionShape2D).disabled,
		"aparecen el piso corrupto y el armario caído")
	# El armario caído (52 px) se salta con un salto simple.
	player.teleport_to(Vector2(400, FLOOR_Y))
	await _frames(6)
	Input.action_press("move_left")
	Input.action_press("jump")
	await _wait(0.5)
	Input.action_release("jump")
	# Puede caer encima del armario: sigue caminando hasta bajar del otro lado.
	await _until(func() -> bool: return player.is_on_floor() and player.global_position.x < 306.0 and player.global_position.y > 300.0)
	Input.action_release("move_left")
	await _frames(2)
	_check(player.global_position.x < 314.0 and player.global_position.x > 262.0,
		"con un salto simple se pasa el armario caído (x=%.0f)" % player.global_position.x)
	# El piso corrupto (100 px): con un salto simple no se cruza; con salto + dash sí.
	var hits := [0]
	player.damage.hurt.connect(func(_hit: HitData) -> void: hits[0] += 1)
	player.teleport_to(Vector2(258, FLOOR_Y))
	await _frames(6)
	Input.action_press("move_left")
	Input.action_press("jump")
	await _wait(0.3)
	Input.action_release("jump")
	await _until(func() -> bool: return hits[0] > 0 or (player.is_on_floor() and player.global_position.x < 150.0))
	Input.action_release("move_left")
	_check(hits[0] > 0, "con un salto simple se cae en el piso corrupto")
	await _until(func() -> bool: return not player.damage.is_respawning and not player.is_invulnerable())
	player.teleport_to(Vector2(258, FLOOR_Y))
	await _frames(6)
	hits[0] = 0
	Input.action_press("move_left")
	Input.action_press("jump")
	await _wait(0.25)
	Input.action_press("dash")
	await _frames(2)
	Input.action_release("dash")
	await _wait(0.2)
	Input.action_release("jump")
	await _until(func() -> bool: return player.is_on_floor())
	Input.action_release("move_left")
	_check(hits[0] == 0 and player.global_position.x < 150.0, "con salto + dash se cruza el piso corrupto (x=%.0f)" % player.global_position.x)
	# A la salida (los pinchos los prueba test_player_health: devuelven al suelo seguro).
	player.teleport_to(Vector2(60, FLOOR_Y))
	await _frames(4)
	Input.action_press("move_left")
	await _until(func() -> bool: return current_scene != null and current_scene.name == "PasilloViejo")
	Input.action_release("move_left")
	await _wait(0.8)
	var hall_again := current_scene as Room
	box = hall_again.get_node("CombatHUD/DialogueBox") as DialogueBox
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing(), "al salir, Kai se pregunta qué le está pasando")
	await _advance(box)
	await _frames(5)
	_check(state.is_quest_completed(QUEST), "la misión «El cuarto viejo» se completa")
	_check(state.has_flag(&"tutorial_terminado"), "termina el tutorial: desde ahora morir cuesta Ecos")
	var title := hall_again.get_node("CombatHUD/TitleCard") as TitleCard
	_check(title.is_showing() and title._title.text == "EL DESPERTAR", "aparece «EL DESPERTAR»")
	await _until(func() -> bool: return title._title.text == "CAPÍTULO 1")
	_check(title._title.text == "CAPÍTULO 1" and title._subtitle.text == "EL ORIGEN DIGITAL", "y después «CAPÍTULO 1 · EL ORIGEN DIGITAL»")
	_action("grimorio")
	await _frames(3)
	_check(root.get_node_or_null("GrimorioLayer") != null, "con el Grimorio encontrado, G lo abre")
	_action("grimorio")
	await _frames(3)


func _vision_on(vision: Node) -> void:
	if vision.is_active():
		return
	# La prueba anterior pudo dejarla recargando: se deja lista (en el juego, se espera la recarga).
	vision.reset()
	await _frames(2)
	_action("vision")
	await _until(func() -> bool: return vision.is_active())
	await _frames(4)


func _vision_off(vision: Node) -> void:
	if vision.is_active():
		_action("vision")
		await _until(func() -> bool: return not vision.is_active())
	await _frames(4)


func _advance(box: DialogueBox) -> void:
	for i in 40:
		if not box.is_playing():
			return
		_action("interact")
		await _frames(3)


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
