extends SceneTree
## Prueba automática: el hogar de Kai (Capítulo 1, misión «Camino a casa»; docs/escenarios/HOGAR_DE_KAI.md).
## Al vencer a Chip y Glitch empieza «Camino a casa» (el «CAPÍTULO 2» espera a la mañana); los amigos en la
## entrada; la salida a la calle se abre recién entonces; la calle (comentario, perro, tarde); la casa (los
## papás en su rutina, la charla familiar en dos partes, «Más tarde...» y la noche); el cuarto (estantería
## de recuerdos con lo que Kai tiene, recuerdos que cambian con los años, vitrina de fragmentos con «???»,
## soporte de la Nullblade con las formas bloqueadas sin quitarle la espada, la computadora con sus
## mensajes, ventanas que pausan el juego); la cama (pregunta, «no» no hace nada, fuera de momento no
## deja); la charla a solas de los papás; la Resonancia Digital; la mañana («CAPÍTULO 2», el capítulo 2
## empieza, guardado en la cama con todo lleno); la casa de mañana; cargar la partida conserva todo; otra
## ranura no comparte nada.
## Ejecutar: godot --headless --path . --script res://tests/test_hogar.gd

const Z := "res://world/zones/zone0/"
const B := "res://world/zones/barrio/"
const Q := &"camino_a_casa"

var _failures := 0
var state: Node
var room: Room


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	root.get_node("SaveManager").new_game(1)
	DevPoints._advance(state, &"travesuras_en_el_sistema", &"hablar_profesor")
	state.unlock_vision()
	state.unlock_immersion()
	state.set_nullblade_stage(1)
	state.set_dash_level(1)
	state.set_flag(GameState.GRIMORIO_FLAG)
	_test_chain()
	await _test_entrance()
	await _test_street()
	await _test_family()
	await _test_bedroom()
	await _test_night()
	await _test_morning()
	await _test_saved()
	await _test_other_slot()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_chain() -> void:
	state.set_flag(&"cap1_fragmento_leido")  # Lo deja el cierre del combate.
	state.complete_step(&"travesuras_en_el_sistema", &"hablar_profesor")
	var chip_glitch := QuestDB.get_quest(&"travesuras_en_el_sistema")
	_check(state.is_quest_completed(&"travesuras_en_el_sistema") and state.has_flag(&"capitulo_1_completado"),
		"Chip y Glitch terminan su misión («FIN DEL CAPÍTULO 1»)")
	_check(chip_glitch.followup_title.is_empty() and state.get_current_step(Q) == &"charla_amigos",
		"empieza «Camino a casa» (el «CAPÍTULO 2» espera al día siguiente)")
	_check(ProgressTracker.chapter(state) == 1 and DayPhase.current(state) == DayPhase.Phase.TARDE, "sigue siendo el Capítulo 1, de tarde")


func _test_entrance() -> void:
	await _open(Z + "entrada.tscn")
	var exit := room.get_node("Exits/ToCalle") as RoomExit
	var friend := room.get_node("Gente/AmigaSalida") as Node2D
	await _frames(4)
	_check(friend.visible and not exit.is_open(), "en la entrada esperan los amigos; todavía no se sale a la calle")
	room.player.teleport_to(Vector2(640, 304))
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing(), "los amigos comentan lo que pasó")
	await _advance(box)
	await _until(func() -> bool: return state.get_current_step(Q) == &"volver_a_casa")
	_check(state.get_current_step(Q) == &"volver_a_casa" and state.get_objective_text() == "Regresá a casa.", "objetivo: «Regresá a casa.»")
	_check(exit.is_open(), "ahora se abre la salida a la calle")
	room.player.teleport_to(Vector2(10, 304))
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == B + "calle.tscn" and current_scene.is_node_ready())
	await _frames(6)
	room = current_scene as Room
	_check(room.scene_file_path == B + "calle.tscn" and room.player.global_position.distance_to(Vector2(40, 304)) < 2.0,
		"Kai sale del colegio a la calle del barrio")


func _test_street() -> void:
	var box := _box()
	room.player.teleport_to(Vector2(140, 304))
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing() and state.has_flag(&"cap1_calle_comentario"), "al salir, Kai comenta algo (una sola vez)")
	await _advance(box)
	_check((room.get_node("Luz") as CanvasModulate).color.is_equal_approx(DayPhase.ambient(DayPhase.Phase.TARDE)) or DayPhase.current(state) == DayPhase.Phase.TARDE,
		"luz de tarde en el barrio")
	var dog := room.get_node("Gente/Canelo/Acariciar") as Examinable
	room.player.teleport_to(dog.global_position)
	await _frames(6)
	await _action(&"interact")
	await _until(func() -> bool: return box.is_playing())
	_check(box.is_playing(), "se puede acariciar al perro del barrio (opcional)")
	await _advance(box)
	_check(state.get_current_step(Q) == &"volver_a_casa", "nada de eso es obligatorio: la misión sigue igual")
	room.player.teleport_to(Vector2(1794, 304))
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == B + "casa.tscn" and current_scene.is_node_ready())
	await _frames(8)
	room = current_scene as Room
	_check(state.get_current_step(Q) == &"hablar_familia", "Kai llega a su casa («Saludá a tu familia»)")


func _test_family() -> void:
	var mom := room.get_node("Familia/Mama") as FamilyMember
	var dad := room.get_node("Familia/Papa") as FamilyMember
	_check(absf(mom.position.x - 830.0) < 1.0 and mom.chore == &"cocinar" and absf(dad.position.x - 330.0) < 1.0,
		"de tarde, mamá cocina y papá lee en la sala")
	var box := _box()
	room.player.teleport_to(Vector2(270, 304))
	await _until(func() -> bool: return box.is_playing())
	_check(room.player.controls_locked and absf(mom.position.x - 270.0) < 90.0, "al entrar a la sala, mamá viene a hablar con Kai")
	_check(_line(box).contains("Ya estaba empezando a preocuparme"), "«¡Kai! Ya estaba empezando a preocuparme...»")
	var lines_seen := PackedStringArray()
	for i in 80:
		if state.get_current_step(Q) == &"descansar":
			break
		if box.is_playing():
			lines_seen.append(_line(box))
			await _action(&"interact")
		await _frames(3)
	var all := "\n".join(lines_seen)
	_check(all.contains("Kai, vení. Quiero decirte algo") and all.contains("mayor será tu responsabilidad de hacer lo correcto"),
		"papá se acerca: «...mayor será tu responsabilidad de hacer lo correcto»")
	_check(not all.contains("Génesis") and not all.contains("sintétic") and not all.contains("experimento"), "no se revela nada del origen de Kai")
	await _until(func() -> bool: return not room.player.controls_locked)
	_check(state.get_current_step(Q) == &"descansar" and state.has_flag(HomeStory.FAMILY_FLAG) and DayPhase.current(state) == DayPhase.Phase.NOCHE,
		"«Más tarde, después de la cena...»: es de noche («Descansá en tu cuarto»)")
	_check(absf(mom.position.x - 612.0) < 1.0 and absf(dad.position.x - 392.0) < 1.0, "de noche, mamá en el comedor y papá viendo la tele")
	room.player.teleport_to(dad.global_position + Vector2(-20, 0))
	await _frames(6)
	await _action(&"interact")
	await _until(func() -> bool: return box.is_playing())
	_check(_line(box).contains("Mañana tenés clase temprano"), "papá tiene su frase de la noche (no repite la charla)")
	await _advance(box)
	room.player.teleport_to(Vector2(1034, 304))
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == B + "cuarto_kai.tscn" and current_scene.is_node_ready())
	await _frames(8)
	room = current_scene as Room


func _test_bedroom() -> void:
	var shelf := room.get_node("Cuarto/EstanteriaRecuerdos") as KeepsakeShelf
	var shown := PackedStringArray()
	for item in shelf.displayed():
		shown.append(String(item.id))
	_check(shown.has("robot_juguete") and shown.has("foto_familia") and shown.has("dibujo_hermanos") and not shown.has("pulsera_amistad")
		and not shown.has("reloj_papa"), "la estantería muestra lo que Kai tiene (y el dibujo de Chip y Glitch nuevo) %s" % [shown])
	var window := shelf.inspect()
	await _frames(3)
	_check(paused and window.entries.size() == shown.size(), "con E se abre la estantería: el juego se pausa (Kai no se mueve)")
	window.select(0)
	_check(window.entries[0]["name"] == "Robot de juguete" and String(window.entries[0]["note"]).begins_with("Mi papá me ayudó a repararlo"),
		"el robot: nombre, descripción y lo que recuerda Kai")
	window.close()
	await _frames(2)
	_check(not paused, "al volver, el juego sigue")
	var robot := HomeCollection.get_item(&"robot_juguete")
	state.set_flag(&"capitulo_5")
	var eleventh := robot.note_for(state)
	state.set_flag(&"capitulo_9")
	var twelfth := robot.note_for(state)
	state.clear_flag(&"capitulo_5")
	state.clear_flag(&"capitulo_9")
	_check(eleventh.begins_with("A veces me pregunto") and twelfth.begins_with("Durante mucho tiempo pensé"),
		"el mismo robot dice otra cosa en undécimo y en duodécimo (datos, no código)")
	var vitrine := room.get_node("Cuarto/VitrinaFragmentos") as KeepsakeShelf
	var fragments := vitrine.inspect()
	await _frames(2)
	var locked := 0
	for entry in fragments.entries:
		if entry["locked"]:
			locked += 1
	_check(fragments.entries.size() == 3 and locked == 2 and vitrine.displayed().size() == 1,
		"vitrina: el fragmento de Chip y Glitch está; el que falta se ve como «???»")
	fragments.close()
	await _frames(2)
	var stand := room.get_node("Cuarto/SoporteNullblade") as NullbladeStand
	var forms := stand.inspect()
	await _frames(2)
	_check(forms.entries.size() == 4 and not forms.entries[0]["locked"] and forms.entries[0]["subtitle"] == "Forma actual"
		and forms.entries[1]["locked"] and forms.entries[3]["locked"], "la Nullblade: .exe es la forma actual; .zero, .void y .max, bloqueadas")
	forms.close()
	await _frames(2)
	_check(state.nullblade_stage == 1 and stand.has_sword(), "mirarla no se la quita a Kai (sigue en su equipo)")
	var computer := room.get_node("Cuarto/Computadora") as KaiComputer
	var pc := computer.use()
	await _frames(3)
	var titles := PackedStringArray()
	for entry in pc.entries:
		titles.append(entry.title)
	_check(paused and pc.entries.size() >= 1 and pc.entries[0].body.contains("Mae, ¿viste lo que pasó con las computadoras del laboratorio?"),
		"la computadora: mensajes de los amigos %s" % [titles])
	pc.show_section(ComputerEntry.Section.NOTAS)
	var notes := PackedStringArray()
	for entry in pc.entries:
		notes.append(entry.title)
	_check(notes.has("Cosas raras") and not notes.has("El sueño"), "y notas de Kai (la del sueño todavía no) %s" % [notes])
	pc.close()
	await _frames(2)
	var bed := room.get_node("Cuarto/Cama") as KaiBed
	bed._on_interacted(room.player)
	await _frames(3)
	var prompt := get_first_node_in_group(&"confirm_prompt") as ConfirmPrompt
	_check(prompt != null and prompt.no_button.has_focus(), "la cama pregunta «¿Descansar hasta mañana?» (empieza en «No»)")
	prompt.answer(false)
	await _frames(3)
	_check(current_scene == room and state.get_current_step(Q) == &"descansar" and not bed.sleeping, "con «No» no pasa nada")


func _test_night() -> void:
	var bed := room.get_node("Cuarto/Cama") as KaiBed
	room.player.health.take_damage(1.0)
	bed._on_interacted(room.player)
	await _frames(3)
	(get_first_node_in_group(&"confirm_prompt") as ConfirmPrompt).answer(true)
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == B + "casa.tscn" and current_scene.is_node_ready())
	await _frames(4)
	room = current_scene as Room
	_check(state.has_flag(HomeStory.SLEEP_FLAG) and not room.player.visible, "Kai se duerme: escena aparte en la sala (sin Kai)")
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	_check(_line(box).contains("¿Creés que ya empezó?"), "mamá: «¿Creés que ya empezó?»")
	await _advance(box)
	_check(state.has_flag(HomeStory.PARENTS_FLAG), "papá: «...podemos enseñarle a elegir» (sin más explicaciones)")
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == B + "cuarto_kai.tscn" and current_scene.is_node_ready())
	await _frames(4)
	room = current_scene as Room
	await _until(func() -> bool: return get_first_node_in_group(&"resonance_overlay") != null)
	var computer := room.get_node("Cuarto/Computadora") as KaiComputer
	_check(get_first_node_in_group(&"resonance_overlay") != null and computer.flicker > 0.0 and (room.get_node("Cuarto/Cama") as KaiBed).sleeping,
		"la Resonancia Digital: interferencias y la computadora se enciende sola mientras Kai duerme")
	box = _box()
	await _until(func() -> bool: return box.is_playing())
	_check(state.has_flag(&"resonancia_digital_1") and DayPhase.current(state) == DayPhase.Phase.MANANA, "amanece (queda como evento narrativo)")
	_check(_line(box).contains("Amanece") or _line(box).contains("¿Qué fue eso?"), "Kai despierta confundido")
	await _advance(box)
	await _until(func() -> bool: return state.is_quest_completed(Q))


func _test_morning() -> void:
	_check(state.is_quest_completed(Q) and state.get_current_step(&"el_lenguaje_de_las_maquinas") == &"clase_programacion"
		and ProgressTracker.chapter(state) == 2, "termina «Camino a casa»: empieza el Capítulo 2")
	var card := room.get_node("CombatHUD/TitleCard") as TitleCard
	_check(card.is_showing(), "«CAPÍTULO 2 · LOS PRIMEROS CÓDIGOS»")
	_check(room.player.health.current == room.player.health.max_health and not room.player.controls_locked, "Kai descansó: cristales llenos y con control")
	_check(not state.has_flag(&"habilidad_resonancia") and state.domain_stage == 0, "la Resonancia no es una habilidad (ni Dominio Nulo)")
	var saved: Dictionary = root.get_node("SaveManager").read_slot(1).get("ubicacion", {})
	_check(String(saved.get("escena", "")).ends_with("cuarto_kai.tscn") and saved.get("punto") == "cama", "se guardó en la cama %s" % [saved])
	var bed := room.get_node("Cuarto/Cama") as KaiBed
	bed._on_interacted(room.player)
	await _frames(3)
	_check(get_first_node_in_group(&"confirm_prompt") == null, "de día la cama no deja dormir («Todavía es temprano»)")
	await _open(B + "casa.tscn")
	var mom := room.get_node("Familia/Mama") as FamilyMember
	await _frames(4)
	_check(absf(mom.position.x - 830.0) < 1.0, "de mañana, mamá en la cocina")
	room.player.teleport_to(mom.global_position + Vector2(-20, 0))
	await _frames(6)
	await _action(&"interact")
	var box := _box()
	await _until(func() -> bool: return box.is_playing())
	_check(_line(box).contains("Buenos días"), "mamá: «¡Buenos días!» (antes de salir al colegio)")
	await _advance(box)
	await _open(Z + "entrada.tscn")
	_check((room.get_node("Exits/ToCalle") as RoomExit).is_open(), "la salida a la calle sigue abierta (se puede volver a casa)")


func _test_saved() -> void:
	var saves := root.get_node("SaveManager")
	state.reset()
	saves.load_slot(1)
	_check(state.has_flag(&"resonancia_digital_1") and state.has_flag(HomeStory.FAMILY_FLAG) and state.is_quest_completed(Q)
		and state.has_flag(&"cap1_fragmento_leido") and state.has_flag(StringName("pc_leido_mensaje_laboratorio")),
		"al cargar la partida, la casa recuerda todo (charla, noche, fragmentos, mensajes leídos)")


func _test_other_slot() -> void:
	root.get_node("SaveManager").new_game(2)
	var shelf_items := HomeCollection.of_categories([Keepsake.Category.RECUERDO, Keepsake.Category.REGALO] as Array[Keepsake.Category], state, true)
	var fragments := HomeCollection.of_categories([Keepsake.Category.FRAGMENTO] as Array[Keepsake.Category], state, true)
	var ids := PackedStringArray()
	for item in shelf_items:
		ids.append(String(item.id))
	_check(not ids.has("dibujo_hermanos") and fragments.is_empty() and not state.has_flag(&"resonancia_digital_1"),
		"otra ranura no comparte nada (ni recuerdos nuevos, ni fragmentos, ni la noche)")


func _line(box: DialogueBox) -> String:
	return box._text.text


func _open(path: String) -> void:
	change_scene_to_file(path)
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == path and current_scene.is_node_ready())
	await _frames(4)
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
