class_name CoreDefense
extends Node2D
## La estabilización del núcleo de Aegis (etapa 3 de «Eco en la Red», Capítulo 3), hijo de la sala. Con los tres
## módulos, Kai instala todo (start): empieza el procedimiento y aparecen Bitcucarachas en oleadas chicas (waves) que
## corren hacia el núcleo. Si una llega, el núcleo pierde estabilidad; si la estabilidad se acaba, la oleada vuelve a
## empezar (sin castigo: no hay derrota). Entre la primera y las demás, Kai y Aegis discuten (alarm_dialogue). Al
## terminar la última oleada: el núcleo se ilumina, queda STABLE_FLAG y se completa step_id. El origen es el núcleo.

signal wave_started(index: int)
signal finished

const STABLE_FLAG := &"aegis_nucleo_estable"
const CYAN := Color("3ef2ff")

@export var waves: PackedInt32Array = [4, 6, 6]
## Dónde salen (x de las rejillas de ventilación, en coordenadas de la sala).
@export var spawn_x: PackedFloat32Array = [40.0, 920.0]
@export var spawn_y := 300.0
@export var alarm_dialogue: Dialogue
@export var stable_dialogue: Dialogue
@export var quest_id: StringName = &"eco_en_la_red"
@export var step_id: StringName = &"estabilizar_nucleo"
@export var spawn_every := 0.9
@export var quick := false

var running := false
var wave := -1
var stability := 100.0
var _alive: Array[Node] = []
var _restarting := false
var _clock := 0.0


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func is_stable() -> bool:
	return get_node("/root/GameState").has_flag(STABLE_FLAG)


## Empieza el procedimiento (Kai instaló los tres módulos).
func start() -> void:
	if running or is_stable():
		return
	running = true
	wave = -1
	await _next_wave()


func _next_wave() -> void:
	wave += 1
	if wave >= waves.size():
		await _finish()
		return
	stability = 100.0
	wave_started.emit(wave)
	if wave == 0:
		await _spawn(1)
		await StoryHelper.say(self, alarm_dialogue)
		await _spawn(waves[0] - 1)
	else:
		await _spawn(waves[wave])


func _spawn(count: int) -> void:
	for i in count:
		var bug := Bitcucaracha.new()
		var room := get_parent()
		room.add_child(bug)
		bug.global_position = Vector2(spawn_x[i % spawn_x.size()], spawn_y)
		bug.target_x = global_position.x
		bug.reached_core.connect(_on_reached)
		bug.died.connect(_on_bug_gone.bind(bug))
		bug.tree_exited.connect(_on_bug_gone.bind(bug))
		_alive.append(bug)
		await get_tree().create_timer(spawn_every * (0.2 if quick else 1.0), false, true).timeout


func _on_reached(_bug: Node) -> void:
	stability = maxf(stability - 25.0, 0.0)
	Sfx.play(&"error")
	if stability <= 0.0 and not _restarting:
		# El núcleo se desestabiliza: la oleada vuelve a empezar (no hay derrota).
		_restarting = true
		var bugs := _alive.duplicate()
		_alive.clear()
		for bug in bugs:
			if is_instance_valid(bug):
				bug.queue_free()
		get_tree().call_group(&"toast", &"show_message", "El núcleo se desestabilizó: ¡otra vez!", 2.0)
		wave -= 1
		await get_tree().create_timer(0.6, false, true).timeout
		_restarting = false
		await _next_wave()


func _on_bug_gone(bug: Node) -> void:
	if not running or _restarting or not _alive.has(bug):
		return
	_alive.erase(bug)
	if _alive.is_empty():
		await get_tree().create_timer(0.3 if quick else 1.0, false, true).timeout
		if _alive.is_empty() and running:
			await _next_wave()


func _finish() -> void:
	running = false
	var state := get_node("/root/GameState")
	state.set_flag(STABLE_FLAG)
	Sfx.play(&"reveal_flash")
	await StoryHelper.say(self, stable_dialogue)
	state.complete_step(quest_id, step_id)
	finished.emit()


func _draw() -> void:
	# El núcleo de la estación: una columna con un anillo que se llena de azul al estabilizarse.
	var stable := is_stable()
	draw_rect(Rect2(-26, -120, 52, 120), Color("dfe6f0"))
	draw_rect(Rect2(-26, -120, 52, 120), Color("3a8adf"), false, 2.0)
	var pulse := 0.5 + 0.5 * sin(_clock * 3.0)
	var color := CYAN if stable else Color(1, 0.4 + 0.3 * pulse, 0.3)
	draw_circle(Vector2(0, -70), 16.0, Color(color, 0.3))
	draw_circle(Vector2(0, -70), 9.0, color)
	if running:
		draw_rect(Rect2(-40, -140, 80, 6), Color("2a3048"))
		draw_rect(Rect2(-40, -140, 80 * stability / 100.0, 6), CYAN if stability > 40.0 else Color("ff6a6a"))
		draw_string(ThemeDB.fallback_font, Vector2(-50, -146), "ESTABILIDAD", HORIZONTAL_ALIGNMENT_CENTER, 100, 8, Color("c8d0e0"))
