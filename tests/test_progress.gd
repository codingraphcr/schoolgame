extends SceneTree
## Prueba automática: progreso del jugador en GameState, créditos, penalización al morir,
## guardado y sesión de desarrollo de la sala de pruebas.
## Ejecutar: godot --headless --path . --script res://tests/test_progress.gd

const ROOM := "res://world/test/combat_test_room.tscn"
const MENU := "res://ui/menus/main_menu/main_menu.tscn"

var _failures := 0
var state: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	_test_defaults_and_credits()
	_test_limits()
	_test_save_and_load()
	await _test_dev_session()

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_defaults_and_credits() -> void:
	state.reset()
	_check(state.credits == 0 and state.max_masks == 4, "partida nueva: 0 créditos y 4 máscaras")
	_check(state.dash_level == 0 and not state.can_double_jump and not state.can_wall_jump, "partida nueva: sin dash, doble salto ni pared")
	_check(state.nullblade_stage == 0 and state.aegis_stage == 0 and state.domain_stage == 0, "partida nueva: sin Nullblade, Aegis ni Dominio")
	_check(state.budget == state.START_BUDGET, "los créditos no tocan el presupuesto del colegio")

	state.add_credits(105)
	_check(state.credits == 105, "ganar créditos")
	_check(not state.spend_credits(200) and state.credits == 105, "no se puede gastar más de lo que se tiene")
	_check(state.spend_credits(5) and state.credits == 100, "gastar créditos")
	state.add_credits(5)
	var lost: int = state.apply_death_penalty()
	_check(lost == 10 and state.credits == 95, "morir quita el 10 %% (105 → 95, perdió %d)" % lost)
	state.reset()
	_check(state.apply_death_penalty() == 0 and state.credits == 0, "morir sin créditos no deja números negativos")


func _test_limits() -> void:
	state.reset()
	state.set_dash_level(7)
	state.set_nullblade_stage(9)
	state.set_aegis_stage(-2)
	state.set_domain_stage(5)
	_check(state.dash_level == 3 and state.nullblade_stage == 4 and state.aegis_stage == 0 and state.domain_stage == 3,
		"los niveles y etapas se limitan a sus rangos")
	state.reset()


func _test_save_and_load() -> void:
	state.reset()
	state.add_credits(321)
	state.set_dash_level(2)
	state.unlock_wall_jump()
	state.set_nullblade_stage(3)
	state.set_domain_stage(1)
	state.set_max_masks(6)
	var json := JSON.stringify(state.to_dict())
	state.reset()
	state.from_dict(JSON.parse_string(json))
	_check(state.credits == 321 and state.dash_level == 2 and state.can_wall_jump and not state.can_double_jump,
		"guardar/cargar: créditos y habilidades")
	_check(state.nullblade_stage == 3 and state.domain_stage == 1 and state.aegis_stage == 0 and state.max_masks == 6,
		"guardar/cargar: evoluciones y máscaras")
	var old_save: Dictionary = state.to_dict()
	old_save.erase("player")
	state.from_dict(old_save)
	_check(state.credits == 0 and state.dash_level == 0, "una partida antigua sin progreso carga los valores iniciales")
	state.reset()


func _test_dev_session() -> void:
	# Progreso "real" de la historia antes de entrar a la sala de desarrollo.
	state.reset()
	state.add_credits(42)
	state.set_dash_level(1)

	change_scene_to_file(ROOM)
	await _frames(30)
	var room: Room = current_scene
	var player := room.player
	_check(state.is_dev_session, "la sala de pruebas abre una sesión de desarrollo")
	_check(player.dash_level == 2 and player.can_double_jump and player.can_wall_jump, "en la sesión todo está desbloqueado y aplicado al jugador")
	_check(state.credits == 500, "la sesión da créditos de prueba")

	state.set_dash_level(3)
	state.set_max_masks(5)
	await _frames(2)
	_check(player.dash_level == 3, "un cambio de progreso se aplica al jugador en vivo")
	_check(player.health.max_health == 5.0 and room.get_node("CombatHUD/Masks").get_child_count() == 5, "más máscaras: el jugador y el HUD se actualizan")
	state.set_max_masks(4)

	var killer := HitboxComponent.new()
	killer.collision_layer = 16
	killer.collision_mask = 0
	killer.damage = 10.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 40)
	shape.shape = rect
	killer.add_child(shape)
	room.add_child(killer)
	killer.global_position = player.global_position + Vector2(0, -10)
	await _frames(6)
	killer.queue_free()
	_check(state.credits == 450, "morir en la sesión quita el 10 %% de los créditos (500 → %d)" % state.credits)
	await create_timer(1.2, true, false, true).timeout
	_check(room.get_node("CombatHUD/Credits")._amount.text == "450", "el HUD muestra los créditos actuales")

	change_scene_to_file(MENU)
	await _frames(10)
	_check(not state.is_dev_session, "al salir de la sala termina la sesión de desarrollo")
	_check(state.credits == 42 and state.dash_level == 1 and not state.can_wall_jump and state.max_masks == 4,
		"y se restaura el progreso real de la historia")


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
