extends SceneTree
## Prueba automática: el descubrimiento «Una fotografía antigua» de la biblioteca (expansión del Capítulo 1;
## docs/mundo/COLEGIO.md). La foto está en la pared; con E se mira (pausa el juego); muestra al profesor Alvarado
## joven en la inauguración del Laboratorio 2 sin nombrar el Proyecto Génesis ni el origen de Kai; la primera vez
## registra el descubrimiento (misión de tipo Descubrimiento y página del Grimorio); mirarla otra vez no repite
## nada; la biblioteca tiene más objetos para examinar; guardar y cargar conserva el descubrimiento y otra ranura
## no lo comparte.
## Ejecutar: godot --headless --path . --script res://tests/test_foto_antigua.gd

const Z := "res://world/zones/zone0/"
const PAGE := "res://data/grimorio/registro_foto_antigua.tres"

var _failures := 0
var state: Node
var room: Room


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	root.get_node("SaveManager").new_game(1)
	DevPoints._advance(state, &"una_clase_diferente", &"pedir_permiso")
	state.unlock_vision()
	state.set_nullblade_stage(1)
	await _open(Z + "biblioteca.tscn")
	await _test_photo()
	await _test_room_objects()
	await _test_saved()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_photo() -> void:
	var photo := room.get_node("Objetos/FotoAntigua") as OldPhoto
	var page := load(PAGE) as GrimorioEntry
	_check(photo != null and photo.visible and not photo.is_discovered() and not page.is_unlocked(state),
		"en la biblioteca hay una foto vieja en la pared (todavía sin descubrir; el Grimorio la muestra como «???»)")
	room.player.teleport_to(Vector2(photo.global_position.x, 304))
	await _frames(3)
	var window := photo.look()
	await _frames(3)
	var entry: Dictionary = window.entries[0]
	var all_text := "%s %s %s %s" % [entry["name"], entry["description"], entry["note"], " ".join(entry["lines"])]
	_check(paused and entry["name"] == "Una fotografía antigua", "con E se mira la foto (el juego se pausa)")
	_check(String(entry["description"]).contains("LABORATORIO 2") and String(entry["note"]).contains("Alvarado"),
		"es la inauguración del Laboratorio 2 y Kai reconoce al profesor Alvarado")
	_check(not all_text.to_lower().contains("génesis") and not all_text.to_lower().contains("biomateria")
		and not all_text.to_lower().contains("adopt"), "pista sutil: no nombra el Proyecto Génesis ni el origen de Kai")
	var quest := QuestDB.get_quest(OldPhoto.QUEST)
	_check(quest != null and quest.category == Quest.Category.DESCUBRIMIENTO and state.is_quest_completed(OldPhoto.QUEST)
		and photo.is_discovered(), "queda registrado como descubrimiento")
	_check(page.is_unlocked(state) and page.text.contains("LABORATORIO 2"), "y se puede volver a leer en el Grimorio (Registros)")
	_check(state.get_current_step(&"una_clase_diferente") == &"pedir_permiso" and state.active_quest == &"una_clase_diferente",
		"no cambia el objetivo de la historia")
	window.close()
	await _frames(2)
	_check(not paused and not photo.interactable.busy, "al cerrar, el juego sigue")
	var completed: Array[int] = [0]  # En una lambda, un int se copia; el arreglo no.
	state.quest_completed.connect(func(_id: StringName) -> void: completed[0] += 1)
	window = photo.look()
	await _frames(2)
	window.close()
	await _frames(2)
	_check(completed[0] == 0, "mirarla otra vez no la registra de nuevo")


func _test_room_objects() -> void:
	for path in ["Objetos/Estante", "Objetos/Mesa"]:
		var item := room.get_node(path) as Examinable
		_check(item != null and not item.dialogues.is_empty(), "en la biblioteca se puede examinar %s" % path.get_file())


func _test_saved() -> void:
	var saves := root.get_node("SaveManager")
	_check(saves.save_game(Z + "biblioteca.tscn", &"desde_escaleras"), "se guarda la partida")
	state.reset()
	saves.load_slot(1)
	_check(state.has_flag(OldPhoto.SEEN_FLAG) and state.is_quest_completed(OldPhoto.QUEST), "al cargar, el descubrimiento sigue ahí")
	saves.new_game(2)
	_check(not state.has_flag(OldPhoto.SEEN_FLAG) and not (load(PAGE) as GrimorioEntry).is_unlocked(state), "otra ranura no lo comparte")


func _open(path: String) -> void:
	change_scene_to_file(path)
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == path and current_scene.is_node_ready())
	await _frames(4)
	room = current_scene as Room


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
