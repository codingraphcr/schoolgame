extends SceneTree
## Prueba automática: sonidos. Todos los efectos provisionales se generan; suenan por el bus de
## Efectos; los momentos del juego disparan el sonido que corresponde; las salas piden su música.
## Ejecutar: godot --headless --path . --script res://tests/test_sound.gd

const ROOM := "res://tests/fixtures/combat_test_room.tscn"
const ENEMY := preload("res://characters/enemies/weak_password/weak_password.tscn")

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var bad: Array[StringName] = []
	for id: StringName in Sfx.RECIPES:
		var stream := Sfx.stream_for(id) as AudioStreamWAV
		if stream == null or stream.data.size() < 100:
			bad.append(id)
	_check(bad.is_empty(), "los %d sonidos provisionales se generan %s" % [Sfx.RECIPES.size(), "" if bad.is_empty() else str(bad)])
	await process_frame
	var voice := Sfx.play(&"ui_accept")
	await process_frame
	_check(is_instance_valid(root.get_node_or_null("Sfx")), "el reproductor de sonidos se crea solo")
	_check(voice == null or voice.bus == GameSettings.SFX_BUS, "los efectos suenan por el bus de Efectos (volumen de Opciones)")

	var state := root.get_node("GameState")
	state.reset()
	change_scene_to_file(ROOM)
	await _wait(0.6)
	var room := current_scene as Room
	var player := room.player
	await _until(func() -> bool: return player.is_on_floor())
	Sfx.history.clear()
	Input.action_press("jump")
	await _wait(0.15)
	Input.action_release("jump")
	await _wait(0.5)
	_check(&"jump" in Sfx.history, "saltar suena")
	await _until(func() -> bool: return player.is_on_floor())
	await _frames(3)
	_check(&"land" in Sfx.history, "caer al suelo suena")
	Input.action_press("move_right")
	await _wait(0.6)
	Input.action_release("move_right")
	_check(&"step_school" in Sfx.history, "los pasos suenan al correr")

	Sfx.history.clear()
	player.combat.weapon = load("res://data/weapons/nullblade.tres")
	player.face(1)
	var enemy := ENEMY.instantiate() as EnemyBase
	enemy.ai_enabled = false
	room.add_child(enemy)
	enemy.global_position = player.global_position + Vector2(24, -4)
	await _until(func() -> bool: return enemy.is_on_floor())
	_action("attack")
	await _until(func() -> bool: return player.combat.is_attacking())
	await _until(func() -> bool: return not player.combat.is_attacking())
	await _frames(3)
	_check(&"slash" in Sfx.history and &"hit" in Sfx.history and &"enemy_hit" in Sfx.history, "el tajo, el golpe y el enemigo herido suenan")
	enemy.health.take_damage(99)
	await _frames(3)
	_check(&"enemy_death" in Sfx.history, "la desintegración del enemigo suena")
	await _wait(0.5)
	for coin in room.get_children():
		if coin is BitCoin:
			player.teleport_to(coin.global_position)
			break
	await _wait(0.6)
	_check(&"bit_pickup" in Sfx.history, "recoger BITS suena")

	Sfx.history.clear()
	player.health.current = 2.0
	Input.action_press("heal")
	await _wait(1.3)
	Input.action_release("heal")
	_check(&"heal_charge" in Sfx.history and &"heal_done" in Sfx.history, "la curación suena al cargar y al curar")
	var hit := HitData.new()
	hit.damage = 1.0
	player.damage._on_hit_received(hit)
	await _frames(2)
	_check(&"hurt" in Sfx.history and &"crystal_crack" in Sfx.history, "recibir daño suena (con el crujido del cristal)")

	change_scene_to_file("res://world/zones/pc_profesor/escritorio.tscn")
	await _wait(0.8)
	_check(Music.current == &"computadora", "la computadora pide su música")
	var ambient := Music.stream_for(&"computadora") as AudioStreamWAV
	_check(ambient != null and ambient.loop_mode == AudioStreamWAV.LOOP_FORWARD, "la música provisional de la computadora existe y se repite")
	_check((current_scene as Room).footstep == &"step_digital", "dentro de la computadora los pasos son digitales")

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


func _until(condition: Callable) -> void:
	for i in 600:
		if condition.call():
			return
		await process_frame
		await physics_frame


func _frames(count: int) -> void:
	for i in count:
		await process_frame
		await physics_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
