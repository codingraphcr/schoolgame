extends SceneTree
## Prueba automática: Visión Digital controlada con Q (bloqueo, desbloqueo, duración, recarga,
## puente de datos, fragmento oculto y capa digital) en el Pasillo + Laboratorio.
## La visión involuntaria del prólogo se prueba en test_prologue.gd.
## Ejecutar: godot --headless --path . --script res://tests/test_vision.gd

const PASILLO := "res://world/zones/zone0/pasillo_laboratorio.tscn"
const ABOVE_BRIDGE := Vector2(600, 130)  # El puente de datos está en y=148
const FRAGMENT := Vector2(640, 148)
const FRAGMENT_FLAG := &"zona0_fragmento_recogido"

var _failures := 0
var _denied: Array[StringName] = []
var state: Node
var vision: Node
var room: Room
var player: Player


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	vision = root.get_node("DigitalVision")
	vision.denied.connect(func(reason: StringName, _s: float) -> void: _denied.append(reason))
	# Tiempos cortos para la prueba (en el juego: 10 s y 16 s).
	vision.duration = 3.0
	vision.cooldown = 1.0

	state.reset()
	vision.reset()
	change_scene_to_file(PASILLO)
	await _wait(0.5)
	room = current_scene as Room
	player = room.player

	await _test_locked()
	await _test_unlocked()
	await _test_bridge_and_fragment()
	await _test_recharge_and_duration()

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_locked() -> void:
	_check(not state.vision_unlocked, "partida nueva: la Visión Digital no está descubierta")
	_action("vision")
	await _until(func() -> bool: return _denied.has(&"locked"))
	await _frames(3)
	_check(not vision.is_active() and _denied.has(&"locked"), "Q no hace nada antes de descubrirla")
	_check(not room.get_node("CombatHUD/VisionMeter").visible, "el indicador está oculto mientras no se descubre")
	_check(not room.get_node("DigitalLayer/Network").visible, "la capa digital está oculta")


func _test_unlocked() -> void:
	# En la historia se desbloquea al terminar la misión de la contraseña del profesor.
	state.unlock_vision()
	await _until(func() -> bool: return room.get_node("CombatHUD/VisionMeter").visible)
	_check(room.get_node("CombatHUD/VisionMeter").visible, "al desbloquearla aparece el indicador de la Visión Digital")
	_action("vision")
	await _until(func() -> bool: return vision.is_active() and vision.blend > 0.9)
	_check(vision.is_active() and not vision.involuntary, "Q enciende la Visión Digital")
	_check(room.get_node("DigitalLayer/Network").visible and vision.blend > 0.9, "se ve la red (capa digital)")
	var ambient := room.get_node("Ambient") as CanvasModulate
	await _until(func() -> bool: return ambient.color.v < 0.5)
	_check(ambient.color.v < 0.5, "el mundo físico se oscurece")
	_check(player.get_collision_mask_value(7), "Kai puede pisar el mundo digital (capa 7)")


func _test_bridge_and_fragment() -> void:
	vision.time_left = vision.duration  # Tiempo completo para esta parte
	player.teleport_to(ABOVE_BRIDGE)
	await _frames(2)  # El "en el suelo" del cuadro anterior todavía no se actualizó.
	await _until_on_floor()
	_check(absf(player.global_position.y - 148.0) < 1.0, "con la visión activa, el puente de datos sostiene a Kai (y=%.0f)" % player.global_position.y)
	var credits_before: int = state.credits
	player.teleport_to(FRAGMENT)
	await _frames(10)
	_check(state.has_flag(FRAGMENT_FLAG) and state.credits == credits_before + 25, "recoger el fragmento da 25 créditos y queda marcado")
	_check(room.get_node("CombatHUD/Toast").text.contains("fragmento"), "aparece el mensaje del fragmento")

	_action("vision")
	await _wait(0.8)
	_check(not vision.is_active() and vision.state == vision.State.RECHARGING, "Q la apaga antes de tiempo y empieza la recarga")
	_check(not player.get_collision_mask_value(7) and player.global_position.y > 160.0,
		"sin la visión, el puente desaparece y Kai cae (y=%.0f)" % player.global_position.y)
	_check(not room.get_node("DigitalLayer/Network").visible, "la capa digital se oculta")


func _test_recharge_and_duration() -> void:
	_denied.clear()
	_action("vision")
	await _frames(3)
	_check(not vision.is_active() and _denied.has(&"recharging"), "mientras recarga, Q no la enciende")
	_check(room.get_node("CombatHUD/Toast").text.contains("recargando"), "avisa que se está recargando")
	await _wait(1.2)
	_check(vision.state == vision.State.READY, "termina de recargar")
	var credits_before: int = state.credits
	_action("vision")
	await _frames(3)
	_check(vision.is_active(), "lista: Q la vuelve a encender")
	player.teleport_to(FRAGMENT)
	await _frames(10)
	_check(state.credits == credits_before, "el fragmento no se puede recoger dos veces")
	await _until(func() -> bool: return not vision.is_active())
	_check(not vision.is_active() and vision.state == vision.State.RECHARGING, "se apaga sola al terminar su duración")


func _action(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


func _until_on_floor() -> void:
	for i in 120:
		await physics_frame
		if player.is_on_floor():
			return


## Espera (en cuadros de física) a que se cumpla la condición, hasta unos 10 s de juego.
func _until(condition: Callable) -> void:
	for i in 600:
		if condition.call():
			return
		await process_frame
		await physics_frame


func _frames(count: int) -> void:
	for i in count:
		await process_frame  # Teclas y HUD se procesan en cuadros de dibujo.
		await physics_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
