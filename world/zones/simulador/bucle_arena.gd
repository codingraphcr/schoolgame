class_name BucleArenaController
extends Node
## El combate contra Bucle (Capítulo 2, nivel 4 · Código fuera de control) y su cierre. Ver
## docs/jefes/BUCLE_INFINITO.md. Sin límite de tiempo.
##
## - Al llegar se registra el checkpoint (como la arena de Chip y Glitch) y la puerta se cierra.
## - Introducción, la barra «BUCLE» con siete segmentos (los impactos clave) y el combate (BucleBoss).
## - Golpe arriesgado (mientras ataca): Kai recibe energía (risky_energy).
## - Error de ejecución: apaga una sola plataforma unos segundos (rotando: nunca todas).
## - Cada impacto: el fondo cambia con la etapa de Bucle (background.stage).
## - Si Kai pierde, reaparece en la entrada y el combate vuelve a empezar (ciclo 1, sin introducción).
## - Final: diálogo, recompensa única, Bucle liberado (no muere: queda en la arena), el puzle de la
##   condición de salida (simulado) y se abre la salida.

signal fight_started
signal victory

enum Phase { WAITING, INTRO, FIGHT, CLOSING, DONE }

const DONE_FLAG := &"cap2_bucle_vencido"
## Bucle queda libre (podrá volver como personaje secundario).
const FREED_FLAG := &"cap2_bucle_liberado"
const PUZZLE_FLAG := &"cap2_condicion_corregida"
const REWARD_ID := &"capitulo2:bucle"

@export var boss: BucleBoss
@export var gate: ArenaBarrier
## Plataformas que el Error de ejecución puede apagar (de a una).
@export var platforms: Array[DataPlatform] = []
## Fondo de la arena (si tiene la propiedad stage, cambia con la transformación).
@export var background: Node2D
@export var intro_dialogue: Dialogue
@export var closing_dialogue: Dialogue
@export var exit_challenge: ChoiceChallenge
@export var after_puzzle_dialogue: Dialogue
## Entrada donde se guarda la partida al llegar (el checkpoint de la arena).
@export var entry_id: StringName = &"inicio"
## Saltear diálogos y el puzle (solo pruebas).
@export var skip_cinematics := false

var phase := Phase.WAITING

var _room: Room
var _bar: BossBar
var _error_index := 0


func _ready() -> void:
	_room = get_parent() as Room
	boss.ai_enabled = false
	boss.key_hit.connect(_on_key_hit)
	boss.transformed.connect(_on_transformed)
	boss.execution_error.connect(_on_execution_error)
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
	gate.active = true
	await _play(intro_dialogue)
	_begin_fight()


func _begin_fight() -> void:
	phase = Phase.FIGHT
	_error_index = 0
	_set_background_stage(1)
	if is_instance_valid(_bar):
		_bar.queue_free()
	_bar = BossBar.show_for(_room.get_node("CombatHUD"), boss, "BUCLE", 0, BucleArt.WARM)
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
	if platforms.is_empty():
		return
	var platform := platforms[_error_index % platforms.size()]
	_error_index += 1
	platform.force_close(boss.config.error_time)


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
	_room.player.damage.protected = true
	var state := get_node("/root/GameState")
	state.set_flag(DONE_FLAG)
	state.set_flag(FREED_FLAG)
	# Recompensa única (aunque se repita el combate o se cargue la partida).
	var economy := get_node("/root/Economy")
	economy.claim_reward(REWARD_ID, economy.reward_for(EconomyConfig.Source.BOSS))
	victory.emit()
	await _play(closing_dialogue)
	if exit_challenge and not skip_cinematics:
		await StoryHelper.choose_until_done(self, exit_challenge)
	state.set_flag(PUZZLE_FLAG)
	await _play(after_puzzle_dialogue)
	_room.player.damage.protected = false
	gate.active = false
	phase = Phase.DONE


func _already_won() -> void:
	phase = Phase.DONE
	gate.active = false
	boss.rest()


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
