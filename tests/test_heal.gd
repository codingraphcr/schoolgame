extends SceneTree
## Prueba automática: curación con L (energía, tiempos, cancelación, en el suelo y en el aire).
## Ejecutar: godot --headless --path . --script res://tests/test_heal.gd

const ROOM := "res://world/zones/zone0/entrada.tscn"

var _failures := 0
var player: Player
var room: Room


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.get_node("GameState").reset()
	change_scene_to_file(ROOM)
	await _wait(0.8)
	room = current_scene as Room
	player = room.player
	var heal := player.get_node("Heal") as PlayerHeal
	var kai := player.get_node("Visual/Body/Kai") as KaiVisual
	var energy_bar := room.get_node("CombatHUD/EnergyBar") as EnergyBar
	_check(is_equal_approx(player.energy, 2.0) and is_equal_approx(player.max_energy, 2.0), "Kai empieza con 2 barritas de energía")

	# Con la vida llena no se cura.
	Input.action_press("heal")
	await _wait(0.2)
	_check(not heal.active, "con la vida llena, L no hace nada")
	Input.action_release("heal")

	# Curación en el suelo: 1,141 s para la primera; gasta media barrita y devuelve 1,5.
	player.health.current = 1.0
	player.health.health_changed.emit(1.0, player.health.max_health)
	await _wait(0.2)
	Input.action_press("heal")
	await _wait(0.15)
	_check(heal.active and not heal.in_air, "L empieza a curar en el suelo")
	_check(kai.current_animation() == &"curar_suelo_inicio", "Kai se arrodilla (%s)" % kai.current_animation())
	_check(player.velocity == Vector2.ZERO, "Kai se queda quieto mientras se cura")
	await _wait(0.4)
	_check(kai.current_animation() == &"curar_suelo", "después del inicio canaliza (%s)" % kai.current_animation())
	_check(player.health.current == 1.0 and is_equal_approx(player.energy, 2.0), "antes de 1,141 s no cura todavía")
	await _wait(0.7)  # ~1,25 s en total
	_check(is_equal_approx(player.health.current, 2.5) and is_equal_approx(player.energy, 1.5),
		"a los 1,141 s cura 1,5 cristales y gasta media barrita (vida %.1f, energía %.1f)" % [player.health.current, player.energy])
	await _wait(0.9)  # ~2,15 s: segunda curación
	_check(is_equal_approx(player.health.current, 4.0) and is_equal_approx(player.energy, 1.0),
		"manteniendo L, 0,9 s después cura otra vez (vida %.1f, energía %.1f)" % [player.health.current, player.energy])
	_check(not heal.active, "con la vida llena, la curación termina sola")
	Input.action_release("heal")
	await _wait(0.4)
	_check(is_equal_approx(energy_bar.energy, 1.0), "el HUD muestra la energía que queda (%.1f)" % energy_bar.energy)

	# Soltar antes de tiempo cancela sin gastar energía.
	player.health.current = 2.0
	await _wait(0.5)
	Input.action_press("heal")
	await _wait(0.6)
	Input.action_release("heal")
	await _wait(0.1)
	_check(not heal.active and player.health.current == 2.0 and is_equal_approx(player.energy, 1.0),
		"soltar L antes de tiempo cancela y no gasta energía")

	# Sin energía suficiente no se puede curar.
	player.set_energy(0.3)
	Input.action_press("heal")
	await _wait(0.2)
	_check(not heal.active, "sin media barrita de energía no se cura")
	Input.action_release("heal")

	# En el aire: se queda flotando con la otra animación.
	player.set_energy(2.0)
	player.teleport_to(player.global_position + Vector2(0, -60))
	await _frames(2)
	Input.action_press("heal")
	await _wait(0.15)
	var height := player.global_position.y
	_check(heal.active and heal.in_air, "en el aire también se puede curar")
	_check(kai.current_animation() == &"curar_aire_inicio", "con la animación del aire (%s)" % kai.current_animation())
	await _wait(0.5)
	_check(absf(player.global_position.y - height) < 1.0, "Kai se queda flotando mientras se cura")
	_check(kai.current_animation() == &"curar_aire", "y canaliza en el aire (%s)" % kai.current_animation())

	# Un golpe corta la curación.
	var hit := HitData.new()
	hit.damage = 1.0
	player.damage._on_hit_received(hit)
	await _frames(4)
	_check(not heal.active, "un golpe corta la curación (y no vuelve a empezar sin soltar L)")
	Input.action_release("heal")
	await _wait(1.5)
	_check(player.is_on_floor(), "al terminar, Kai vuelve a caer")

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
