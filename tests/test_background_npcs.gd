extends SceneTree
## Prueba automática: NPC de fondo (BackgroundNpc) en la Entrada, el Pasillo, la Biblioteca, el Aula, las
## Escaleras y el Salón 3 (ninguno en el Cuarto técnico): tienen sus animaciones,
## no chocan con Kai, la pareja que charla se mira y se turna para hablar, el conserje camina con el
## trapeador sin salirse de su tramo y la profesora va y viene.
## Ejecutar: godot --headless --path . --script res://tests/test_background_npcs.gd

const ENTRADA := "res://world/zones/zone0/entrada.tscn"
const PASILLO := "res://world/zones/zone0/pasillo.tscn"
const FLOOR_Y := 304.0

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.get_node("GameState").reset()
	change_scene_to_file(ENTRADA)
	await _frames(10)
	await _test_entrada()
	change_scene_to_file(PASILLO)
	await _frames(10)
	await _test_pasillo()
	await _test_otras_salas()
	await _test_sala_3_en_clase()
	await _test_sin_repetir()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_entrada() -> void:
	var npcs := _npcs()
	_check(npcs.size() == 3, "la Entrada tiene 3 NPC de fondo (hay %d)" % npcs.size())
	for npc in npcs:
		_check(absf(npc.global_position.y - FLOOR_Y) < 0.5, "%s está parado en el suelo" % npc.name)
		_check(npc.find_children("*", "CollisionObject2D").is_empty(), "%s no choca con nada" % npc.name)
		var sprite := _sprite(npc)
		_check(sprite.sprite_frames.has_animation(StringName(npc.character + "_quieto")), "%s tiene sus sprites" % npc.name)
	var girl := current_scene.get_node("Gente/ChicaCharla") as BackgroundNpc
	var boy := current_scene.get_node("Gente/ChicoCharla") as BackgroundNpc
	_check(girl.facing == 1 and boy.facing == -1, "la pareja que charla se mira")
	var turns := {}
	var both := false
	for i in 60:
		await create_timer(0.15).timeout
		both = both or (girl.is_talking() and boy.is_talking())
		if girl.is_talking():
			turns["chica"] = true
		if boy.is_talking():
			turns["chico"] = true
	_check(turns.has("chica") and turns.has("chico") and not both, "se turnan para hablar (nunca los dos a la vez)")
	var janitor := current_scene.get_node("Gente/Conserje") as BackgroundNpc
	var sprite := _sprite(janitor)
	_check(not sprite.sprite_frames.has_animation(&"cj_espalda"), "el conserje no tiene la pose de espalda (no se usa)")
	var start_x := janitor.position.x
	var moved := false
	var walked := false
	for i in 80:
		await create_timer(0.1).timeout
		moved = moved or absf(janitor.position.x - start_x) > 2.0
		walked = walked or sprite.animation == &"cj_caminar"
		if janitor.position.x < 530.0 - 0.1 or janitor.position.x > 590.0 + 0.1:
			_check(false, "el conserje se sale de su tramo (x=%.1f)" % janitor.position.x)
			break
	_check(moved and walked, "el conserje camina con el trapeador")


func _test_pasillo() -> void:
	var npcs := _npcs()
	_check(npcs.size() == 4, "el Pasillo tiene 4 NPC de fondo (hay %d)" % npcs.size())
	var teacher := current_scene.get_node("Gente/Profesora") as BackgroundNpc
	var sprite := _sprite(teacher)
	var frames := sprite.sprite_frames
	_check(frames.get_frame_count(&"pf_caminar") == 2, "la profesora camina con un solo conjunto de ropa (2 cuadros)")
	var start_x := teacher.position.x
	var turned := false
	var start_facing := teacher.facing
	for i in 100:
		await create_timer(0.1).timeout
		turned = turned or teacher.facing != start_facing
	_check(absf(teacher.position.x - start_x) > 2.0 or turned, "la profesora va y viene por el pasillo")
	var locker := current_scene.get_node("Gente/ChicaCasillero") as BackgroundNpc
	var locker_sprite := _sprite(locker)
	_check(locker_sprite.animation == &"f3_espalda", "la chica del casillero está de espaldas")



## Biblioteca, Aula, Escaleras y Salón 3: cuántos hay (pocos: no hace falta llenar), parados en el suelo
## (abajo, en un descanso o en el 2° piso de la escalera), sin chocar y con sus sprites, y sin repetir
## la misma gente de otra sala. En el Cuarto técnico no hay (solo personal autorizado).
func _test_otras_salas() -> void:
	for room: Array in [["biblioteca", 5, [304.0]], ["aula", 2, [304.0]], ["escaleras", 4, [304.0, 188.0, -48.0]],
			["sala_3", 7, [304.0]], ["cuarto_tecnico", 0, [304.0]]]:
		change_scene_to_file("res://world/zones/zone0/%s.tscn" % room[0])
		await _frames(10)
		var npcs := _npcs().filter(func(n: BackgroundNpc) -> bool: return n.get_parent().name == "Gente")
		_check(npcs.size() == room[1], "%s: %d NPC de fondo (hay %d)" % [room[0], room[1], npcs.size()])
		for npc: BackgroundNpc in npcs:
			var grounded: bool = (room[2] as Array).any(func(y: float) -> bool: return absf(npc.global_position.y - y) < 0.5)
			var sprite := _sprite(npc)
			if not grounded or not npc.find_children("*", "CollisionObject2D").is_empty() \
					or not sprite.sprite_frames.has_animation(StringName(npc.character + "_quieto")):
				_check(false, "%s/%s: en el suelo, sin chocar y con sus sprites" % [room[0], npc.name])
		if room[0] == "escaleras":
			var props := current_scene.get_node("Props")
			_check(not props.bins.is_empty() and not props.recycling.is_empty() and not props.boards.is_empty()
				and not props.extinguishers.is_empty() and not props.fountains.is_empty() and not props.plants.is_empty(),
				"en las escaleras hay basureros, reciclaje, un diario mural, extintores, un bebedero y macetas")


## En el Salón 3 los del recreo no están durante la clase ni con Chip y Glitch (vuelven al terminar).
func _test_sala_3_en_clase() -> void:
	var state := root.get_node("GameState")
	state.reset()
	state.start_quest(&"una_clase_diferente")
	change_scene_to_file("res://world/zones/zone0/sala_3.tscn")
	await _frames(10)
	var gente := current_scene.get_node("Gente") as Node2D
	_check(not gente.visible, "durante la clase no están los del recreo en el Salón 3")
	# Capítulo 2: tampoco durante la clase de programación ni mientras el profesor sigue en el salón.
	for moment: Array in [["Clase de programación (Sala 3)", false], ["Simulador · ciclos y repaso", false],
			["Final del capítulo (el profesor)", true]]:
		DevPoints.prepare(_dev_point(moment[0]), state)
		change_scene_to_file("res://world/zones/zone0/sala_3.tscn")
		await _frames(10)
		var seen: bool = (current_scene.get_node("Gente") as Node2D).visible
		var class_seen: bool = (current_scene.get_node("Capitulo2/Clase") as Node2D).visible or (current_scene.get_node("Capitulo2/Profesor") as Node2D).visible
		_check(seen == moment[1] and not (seen and class_seen),
			"capítulo 2 · %s: los del recreo %s (nunca junto con la clase o el profesor)" % [moment[0], "están" if moment[1] else "no están"])
	state.reset()


## Ninguna sala repite la gente de otra (antes la pareja de la Entrada estaba también en las Escaleras).
func _test_sin_repetir() -> void:
	var seen := {}
	for room in ["entrada", "pasillo", "biblioteca", "aula", "escaleras", "sala_3"]:
		change_scene_to_file("res://world/zones/zone0/%s.tscn" % room)
		await _frames(6)
		var people: Array[String] = []
		for npc in _npcs():
			if npc.get_parent().name != "Gente":
				continue  # Los de la clase del Salón 3 son de la historia (solo están en la clase).
			people.append(npc.character)
		people.sort()
		var key := ",".join(people)
		_check(not seen.has(key), "%s no tiene la misma gente que %s (%s)" % [room, seen.get(key, "otra sala"), key])
		seen[key] = room
		var pairs := 0
		for other in seen:
			if other != key and _shared(other.split(","), people) >= 2:
				pairs += 1
		_check(pairs == 0, "%s no repite una pareja de otra sala" % room)


## Cuántos personajes tienen en común dos salas.
func _shared(a: PackedStringArray, b: Array[String]) -> int:
	var count := 0
	for character in b:
		if character in a:
			count += 1
	return count

func _npcs() -> Array[BackgroundNpc]:
	var list: Array[BackgroundNpc] = []
	for node in current_scene.find_children("*", "BackgroundNpc"):
		list.append(node as BackgroundNpc)
	return list


func _frames(count: int) -> void:
	for i in count:
		await process_frame
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])


## El sprite lo crea el NPC por código (no tiene dueño en la escena).
func _sprite(npc: Node) -> AnimatedSprite2D:
	for child in npc.get_children():
		if child is AnimatedSprite2D:
			return child
	return null


## Un punto del menú de pruebas (DevPoints) por su nombre.
func _dev_point(point_name: String) -> Dictionary:
	for point: Dictionary in DevPoints.POINTS:
		if point["nombre"] == point_name:
			return point
	return {}
