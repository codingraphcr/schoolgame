class_name BucleBoss
extends EnemyBase
## Bucle, jefe del Capítulo 2 («Bucle Infinito», nivel 4 · Código fuera de control). Una entidad
## pequeña atrapada en una instrucción sin condición de salida. Ver docs/jefes/BUCLE_INFINITO.md.
##
## Siete impactos clave: un golpe válido de la Nullblade cuenta si Bucle está vulnerable y todavía no
## recibió el impacto de su ciclo. Su vida son siete segmentos (HealthComponent con 7): cada impacto
## quita exactamente 1, sin importar el daño del arma.
##
## Estados (cada uno con su propio reloj de física: nunca se traban esperando una animación):
##   INTRO → PREPARE_PATTERN → EXECUTE_PATTERN → FATIGUE ─(sin golpe)→ PREPARE_PATTERN (mismo ciclo)
##   golpe válido en PREPARE / EXECUTE / FATIGUE → HIT_REACTION → TRANSFORMATION → PREPARE (ciclo + 1)
##   el séptimo → HIT_REACTION → DEFEATED (se queda en la arena: no muere).
## Golpear durante EXECUTE es un golpe arriesgado (key_hit con risky = true: el controlador lo premia).
## Al cambiar de estado se cancelan los ataques en curso (época) y se borran los peligros.
##
## Versión difícil («como Sans»): Bucle no se queda quieto. Antes de cada ataque se teletransporta
## (parpadeo, blink_time) a otro lugar de la arena (config.attack_spots, también arriba, donde Kai no llega);
## si Kai se le acerca mientras prepara o ataca, lo esquiva (dodge); y descansa (FATIGUE) poco tiempo en un
## lugar alcanzable pero lejos de Kai (config.rest_spots), a veces encima de una plataforma. Mientras
## parpadea no se le puede golpear. Ataques nuevos (Barrido, Rastreo) y combinados («a+b»).

signal state_changed(state: State)
## count: impactos hasta ahora (1 a 7). risky: llegó mientras atacaba.
signal key_hit(count: int, risky: bool)
## Golpe que no cuenta (invulnerable o ya recibió el de este ciclo).
signal hit_ignored
## number: ciclo (1 a 7); repeat: veces que lo repitió sin recibir golpe.
signal cycle_started(number: int, repeat: int)
signal transformed(stage: int)
## Pide al controlador un Error de ejecución (apagar una plataforma un rato).
signal execution_error(number: int)
signal finished

enum State { INTRO, PREPARE_PATTERN, EXECUTE_PATTERN, FATIGUE, HIT_REACTION, TRANSFORMATION, DEFEATED }

const HOVER_Y := 296.0
const DODGE_LINES: PackedStringArray = ["¡Fuera de rango!", "¡Otra vez no!", "Repetir... ¡en otro lado!", "¡Jijiji, no!"]

@export var config: BucleConfig
## Límites de la arena: x de las paredes, y de arriba y del suelo (los ataques la usan).
@export var arena := Rect2(40, 40, 560, 264)

var state := State.INTRO
var impacts := 0
## Etapa visual (1 a 7).
var stage := 1
## Veces que repitió el ciclo actual sin recibir un golpe.
var repeats := 0
var hit_this_cycle := false
## Ataque que está ejecutando (para las pruebas y los efectos).
var current_attack: StringName = &""
var rng := RandomNumberGenerator.new()

var _epoch := 0
var _state_left := 0.0
var _pattern_done := false
var _clock := 0.0
var _flash := 0.0
## Teletransporte en curso (segundos que faltan) y de dónde venía (para dibujar el rastro).
var _blink_left := 0.0
var _blink_from := Vector2.ZERO
var _dodge_cd := 0.0
var _dodges := 0
## Quién decide si un lugar de descanso está disponible (p. ej. la plataforma no está apagada).
var spot_filter := Callable()


func _ready() -> void:
	rank = Rank.JEFE
	ecos_reward = 0  # La recompensa la da el controlador, una sola vez.
	display_name = "Bucle"
	gravity = 0.0
	knockback_resistance = 1.0
	body_size = Vector2(22, 24)
	if config:
		max_health = config.key_hits
		contact_damage = config.attack_damage
	super()
	# No muere: con la vida en cero queda DEFEATED (no se desintegra ni se borra).
	health.died.disconnect(_die)
	contact.deactivate()


## Empieza el combate (después de la introducción).
func begin() -> void:
	if state == State.INTRO:
		_enter(State.PREPARE_PATTERN)


## El ciclo actual (1 a 7).
func cycle() -> int:
	return mini(impacts + 1, config.key_hits)


func cycle_data() -> BucleCycle:
	return config.cycle(cycle())


## Si un golpe ahora cuenta como impacto clave (no mientras parpadea).
func is_vulnerable() -> bool:
	return state in [State.PREPARE_PATTERN, State.EXECUTE_PATTERN, State.FATIGUE] and not hit_this_cycle and _blink_left <= 0.0


func is_blinking() -> bool:
	return _blink_left > 0.0


## Se teletransporta a target (parpadeo corto).
func blink_to(target: Vector2) -> void:
	_blink_from = position
	_blink_left = config.blink_time
	position = target
	Sfx.play(&"dash", 1.6, -8.0)


## Vuelve a empezar (Kai perdió): ciclo 1, sin impactos, en su lugar.
func restore() -> void:
	_epoch += 1
	BucleAttacks.clear(get_tree())
	impacts = 0
	stage = 1
	repeats = 0
	hit_this_cycle = false
	current_attack = &""
	health.restore_full()
	position = Vector2(320, HOVER_Y)
	_blink_left = 0.0
	_dodge_cd = 0.0
	modulate = Color.WHITE
	hurtbox.set_physics_process(true)
	_set_state(State.INTRO)


## Combate ya ganado (se cargó la partida): descansa en su lugar, sin instrucciones ni ataques.
func rest() -> void:
	_epoch += 1
	impacts = config.key_hits
	stage = 1
	ai_enabled = false
	contact.deactivate()
	hurtbox.set_physics_process(false)
	_set_state(State.DEFEATED)


func _ai(delta: float) -> void:
	velocity = Vector2.ZERO
	_blink_left = maxf(_blink_left - delta, 0.0)
	_dodge_cd = maxf(_dodge_cd - delta, 0.0)
	_try_dodge()
	match state:
		State.PREPARE_PATTERN, State.FATIGUE, State.HIT_REACTION, State.TRANSFORMATION:
			_state_left -= delta
			if _state_left <= 0.0:
				_advance()
		State.EXECUTE_PATTERN:
			if _pattern_done:
				_enter(State.FATIGUE)


func _physics_process(delta: float) -> void:
	_clock += delta
	_flash = maxf(_flash - delta, 0.0)
	queue_redraw()
	super(delta)


## Siguiente estado al terminar el reloj del actual.
func _advance() -> void:
	match state:
		State.PREPARE_PATTERN:
			_enter(State.EXECUTE_PATTERN)
		State.FATIGUE:
			# Nadie lo golpeó: se recupera y repite el mismo ciclo (no sube la dificultad).
			repeats += 1
			_enter(State.PREPARE_PATTERN)
		State.HIT_REACTION:
			_enter(State.DEFEATED if impacts >= config.key_hits else State.TRANSFORMATION)
		State.TRANSFORMATION:
			repeats = 0
			hit_this_cycle = false
			_enter(State.PREPARE_PATTERN)


func _enter(next: State) -> void:
	_epoch += 1
	_set_state(next)
	match next:
		State.PREPARE_PATTERN:
			_state_left = config.prepare_time / maxf(cycle_data().speed, 0.1)
			contact.activate()
			cycle_started.emit(cycle(), repeats)
		State.EXECUTE_PATTERN:
			_pattern_done = false
			_run_pattern(_epoch)
		State.FATIGUE:
			current_attack = &""
			_state_left = cycle_data().fatigue_time
			contact.deactivate()  # Cansado: se puede acercar sin que el contacto dañe.
			blink_to(rest_spot())
		State.HIT_REACTION:
			current_attack = &""
			_state_left = config.reaction_time
			contact.deactivate()
			BucleAttacks.clear(get_tree())
		State.TRANSFORMATION:
			_state_left = config.transformation_time
			stage = mini(impacts + 1, config.key_hits)
			transformed.emit(stage)
		State.DEFEATED:
			current_attack = &""
			contact.deactivate()
			hurtbox.set_physics_process(false)
			BucleAttacks.clear(get_tree())
			finished.emit()


func _set_state(next: State) -> void:
	state = next
	state_changed.emit(next)


## --- Impactos clave ---

func _on_hit_received(_hit: HitData) -> void:
	if state == State.DEFEATED:
		return
	if not is_vulnerable():
		hit_ignored.emit()
		Sfx.play(&"enemy_hit", 1.6, -8.0)
		return
	var risky := state == State.EXECUTE_PATTERN
	hit_this_cycle = true
	impacts += 1
	health.take_damage(1.0)
	damaged.emit(1.0)
	_flash = 0.25
	Sfx.play(&"enemy_hit", 0.9)
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -14), [BucleArt.body_color(stage), Color.WHITE], 10, 90.0, Vector2(20, 20), 0.4)
	if config.hit_lines.size() >= impacts:
		SpeechBark.say(self, config.hit_lines[impacts - 1], Vector2(0, -52))
	key_hit.emit(impacts, risky)
	_enter(State.HIT_REACTION)


## --- Movimiento ---

## Un lugar de descanso alcanzable, lejos de Kai (entre rest_min_distance y rest_max_distance), al azar.
func rest_spot() -> Vector2:
	var kai := get_player()
	var options: Array[Vector2] = []
	var fallback := position
	var best := -1.0
	for spot in config.rest_spots:
		if spot_filter.is_valid() and not spot_filter.call(spot):
			continue
		var distance := spot.distance_to(kai.global_position) if kai else 200.0
		if distance >= config.rest_min_distance and distance <= config.rest_max_distance:
			options.append(spot)
		if distance > best and distance <= config.rest_max_distance:
			best = distance
			fallback = spot
	return options[rng.randi_range(0, options.size() - 1)] if not options.is_empty() else fallback


## Un lugar para atacar distinto del actual y no pegado a Kai.
func attack_spot() -> Vector2:
	var kai := get_player()
	var options: Array[Vector2] = []
	for spot in config.attack_spots:
		if spot.distance_to(position) < 60.0:
			continue
		if kai and spot.distance_to(kai.global_position) < 140.0:
			continue
		options.append(spot)
	if options.is_empty():
		return config.attack_spots[rng.randi_range(0, config.attack_spots.size() - 1)]
	return options[rng.randi_range(0, options.size() - 1)]


## Esquiva: si Kai se acerca mientras prepara o ataca, se va a otro lugar.
func _try_dodge() -> void:
	if state not in [State.PREPARE_PATTERN, State.EXECUTE_PATTERN] or not cycle_data().dodge or _dodge_cd > 0.0 or hit_this_cycle:
		return
	var kai := get_player()
	if kai == null or (global_position + BucleArt.CENTER).distance_to(kai.global_position + Vector2(0, -20)) > config.dodge_distance:
		return
	_dodge_cd = config.dodge_cooldown
	_dodges += 1
	blink_to(attack_spot())
	if _dodges % 3 == 1:
		SpeechBark.say(self, DODGE_LINES[int(_dodges / 3.0) % DODGE_LINES.size()], Vector2(0, -52), 1.0)


## --- La secuencia del ciclo ---

func _run_pattern(epoch: int) -> void:
	var data := cycle_data()
	if data.execution_error:
		execution_error.emit(cycle())
	for i in data.attacks.size():
		if epoch != _epoch:
			return
		var attack: StringName = data.attacks[i]
		# Cambia de lugar antes de cada ataque (salvo el primero del ciclo 1: se presenta en su lugar).
		if cycle() > 1 or i > 0:
			blink_to(attack_spot())
			await _wait(config.blink_time)
			if epoch != _epoch:
				return
		current_attack = attack
		var parts := String(attack).split("+", false)
		# Los combinados («a+b») van a la vez: se espera al último.
		for k in parts.size() - 1:
			_attack(StringName(parts[k]), data, epoch)
		await _attack(StringName(parts[parts.size() - 1]), data, epoch)
		if epoch != _epoch:
			return
		await _wait(data.gap / maxf(data.speed, 0.1))
	if epoch == _epoch:
		current_attack = &""
		_pattern_done = true


func _attack(attack: StringName, data: BucleCycle, epoch: int) -> void:
	var telegraph := maxf(data.telegraph, config.min_telegraph)
	var damage := config.attack_damage
	var center := global_position + BucleArt.CENTER
	match attack:
		&"pulso":
			for i in maxi(data.pulse_count, 1):
				if epoch != _epoch:
					return
				BucleAttacks.pulse(get_parent(), global_position, arena, config.pulse_speed * data.speed, telegraph, damage)
				await _wait(telegraph + 0.45 / data.speed)
		&"lluvia":
			var lane_width := arena.size.x / config.rain_lanes
			var kai := get_player()
			var target := int((kai.global_position.x - arena.position.x) / lane_width) if kai else -1
			var lanes := BucleAttacks.rain_lanes(data.rain_blocks, config.rain_lanes, config.min_free_lanes, target, rng)
			BucleAttacks.rain(get_parent(), arena, lanes, config.rain_lanes, config.rain_fall_speed * data.speed, telegraph, damage)
			await _wait(telegraph + 0.6)
		&"anillo":
			var angle := rng.randf_range(0.0, 180.0)
			BucleAttacks.ring(get_parent(), center, config.ring_speed * data.speed, config.ring_width, data.ring_gap, data.ring_spin,
				angle, telegraph, damage)
			await _wait(telegraph + 0.9)
		&"barrido":
			var kai := get_player()
			var y := kai.global_position.y - 14.0 if kai else arena.end.y - 14.0
			BucleAttacks.sweep(get_parent(), arena, y, telegraph, config.sweep_live, damage)
			await _wait(telegraph + config.sweep_live)
		&"rastreo":
			BucleAttacks.seekers(get_parent(), center, arena, maxi(data.seeker_count, 1), get_player(),
				config.seeker_speed * data.speed, config.seeker_turn, config.seeker_life, telegraph, damage)
			await _wait(telegraph + 0.8)


## Espera con el tiempo de las amenazas (el Dominio Nulo la alarga).
func _wait(seconds: float) -> void:
	await CombatClock.wait(self, maxf(seconds, 0.0))


## --- Dibujo ---

func _draw() -> void:
	var mood: StringName = &""
	match state:
		State.FATIGUE:
			mood = &"cansado"
		State.HIT_REACTION:
			mood = &"golpe"
		State.DEFEATED:
			mood = &"libre"
	if state == State.PREPARE_PATTERN:
		# Anuncia la secuencia: un anillo que se cierra sobre él.
		var t := 1.0 - clampf(_state_left / maxf(config.prepare_time, 0.01), 0.0, 1.0)
		draw_arc(BucleArt.CENTER, 40.0 - t * 22.0, 0.0, TAU, 32, Color(BucleArt.body_color(stage), 0.6), 2.0)
	var shown_stage := stage if state != State.DEFEATED else 1
	if _blink_left > 0.0:
		# Rastro del teletransporte: un eco que se desvanece donde estaba.
		var t := _blink_left / maxf(config.blink_time, 0.01)
		draw_set_transform(_blink_from - position)
		draw_arc(BucleArt.CENTER, BucleArt.BODY_RADIUS + 4.0, 0, TAU, 20, Color(BucleArt.body_color(stage), 0.6 * t), 2.0)
		draw_set_transform(Vector2.ZERO)
		modulate.a = 1.0 - t * 0.7
	else:
		modulate.a = 1.0
	BucleArt.draw(self, shown_stage, _clock, mood, GameSettings.glitch_factor())
	if _flash > 0.0:
		draw_circle(BucleArt.CENTER, BucleArt.BODY_RADIUS + 3.0, Color(1, 1, 1, _flash * 3.0))
	if state == State.FATIGUE:
		draw_string(ThemeDB.fallback_font, BucleArt.CENTER + Vector2(10, -16), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(Color.WHITE, 0.6))
