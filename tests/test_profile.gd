extends SceneTree
## Prueba automática: «Mi perfil» (T8, ProfileStats y ProfileScreen). Tiempo total de las ranuras,
## la partida más reciente (año, capítulo, nivel, lugar, Ecos, habilidades, porcentajes),
## estadísticas educativas, logros y último guardado; sin datos privados; y el botón del menú.
## Las pruebas usan su propia carpeta de partidas (IdentityManager en modo prueba).
## Ejecutar: godot --headless --path . --script res://tests/test_profile.gd

const MENU := "res://ui/menus/main_menu/main_menu.tscn"
const LAB := "res://world/zones/zone0/laboratorio.tscn"

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var saves := root.get_node("SaveManager")
	var state := root.get_node("GameState")
	var economy := root.get_node("Economy")
	var empty := ProfileStats.compute(saves)
	_check(empty["tiempo_total"] == 0 and empty["ranura"] == 0, "sin partidas, el perfil está vacío")
	saves.new_game(1)
	state.play_time = 600.0
	saves.save_game(LAB, &"desde_pc")
	saves.new_game(2)
	root.get_node("World").enter(LAB)
	state.play_time = 3000.0
	economy.add_ecos(250)
	state.set_dash_level(1)
	state.unlock_double_jump()
	state.unlock_vision()
	state.set_nullblade_stage(1)
	state.learn_command(&"ls")
	state.learn_command(&"cd")
	economy.claim_reward(&"terminal:pc_profesor_cuenta", 0)
	state.set_flag(&"tutorial_terminado")
	saves.save_game(LAB, &"desde_pc")
	var stats := ProfileStats.compute(saves)
	_check(stats["tiempo_total"] == 3600 and stats["partidas"] == 2, "tiempo total = suma de las ranuras (%d s en %d partidas)" % [stats["tiempo_total"], stats["partidas"]])
	_check(stats["ranura"] == 2 and stats["ecos"] == 250, "la partida actual es la más reciente (ranura 2, 250 Ecos)")
	_check(Array(stats["habilidades"]) == ["Nullblade.exe", "Visión Digital", "Dash", "Doble salto"], "habilidades en orden (%s)" % ", ".join(stats["habilidades"]))
	_check(stats["comandos"] == 2 and stats["terminales"] == 1, "estadísticas educativas (comandos y terminales)")
	change_scene_to_file(MENU)
	await create_timer(0.6).timeout
	var button := current_scene.get_node("%ProfileButton") as Button
	_check(button.visible, "el menú tiene MI PERFIL")
	button.pressed.emit()
	await process_frame
	var screen := current_scene.get_node_or_null("Perfil") as ProfileScreen
	_check(screen != null and not current_scene.get_node("%Buttons").visible, "MI PERFIL abre el perfil")
	if screen == null:
		quit(1)
		return
	var text := ""
	for row in screen.rows():
		text += "%s: %s\n" % row
	for expected in ["01:00:00", "Ranura 2", "Décimo — Capítulo 1 · Nivel 1", "Laboratorio", "250", "Doble salto", "Historia completada", "2 comandos aprendidos · 1 terminales resueltas", "llegarán con Steam"]:
		_check(text.contains(expected), "el perfil muestra «%s»" % expected)
	var labels := ""
	for node in screen.find_children("*", "Label", true, false):
		labels += (node as Label).text + "\n"
	_check(labels.contains("Desarrollo (sin Steam)"), "muestra el nombre del jugador")
	_check(not labels.contains("dev_") and not labels.contains("partida_id"), "no muestra ids técnicos ni datos privados")
	screen.close()
	await process_frame
	_check(current_scene.get_node("%Buttons").visible, "Volver regresa al menú")
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
