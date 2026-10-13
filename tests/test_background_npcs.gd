extends SceneTree
## Prueba automática: NPC de fondo (BackgroundNpc) en la Entrada y el Pasillo: tienen sus animaciones,
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
