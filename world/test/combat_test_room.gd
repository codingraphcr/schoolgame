extends Room
## Sala de pruebas del prototipo de combate. Esc vuelve al menú principal
## (temporal, hasta que exista el menú de pausa).


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		SceneManager.change_scene(SceneManager.MAIN_MENU)
