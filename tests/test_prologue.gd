extends SceneTree
## Prueba automática: el prólogo completo como misión (objetivo en pantalla, profesor,
## computadora del laboratorio con la Visión Digital involuntaria, título "EL DESPERTAR")
## y el comienzo de la misión de la contraseña del profesor. También misiones en GameState.
## Ejecutar: godot --headless --path . --script res://tests/test_prologue.gd

const MENU := "res://ui/menus/main_menu/main_menu.tscn"
const PASILLO := "res://world/zones/zone0/pasillo_laboratorio.tscn"
const NEAR_PROFESOR := Vector2(170, 304)
const COMPUTER := Vector2(716, 304)

var _failures := 0
var state: Node
var vision: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	vision = root.get_node("DigitalVision")
	_test_quest_api()

	change_scene_to_file(MENU)
	await _frames(20)
	current_scene.get_node("%PlayButton").pressed.emit()
	await _wait(1.2)
	_check(state.get_current_step(&"prologo") == &"hablar_profesor", "Jugar empieza el prólogo")
	var objective: Label = current_scene.get_node("CombatHUD/Objective")._text
	_check(objective.text == "Busca al profesor en el pasillo.", "el objetivo aparece en pantalla")

	change_scene_to_file(PASILLO)
	await _wait(0.5)
	var room := current_scene as Room
	var player := room.player
	var computer := room.get_node("LabComputer") as Interactable

	player.teleport_to(COMPUTER)
	await _frames(8)
	_check(not computer._prompt.visible, "la computadora no se puede usar antes de hablar con el profesor")

	player.teleport_to(NEAR_PROFESOR)
	await _frames(8)
	await _talk(room)
	_check(state.get_current_step(&"prologo") == &"revisar_computadora", "el profesor pide revisar la computadora")
	objective = room.get_node("CombatHUD/Objective")._text
	_check(objective.text == "Revisa la computadora del laboratorio.", "el objetivo cambia")

	await _test_involuntary_vision(room, player, computer)

	player.teleport_to(NEAR_PROFESOR)
	await _frames(8)
	await _talk(room)
	await _until(func() -> bool: return state.is_quest_completed(&"prologo"))
	_check(state.is_quest_completed(&"prologo"), "contarle al profesor completa el prólogo")
	var title := room.get_node("CombatHUD/TitleCard") as TitleCard
	_check(title.is_showing() and title._title.text == "EL DESPERTAR", "aparece el título «EL DESPERTAR»")
	_check(state.active_quest == &"contrasena_profesor" and state.get_current_step(&"contrasena_profesor") == &"entrar_pc",
		"empieza la misión «La contraseña del profesor»")
	_check(objective.text.contains("cuenta del profesor"), "el objetivo muestra la nueva misión")
	_check(not state.vision_unlocked, "Q sigue bloqueada hasta terminar la misión del profesor")
	player.teleport_to(COMPUTER)
	await _frames(8)
	_check(computer._prompt.visible and computer._prompt.text == "E: revisar la cuenta del profesor",
		"la computadora ahora sirve para revisar la cuenta del profesor")

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_quest_api() -> void:
	state.reset()
	_check(state.start_quest(&"prologo") and not state.start_quest(&"prologo"), "misiones: una misión no empieza dos veces")
	_check(not state.complete_step(&"prologo", &"volver_profesor"), "misiones: no se puede saltar pasos")
	_check(state.complete_step(&"prologo", &"hablar_profesor"), "misiones: se completa el paso actual")
	var saved := JSON.stringify(state.to_dict())
	state.reset()
	state.from_dict(JSON.parse_string(saved))
	_check(state.get_current_step(&"prologo") == &"revisar_computadora" and state.active_quest == &"prologo", "misiones: se guardan y cargan")
	_check(not state.start_quest(&"no_existe"), "misiones: una misión no registrada no empieza")
	state.reset()


func _test_involuntary_vision(room: Room, player: Player, computer: Interactable) -> void:
	player.teleport_to(COMPUTER)
	await _frames(8)
	_check(computer._prompt.visible and computer._prompt.text == "E: revisar la computadora", "junto a la computadora aparece «E: revisar la computadora»")
	_action("interact")
	await _frames(3)
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	var monitor := room.get_node("Lab/LabMonitor") as LabMonitor
	_check(player.controls_locked and not box.is_playing() and monitor.state != LabMonitor.State.OFF,
		"el monitor se enciende solo con interferencia antes del mensaje")
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing() and player.controls_locked, "la pantalla muestra su mensaje y Kai no se mueve")
	# Pasa la narración hasta que habla «???».
	for i in 10:
		if box.get_node("%Speaker").text == "???" and box.get_node("%NamePlate").visible:
			break
		_action("interact")
		await _frames(3)
	await _until(func() -> bool: return monitor.state == LabMonitor.State.EYE)
	_check(monitor.state == LabMonitor.State.EYE, "mientras habla «???» el monitor muestra el ojo")
	await _advance_dialogue(box)
	await _until(func() -> bool: return monitor.state == LabMonitor.State.OFF)
	_check(monitor.state == LabMonitor.State.OFF, "después del mensaje el monitor parpadea y se apaga")
	await _until(func() -> bool: return vision.is_active())
	await _until(func() -> bool: return vision.blend > 0.9)
	_check(vision.is_active() and vision.involuntary, "la Visión Digital se activa sola")
	_check(not state.vision_unlocked and not room.get_node("CombatHUD/VisionMeter").visible,
		"no se desbloquea ni aparece el indicador: es un glitch")
	_check(room.get_node("DigitalLayer/Network").visible, "durante el glitch se ve la red")
	_action("vision")
	await _frames(3)
	_check(vision.is_active(), "Q no la apaga: Kai todavía no la controla")
	await _until(func() -> bool: return not vision.is_active())
	_check(not vision.is_active() and vision.state == vision.State.READY and vision.cooldown_left == 0.0,
		"se apaga sola y no deja recarga")
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing() and box.get_node("%Speaker").text == "Kai", "Kai reacciona a lo que vio")
	_check(monitor.state == LabMonitor.State.IDLE, "el monitor vuelve a la pantalla normal")
	await _advance_dialogue(box)
	await _frames(5)
	_check(state.get_current_step(&"prologo") == &"volver_profesor" and not player.controls_locked,
		"la misión avanza: contarle al profesor")


## Espera (en cuadros de física) a que se cumpla la condición, hasta unos 10 s de juego.
func _until(condition: Callable) -> void:
	for i in 600:
		if condition.call():
			return
		await physics_frame


func _talk(room: Room) -> void:
	_action("interact")
	await _frames(3)
	await _advance_dialogue(room.get_node("CombatHUD/DialogueBox"))
	await _frames(5)


func _advance_dialogue(box: DialogueBox) -> void:
	for i in 40:
		if not box.is_playing():
			return
		_action("interact")
		await _frames(3)


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
		await physics_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
