extends SceneTree
## Prueba automática: el menú de pruebas (F9, solo en el editor). Cada punto de DevPoints abre su sala
## con la misión en el paso correcto y las habilidades de ese momento, sin tocar las ranuras de guardado;
## F9 abre y cierra el menú (pausa el juego); los trucos funcionan.
## Ejecutar: godot --headless --path . --script res://tests/test_menu_pruebas.gd

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var menu := root.get_node("DevMenu")
	var state := root.get_node("GameState")
	var saves := root.get_node("SaveManager")
	_check(menu.is_available(), "al correr desde el editor el menú de pruebas está disponible")
	var problems: Array[String] = []
	for i in DevPoints.POINTS.size():
		var point: Dictionary = DevPoints.POINTS[i]
		menu.jump(i)
		var loaded := false
		for k in 600:
			await process_frame
			if current_scene is Room and current_scene.scene_file_path == point["escena"] and current_scene.is_node_ready() \
					and not root.get_node("SceneManager").is_changing():
				loaded = true
				break
		for k in 10:
			await physics_frame
		var room := current_scene as Room
		var target: Array = point.get("mision", [])
		var step_ok: bool = target.is_empty() or state.get_current_step(target[0]) == target[1] \
			or state.has_reached_step(target[0], target[1])
		var abilities_ok: bool = (not point["habilidades"].has(&"nullblade") or state.nullblade_stage >= 1) \
			and (not point["habilidades"].has(&"inmersion") or state.immersion_unlocked)
		if not loaded or room == null or room.player == null or not step_ok or not abilities_ok or saves.active_slot != 0:
			problems.append("%s (cargó %s, paso %s, habilidades %s)" % [point["nombre"], loaded, step_ok, abilities_ok])
	_check(problems.is_empty(), "los %d puntos abren su sala con la misión y las habilidades de ese momento, sin guardar %s"
		% [DevPoints.POINTS.size(), problems])
	# F9 abre y cierra (y pausa el juego mientras está abierto).
	var f9 := InputEventKey.new()
	f9.physical_keycode = KEY_F9
	f9.pressed = true
	Input.parse_input_event(f9)
	await process_frame
	await process_frame
	_check(menu.is_open() and paused, "F9 abre el menú y pausa el juego")
	Input.parse_input_event(f9)
	await process_frame
	await process_frame
	_check(not menu.is_open() and not paused, "F9 otra vez lo cierra")
	# Trucos.
	menu.god_mode = true
	menu.double_jump = true
	await physics_frame
	await physics_frame
	var player := (current_scene as Room).player
	_check(player.damage.protected and player.can_double_jump, "los trucos funcionan (sin daño, doble salto)")
	menu.god_mode = false
	menu.double_jump = false
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
