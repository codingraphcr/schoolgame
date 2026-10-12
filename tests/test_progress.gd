extends SceneTree
## Prueba automática: progreso del jugador en GameState, Ecos (Economy), penalización al morir,
## guardado (también de partidas viejas con «créditos») y aplicación del progreso en una sala.
## Ejecutar: godot --headless --path . --script res://tests/test_progress.gd

const ROOM := "res://tests/fixtures/combat_test_room.tscn"

var _failures := 0
var state: Node
var economy: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	economy = root.get_node("Economy")
	_test_defaults_and_ecos()
	_test_death_penalty()
	_test_limits()
	_test_save_and_load()
	await _test_room_applies_progress()

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_defaults_and_ecos() -> void:
	state.reset()
	_check(economy.ecos == 0 and state.max_masks == 4, "partida nueva: 0 Ecos y 4 máscaras")
	_check(state.dash_level == 0 and not state.can_double_jump and not state.can_wall_jump, "partida nueva: sin dash, doble salto ni pared")
	_check(state.nullblade_stage == 0 and state.aegis_stage == 0 and state.domain_stage == 0, "partida nueva: sin Nullblade, Aegis ni Dominio")
	_check(state.budget == state.START_BUDGET, "los Ecos no tocan el presupuesto del colegio")

	_check(economy.add_ecos(105) and economy.ecos == 105, "ganar Ecos")
	_check(not economy.add_ecos(0) and not economy.add_ecos(-50) and economy.ecos == 105, "no se pueden sumar cantidades inválidas")
	_check(not economy.spend_ecos(200) and economy.ecos == 105, "no se puede gastar más de lo que se tiene")
	_check(not economy.spend_ecos(-5) and not economy.spend_ecos(0) and economy.ecos == 105, "ni gastar cantidades inválidas")
	_check(economy.can_afford_ecos(105) and not economy.can_afford_ecos(106) and not economy.can_afford_ecos(-1), "saber si alcanza")
	_check(economy.spend_ecos(5) and economy.ecos == 100, "gastar Ecos")
	state.reset()
	_check(economy.ecos == 0, "una partida nueva reinicia los Ecos")


func _test_death_penalty() -> void:
	state.reset()
	economy.add_ecos(500)
	_check(economy.apply_death_penalty() == 0 and economy.ecos == 500, "durante el tutorial no se pierden Ecos al morir")
	state.set_flag(economy.TUTORIAL_DONE_FLAG)
	_check(economy.apply_death_penalty() == 50 and economy.ecos == 450, "después del tutorial, morir quita el 10 % (500 → 450)")
	economy.add_ecos(1550)
	_check(economy.apply_death_penalty() == 100 and economy.ecos == 1900, "como máximo se pierden 100 (2000 → 1900)")
	_check(economy.death_penalty_for(109) == 10 and economy.death_penalty_for(9) == 0, "se redondea hacia abajo (109 → pierde 10; 9 → 0)")
	state.reset()
	state.set_flag(economy.TUTORIAL_DONE_FLAG)
	_check(economy.apply_death_penalty() == 0 and economy.ecos == 0, "morir sin Ecos no deja números negativos")
	state.reset()


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
	economy.add_ecos(321)
	state.set_dash_level(2)
	state.unlock_wall_jump()
	state.set_nullblade_stage(3)
	state.set_domain_stage(1)
	state.set_max_masks(6)
	var json := JSON.stringify(state.to_dict())
	state.reset()
	state.from_dict(JSON.parse_string(json))
	_check(economy.ecos == 321 and state.dash_level == 2 and state.can_wall_jump and not state.can_double_jump,
		"guardar/cargar: Ecos y habilidades")
	_check(state.nullblade_stage == 3 and state.domain_stage == 1 and state.aegis_stage == 0 and state.max_masks == 6,
		"guardar/cargar: evoluciones y máscaras")
	var old_save: Dictionary = state.to_dict()
	old_save.erase("player")
	old_save.erase("economy")  # Las partidas antiguas no tenían Ecos.
	state.from_dict(old_save)
	_check(economy.ecos == 0 and state.dash_level == 0, "una partida antigua sin progreso carga los valores iniciales")
	# Partida guardada antes de los Ecos: tenía «créditos» en el jugador.
	var legacy: Dictionary = state.to_dict()
	legacy.erase("economy")
	legacy["player"]["credits"] = 77
	state.from_dict(legacy)
	_check(economy.ecos == 77, "una partida vieja convierte sus «créditos» en Ecos")
	state.reset()


func _test_room_applies_progress() -> void:
	state.reset()
	state.set_flag(economy.TUTORIAL_DONE_FLAG)
	economy.add_ecos(42)
	state.set_dash_level(1)
	state.set_max_masks(5)

	change_scene_to_file(ROOM)
	await _frames(30)
	var room: Room = current_scene
	var player := room.player
	_check(player.dash_level == 1 and not player.can_double_jump and not player.can_wall_jump,
		"la sala aplica el progreso: solo lo adquirido (dash 1, sin doble salto ni pared)")
	_check(player.health.max_health == 5.0 and player.health.current == 5.0, "y las máscaras máximas, llenas al entrar")
	_check(room.get_node("CombatHUD/Masks").get_child_count() == 5, "el HUD muestra 5 máscaras")
	_check(room.get_node("CombatHUD/Ecos")._amount.text == "42", "el HUD muestra los Ecos")

	state.set_dash_level(2)
	state.unlock_double_jump()
	await _frames(2)
	_check(player.dash_level == 2 and player.can_double_jump, "un desbloqueo se aplica al jugador en vivo")

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
	_check(economy.ecos == 38, "morir quita el 10 %% de los Ecos (42 → %d)" % economy.ecos)
	await create_timer(1.2, true, false, true).timeout
	_check(room.get_node("CombatHUD/Ecos")._amount.text == "38", "el HUD actualiza los Ecos")
	_check(player.health.current == 5.0, "reaparece con las máscaras llenas")
	state.reset()


func _frames(count: int) -> void:
	for i in count:
		await process_frame  # Teclas y HUD se procesan en cuadros de dibujo.
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
