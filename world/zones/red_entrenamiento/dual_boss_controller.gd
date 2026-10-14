class_name DualBossController
extends Node
## El combate contra Glitch y Chip (Capítulo 1) y su cierre. Sin límite de tiempo. Ataques de Ariel
## (docs/arte/referencias/glitch_chip_concepto.webp), **dos barras de vida** (una por hermano) y tres fases
## según la vida de los dos juntos, con secuencias fijas («más rápidos, pero no aleatorios»):
##
## - Fase 1 · Reconocimiento (100-70 %): alternan ataques individuales y algunos en conjunto sencillos.
##   El jugador aprende sus señales.
## - Fase 2 · Sincronización (70-35 %): encadenan ataques y cambian de posición. Se activa el anillo del
##   fondo (Cámara de convergencia) y entra una segunda melodía en la música.
## - Fase segura (al 35 %): Chip levanta un escudo ligado a una configuración insegura; la pelea se
##   pausa y Kai lo desactiva en una terminal (mínimo privilegio).
## - Fase 3 · Protocolo Dual (35-0 %): más rápidos, secuencias combinadas y su ataque definitivo, el
##   Campo Dual.
## - Furia fraternal: si un hermano queda neutralizado, el otro se vuelve más fuerte (más rápido, avisos
##   más cortos, más proyectiles y recupera parte de su vida) y sigue solo con sus ataques. Y viceversa.
##
## Ataques en conjunto: Intercepción cruzada, Corte y respuesta, Sincronización aérea, Cambio de
## posición, Cadena de proyecciones y Campo Dual.
## Vínculo: cuando uno queda aturdido (varios golpes seguidos), el otro abandona su ataque para
## protegerlo hasta que se recupera.
## Si Kai pierde, reaparece en la entrada y la pelea vuelve a empezar (sin la introducción). Con su vida
## en cero cada uno queda neutralizado (no muere); con los dos neutralizados: cierre (diálogo, Fragmento de Datos, lectura del Grimorio,
## recompensas una sola vez) y aparece la conexión para volver al cuarto técnico.

signal fight_started
signal phase_changed(number: int)
signal pattern_started(pattern: StringName)
signal safe_phase_changed(active: bool)
## protector: &"glitch" o &"chip" (el que protege al otro).
signal guard_started(protector: StringName)
## survivor: &"glitch" o &"chip" (el que queda en pie y se enfurece).
signal rage_started(survivor: StringName)
signal victory

enum Phase { WAITING, INTRO, FIGHT, SAFE, CLOSING, DONE }

const QUEST := &"travesuras_en_el_sistema"
const DONE_FLAG := &"cap1_hermanos_vencidos"
const READING_FLAG := &"cap1_fragmento_leido"
const REWARD_ID := &"capitulo1:hermanos"
const FRAGMENT_LINES: PackedStringArray = ["ORIGEN: DESCONOCIDO", "ESTADO: INCOMPLETO", "OBSERVADOR: RECONOCIDO", "PROTOCOLO: [DATOS CORRUPTOS]"]
## Secuencias de cada fase (se repiten en orden).
const PHASE1: Array[StringName] = [&"corte_acelerado", &"discos_orbitales", &"salto_en_picada", &"zona_de_control",
	&"intercepcion_cruzada", &"lanzamiento_de_fragmentos", &"rayo_de_sincronia", &"corte_y_respuesta"]
const PHASE2: Array[StringName] = [&"cambio_de_posicion", &"embestida_y_discos", &"sincronizacion_aerea", &"proyecciones",
	&"cadena_de_proyecciones", &"corte_y_respuesta", &"zona_y_picada"]
const PHASE3: Array[StringName] = [&"cambio_de_posicion", &"intercepcion_cruzada", &"cadena_de_proyecciones",
	&"sincronizacion_aerea", &"campo_dual"]
## Furia fraternal: lo que hace el que queda en pie (solo, más fuerte).
const GLITCH_RAGE: Array[StringName] = [&"corte_acelerado", &"embestida_en_cadena", &"lanzamiento_de_fragmentos",
	&"salto_en_picada", &"corte_acelerado", &"lanzamiento_de_fragmentos"]
const CHIP_RAGE: Array[StringName] = [&"discos_orbitales", &"rayo_de_sincronia", &"proyecciones", &"zona_de_control",
	&"discos_orbitales", &"rayo_de_sincronia"]
const PHASE_NAMES := { 2: "FASE 2 · SINCRONIZACIÓN", 3: "FASE 3 · PROTOCOLO DUAL" }

@export var config: DualBossConfig
@export var chip: ChipBoss
@export var glitch: GlitchBoss
## Puerta que se cierra detrás de Kai durante la pelea.
@export var gate: ArenaBarrier
## Conexión para volver al cuarto técnico (aparece al final).
@export var exit_portal: ImmersionPortal
## El fondo de la arena (su anillo se activa en la Fase 2).
@export var chamber: ConvergenceChamber
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
## Fase de la pelea: 1 Reconocimiento, 2 Sincronización, 3 Protocolo Dual.
var fight_phase := 1
## El que quedó en pie cuando el otro fue neutralizado (Furia fraternal), o null.
var survivor: SiblingBoss
var patterns_done: Array[StringName] = []
var terminal: TerminalStation

var _room: Room
var _bar: BossBar
var _bar_chip: BossBar
var _banner: Label
var _index := 0
var _cooldown := 0.0
var _running := false
## Cambia cuando se corta la secuencia en curso (aturdido, fase segura, reinicio).
var _token := 0


func _ready() -> void:
	_room = get_parent() as Room
	for boss: SiblingBoss in [chip, glitch]:
		boss.config = config
		boss.ai_enabled = false
		boss.max_health = config.glitch_health if boss == glitch else config.chip_health
		# Los hermanos están antes en la escena: su vida ya existe.
		boss.health.max_health = boss.max_health
		boss.health.restore_full()
		boss.health.health_changed.connect(func(_current: float, _maximum: float) -> void: _on_health_changed())
		boss.neutralized.connect(_on_neutralized)
		boss.incapacitated.connect(_on_incapacitated)
		boss.recovered.connect(_on_recovered)
	exit_portal.visible = false
	exit_portal.process_mode = Node.PROCESS_MODE_DISABLED
	_room.player_respawned.connect(_on_player_respawned)
	var state := get_node("/root/GameState")
	if state.has_flag(DONE_FLAG):
		_already_won()
		return
	_start.call_deferred()


func _physics_process(delta: float) -> void:
	if phase != Phase.FIGHT or _running or _protecting():
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		var sequence := _sequence()
		start_pattern(sequence[_index % sequence.size()])
		_index += 1


func _sequence() -> Array[StringName]:
	if survivor:
		return GLITCH_RAGE if survivor == glitch else CHIP_RAGE
	match fight_phase:
		2:
			return PHASE2
		3:
			return PHASE3
	return PHASE1


func _pause() -> float:
	if survivor:
		return config.rage_pause
	match fight_phase:
		2:
			return config.pause_phase2
		3:
			return config.pause_phase3
	return config.pause_phase1


## Si uno está aturdido (y el otro lo protege): mientras tanto no empiezan ataques nuevos.
func _protecting() -> bool:
	return chip.stunned or glitch.stunned


## Ejecuta un ataque (individual o en conjunto). Lo usa el ciclo de la pelea y las pruebas.
func start_pattern(pattern: StringName) -> void:
	_running = true
	_token += 1
	var token := _token
	patterns_done.append(pattern)
	pattern_started.emit(pattern)
	await _pattern(pattern, token)
	if token == _token:
		_running = false
		_cooldown = _pause()


func _alive(token: int) -> bool:
	return token == _token and phase == Phase.FIGHT


func _pattern(pattern: StringName, token: int) -> void:
	match pattern:
		&"corte_acelerado":
			await glitch.corte_acelerado()
		&"salto_en_picada":
			await glitch.salto_en_picada()
		&"embestida_en_cadena":
			await glitch.embestida_en_cadena(config.rage_chain_dashes if survivor == glitch else -1)
		&"lanzamiento_de_fragmentos":
			await glitch.lanzamiento_de_fragmentos(config.rage_fragments if survivor == glitch else -1)
		&"discos_orbitales":
			await chip.discos_orbitales(config.rage_discs if survivor == chip else (1 if fight_phase == 1 else 2))
		&"zona_de_control":
			await chip.zona_de_control()
		&"proyecciones":
			await chip.proyecciones(config.rage_copies if survivor == chip else -1)
		&"rayo_de_sincronia":
			await chip.rayo_de_sincronia()
		&"intercepcion_cruzada":
			await _intercepcion_cruzada(token)
		&"corte_y_respuesta":
			await _corte_y_respuesta(token)
		&"sincronizacion_aerea":
			await _sincronizacion_aerea(token)
		&"cambio_de_posicion":
			await _cambio_de_posicion(token)
		&"cadena_de_proyecciones":
			await _cadena_de_proyecciones(token)
		&"embestida_y_discos":
			glitch.embestida_en_cadena()
			await chip.discos_orbitales(2)
			await _until_free(glitch, token)
		&"zona_y_picada":
			await chip.zona_de_control()
			if _alive(token):
				await glitch.salto_en_picada()
		&"campo_dual":
			await _campo_dual(token)


## Espera a que boss termine su ataque (o a que se corte la secuencia).
func _until_free(boss: SiblingBoss, token: int) -> void:
	while boss.busy and _alive(token):
		await get_tree().physics_frame


## Los dos aparecen en sus lugares con un parpadeo (para los ataques en conjunto).
func _positions(glitch_x: float, chip_x: float, token: int) -> bool:
	var ge := glitch.begin_attack()
	var ce := chip.begin_attack()
	if ge < 0 or ce < 0:
		glitch.end_attack(ge)
		chip.end_attack(ce)
		return false
	glitch.blink_to(glitch_x, ge)
	await chip.blink_to(chip_x, ce)
	await get_tree().create_timer(0.05, false, true).timeout
	glitch.end_attack(ge)
	chip.end_attack(ce)
	return _alive(token)


## 1. Intercepción cruzada: atacan desde lados opuestos a la vez (Glitch corta, Chip lanza un disco).
func _intercepcion_cruzada(token: int) -> void:
	var kai_x := _room.player.global_position.x
	var glitch_left := kai_x > (glitch.arena_left + glitch.arena_right) / 2.0
	var left := glitch.arena_left + 10.0
	var right := glitch.arena_right - 10.0
	if not await _positions(left if glitch_left else right, right if glitch_left else left, token):
		return
	glitch.corte_acelerado(1.0 if glitch_left else -1.0)
	await chip.discos_orbitales(1)
	await _until_free(glitch, token)


## 2. Corte y respuesta: Glitch inicia con su corte, Chip completa con el rayo donde quedó Kai.
func _corte_y_respuesta(token: int) -> void:
	await glitch.corte_acelerado()
	if _alive(token):
		await chip.rayo_de_sincronia()


## 3. Sincronización aérea: los dos saltan y atacan en el aire (picada y discos hacia abajo).
func _sincronizacion_aerea(token: int) -> void:
	glitch.salto_en_picada()
	var epoch := chip.begin_attack()
	if epoch < 0:
		return
	chip.face_player()
	if await chip.telegraph(&"sincronizacion_aerea", config.chip_disc_telegraph, epoch):
		chip.velocity = Vector2(0, -sqrt(2.0 * 900.0 * 70.0))
		await get_tree().create_timer(0.3, false, true).timeout
		if chip.still(epoch):
			chip.throw_discs(2)
		while chip.still(epoch) and not chip.is_on_floor():
			await get_tree().physics_frame
	chip.end_attack(epoch)
	await _until_free(glitch, token)


## 4. Cambio de posición: preparan su ataque, se intercambian de lugar en plena secuencia y lo
## lanzan desde el otro lado.
func _cambio_de_posicion(token: int) -> void:
	var ge := glitch.begin_attack()
	var ce := chip.begin_attack()
	if ge < 0 or ce < 0:
		glitch.end_attack(ge)
		chip.end_attack(ce)
		return
	glitch.face_player()
	chip.face_player()
	glitch.telegraph(&"cambio_de_posicion", 0.45, ge)
	if not await chip.telegraph(&"cambio_de_posicion", 0.45, ce):
		glitch.end_attack(ge)
		chip.end_attack(ce)
		return
	var glitch_x := glitch.global_position.x
	var chip_x := chip.global_position.x
	glitch.blink_to(chip_x, ge)
	await chip.blink_to(glitch_x, ce)
	glitch.end_attack(ge)
	chip.end_attack(ce)
	if not _alive(token):
		return
	glitch.corte_acelerado()
	await chip.discos_orbitales(1 if fight_phase == 1 else 2)
	await _until_free(glitch, token)


## 5. Cadena de proyecciones: Chip crea copias mientras Glitch presiona con su embestida.
func _cadena_de_proyecciones(token: int) -> void:
	chip.proyecciones(3 if fight_phase == 3 else 2)
	await glitch.embestida_en_cadena()
	await _until_free(chip, token)


## 6. Campo Dual (ataque definitivo): el piso se vuelve peligroso salvo un hueco seguro (lejos de
## Kai, para obligarlo a moverse; las plataformas también son seguras) y Glitch lanza fragmentos.
func _campo_dual(token: int) -> void:
	var center := (glitch.arena_left + glitch.arena_right) / 2.0
	if not await _positions(center - 50.0, center + 50.0, token):
		return
	var ge := glitch.begin_attack()
	var ce := chip.begin_attack()
	if ge < 0 or ce < 0:
		glitch.end_attack(ge)
		chip.end_attack(ce)
		return
	glitch.telegraph(&"campo_dual", 0.5, ge)
	if not await chip.telegraph(&"campo_dual", 0.5, ce):
		glitch.end_attack(ge)
		chip.end_attack(ce)
		return
	var kai_x := _room.player.global_position.x
	var gap_x := glitch.arena_right - 50.0 if kai_x < center else glitch.arena_left + 50.0
	var field := BossAttacks.field(get_parent(), SiblingBoss.FLOOR_Y, glitch.arena_left - 40.0, glitch.arena_right + 40.0, gap_x, config, glitch.telegraph_scale)
	Sfx.play(&"boss_charge", 0.8)
	var throws := 0
	var elapsed := 0.0
	var total := field.warning + field.duration
	while elapsed < total and glitch.still(ge) and chip.still(ce):
		if throws < 2 and elapsed >= field.warning + throws * 1.1:
			throws += 1
			glitch.face_player()
			glitch.throw_fragments(_room.player.global_position + Vector2(0, -16), 3)
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	glitch.end_attack(ge)
	chip.end_attack(ce)


## --- Vínculo: proteger al hermano aturdido ---

func _on_incapacitated(boss: SiblingBoss) -> void:
	if phase != Phase.FIGHT:
		return
	var other: SiblingBoss = glitch if boss == chip else chip
	_token += 1
	_running = false
	if other.is_dead or other.stunned:
		return
	other.guard_for(boss)
	guard_started.emit(&"glitch" if other == glitch else &"chip")


func _on_recovered(boss: SiblingBoss) -> void:
	for other: SiblingBoss in [chip, glitch]:
		if other.guarding == boss:
			other.stop_guarding()
	_cooldown = _pause()


## --- Fases ---

## Vida de los dos juntos (0 a 1): de ella dependen las fases.
func total_ratio() -> float:
	var maximum := glitch.health.max_health + chip.health.max_health
	return (glitch.health.current + chip.health.current) / maximum


func _on_health_changed() -> void:
	if phase != Phase.FIGHT:
		return
	for boss: SiblingBoss in [chip, glitch]:
		if boss.health.is_dead() and not boss.is_dead:
			return  # Está por quedar neutralizado: primero se resuelve eso (_on_neutralized).
	var ratio := total_ratio()
	if fight_phase == 1 and ratio <= config.phase2_at:
		_enter_phase(2)
	if fight_phase == 2 and ratio <= config.phase3_at and ratio > 0.0:
		if chip.is_dead:
			_enter_phase(3)  # Sin Chip no hay escudo: la Fase 3 empieza directamente.
		else:
			_start_safe_phase()


## Un hermano quedó neutralizado: si el otro sigue en pie, entra en Furia fraternal; si no, se gana.
func _on_neutralized(boss: SiblingBoss) -> void:
	if phase != Phase.FIGHT:
		return
	var other: SiblingBoss = glitch if boss == chip else chip
	if other.is_dead:
		_victory()
		return
	_token += 1
	_running = false
	_cooldown = 1.0
	_index = 0
	if other.guarding:
		other.stop_guarding()
	survivor = other
	other.enter_rage()
	other.tempo = maxf(other.tempo, config.rage_speed_scale)
	other.telegraph_scale = minf(other.telegraph_scale, config.rage_telegraph_scale)
	other.health.heal(other.health.max_health * config.rage_heal)
	var survivor_name := "GLITCH" if other == glitch else "CHIP"
	_show_banner("¡FURIA FRATERNAL! · %s" % survivor_name)
	get_tree().create_timer(2.2, false, true).timeout.connect(func() -> void:
		if phase == Phase.FIGHT:
			_hide_banner())
	Sfx.play(&"boss_charge", 0.7)
	rage_started.emit(&"glitch" if other == glitch else &"chip")
	_on_health_changed()


func _enter_phase(number: int) -> void:
	fight_phase = number
	_index = 0
	if number >= 2 and chamber:
		chamber.active = true
	if number >= 2:
		Music.set_layer(true)
	if number == 3:
		for boss: SiblingBoss in [chip, glitch]:
			boss.tempo = maxf(boss.tempo, config.phase3_speed_scale)
			boss.telegraph_scale = minf(boss.telegraph_scale, config.phase3_telegraph_scale)
	get_tree().call_group(&"toast", &"show_message", PHASE_NAMES.get(number, ""), 2.2)
	phase_changed.emit(number)


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
	fight_phase = 1
	_index = 0
	_running = false
	_cooldown = 0.6
	if chamber:
		chamber.active = false
	Music.play(&"hermanos")
	Music.set_layer(false)
	for boss: SiblingBoss in [chip, glitch]:
		boss.ai_enabled = true
	survivor = null
	for old in [_bar, _bar_chip]:
		if is_instance_valid(old):
			old.queue_free()
	# Dos barras: Glitch arriba y Chip debajo (las fases dependen de la vida de los dos juntos).
	_bar = BossBar.show_for(_room.get_node("CombatHUD"), glitch, "GLITCH", 0, SiblingArt.GLITCH)
	_bar.phase_mark = -1.0
	_bar_chip = BossBar.show_for(_room.get_node("CombatHUD"), chip, "CHIP", 1, SiblingArt.CHIP)
	_bar_chip.phase_mark = -1.0
	fight_started.emit()


## --- Fase segura: el escudo de Chip (al 35 %) ---

func _start_safe_phase() -> void:
	if phase != Phase.FIGHT:
		return
	phase = Phase.SAFE
	_token += 1
	_running = false
	for boss: SiblingBoss in [chip, glitch]:
		if boss.guarding:
			boss.stop_guarding()
		boss.stunned = false
		boss.frozen = true
		boss.hurtbox.immune = true
	chip.shield_on()
	for attack in get_tree().get_nodes_in_group(&"boss_attack"):
		attack.queue_free()
	_room.player.damage.protected = true
	_room.player.speed_scale = 1.0
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


## Termina la fase segura: el escudo se apaga y empieza el Protocolo Dual (Furia fraternal).
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
	for boss: SiblingBoss in [chip, glitch]:
		boss.frozen = false
		boss.hurtbox.immune = false
	safe_phase_changed.emit(false)
	_cooldown = 0.8
	_enter_phase(3)


## --- Final ---

func _victory() -> void:
	if phase in [Phase.CLOSING, Phase.DONE]:
		return
	phase = Phase.CLOSING
	_token += 1
	for attack in get_tree().get_nodes_in_group(&"boss_attack"):
		attack.queue_free()
	_room.player.speed_scale = 1.0
	for bar in [_bar, _bar_chip]:
		if is_instance_valid(bar):
			bar.dismiss()
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
	Music.set_layer(false)
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
	_token += 1
	for attack in get_tree().get_nodes_in_group(&"boss_attack"):
		attack.queue_free()
	if is_instance_valid(terminal):
		terminal.queue_free()
	_hide_banner()
	_room.player.damage.protected = false
	_room.player.speed_scale = 1.0
	patterns_done.clear()
	for boss: SiblingBoss in [chip, glitch]:
		boss.restore()
		boss.health.restore_full()
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
