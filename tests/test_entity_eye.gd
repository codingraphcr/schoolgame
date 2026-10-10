extends SceneTree
## Prueba automática: el ojo de la entidad en la computadora del profesor. Vigila a Kai, parpadea,
## se cierra y desaparece al llegar a la terminal, y ya no está después de resolverla.
## Ejecutar: godot --headless --path . --script res://tests/test_entity_eye.gd

const PC := "res://world/zones/pc_profesor/escritorio.tscn"

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.reset()
	state.start_quest(&"contrasena_profesor")
	state.complete_step(&"contrasena_profesor", &"entrar_pc")
	change_scene_to_file(PC)
	await _wait(0.8)
	var room := current_scene as Room
	var eye := room.get_node("EntityEye") as EntityEye
	_check(eye.visible and eye.state == EntityEye.State.WATCHING, "al entrar, el ojo de la entidad vigila")
	var camera := room.camera
	var gap := eye.global_position.distance_to(camera.get_screen_center_position() + eye.screen_offset)
	_check(gap < 30.0, "acompaña a la cámara (arriba de la pantalla; a %.0f px)" % gap)
	var saw_blink := false
	for i in 400:
		await physics_frame
		if eye.openness < 0.5:
			saw_blink = true
			break
	_check(saw_blink, "parpadea")
	# Kai llega a la terminal: el ojo se cierra y desaparece.
	room.player.teleport_to(eye.terminal.global_position + Vector2(-60, 0))
	await _frames(4)
	_check(eye.state != EntityEye.State.WATCHING, "al llegar a la terminal, el ojo se cierra")
	await _wait(1.5)
	_check(eye.state == EntityEye.State.GONE and not eye.visible, "y desaparece")
	# Después de resolver la terminal ya no aparece.
	state.complete_step(&"contrasena_profesor", &"cruzar_spam")
	state.complete_step(&"contrasena_profesor", &"revisar_configuracion")
	change_scene_to_file(PC)
	await _wait(0.8)
	var again := current_scene.get_node("EntityEye") as EntityEye
	_check(again.state == EntityEye.State.GONE and not again.visible, "después de resolver la terminal, el ojo ya no está")
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
		await physics_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
