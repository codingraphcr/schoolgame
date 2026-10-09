extends SceneTree
## Prueba automática: opciones (volumen, velocidad del texto, glitch, teclas) y el Grimorio.
## Ejecutar: godot --headless --path . --script res://tests/test_settings_grimorio.gd
## Usa un archivo de ajustes propio, así no cambia los ajustes del jugador.

const SETTINGS := "res://ui/menus/settings/settings_screen.tscn"

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	GameSettings.path = "user://ajustes_prueba.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.path))
	GameSettings.ensure_loaded()
	_test_settings()
	await _test_settings_screen()
	await _test_grimorio()
	await _test_in_game()
	GameSettings.reset_controls()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.path))
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_settings() -> void:
	_check(AudioServer.get_bus_index(GameSettings.MUSIC_BUS) != -1 and AudioServer.get_bus_index(GameSettings.SFX_BUS) != -1,
		"existen los buses de música y efectos")
	GameSettings.music_volume = 0.5
	GameSettings.apply_audio()
	var music := AudioServer.get_bus_index(GameSettings.MUSIC_BUS)
	_check(absf(AudioServer.get_bus_volume_db(music) - linear_to_db(0.5)) < 0.01, "el volumen de la música cambia el bus")
	GameSettings.sfx_volume = 0.0
	GameSettings.apply_audio()
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index(GameSettings.SFX_BUS)), "efectos en 0 = silencio")
	GameSettings.text_speed = 3
	_check(GameSettings.text_speed_factor() == 0.0, "velocidad del texto instantánea")
	GameSettings.text_speed = 1
	GameSettings.reduce_glitch = true
	_check(GameSettings.glitch_factor() < 1.0, "reducir glitch baja la intensidad")
	GameSettings.reduce_glitch = false

	var key := InputEventKey.new()
	key.physical_keycode = KEY_K
	GameSettings.remap(&"jump", key)
	_check(GameSettings.key_name(&"jump") == "K", "se puede cambiar la tecla de saltar (ahora %s)" % GameSettings.key_name(&"jump"))
	var press := InputEventKey.new()
	press.physical_keycode = KEY_K
	press.pressed = true
	_check(press.is_action(&"jump"), "la tecla nueva hace saltar")
	GameSettings.save()
	GameSettings.reset_controls()
	_check(GameSettings.key_name(&"jump") == "ESPACIO", "restablecer devuelve la tecla original")
	var config := ConfigFile.new()
	_check(config.load(GameSettings.path) == OK and config.get_value("audio", "musica", 0.0) == 0.5,
		"los ajustes se guardan en el archivo")
	GameSettings.music_volume = 0.8
	GameSettings.sfx_volume = 1.0
	GameSettings.apply_audio()


func _test_settings_screen() -> void:
	change_scene_to_file(SETTINGS)
	await _wait(0.4)
	var screen := current_scene
	var master: SettingRow = screen.get_node("%MasterRow")
	var before := GameSettings.master_volume
	master.grab_focus()
	_key(KEY_LEFT)
	await _wait(0.1)
	_check(GameSettings.master_volume < before, "◀ baja el volumen general (%.1f → %.1f)" % [before, GameSettings.master_volume])
	var text_speed: SettingRow = screen.get_node("%TextSpeedRow")
	text_speed.pressed.emit()
	_check(GameSettings.text_speed == 2, "la velocidad del texto cambia a %s" % GameSettings.TEXT_SPEED_NAMES[GameSettings.text_speed])
	GameSettings.text_speed = 1
	screen.get_node("%ControlsRow").pressed.emit()
	await _wait(0.1)
	_check(screen.get_node("%Controls").visible and screen.get_node("%KeyRows").get_child_count() == GameSettings.REMAPPABLE.size(),
		"la pantalla de controles lista todas las acciones")
	screen.get_node("%ControlsBackButton").pressed.emit()
	await _wait(0.1)
	_check(screen.get_node("%Options").visible, "Volver regresa a las opciones")
	GameSettings.master_volume = before
	GameSettings.apply_audio()


func _test_grimorio() -> void:
	var state := root.get_node("GameState")
	state.reset()
	state.start_quest(&"prologo")
	change_scene_to_file("res://ui/menus/grimorio/grimorio.tscn")
	await _wait(0.4)
	var grimorio := current_scene
	_check(grimorio.get_node("%Tabs").get_child_count() == 5, "el Grimorio tiene 5 pestañas")
	var firewall: GrimorioEntry = load("res://data/grimorio/firewall.tres")
	var phishing: GrimorioEntry = load("res://data/grimorio/phishing.tres")
	_check(grimorio.is_unlocked(firewall) and not grimorio.is_unlocked(phishing), "al empezar, Phishing está oculto")
	state.complete_step(&"prologo", &"hablar_profesor")
	_check(grimorio.is_unlocked(phishing), "al revisar la computadora se descubre Phishing")
	grimorio.select_category(GrimorioEntry.Category.CONCEPTOS)
	await _wait(0.1)
	var list: VBoxContainer = grimorio.get_node("%EntryList")
	_check(list.get_child_count() == grimorio.entries_in(GrimorioEntry.Category.CONCEPTOS).size(), "la lista muestra los conceptos")
	var locked: GrimorioEntry = load("res://data/grimorio/contrasena_segura.tres")
	grimorio.show_entry(locked)
	_check(grimorio.get_node("%EntryTitle").text == "???", "una entrada no descubierta se ve como «???»")
	grimorio.select_category(GrimorioEntry.Category.MAPA)
	await _wait(0.1)
	_check(grimorio.get_node("%Map").visible and grimorio.get_node("%EntryProgress").text.ends_with("%"), "el mapa muestra el avance de la zona")


func _key(keycode: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = keycode
	press.physical_keycode = keycode
	press.pressed = true
	Input.parse_input_event(press)
	var release := press.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])


## En una sala: G abre el Grimorio encima del juego (en pausa) y lo cierra; barritas de energía.
func _test_in_game() -> void:
	var state := root.get_node("GameState")
	state.reset()
	change_scene_to_file("res://world/zones/zone0/entrada.tscn")
	await _wait(0.6)
	var room := current_scene as Room
	var energy := room.get_node("CombatHUD/EnergyBar") as EnergyBar
	_check(energy.cells == 2 and is_equal_approx(energy.energy, 2.0), "la energía empieza con 2 barritas llenas")
	state.set_max_energy_cells(3)
	_check(energy.cells == 3 and is_equal_approx(energy.energy, 3.0), "con la historia suben las barritas (ahora 3)")
	state.set_max_energy_cells(GameState.START_ENERGY_CELLS)
	_check(InputMap.has_action(&"grimorio") and GameSettings.key_name(&"grimorio") == "G", "la tecla del Grimorio es G")
	_action(&"grimorio")
	await _frames(3)
	var screen := root.get_node_or_null("GrimorioLayer/Grimorio") as GrimorioScreen
	_check(screen != null and paused, "G abre el Grimorio y pausa el juego")
	_check(current_scene == room, "la sala sigue debajo del Grimorio")
	_action(&"grimorio")
	await _frames(3)
	_check(root.get_node_or_null("GrimorioLayer") == null and not paused, "G otra vez lo cierra y el juego sigue")


func _action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
