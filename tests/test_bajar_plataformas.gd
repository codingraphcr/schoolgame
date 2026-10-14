extends SceneTree
## Prueba automática: con S, parado sobre una plataforma de un solo sentido (un pop-up del SPAM, una
## plataforma de datos), Kai baja a través de ella. Sobre el suelo firme, S no hace nada.
## Ejecutar: godot --headless --path . --script res://tests/test_bajar_plataformas.gd

const PC := "res://world/zones/pc_profesor/escritorio.tscn"
const CHASE := "res://world/zones/red_entrenamiento/persecucion.tscn"

var _failures := 0
var player: Player


func _initialize() -> void:
	Engine.max_physics_steps_per_frame = 1
	Engine.physics_jitter_fix = 0.0
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.reset()
	state.set_flag(&"tutorial_terminado")
	await _open(PC)
	for spawner in current_scene.get_node("SpamMail").get_children():
		spawner.set_process(false)
	await _drop_on(Vector2(700, 190))
	_check(player.is_on_floor() and absf(player.global_position.y - 230.0) < 1.0, "Kai está parado sobre un pop-up (y=%.0f)" % player.global_position.y)
	await _action(&"move_down")
	await _frames(30)
	_check(player.global_position.y > 240.0, "con S baja a través del pop-up (y=%.0f)" % player.global_position.y)
	await _drop_on(Vector2(140, 296))
	var floor_y := player.global_position.y
	await _action(&"move_down")
	await _frames(20)
	_check(player.is_on_floor() and absf(player.global_position.y - floor_y) < 1.0, "sobre el suelo firme, S no hace nada")
	await _open(CHASE)
	await _drop_on(Vector2(800, 232))
	_check(player.is_on_floor() and absf(player.global_position.y - 240.0) < 1.0, "Kai está sobre una plataforma de datos")
	await _action(&"move_down")
	await _frames(30)
	_check(player.global_position.y > 250.0, "con S también baja de una plataforma de datos")
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _open(path: String) -> void:
	change_scene_to_file(path)
	for i in 600:
		await process_frame
		if current_scene is Room and current_scene.scene_file_path == path and current_scene.is_node_ready():
			break
	await _frames(10)
	player = (current_scene as Room).player
	var box := current_scene.get_node_or_null("CombatHUD/DialogueBox") as DialogueBox
	for i in 60:
		if box == null or not box.is_playing():
			break
		await _action(&"interact")
		await _frames(3)


func _drop_on(position: Vector2) -> void:
	player.teleport_to(position)
	for i in 4:
		await physics_frame
	for i in 120:
		await physics_frame
		if player.is_on_floor():
			break
	await _frames(4)


func _action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	await physics_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _frames(count: int) -> void:
	for i in count:
		await process_frame
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])
