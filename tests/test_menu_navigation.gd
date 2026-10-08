extends SceneTree
## Prueba automática: navegación del menú principal.
## Ejecutar: godot --headless --path . --script res://tests/test_menu_navigation.gd

const MAIN_MENU := "res://ui/menus/main_menu/main_menu.tscn"

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file(MAIN_MENU)
	await _wait(0.5)
	_expect_scene("MainMenu")

	_press("SettingsButton")
	await _wait(1.0)
	_expect_scene("SettingsScreen")

	_press("BackButton")
	await _wait(1.0)
	_expect_scene("MainMenu")

	_press("PlayButton")
	await _wait(1.0)
	_expect_not_scene("MainMenu")

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _press(unique_name: String) -> void:
	var button: Button = current_scene.get_node("%" + unique_name)
	button.pressed.emit()


func _expect_scene(scene_name: String) -> void:
	var actual := String(current_scene.name) if current_scene else "null"
	_check(actual == scene_name, "escena esperada=%s actual=%s" % [scene_name, actual])


func _expect_not_scene(scene_name: String) -> void:
	var actual := String(current_scene.name) if current_scene else "null"
	_check(current_scene != null and actual != scene_name, "se salió de %s (actual=%s)" % [scene_name, actual])


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
