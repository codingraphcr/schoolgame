extends SceneTree
## Prueba automática: la actividad opcional «Un recreo diferente» (expansión del Capítulo 1; docs/mundo/COLEGIO.md).
## El amigo de Kai está en la soda solo mientras el profesor prepara el acceso; con E charlan; Kai elige qué decirle
## (tres opciones, ninguna incorrecta; la ventana pausa el juego y Esc no la cierra); cada opción tiene su respuesta;
## al terminar se completa la misión secundaria sin cambiar el objetivo de la historia y queda marcada la opción;
## después el amigo solo se despide; guardar y cargar conserva la elección; otra ranura no; el amigo espera en la
## soda hasta el Capítulo 3.
## Ejecutar: godot --headless --path . --script res://tests/test_recreo.gd

const Z := "res://world/zones/zone0/"
const Q1 := &"una_clase_diferente"
const Q := &"un_recreo_diferente"

var _failures := 0
var state: Node
var room: Room


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	root.get_node("SaveManager").new_game(1)
	DevPoints._advance(state, Q1, &"pedir_permiso")
	state.unlock_vision()
	state.set_nullblade_stage(1)
	await _open(Z + "soda.tscn")
	_check(not _friend().visible, "antes de pedir permiso, el amigo no está en la soda")
	DevPoints._advance(state, Q1, &"buscar_huellas")
	await _open(Z + "soda.tscn")
	await _test_chat()
	await _test_repeat()
	await _test_saved()
	await _test_later()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_chat() -> void:
	var friend := _friend()
	var chat := friend.get_node("Recreo") as RecessChat
	_check(friend.visible and not chat.is_done() and chat.chosen_option() == -1, "mientras el profe prepara el acceso, el amigo está en la soda")
	room.player.teleport_to(Vector2(friend.global_position.x - 20, 304))
	await _frames(3)
	chat._on_interacted(room.player)
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	_check(_line(box).contains("Te guardé campo"), "el amigo lo invita a sentarse: «%s»" % _line(box))
	await _advance(box)
	await _until(func() -> bool: return get_first_node_in_group(&"dialogue_choice") != null)
	var choice := get_first_node_in_group(&"dialogue_choice") as DialogueChoice
	_check(choice != null and paused and choice.buttons.size() == 3, "Kai elige qué contarle (tres opciones; el juego se pausa)")
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	Input.parse_input_event(esc)
	await _frames(2)
	_check(is_instance_valid(choice) and choice.is_inside_tree(), "Esc no cierra la elección: hay que elegir")
	choice.choose(2)
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	_check(not paused and _line(box).contains("robótica"), "cada opción lleva a otra charla (robótica)")
	await _advance(box)
	await _until(func() -> bool: return box.is_playing() or chat.is_done())
	await _advance(box)
	await _until(func() -> bool: return chat.is_done())
	var quest := QuestDB.get_quest(Q)
	_check(chat.is_done() and quest.category == Quest.Category.SECUNDARIA and quest.ecos_reward == 0 and state.has_flag(&"recreo_eleccion_2")
		and chat.chosen_option() == 2, "al terminar, la actividad queda completada y se recuerda lo elegido")
	_check(state.get_current_step(Q1) == &"buscar_huellas" and state.active_quest == Q1, "no cambia el objetivo de la historia")


func _test_repeat() -> void:
	var chat := _friend().get_node("Recreo") as RecessChat
	await _frames(4)
	chat._on_interacted(room.player)
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	var line := _line(box)
	await _advance(box)
	await _frames(4)
	_check(line.contains("Nos vemos") and get_first_node_in_group(&"dialogue_choice") == null and chat.chosen_option() == 2,
		"después solo se despide (no hay que volver a elegir)")


func _test_saved() -> void:
	var saves := root.get_node("SaveManager")
	_check(saves.save_game(Z + "soda.tscn", &"desde_patio"), "se guarda la partida")
	state.reset()
	saves.load_slot(1)
	_check(state.is_quest_completed(Q) and state.has_flag(&"recreo_eleccion_2"), "al cargar, la elección sigue ahí")


func _test_later() -> void:
	DevPoints._advance(state, &"travesuras_en_el_sistema", &"revisar_servidor")
	await _open(Z + "soda.tscn")
	_check(_friend().visible, "el amigo sigue en la soda después (la charla se puede hacer hasta el Capítulo 3)")
	state.set_flag(&"capitulo_3")
	await _open(Z + "soda.tscn")
	_check(not _friend().visible, "en el Capítulo 3 ya no está (pasaron unas semanas)")
	root.get_node("SaveManager").new_game(2)
	_check(not state.is_quest_completed(Q) and not state.has_flag(&"recreo_eleccion_2"), "otra ranura no comparte la charla")


func _friend() -> Node2D:
	return room.get_node("Gente/Amigo") as Node2D


func _box() -> DialogueBox:
	return room.get_node("CombatHUD/DialogueBox") as DialogueBox


func _line(box: DialogueBox) -> String:
	return box._text.text


func _advance(box: DialogueBox) -> void:
	for i in 80:
		if not box.is_playing():
			return
		await _action(&"interact")
		await _frames(3)


func _open(path: String) -> void:
	change_scene_to_file(path)
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == path and current_scene.is_node_ready())
	await _frames(4)
	room = current_scene as Room


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
	for i in 2400:
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
