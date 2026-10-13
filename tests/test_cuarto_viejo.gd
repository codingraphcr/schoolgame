extends SceneTree
## Prueba automática: H5, el cuarto viejo. Al asegurar la cuenta del profesor empieza la misión
## «El cuarto viejo»; el profesor invita a Kai al pasillo viejo y, si se le vuelve a hablar, solo
## recuerda dónde queda. La puerta del fondo del Laboratorio está cerrada hasta la invitación; el
## pasillo viejo tiene una nota que solo se ve con la Visión Digital. (Las tareas siguientes de H5
## suman sus comprobaciones aquí.)
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
