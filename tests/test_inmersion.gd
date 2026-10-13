extends SceneTree
## Prueba automática: Capítulo 1, etapa 2 (la transición de la Inmersión Digital). La conexión del
## monitor solo se ve y se usa con la Visión Digital; la primera vez hay diálogo, Kai atraviesa la
## pantalla, se desbloquea la habilidad para siempre y la transición dice «INMERSIÓN DIGITAL»; Kai se
## materializa del otro lado y la transición se cierra. La segunda vez no repite nada. La habilidad
## se guarda en la partida, la acepta el validador y aparece en «Mi perfil».
## Ejecutar: godot --headless --path . --script res://tests/test_inmersion.gd

const LAB := "res://world/zones/zone0/laboratorio.tscn"
const PC := "res://world/zones/pc_profesor/escritorio.tscn"
const PORTAL_AT := Vector2(600, 262)

var _failures := 0
var state: Node
var vision: Node


func _initialize() -> void:
	Engine.max_physics_steps_per_frame = 1
	Engine.physics_jitter_fix = 0.0
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	vision = root.get_node("DigitalVision")
	state.reset()
	state.unlock_vision()
	state.set_flag(&"tutorial_terminado")
	_check(not state.immersion_unlocked, "al empezar, Kai no tiene la Inmersión Digital")
	await _first_entry()
	await _second_entry()
	_test_save()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _first_entry() -> void:
	var portal := await _room_with_portal()
	var player := (current_scene as Room).player
	_check(not portal.enabled, "sin la Visión Digital, la conexión no se ve ni se usa")
	await _action(&"interact")
	await _frames(10)
	_check(current_scene.scene_file_path == LAB and not player.controls_locked, "con E y sin la Visión, Kai no entra")
	vision.activate(true)
	await _frames(3)
	_check(portal.enabled, "con la Visión Digital aparece la conexión en el monitor")
	var first := [false]
	portal.entered.connect(func(first_time: bool) -> void: first[0] = first_time)
	await _action(&"interact")
	var box := (current_scene as Room).get_node("CombatHUD/DialogueBox") as DialogueBox
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing(), "la primera vez hay una pequeña secuencia («Esta vez... voy yo»)")
	await _advance(box)
	await _until(func() -> bool: return not get_nodes_in_group(&"loading_screen").is_empty())
	var screen := get_first_node_in_group(&"loading_screen")
	_check(screen != null and String(screen.get("_title").text) == "INMERSIÓN DIGITAL", "la transición dice «INMERSIÓN DIGITAL»")
	_check(state.immersion_unlocked and first[0], "al atravesar el monitor se desbloquea la Inmersión Digital")
	await _until(func() -> bool: return current_scene != null and current_scene.scene_file_path == PC and current_scene.is_node_ready())
	await _until(func() -> bool: return get_nodes_in_group(&"loading_screen").is_empty() and not (current_scene as Room).player.controls_locked)
	_check(current_scene.scene_file_path == PC and get_nodes_in_group(&"loading_screen").is_empty(),
		"Kai se materializa del otro lado y la transición se cierra")
	_check(not (current_scene as Room).player.controls_locked, "y Kai se puede mover")


func _second_entry() -> void:
	vision.deactivate()
	var portal := await _room_with_portal()
	vision.activate(true)
	await _frames(3)
	var first := [true]
	portal.entered.connect(func(first_time: bool) -> void: first[0] = first_time)
	await _action(&"interact")
	var box := (current_scene as Room).get_node("CombatHUD/DialogueBox") as DialogueBox
	await _until(func() -> bool: return not get_nodes_in_group(&"loading_screen").is_empty())
	var screen := get_first_node_in_group(&"loading_screen")
	_check(not first[0] and not box.is_playing() and String(screen.get("_title").text) == "CONECTANDO...",
		"la segunda vez no repite la secuencia ni el título de la habilidad")
	await _until(func() -> bool: return current_scene != null and current_scene.scene_file_path == PC and get_nodes_in_group(&"loading_screen").is_empty())
	_check(current_scene.scene_file_path == PC, "y entra igual")
	vision.deactivate()


func _test_save() -> void:
	var data: Dictionary = state.to_dict()
	_check(data["player"]["immersion_unlocked"] == true, "la habilidad se guarda en la partida")
	state.reset()
	_check(not state.immersion_unlocked, "una partida nueva no la tiene")
	state.from_dict(JSON.parse_string(JSON.stringify(data)))
	_check(state.immersion_unlocked, "al cargar la partida sigue desbloqueada")
	var bad := data.duplicate(true)
	bad["player"]["immersion_unlocked"] = "si"
	_check(SaveValidator._state(data).is_empty() and not SaveValidator._state(bad).is_empty(),
		"el validador la acepta solo como verdadero o falso")
	_check(ProfileStats.abilities(data["player"]).has("Inmersión Digital"), "«Mi perfil» la muestra entre las habilidades")
	var page := load("res://data/grimorio/inmersion_digital.tres") as GrimorioEntry
	_check(page.is_unlocked(state), "y se abre su página del Grimorio")


## El laboratorio con una conexión de prueba en un monitor (en el juego irá en el cuarto técnico).
func _room_with_portal() -> ImmersionPortal:
	change_scene_to_file(LAB)
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == LAB and current_scene.is_node_ready())
	await _until(func() -> bool: return not root.get_node("SceneManager").is_changing())
	await _frames(4)
	var portal := ImmersionPortal.new()
	portal.target_scene = PC
	portal.target_entry = &"inicio"
	portal.first_dialogue = load("res://data/dialogues/capitulo1/inmersion_conexion.tres")
	portal.position = PORTAL_AT
	current_scene.add_child(portal)
	var player := (current_scene as Room).player
	player.teleport_to(Vector2(PORTAL_AT.x, 304))
	await _frames(6)
	return portal


func _advance(box: DialogueBox) -> void:
	for i in 40:
		if not box.is_playing():
			return
		await _action(&"interact")
		await _frames(3)


func _action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _until(condition: Callable) -> void:
	for i in 900:
		if condition.call():
			return
		await process_frame
		await physics_frame


func _frames(count: int) -> void:
	for i in count:
		await process_frame
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
