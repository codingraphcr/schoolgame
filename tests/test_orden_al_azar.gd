extends SceneTree
## Prueba automática: las respuestas de las preguntas (ChoiceWindow) y las contraseñas para elegir en la
## terminal (TerminalWindow) aparecen en un orden al azar cada vez, para que la respuesta correcta no
## esté siempre en el mismo lugar. Elegir sigue funcionando con el índice original.
## Ejecutar: godot --headless --path . --script res://tests/test_orden_al_azar.gd

const CHECKPOINT := "res://data/challenges/cap1_checkpoint_1.tres"
const LAB2 := "res://data/terminals/puerta_lab2.tres"

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var holder := Node.new()
	root.add_child(holder)
	current_scene = holder
	await _test_choice_window()
	await _test_terminal()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_choice_window() -> void:
	var challenge := load(CHECKPOINT) as ChoiceChallenge
	var size := challenge.questions[0].options.size()
	var orders := {}
	var correct_slots := {}
	var all_ok := true
	for k in 12:
		var window := ChoiceWindow.open(current_scene, challenge)
		await process_frame
		var order := window.display_order.duplicate()
		var sorted := order.duplicate()
		sorted.sort()
		var on_screen: Array[int] = []
		for child in window._options.get_children():
			on_screen.append(window._buttons.find(child))
		all_ok = all_ok and sorted == range(size) and on_screen == order
		orders[str(order)] = true
		for slot in order.size():
			if challenge.questions[0].options[order[slot]].correct:
				correct_slots[slot] = true
		if k == 0:
			# Elegir con el índice original sigue marcando la opción correcta.
			var right := -1
			for i in size:
				if challenge.questions[0].options[i].correct:
					right = i
			window.choose(right)
			_check(window._continue.visible and window.mistakes[0] == 0, "elegir por el índice original sigue funcionando")
		window.close()
		await process_frame
	_check(all_ok, "las opciones en pantalla son todas, sin repetir, en el orden de display_order")
	_check(orders.size() >= 4, "el orden cambia cada vez que se abre (%d órdenes distintos en 12)" % orders.size())
	_check(correct_slots.size() >= 3, "la respuesta correcta aparece en lugares distintos (%d)" % correct_slots.size())


func _test_terminal() -> void:
	var challenge := load(LAB2) as TerminalChallenge
	var orders := {}
	var ok := true
	for k in 10:
		var window := TerminalWindow.open(current_scene, challenge)
		await process_frame
		window._ask_password()
		var order := window.password_order.duplicate()
		var sorted := order.duplicate()
		sorted.sort()
		ok = ok and sorted == range(challenge.password_options.size())
		ok = ok and window._password_panel.get_child(0) == window._password_buttons[order[0]]
		ok = ok and window._password_buttons[order[0]].text.begins_with("1 · ")
		orders[str(order)] = true
		window.queue_free()
		paused = false
		await process_frame
	_check(ok, "en la terminal, las contraseñas se numeran en el orden en que se ven")
	_check(orders.size() >= 3, "y el orden cambia cada vez (%d órdenes distintos en 10)" % orders.size())


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
