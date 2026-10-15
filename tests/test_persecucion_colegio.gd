extends SceneTree
## Prueba automática: la persecución larga de Chip y Glitch por el pasillo del segundo piso (Capítulo 1,
## paso seguir_criaturas). El pasillo está entre las escaleras y la biblioteca (en el mapa y en las
## salidas); los hermanos aparecen solo durante el paso; Chip tira estanterías que avisan, caen y quedan
## como obstáculo sólido que se salta; Glitch tira cajas que quitan medio cristal; hay dos «¡casi!» en
## los que Kai casi los atrapa; al final desaparecen hacia la biblioteca; los estudiantes comentan.
## Ejecutar: godot --headless --path . --script res://tests/test_persecucion_colegio.gd

const Z := "res://world/zones/zone0/"
const ROOM := Z + "pasillo_segundo.tscn"
const Q1 := &"una_clase_diferente"

var _failures := 0
var state: Node
var room: Room
var player: Player
var chase: SchoolChase


func _initialize() -> void:
	Engine.max_physics_steps_per_frame = 1
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	_test_links()
	var point := {}
	for candidate: Dictionary in DevPoints.POINTS:
		if candidate["escena"] == ROOM:
			point = candidate
	_check(not point.is_empty(), "el menú de pruebas (F9) tiene un punto para la persecución larga")
	DevPoints.prepare(point, state)
	_check(state.get_current_step(Q1) == &"seguir_criaturas", "la misión está en «seguir a las criaturas»")
	await _open()
	await _test_chase()
	await _test_shelf_blocks()
	await _test_box_hits()
	await _test_bark()
	await _test_other_step()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_links() -> void:
	var stairs := (load(Z + "escaleras.tscn") as PackedScene).instantiate()
	var library := (load(Z + "biblioteca.tscn") as PackedScene).instantiate()
	var corridor := (load(ROOM) as PackedScene).instantiate()
	var up := stairs.get_node("Exits/ToBiblioteca") as RoomExit
	var back := library.get_node("Exits/ToEscaleras") as RoomExit
	_check(up.target_scene == ROOM and up.target_entry == &"desde_escaleras", "de las escaleras se sube al pasillo del segundo piso")
	_check(back.target_scene == ROOM and back.target_entry == &"desde_biblioteca", "de la biblioteca se sale al pasillo del segundo piso")
	var west := corridor.get_node("Exits/ToEscaleras") as RoomExit
	var east := corridor.get_node("Exits/ToBiblioteca") as RoomExit
	_check(west.target_scene == Z + "escaleras.tscn" and stairs.has_node("Entries/" + _entry_name(stairs, west.target_entry)),
		"el pasillo vuelve a las escaleras (entrada «%s»)" % west.target_entry)
	_check(east.target_scene == Z + "biblioteca.tscn" and library.has_node("Entries/" + _entry_name(library, east.target_entry)),
		"el pasillo sigue a la biblioteca (entrada «%s»)" % east.target_entry)
	_check((corridor as Room).room_size.size.x >= 1800.0, "el pasillo es largo (%d px)" % (corridor as Room).room_size.size.x)
	var district := load("res://data/world/districts/colegio.tres") as DistrictLayout
	var linked := 0
	var direct := false
	for link in district.links:
		if (link.room_a == &"escaleras" and link.room_b == &"pasillo_segundo") or (link.room_a == &"pasillo_segundo" and link.room_b == &"biblioteca"):
			linked += 1
		if link.room_a == &"escaleras" and link.room_b == &"biblioteca":
			direct = true
	_check(not direct, "en el mapa las escaleras ya no van directo a la biblioteca")
	_check(linked == 2, "en el mapa del Grimorio: escaleras ↔ pasillo del segundo piso ↔ biblioteca")
	stairs.free()
	library.free()
	corridor.free()


func _entry_name(scene: Node, id: StringName) -> String:
	for entry in scene.get_node("Entries").get_children():
		if entry.get(&"id") == id:
			return entry.name
	return "(no existe)"


func _test_chase() -> void:
	var chip := chase.chip
	var glitch := chase.glitch
	await _frames(10)
	_check(chip.is_shown() and glitch.is_shown(), "Chip y Glitch esperan a Kai al principio del pasillo")
	_check(chase.points.size() >= 8 and chase.points[-1].x - chase.points[0].x >= 1500.0, "corren casi todo el pasillo (%d puntos)" % chase.points.size())
	var shelves_fallen := 0
	for i in 40:
		await _until(func() -> bool: return not chase._moving)
		if chase.is_done():
			break
		var rear := minf(chip.global_position.x, glitch.global_position.x)
		var action := chase.actions[chase.index]
		if action.contains("casi"):
			# Primero, Kai todavía no los alcanza: no se escapan.
			player.teleport_to(Vector2(rear - 120.0, 304.0))
			await _frames(10)
			_check(not chase._moving, "en un «casi» esperan hasta que Kai casi los toca")
			player.teleport_to(Vector2(rear - 30.0, 304.0))
		else:
			player.teleport_to(Vector2(rear - 140.0, 304.0))
		await _frames(4)
	await _until(func() -> bool: return chase.is_done() and not chase._moving)
	await _frames(40)
	for shelf in chase.shelves:
		if shelf.is_blocking():
			shelves_fallen += 1
	_check(shelves_fallen == 3, "Chip tiró las 3 estanterías y quedaron en el piso (%d)" % shelves_fallen)
	_check(chase.boxes_thrown == 3, "Glitch tiró 3 cajas (%d)" % chase.boxes_thrown)
	_check(chase.near_catches == 2, "dos veces Kai casi los atrapa (%d)" % chase.near_catches)
	_check(chase.is_done() and not chip.is_shown() and not glitch.is_shown(), "al final se escapan hacia la biblioteca")
	_check(state.get_current_step(Q1) == &"seguir_criaturas", "la misión sigue: hay que llegar a la biblioteca")


## Una estantería caída es un obstáculo sólido: caminando no se pasa, saltando sí.
func _test_shelf_blocks() -> void:
	var shelf := chase.shelves[0]
	var left_edge := shelf.global_position.x - shelf.height
	player.health.current = player.health.max_health
	player.teleport_to(Vector2(left_edge - 90.0, 304.0))
	await _frames(20)
	Input.action_press(&"move_right")
	await _frames(70)
	_check(player.global_position.x < left_edge, "caminando, la estantería caída no deja pasar (x %.0f, borde %.0f)" % [player.global_position.x, left_edge])
	Input.action_press(&"jump")
	await _frames(50)
	Input.action_release(&"jump")
	await _frames(30)
	Input.action_release(&"move_right")
	_check(player.global_position.x > shelf.global_position.x, "saltando se pasa por encima (x %.0f)" % player.global_position.x)
	# Avisa antes de caer: tiembla y después cae.
	shelf.reset()
	await _frames(2)
	shelf.knock()
	await _frames(3)
	_check(shelf.state == FallingShelf.State.SHAKING and not shelf.is_blocking(), "antes de caer, la estantería tiembla (aviso «!»)")
	await _until(func() -> bool: return shelf.is_blocking())
	_check(shelf.is_blocking(), "y después cae")


func _test_box_hits() -> void:
	await _frames(60)  # Que pase la invulnerabilidad.
	player.health.current = player.health.max_health
	var before: float = player.health.current
	player.teleport_to(Vector2(1100.0, 304.0))
	await _frames(10)
	var box := ThrownBox.new()
	box.direction = -1.0
	box.floor_y = 304.0
	room.add_child(box)
	box.global_position = Vector2(1220.0, 296.0)
	var ref: WeakRef = weakref(box)
	await _until(func() -> bool: return ref.get_ref() == null)
	_check(is_equal_approx(before - player.health.current, 0.5), "una caja que toca a Kai quita medio cristal (%.1f)" % (before - player.health.current))


func _test_bark() -> void:
	var bark := room.get_node("Gente/Comentario_Estudiante_m3") as NpcBark
	bark.said = false
	player.teleport_to(Vector2(1300.0, 304.0))
	await _frames(10)
	player.teleport_to(bark.global_position)
	await _frames(10)
	_check(bark.said, "al pasar cerca, un estudiante comenta algo")


## Fuera del paso (por ejemplo, ya en la biblioteca), el pasillo está tranquilo: sin hermanos.
func _test_other_step() -> void:
	state.complete_step(Q1, &"seguir_criaturas")
	await _open()
	await _frames(20)
	_check(not chase.chip.is_shown() and not chase.glitch.is_shown(), "después del paso, Chip y Glitch ya no están en el pasillo")
	var standing := 0
	for shelf in chase.shelves:
		if not shelf.is_blocking():
			standing += 1
	_check(standing == 3, "y las estanterías están paradas (se puede pasar)")


func _open() -> void:
	change_scene_to_file(ROOM)
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == ROOM and current_scene.is_node_ready())
	await _frames(8)
	room = current_scene as Room
	player = room.player
	chase = room.get_node("Capitulo1/Persecucion") as SchoolChase


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
