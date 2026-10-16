extends SceneTree
## Prueba automática: el patio y la soda del colegio (expansión de los capítulos 1 y 2; docs/mundo/COLEGIO.md).
## En el prólogo no se baja al patio (ni la escalera se ve, ni la sala se abre); desde el Capítulo 1 sí: el mapa
## une entrada ↔ patio ↔ soda en los dos sentidos; los objetos del patio se examinan; el tablón muestra los
## avisos del capítulo (no los del siguiente), los nuevos primero, y leerlos deja marca; la señora de la soda
## se presenta la primera vez y después dice lo de cada momento (antes de clase, durante el capítulo 1, en
## el capítulo 2); los objetos de la soda; guardar y cargar conserva lo leído y lo hablado; otra ranura no.
## Ejecutar: godot --headless --path . --script res://tests/test_patio_soda.gd

const Z := "res://world/zones/zone0/"
const Q := &"una_clase_diferente"

var _failures := 0
var state: Node
var room: Room
var world: Node
var _saved_step: StringName


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	world = root.get_node("World")
	root.get_node("SaveManager").new_game(1)
	DevPoints._advance(state, &"prologo", &"hablar_profesor")
	await _test_prologue()
	DevPoints._advance(state, Q, &"ir_a_clase")
	state.unlock_vision()
	state.set_nullblade_stage(1)
	_test_map()
	await _test_entrance()
	await _test_patio()
	await _test_notice_board()
	await _test_soda()
	await _test_back_to_patio()
	await _test_saved()
	await _test_chapter_2()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_prologue() -> void:
	await _open(Z + "entrada.tscn")
	var stairs := room.get_node("APatio") as Stairway
	await _frames(4)
	_check(ProgressTracker.chapter(state) == 0 and not stairs.visible and world.lock_reason(&"patio") != "",
		"en el prólogo no se baja al patio (la escalera no está y la sala sigue cerrada)")


func _test_map() -> void:
	_check(ProgressTracker.chapter(state) == 1 and world.lock_reason(&"patio") == "" and world.lock_reason(&"soda") == "",
		"en el Capítulo 1 el patio y la soda están abiertos")
	var pairs := [[&"entrada", &"patio", &"patio", &"desde_entrada"], [&"patio", &"entrada", &"entrada", &"desde_patio"],
		[&"patio", &"soda", &"soda", &"desde_patio"], [&"soda", &"patio", &"patio", &"desde_soda"]]
	for pair in pairs:
		var target: Dictionary = world.destination(pair[0], pair[1])
		_check(target.get("room") == pair[2] and target.get("entry") == pair[3] and ResourceLoader.exists(String(target.get("scene", ""))),
			"mapa: %s → %s llega a %s (%s)" % [pair[0], pair[1], pair[2], pair[3]])


func _test_entrance() -> void:
	await _open(Z + "entrada.tscn")
	var stairs := room.get_node("APatio") as Stairway
	await _frames(4)
	_check(stairs.visible and stairs.resolve().get("scene") == Z + "patio.tscn", "en la entrada aparece la escalera «PATIO»")
	stairs._on_interacted(room.player)
	await _arrive(Z + "patio.tscn")
	_check(room.player.global_position.distance_to(Vector2(1400, 304)) < 2.0, "Kai baja al patio (junto a la escalera de la entrada)")


func _test_patio() -> void:
	for path in ["Objetos/Mural", "Objetos/Almendro", "Objetos/Bebedero", "Objetos/Bandera"]:
		var item := room.get_node(path) as Examinable
		_check(item != null and not item.dialogues.is_empty(), "en el patio se puede examinar %s" % path.get_file())
	var flag := room.get_node("Objetos/Bandera") as Examinable
	room.player.teleport_to(Vector2(flag.global_position.x, 304))
	flag._on_interacted(room.player)
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	_check(_line(box).contains("acto cívico"), "la bandera: «%s»" % _line(box))
	await _advance(box)
	_check(room.get_node("Gente/Charla1").visible and room.get_node("Gente/Almendras").visible, "hay estudiantes en el recreo")


func _test_notice_board() -> void:
	var board := room.get_node("Objetos/Tablon") as NoticeBoard
	var ids := _ids(board.visible_announcements())
	_check(ids.size() == 5 and ids.has("robotica_pronto") and not ids.has("robotica_hoy"),
		"el tablón del Capítulo 1 tiene 5 avisos (la robótica, «pronto») %s" % [ids])
	var window := board.open()
	await _frames(3)
	var unread := 0
	for entry in window.entries:
		if String(entry["name"]).begins_with("● "):
			unread += 1
	_check(paused and unread == 5 and state.has_flag(&"anuncio_leido_reglamento_pasillos"),
		"con E se abre (el juego se pausa); todos son nuevos y el que se mira queda leído")
	window._buttons[2].grab_focus()
	await _frames(2)
	_check(state.has_flag(&"anuncio_leido_robotica_pronto") and not state.has_flag(&"anuncio_leido_feria_ciencias"), "leer otro también lo marca (solo ese)")
	_check(_hint(window).contains("E / Esc: seguir"),
		"la ayuda dice «E / Esc: seguir» (no «volver al cuarto»)")
	window.close()
	await _frames(2)
	_check(not paused, "al cerrar, el juego sigue")
	window = board.open()
	await _frames(3)
	_check(String(window.entries[0]["name"]).begins_with("● ") and not String(window.entries[4]["name"]).begins_with("● "),
		"al volver, los nuevos van primero y los leídos al final")
	window.close()
	await _frames(2)
	state.set_flag(&"capitulo_2")
	ids = _ids(board.visible_announcements())
	state.clear_flag(&"capitulo_2")
	_check(ids.has("robotica_hoy") and not ids.has("robotica_pronto"), "en el Capítulo 2 el aviso cambia a «Hoy: actividad de robótica»")


func _test_soda() -> void:
	room.player.teleport_to(Vector2(10, 304))
	await _arrive(Z + "soda.tscn")
	_check(room.player.global_position.distance_to(Vector2(580, 304)) < 2.0, "por la puerta de la izquierda se entra a la soda")
	var lady := room.get_node("Gente/SenoraSoda") as Npc
	var first := await _talk(lady)
	_check(first.contains("¿Qué le sirvo?") and state.has_flag(&"soda_presentada"), "la primera vez, la señora de la soda se presenta")
	var second := await _talk(lady)
	_check(second.contains("debería estar en clase"), "antes de la clase, lo manda a la Sala 3")
	state.complete_step(Q, &"ir_a_clase")
	var third := await _talk(lady)
	_check(third.contains("computadoras haciendo cosas raras"), "después de las fallas, comenta lo de las computadoras")
	for path in ["Objetos/Menu", "Objetos/Radio", "Objetos/Refri"]:
		var item := room.get_node(path) as Examinable
		_check(item != null and not item.dialogues.is_empty(), "en la soda se puede examinar %s" % path.get_file())


func _test_back_to_patio() -> void:
	room.player.teleport_to(Vector2(634, 304))
	await _arrive(Z + "patio.tscn")
	_check(room.player.global_position.distance_to(Vector2(70, 304)) < 2.0, "por la puerta de la derecha se vuelve al patio (junto a la soda)")
	_saved_step = state.get_current_step(Q)
	_check(root.get_node("SaveManager").save_game(Z + "patio.tscn", &"desde_soda"), "se guarda la partida en el patio")


func _test_saved() -> void:
	state.reset()
	root.get_node("SaveManager").load_slot(1)
	_check(state.has_flag(&"soda_presentada") and state.has_flag(&"anuncio_leido_reglamento_pasillos")
		and state.has_flag(&"anuncio_leido_robotica_pronto") and state.get_current_step(Q) == _saved_step,
		"al cargar, la partida recuerda la soda y los avisos leídos")


func _test_chapter_2() -> void:
	root.get_node("SaveManager").new_game(2)
	var chapter_2 := &"el_lenguaje_de_las_maquinas"
	DevPoints._advance(state, chapter_2, QuestDB.get_quest(chapter_2).steps[0].id)
	_check(not state.has_flag(&"soda_presentada") and not state.has_flag(&"anuncio_leido_reglamento_pasillos"),
		"otra ranura no comparte nada (ni la soda, ni los avisos)")
	await _open(Z + "soda.tscn")
	var lady := room.get_node("Gente/SenoraSoda") as Npc
	await _talk(lady)
	var later := await _talk(lady)
	_check(ProgressTracker.chapter(state) == 2 and later.contains("robótica"), "en el Capítulo 2 habla de la actividad de robótica")


func _talk(npc: Npc) -> String:
	room.player.teleport_to(Vector2(npc.global_position.x + 30, 304))
	await _frames(2)
	npc._on_interacted(room.player)
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	var text := _line(box)
	await _advance(box)
	await _frames(3)
	return text


func _ids(list: Array[Announcement]) -> PackedStringArray:
	var ids := PackedStringArray()
	for item in list:
		ids.append(String(item.id))
	return ids


func _hint(window: InspectionWindow) -> String:
	for label in window.find_children("*", "Label", true, false):
		if (label as Label).text.begins_with("↑↓"):
			return (label as Label).text
	return ""


func _line(box: DialogueBox) -> String:
	return box._text.text


func _open(path: String) -> void:
	change_scene_to_file(path)
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == path and current_scene.is_node_ready())
	await _frames(4)
	room = current_scene as Room


func _arrive(path: String) -> void:
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == path and current_scene.is_node_ready())
	await _frames(6)
	room = current_scene as Room


func _box() -> DialogueBox:
	return room.get_node("CombatHUD/DialogueBox") as DialogueBox


func _advance(box: DialogueBox) -> void:
	for i in 80:
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
