class_name DigitalChaseController
extends Node
## La persecución digital del Capítulo 1: une la barrera de corrupción, los tres checkpoints
## educativos, el temporizador y las caídas. Los valores están en un ChaseConfig (data/chase/).
##
## - Cada tramo empieza cuando Kai cruza tramo_starts[i]: la barrera arranca detrás de él y el
##   temporizador corre. Al llegar a la zona segura del tramo, la barrera se detiene y el tiempo
##   también; la pregunta del checkpoint pausa el juego (Kai no recibe daño).
## - Respuesta incorrecta: −wrong_answer_penalty segundos (nunca por debajo de
##   min_seconds_after_penalty). Correcta: marca «cap1_checkpoint_N», se abre la puerta, se guarda
##   la partida en la entrada del checkpoint y se prepara el siguiente tramo.
## - Tiempo agotado o muerte: Kai vuelve al último checkpoint (o al inicio) con el mayor tiempo
##   entre el que tenía al pasarlo y retry_seconds del tramo: nunca un reintento imposible.
## - Al cargar la partida, los checkpoints hechos no se repiten.
## - Después del tercero, la barrera se apaga para siempre y el temporizador desaparece.
## El tiempo corre con la física (como Kai), así da igual si la computadora va lenta.

signal tramo_started(index: int)
signal time_up
signal finished

const QUEST := &"travesuras_en_el_sistema"

@export var config: ChaseConfig
@export var barrier: CorruptionBarrier
## Los checkpoints en orden (tramo 1, 2 y 3).
@export var checkpoints: Array[EducationalCheckpoint] = []
## x global donde empieza cada tramo (al cruzarla arranca la barrera).
@export var tramo_starts: PackedFloat32Array = []
## Dónde reaparece Kai si muere antes del primer checkpoint.
@export var start_marker: Node2D
## Lo que pasa al llegar por primera vez (Chip y Glitch se dan cuenta de que Kai los siguió).
@export var start_dialogue: Dialogue

## Tramo actual (0, 1, 2; 3 = terminó).
var tramo := 0
var time_left := 0.0
## Si el tramo actual ya empezó (Kai cruzó su línea).
var running := false
## Si el temporizador está detenido (zona segura).
var paused := false
## Tiempo que quedaba al pasar el último checkpoint (para los reintentos).
var snapshot := 0.0

var _room: Room
var _timer: ChaseTimer


func _ready() -> void:
	_room = get_parent() as Room
	var state := get_node("/root/GameState")
	_room.fall_damage = config.fall_damage
	barrier.damage = config.barrier_damage
	barrier.knockback = config.barrier_knockback
	_timer = ChaseTimer.create(_room.get_node("CombatHUD"))
	for checkpoint in checkpoints:
		checkpoint.reached.connect(_on_reached)
		checkpoint.wrong_answer.connect(_on_wrong_answer)
		checkpoint.solved.connect(_on_solved)
	# Los checkpoints hechos no se repiten.
	tramo = 0
	for i in checkpoints.size():
		if state.has_flag(flag_of(i)):
			tramo = i + 1
			checkpoints[i].done = true
			if checkpoints[i].gate:
				checkpoints[i].gate.active = false
	for i in range(tramo, checkpoints.size()):
		if checkpoints[i].gate:
			checkpoints[i].gate.active = true
	if tramo > 0:
		_room.checkpoint = checkpoints[tramo - 1]
	elif start_marker:
		_room.checkpoint = start_marker
	time_left = config.start_seconds if tramo == 0 else retry_time(tramo)
	snapshot = time_left
	_room.player_respawned.connect(_on_player_respawned)
	# Llegar a la red de entrenamiento cumple «sigue a Chip y Glitch adentro».
	if state.get_current_step(QUEST) == &"seguirlos_adentro":
		state.complete_step(QUEST, &"seguirlos_adentro")
		if start_dialogue:
			StoryHelper.say.call_deferred(self, start_dialogue)
	if tramo >= checkpoints.size():
		_finish()
	else:
		_prepare_tramo()


func _physics_process(delta: float) -> void:
	if tramo >= checkpoints.size():
		return
	var player := _room.player
	if not running and player.global_position.x >= tramo_starts[tramo]:
		running = true
		paused = false
		barrier.start()
		tramo_started.emit(tramo)
	if not running:
		return
	if player.global_position.x >= checkpoints[tramo].safe_from_x:
		# Zona segura: se detienen la barrera y el tiempo.
		if not paused:
			paused = true
			barrier.halt()
		return
	if paused:
		# Volvió al tramo antes de responder: todo sigue.
		paused = false
		barrier.start()
	if player.damage.is_respawning:
		return
	time_left -= delta
	_timer.show_seconds(time_left)
	if time_left <= 0.0:
		_on_time_up()


## Marca de un checkpoint hecho (i = 0, 1, 2).
static func flag_of(index: int) -> StringName:
	return StringName("cap1_checkpoint_%d" % (index + 1))


## Tiempo para reintentar el tramo i.
func retry_time(index: int) -> float:
	var minimum: float = config.retry_seconds[mini(index, config.retry_seconds.size() - 1)] if not config.retry_seconds.is_empty() else config.start_seconds
	return maxf(snapshot, minimum)


func _prepare_tramo() -> void:
	running = false
	paused = false
	var start_x := tramo_starts[tramo]
	barrier.place(start_x - config.barrier_start_gap, config.barrier_speeds[mini(tramo, config.barrier_speeds.size() - 1)], checkpoints[tramo].safe_from_x)
	_timer.visible = true
	_timer.show_seconds(time_left)


func _on_reached(_checkpoint: EducationalCheckpoint) -> void:
	paused = true
	barrier.halt()
	_timer.show_seconds(time_left)


func _on_wrong_answer(_checkpoint: EducationalCheckpoint) -> void:
	var before := time_left
	time_left = maxf(time_left - config.wrong_answer_penalty, minf(before, config.min_seconds_after_penalty))
	_timer.show_seconds(time_left)
	_timer.show_penalty(before - time_left)


func _on_solved(checkpoint: EducationalCheckpoint) -> void:
	var index := checkpoints.find(checkpoint)
	var state := get_node("/root/GameState")
	state.set_flag(flag_of(index))
	if checkpoint.gate:
		checkpoint.gate.active = false
	_room.checkpoint = checkpoint
	_room.arrival_entry = checkpoint.entry_id
	snapshot = time_left
	tramo = index + 1
	# Se guarda el progreso en la entrada del checkpoint (al cargar, aparece ahí).
	var saves := get_node_or_null("/root/SaveManager")
	if saves and saves.active_slot > 0 and checkpoint.entry_id != &"":
		saves.save_game(_room.scene_file_path, checkpoint.entry_id)
	if tramo >= checkpoints.size():
		_finish()
	else:
		_prepare_tramo()


func _on_time_up() -> void:
	running = false
	barrier.halt()
	time_up.emit()
	get_tree().call_group(&"toast", &"show_message", "¡Se acabó el tiempo! Vuelves al último checkpoint.", 2.5)
	var player := _room.player
	player.controls_locked = true
	await get_node("/root/SceneManager").transition(func() -> void:
		var target: Node2D = _room.checkpoint if _room.checkpoint else start_marker
		if target:
			player.teleport_to(target.global_position)
		player.velocity = Vector2.ZERO)
	player.controls_locked = false
	_retry()


func _on_player_respawned() -> void:
	_retry()


func _retry() -> void:
	if tramo >= checkpoints.size():
		return
	time_left = retry_time(tramo)
	_prepare_tramo()


func _finish() -> void:
	running = false
	paused = true
	barrier.disable()
	_timer.visible = false
	finished.emit()
