class_name BucleArenaController
extends Node
## El combate contra Bucle (Capítulo 2, nivel 4 · Código fuera de control) y su cierre. Ver
## docs/jefes/BUCLE_INFINITO.md. Sin límite de tiempo.
##
## - Al llegar se registra el checkpoint (como la arena de Chip y Glitch) y la puerta se cierra.
## - Introducción, la barra «BUCLE» con siete segmentos (los impactos clave) y el combate (BucleBoss).
## - Golpe arriesgado (mientras ataca): Kai recibe energía (risky_energy).
## - Error de ejecución: apaga una o dos plataformas unos segundos (rotando; siempre queda una de essential:
##   la ruta al puente).
## - Cada impacto: el fondo cambia con la etapa de Bucle (background.stage).
## - Si Kai pierde, reaparece en la entrada y el combate vuelve a empezar (ciclo 1, sin introducción).
## - Final: diálogo, recompensa única, Bucle liberado (no muere: queda en la arena), el puzle de la
##   condición de salida (simulado), la pista «arquitectura reconocida» y la salida abierta. (En esta pelea
##   no se obtiene el Dominio Nulo I: se consigue más adelante.)

signal fight_started
signal victory

enum Phase { WAITING, INTRO, FIGHT, CLOSING, DONE }

const DONE_FLAG := &"cap2_bucle_vencido"
## Bucle queda libre (podrá volver como personaje secundario).
const FREED_FLAG := &"cap2_bucle_liberado"
const PUZZLE_FLAG := &"cap2_condicion_corregida"
const REWARD_ID := &"capitulo2:bucle"
## Kai terminó todo en el simulador (el puzle y la pista): la conexión del laboratorio se cierra.
const FINISHED_FLAG := &"cap2_simulador_terminado"
## La misión del nivel 4 (paso vencer_bucle).
const QUEST := &"codigo_fuera_de_control"
## Pista de la Biblia (capítulo 2): «Una anomalía reconoce su arquitectura digital». No se explica.
const ANOMALY_LINES: PackedStringArray = ["ANOMALÍA DETECTADA", "ARQUITECTURA DIGITAL: RECONOCIDA", "ORIGEN: [SIN DATOS]"]
const ANOMALY_FLAG := &"cap2_anomalia_vista"

@export var boss: BucleBoss
@export var gate: ArenaBarrier
## La otra salida (la del laboratorio, a la derecha): también se cierra durante la pelea.
@export var exit_gate: ArenaBarrier
## Plataformas que el Error de ejecución puede apagar (en orden, rotando).
@export var platforms: Array[DataPlatform] = []
## De estas siempre queda por lo menos una encendida (las de los costados: por ahí se sube al puente).
@export var essential: Array[DataPlatform] = []
## Fondo de la arena (si tiene la propiedad stage, cambia con la transformación).
@export var background: Node2D
@export var intro_dialogue: Dialogue
@export var closing_dialogue: Dialogue
@export var exit_challenge: ChoiceChallenge
@export var after_puzzle_dialogue: Dialogue
## Kai, después del mensaje «arquitectura reconocida».
@export var anomaly_dialogue: Dialogue
## Entrada donde se guarda la partida al llegar (el checkpoint de la arena).
@export var entry_id: StringName = &"inicio"
## Saltear diálogos y el puzle (solo pruebas).
@export var skip_cinematics := false

var phase := Phase.WAITING

var _room: Room
var _bar: BossBar
var _error_index := 0
## Avisos ya mostrados (tareas pendientes, copias).
var _hints: Array[StringName] = []


func _ready() -> void:
	_room = get_parent() as Room
	boss.ai_enabled = false
	boss.key_hit.connect(_on_key_hit)
	boss.transformed.connect(_on_transformed)
	boss.execution_error.connect(_on_execution_error)
	boss.tasks_spawned.connect(_on_tasks_spawned)
	boss.condition_broken.connect(_on_condition_broken)
	boss.copies_spawned.connect(_on_copies_spawned)
	boss.finished.connect(_victory)
	_room.player_respawned.connect(_on_player_respawned)
	if get_node("/root/GameState").has_flag(DONE_FLAG):
		_already_won()
		return
	_start.call_deferred()


func _start() -> void:
	var saves := get_node_or_null("/root/SaveManager")
	if saves and saves.active_slot > 0:
		saves.save_game(_room.scene_file_path, entry_id)
	_room.arrival_entry = entry_id
	phase = Phase.INTRO
	_set_gates(true)
	await _play(intro_dialogue)
	_begin_fight()


func _begin_fight() -> void:
	phase = Phase.FIGHT
	_error_index = 0
	_set_background_stage(1)
	if is_instance_valid(_bar):
		_bar.queue_free()
	_bar = BossBar.show_for(_room.get_node("CombatHUD"), boss, "BUCLE", 0, BucleArt.PALETTE[0])
	_bar.phase_mark = -1.0
	_bar.segments = boss.config.key_hits
	boss.ai_enabled = true
	boss.begin()
	fight_started.emit()


func _on_key_hit(_count: int, risky: bool) -> void:
	if not risky:
		return
	# Golpe arriesgado: se acercó mientras Bucle atacaba. Recibe energía (una curación).
	var player := _room.player
	player.set_energy(player.energy + boss.config.risky_energy)
	get_tree().call_group(&"toast", &"show_message", "¡Golpe arriesgado! +energía", 1.6)


func _on_transformed(stage: int) -> void:
	_set_background_stage(stage)


func _on_execution_error(_cycle: int) -> void:
	for k in boss.cycle_data().error_platforms:
		_close_one()


## Apaga la próxima plataforma (rotando) que se pueda apagar: nunca una ya apagada ni la última encendida de
## essential (la ruta al puente).
func _close_one() -> void:
	for attempt in platforms.size():
		var platform := platforms[_error_index % platforms.size()]
		_error_index += 1
		if platform.is_closed() or platform.is_in_group(&"unsafe_ground"):
			continue
		if essential.has(platform) and essential.filter(_is_open).size() <= 1:
			continue
		platform.force_close(boss.config.error_time)
		return


func _is_open(platform: DataPlatform) -> bool:
	return not platform.is_closed() and not platform.is_in_group(&"unsafe_ground")


## Avisos la primera vez que aparece cada cosa nueva (no quitan el control).
func _on_tasks_spawned(_count: int) -> void:
	_hint(&"tareas", "¡Tareas pendientes! Rómpelas todas para cortar el bucle")


func _on_condition_broken() -> void:
	get_tree().call_group(&"toast", &"show_message", "¡Condición de salida cumplida! Bucle se cansa", 1.8)


func _on_copies_spawned() -> void:
	_hint(&"copias", "Copias del proceso: la flecha del verdadero gira como el reloj")


func _hint(id: StringName, text: String) -> void:
	if _hints.has(id):
		return
	_hints.append(id)
	get_tree().call_group(&"toast", &"show_message", text, 2.6)


func _on_player_respawned() -> void:
	if phase != Phase.FIGHT:
		return
	# Kai perdió: el combate vuelve a empezar desde el ciclo 1 (sin la introducción).
	BucleAttacks.clear(get_tree())
	boss.restore()
	_begin_fight()


func _victory() -> void:
	if phase in [Phase.CLOSING, Phase.DONE]:
		return
	phase = Phase.CLOSING
	BucleAttacks.clear(get_tree())
	_set_background_stage(1)
	if is_instance_valid(_bar):
		_bar.dismiss()
	var state := get_node("/root/GameState")
	state.set_flag(DONE_FLAG)
	state.set_flag(FREED_FLAG)
	if state.get_current_step(QUEST) == &"vencer_bucle":
		state.complete_step(QUEST, &"vencer_bucle")
	# Recompensa única (aunque se repita el combate o se cargue la partida).
	var economy := get_node("/root/Economy")
	economy.claim_reward(REWARD_ID, economy.reward_for(EconomyConfig.Source.BOSS))
	victory.emit()
	await _play(closing_dialogue)
	await _after_victory()


## Después del combate: el puzle de la condición de salida, la pista de la anomalía y la salida abierta.
## (Si se cerró el juego antes de terminarlo, al volver a la arena sigue desde aquí.)
func _after_victory() -> void:
	phase = Phase.CLOSING
	var state := get_node("/root/GameState")
	_room.player.damage.protected = true
	if exit_challenge and not skip_cinematics:
		await StoryHelper.choose_until_done(self, exit_challenge)
	state.set_flag(PUZZLE_FLAG)
	await _play(after_puzzle_dialogue)
	# Un mensaje que nadie escribió (la pista del capítulo): no se explica quién ni por qué.
	if not skip_cinematics and not state.has_flag(ANOMALY_FLAG):
		Sfx.play(&"entity_whisper", 0.8)
		var reading := FragmentReading.show_lines(self, ANOMALY_LINES)
		await reading.closed
	state.set_flag(ANOMALY_FLAG)
	await _play(anomaly_dialogue)
	state.set_flag(FINISHED_FLAG)
	_room.player.damage.protected = false
	_set_gates(false)
	phase = Phase.DONE


func _already_won() -> void:
	boss.rest()
	if get_node("/root/GameState").has_flag(FINISHED_FLAG):
		phase = Phase.DONE
		_set_gates(false)
	else:
		# Ganó, pero no terminó (se cerró el juego en el puzle): sigue desde ahí.
		_set_gates(true)
		_after_victory.call_deferred()


func _set_background_stage(stage: int) -> void:
	if background and "stage" in background:
		background.stage = stage


func _play(dialogue: Dialogue) -> void:
	if dialogue == null or skip_cinematics:
		return
	var box := DialogueBox.find(self)
	if box == null:
		return
	var player := _room.player
	player.controls_locked = true
	await box.play(dialogue)
	player.controls_locked = false


## Cierra (o abre) las dos salidas de la arena.
func _set_gates(on: bool) -> void:
	gate.active = on
	if exit_gate:
		exit_gate.active = on
