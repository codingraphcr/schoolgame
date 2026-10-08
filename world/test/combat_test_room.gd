extends Room
## Sala de pruebas y desarrollo del prototipo de combate.
## Abre una sesión de desarrollo: todo queda desbloqueado temporalmente y, al salir de la sala,
## se restaura la partida real (las habilidades de capítulos posteriores se prueban aquí sin
## desbloquearlas en la historia). Esc vuelve al menú (temporal, hasta que exista la pausa).
##
## Teclas de desarrollo (también se muestran en el panel F3):
## 1 nivel del dash · 2 Nullblade · 3 Aegis · 4 Dominio Nulo · 5 doble salto · 6 pared
## 7 +100 créditos · 8 llenar máscaras · 9 máscaras máximas (4 a 8)


func _ready() -> void:
	GameState.begin_dev_session()
	super()


func _exit_tree() -> void:
	GameState.end_dev_session()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		SceneManager.change_scene(SceneManager.MAIN_MENU)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_1:
			GameState.set_dash_level((GameState.dash_level + 1) % (GameState.MAX_DASH_LEVEL + 1))
		KEY_2:
			GameState.set_nullblade_stage((GameState.nullblade_stage + 1) % (GameState.MAX_NULLBLADE_STAGE + 1))
		KEY_3:
			GameState.set_aegis_stage((GameState.aegis_stage + 1) % (GameState.MAX_AEGIS_STAGE + 1))
		KEY_4:
			GameState.set_domain_stage((GameState.domain_stage + 1) % (GameState.MAX_DOMAIN_STAGE + 1))
		KEY_5:
			GameState.unlock_double_jump(not GameState.can_double_jump)
		KEY_6:
			GameState.unlock_wall_jump(not GameState.can_wall_jump)
		KEY_7:
			GameState.add_credits(100)
		KEY_8:
			player.health.restore_full()
		KEY_9:
			GameState.set_max_masks(4 if GameState.max_masks >= 8 else GameState.max_masks + 1)
		_:
			return
	get_viewport().set_input_as_handled()
