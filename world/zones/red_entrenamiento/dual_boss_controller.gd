class_name DualBossController
extends Node
## El combate contra Chip y Glitch (Capítulo 1) y su cierre. Sin límite de tiempo.
##
## 1. Al llegar: se registra el checkpoint (se guarda en la entrada de la arena), se cierra la puerta
##    y se reproduce la introducción (texto de la especificación). Empieza el combate.
## 2. Cada hermano pelea con su propia máquina de estados; además, cada combo_cooldown, si los dos
##    están libres, este controlador ordena un ataque combinado (BossSynergy):
##    · Camino cerrado: Chip cierra el paso del lado de Kai lejos de Glitch, y Glitch embiste.
##    · Distracción: Glitch presiona con su combo mientras Chip prepara un disparo grande.
##    · Trampa sincronizada: Chip pone trampas a los costados de Kai y Glitch salta encima.
## 3. Escudo de Chip (a la mitad de su vida, una vez): **fase segura**. Los dos se van a su esquina,
##    se borran los ataques, Kai no recibe daño y aparece una terminal: hay que leer escudo.cfg y
##    elegir la corrección (mínimo privilegio). Después, el escudo se apaga y sigue la pelea.
## 4. Furia fraternal: cuando uno queda neutralizado, el otro entra en furia (una sola vez).
## 5. Si Kai pierde, reaparece en la entrada y la pelea vuelve a empezar (sin la introducción).
## 6. Cuando los dos quedan neutralizados: cierre (diálogo, Fragmento de Datos, lectura del Grimorio,
##    recompensas una sola vez) y aparece la conexión para volver al cuarto técnico.

signal fight_started
signal combo_started(kind: StringName)
signal safe_phase_changed(active: bool)
signal rage_started(survivor: StringName)
signal victory

enum Phase { WAITING, INTRO, FIGHT, SAFE, CLOSING, DONE }

const QUEST := &"travesuras_en_el_sistema"
const COMBOS: Array[StringName] = [&"camino_cerrado", &"distraccion", &"trampa_sincronizada"]
const DONE_FLAG := &"cap1_hermanos_vencidos"
const READING_FLAG := &"cap1_fragmento_leido"
const REWARD_ID := &"capitulo1:hermanos"
const FRAGMENT_LINES: PackedStringArray = ["ORIGEN: DESCONOCIDO", "ESTADO: INCOMPLETO", "OBSERVADOR: RECONOCIDO", "PROTOCOLO: [DATOS CORRUPTOS]"]

@export var config: DualBossConfig
@export var chip: ChipBoss
@export var glitch: GlitchBoss
## Puerta que se cierra detrás de Kai durante la pelea.
@export var gate: ArenaBarrier
## Conexión para volver al cuarto técnico (aparece al final).
@export var exit_portal: ImmersionPortal
@export var platforms: Array[DataPlatform] = []
## Dónde aparece la terminal del escudo.
@export var terminal_position := Vector2(120, 304)
@export var shield_terminal: TerminalChallenge
@export var shield_challenge: ChoiceChallenge
@export var intro_dialogue: Dialogue
@export var shield_dialogue: Dialogue
@export var shield_broken_dialogue: Dialogue
@export var closing_dialogue: Dialogue
@export var after_reading_dialogue: Dialogue
## Entrada donde se guarda la partida al llegar (el checkpoint de la arena).
@export var entry_id: StringName = &"desde_persecucion"
## Saltear diálogos y la lectura (solo pruebas).
@export var skip_cinematics := false

var phase := Phase.WAITING
var combos_done: Array[StringName] = []
## Quién quedó en pie al empezar la furia (&"chip" o &"glitch"; vacío si todavía no).
var rage_survivor: StringName = &""
var terminal: TerminalStation

var _room: Room
var _combo_cd := 0.0
var _combo_index := 0
var _bars: Array[BossBar] = []
var _banner: Label


func _ready() -> void:
	_room = get_parent() as Room
	for boss: SiblingBoss in [chip, glitch]:
		boss.apply_config(config)
		boss.ai_enabled = false
		boss.neutralized.connect(_on_neutralized)
	chip.platforms = platforms
	chip.shield_requested.connect(_on_shield_requested)
	exit_portal.visible = false
	exit_portal.process_mode = Node.PROCESS_MODE_DISABLED
	_room.player_respawned.connect(_on_player_respawned)
	var state := get_node("/root/GameState")
	if state.has_flag(DONE_FLAG):
		_already_won()
		return
	_start.call_deferred()


func _physics_process(delta: float) -> void:
	if phase != Phase.FIGHT or chip.is_dead or glitch.is_dead:
		return
	_combo_cd -= delta
	if _combo_cd <= 0.0 and not chip.busy and not glitch.busy:
		start_combo(COMBOS[_combo_index % COMBOS.size()])
		_combo_index += 1


## Ataque combinado (lo usa el ciclo de la pelea y las pruebas).
func start_combo(kind: StringName) -> void:
	_combo_cd = config.combo_cooldown
	combos_done.append(kind)
	combo_started.emit(kind)
	var kai := _room.player.global_position
	match kind:
		&"camino_cerrado":
			var away := 1.0 if kai.x >= glitch.global_position.x else -1.0
			chip.command_wall(kai.x + away * 60.0)
			_delayed(func() -> void: glitch.charge(), 0.45)
		&"distraccion":
			glitch.combo()
			chip.command_big_shot()
		&"trampa_sincronizada":
			chip.command_traps([kai.x - 70.0, kai.x + 70.0])
			_delayed(func() -> void: glitch.leap(), config.chip_trap_telegraph + config.chip_trap_arm)


func _delayed(callback: Callable, seconds: float) -> void:
	await get_tree().create_timer(seconds, false, true).timeout
	if phase == Phase.FIGHT and not glitch.is_dead:
		callback.call()


func _start() -> void:
	# Se registra el checkpoint: si Kai pierde (o se carga la partida), vuelve a la entrada.
	var saves := get_node_or_null("/root/SaveManager")
	if saves and saves.active_slot > 0:
		saves.save_game(_room.scene_file_path, entry_id)
	_room.arrival_entry = entry_id
	var state := get_node("/root/GameState")
	if state.get_current_step(QUEST) == &"persecucion":
		state.complete_step(QUEST, &"persecucion")
	phase = Phase.INTRO
	gate.active = true
	await _play(intro_dialogue)
	_begin_fight()


func _begin_fight() -> void:
	phase = Phase.FIGHT
	_combo_cd = config.combo_cooldown
	for boss: SiblingBoss in [chip, glitch]:
		boss.ai_enabled = true
	var hud := _room.get_node("CombatHUD")
	for bar in _bars:
		if is_instance_valid(bar):
			bar.queue_free()
	_bars.clear()
	var chip_bar := BossBar.show_for(hud, chip, "CHIP", 0, Color("5ad8ff"))
	chip_bar.phase_mark = config.chip_shield_at
	var glitch_bar := BossBar.show_for(hud, glitch, "GLITCH", 1, Color("ff8a3a"))
	glitch_bar.phase_mark = -1.0
	_bars = [chip_bar, glitch_bar]
	fight_started.emit()


## --- Fase segura: el escudo de Chip ---

func _on_shield_requested() -> void:
	if phase != Phase.FIGHT:
		return
	phase = Phase.SAFE
	for boss: SiblingBoss in [chip, glitch]:
		if not boss.is_dead:
			boss.frozen = true
	for attack in get_tree().get_nodes_in_group(&"boss_attack"):
		attack.queue_free()
	_room.player.damage.protected = true
	_show_banner("FASE SEGURA · Corrige la configuración del escudo de Chip")
	safe_phase_changed.emit(true)
	await _play(shield_dialogue)
	terminal = TerminalStation.new()
	terminal.name = "ShieldTerminal"
	terminal.challenge = shield_terminal
	terminal.position = terminal_position
	_room.add_child(terminal)
	terminal.solved.connect(_on_terminal_solved, CONNECT_ONE_SHOT)


func _on_terminal_solved() -> void:
	var completed := false
	while not completed:
		var window := ChoiceWindow.open(self, shield_challenge)
		completed = await window.closed
		if not completed:
			await get_tree().create_timer(0.3).timeout
	end_safe_phase()


## Termina la fase segura: el escudo se apaga y sigue la pelea.
func end_safe_phase() -> void:
	if phase != Phase.SAFE:
		return
	if is_instance_valid(terminal):
		terminal.queue_free()
	chip.shield_off()
	_hide_banner()
	await _play(shield_broken_dialogue)
	_room.player.damage.protected = false
	phase = Phase.FIGHT
	_combo_cd = config.combo_cooldown
	for boss: SiblingBoss in [chip, glitch]:
		boss.frozen = false
	safe_phase_changed.emit(false)


## --- Furia fraternal y final ---

func _on_neutralized(boss: SiblingBoss) -> void:
	var other: SiblingBoss = glitch if boss == chip else chip
	if not other.is_dead:
		if rage_survivor == &"":
			rage_survivor = &"glitch" if other == glitch else &"chip"
			other.enter_rage()
			get_tree().call_group(&"toast", &"show_message", "¡FURIA FRATERNAL!", 2.0)
			rage_started.emit(rage_survivor)
		return
	_victory()


func _victory() -> void:
	if phase in [Phase.CLOSING, Phase.DONE]:
		return
	phase = Phase.CLOSING
	for attack in get_tree().get_nodes_in_group(&"boss_attack"):
		attack.queue_free()
	for bar in _bars:
		if is_instance_valid(bar):
			bar.dismiss()
	_bars.clear()
	_room.player.damage.protected = true
	var state := get_node("/root/GameState")
	state.set_flag(DONE_FLAG)
	if state.get_current_step(QUEST) == &"persecucion":
		state.complete_step(QUEST, &"persecucion")
	if state.get_current_step(QUEST) == &"vencer_hermanos":
		state.complete_step(QUEST, &"vencer_hermanos")
	# Recompensa única (aunque se repita la pelea o se cargue la partida).
	var economy := get_node("/root/Economy")
	economy.claim_reward(REWARD_ID, economy.reward_for(EconomyConfig.Source.BOSS))
	victory.emit()
	await _play(closing_dialogue)
	# Chip deja caer un Fragmento de Datos y el Grimorio lo lee.
	if not skip_cinematics:
		var reading := FragmentReading.show_lines(self, FRAGMENT_LINES)
		await reading.closed
	state.set_flag(READING_FLAG)
	await _play(after_reading_dialogue)
	_room.player.damage.protected = false
	gate.active = false
	_open_exit()
	phase = Phase.DONE


func _already_won() -> void:
	phase = Phase.DONE
	gate.active = false
	for boss: SiblingBoss in [chip, glitch]:
		boss.visible = false
		boss.process_mode = Node.PROCESS_MODE_DISABLED
	_open_exit()


func _open_exit() -> void:
	exit_portal.visible = true
	exit_portal.process_mode = Node.PROCESS_MODE_INHERIT
	# Los hermanos se van (quedan neutralizados, pero pueden volver más adelante).
	for boss: SiblingBoss in [chip, glitch]:
		if boss.visible:
			var tween := boss.create_tween()
			tween.tween_property(boss, "modulate:a", 0.0, 0.8)
			tween.tween_callback(func() -> void: boss.visible = false)


func _on_player_respawned() -> void:
	if phase not in [Phase.FIGHT, Phase.SAFE]:
		return
	# Kai perdió: la pelea vuelve a empezar (sin la introducción).
	for attack in get_tree().get_nodes_in_group(&"boss_attack"):
		attack.queue_free()
	if is_instance_valid(terminal):
		terminal.queue_free()
	_hide_banner()
	_room.player.damage.protected = false
	rage_survivor = &""
	combos_done.clear()
	for boss: SiblingBoss in [chip, glitch]:
		boss.restore()
	_begin_fight()


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


func _show_banner(text: String) -> void:
	_hide_banner()
	_banner = Label.new()
	_banner.text = text
	_banner.add_theme_font_size_override("font_size", 18)
	_banner.add_theme_color_override("font_color", Color("5dff9a"))
	_banner.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	_banner.add_theme_constant_override("outline_size", 6)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_top = 120.0
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_room.get_node("CombatHUD").add_child(_banner)


func _hide_banner() -> void:
	if is_instance_valid(_banner):
		_banner.queue_free()
	_banner = null
