extends SceneTree
## Prueba automática: la selección de partida (T7, SlotSelect). Tres tarjetas con el resumen de cada
## ranura y su estado; cargar solo partidas usables; sobrescribir con confirmación; borrar con doble
## confirmación; aviso de posible conflicto; y el indicador de guardado del HUD.
## Las pruebas usan su propia carpeta de partidas (IdentityManager en modo prueba).
## Ejecutar: godot --headless --path . --script res://tests/test_slot_select.gd

const ENTRADA := "res://world/zones/zone0/entrada.tscn"

var _failures := 0
var saves: Node
var state: Node
var _picked := 0
var _cancelled := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	saves = root.get_node("SaveManager")
	state = root.get_node("GameState")
	_check(root.get_node("IdentityManager").saves_root().begins_with("user://pruebas_partidas"),
		"las pruebas usan su propia carpeta de partidas (nunca las reales)")
	_check(SlotSelect.format_time(2903) == "00:48:23" and SlotSelect.format_time(52_000) == "14:26:40", "el tiempo jugado se muestra como 00:48:23")
	saves.new_game(1)
	root.get_node("World").enter(ENTRADA)
	state.play_time = 2903.0
	saves.save_game(ENTRADA, &"entrada")
	DirAccess.make_dir_recursive_absolute(saves.slot_dir(2))
	var file := FileAccess.open(saves.slot_path(2), FileAccess.WRITE)
	file.store_string("basura")
	file.close()
	await _test_load_mode()
	await _test_new_mode_and_delete()
	await _test_conflict()
	await _test_hud_indicator()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _open(mode: SlotSelect.Mode) -> SlotSelect:
	_picked = 0
	_cancelled = false
	var screen := SlotSelect.open(root, mode)
	screen.chosen.connect(func(slot: int) -> void: _picked = slot)
	screen.cancelled.connect(func() -> void: _cancelled = true)
	await process_frame
	return screen


func _texts(card: Node) -> String:
	var parts: PackedStringArray = []
	for node in card.find_children("*", "Label", true, false):
		parts.append((node as Label).text)
	return " | ".join(parts)


func _test_load_mode() -> void:
	var screen := await _open(SlotSelect.Mode.LOAD)
	var card_1 := screen.find_child("Ranura1", true, false)
	var card_2 := screen.find_child("Ranura2", true, false)
	var card_3 := screen.find_child("Ranura3", true, false)
	_check(card_1 and card_2 and card_3, "hay tres tarjetas")
	var text_1 := _texts(card_1)
	_check(text_1.contains("RANURA 1") and text_1.contains("Prólogo") and text_1.contains("Entrada") and text_1.contains("00:48:23")
		and text_1.contains("Correcta"), "la ranura 1 muestra capítulo, lugar, tiempo y estado (%s)" % text_1)
	_check(_texts(card_2).contains("Dañada") and (card_2.find_child("Elegir", true, false) as Button).disabled,
		"una partida dañada se marca y no se puede cargar")
	_check((card_3.find_child("Elegir", true, false) as Button).disabled and _texts(card_3).contains("Vacía"), "una ranura vacía no se puede cargar")
	(card_1.find_child("Elegir", true, false) as Button).pressed.emit()
	await process_frame
	_check(_picked == 1, "se elige la partida para cargarla")
	screen = await _open(SlotSelect.Mode.LOAD)
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	Input.parse_input_event(esc)
	await process_frame
	await process_frame
	_check(_cancelled and not is_instance_valid(screen) or screen.is_queued_for_deletion(), "Esc vuelve atrás")


func _test_new_mode_and_delete() -> void:
	var screen := await _open(SlotSelect.Mode.NEW)
	screen.pick(1)
	await process_frame
	_check(_picked == 0 and screen._dialog.visible and screen._dialog.dialog_text.contains("ya tiene una partida"),
		"empezar encima de una partida pide confirmación")
	screen._dialog.confirmed.emit()
	await process_frame
	_check(_picked == 1, "al confirmar, se usa esa ranura")
	screen = await _open(SlotSelect.Mode.NEW)
	screen.pick(3)
	await process_frame
	_check(_picked == 3, "una ranura vacía se usa directo")
	screen = await _open(SlotSelect.Mode.LOAD)
	screen.ask_delete(1)
	await process_frame
	var first := screen._dialog
	_check(first.visible and first.dialog_text.contains("¿Borrar"), "borrar pide una primera confirmación")
	first.confirmed.emit()
	await process_frame
	await process_frame
	_check(screen._dialog != first and screen._dialog.visible and saves.slot_info(1)["estado"] == "ok", "y una segunda, antes de borrar nada")
	screen._dialog.confirmed.emit()
	await process_frame
	await process_frame
	_check(saves.slot_info(1)["estado"] == "vacia", "con la doble confirmación, se borra")
	screen.queue_free()


func _test_conflict() -> void:
	saves.new_game(3)
	saves.save_game(ENTRADA, &"entrada")
	var ledger: Dictionary = saves._ledger()
	ledger["revisiones"]["3"]["revision"] = 99
	saves._save_ledger(ledger)
	var screen := await _open(SlotSelect.Mode.LOAD)
	_check(_texts(screen.find_child("Ranura3", true, false)).contains("Posible conflicto"), "la tarjeta avisa «posible conflicto»")
	screen.pick(3)
	await process_frame
	_check(_picked == 0 and screen._dialog.visible and screen._dialog.dialog_text.contains("conflicto"), "y antes de cargarla, pregunta")
	screen.queue_free()


func _test_hud_indicator() -> void:
	saves.new_game(1)
	change_scene_to_file(ENTRADA)
	await create_timer(0.6).timeout
	var indicator := current_scene.get_node("CombatHUD/SaveIndicator") as SaveIndicator
	_check(indicator != null and indicator.modulate.a == 0.0, "el HUD tiene el indicador de guardado (oculto)")
	saves.save_game(ENTRADA, &"entrada")
	await process_frame
	_check(indicator.modulate.a > 0.9 and indicator.text == "✔ Partida guardada", "al guardar muestra «✔ Partida guardada»")
	saves.save_failed.emit(1, "prueba")
	_check(indicator.text == "✘ Error al guardar", "si falla, «✘ Error al guardar»")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
