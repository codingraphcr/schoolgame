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

## Dónde se pone en cada ciclo (x): cambia de lugar en algunos; en el último queda atrapado en el centro.
const ANCHORS: Array[float] = [320.0, 320.0, 200.0, 440.0, 320.0, 200.0, 320.0]
## Altura donde flota si la escena no dice otra (hover_y): abajo, sobre el piso.
const HOVER_Y := 296.0
const TINT := preload("res://characters/enemies/bucle/bucle_tint.gdshader")

@export var config: BucleConfig
## Límites de la arena: x de las paredes, y de arriba y del suelo (los ataques la usan).
@export var arena := Rect2(40, 40, 560, 264)
## Dónde flota (y) y la plataforma sobre la que está (en la arena de Ariel, el puente de arriba). Si tiene
## ancho, el Pulso también corre por ella (si no, pararse junto a Bucle lo esquivaría siempre).
@export var hover_y := HOVER_Y
@export var perch := Rect2()
## Mientras ataca sube rise px (fuera del alcance de un tajo desde el puente: hay que saltar) y va y viene
## drift px a cada lado de su lugar. Cansado baja a hover_y: la ventana clara para golpearlo.
@export var rise := 76.0
@export var drift := 70.0
## Empuje a Kai cuando un golpe rebota en el escudo o cuando recibe un impacto (para no quedarse pegado).
@export var push := Vector2(260, -150)

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
## El cuerpo (sprites de Ariel con el color de la etapa) y su animación en curso.
var _body: Node2D
var _anim := ""
var _anim_since := 0.0
## Su lugar (x) en este ciclo: cambia al transformarse (ANCHORS).
var _anchor_x := 0.0
var _shield_flash := 0.0


func _ready() -> void:
	rank = Rank.JEFE
	ecos_reward = 0  # La recompensa la da el controlador, una sola vez.
	display_name = "Bucle"
	gravity = 0.0
	knockback_resistance = 1.0
	body_size = Vector2(22, 24)
	_body = Node2D.new()
	_body.name = "Cuerpo"
	var tint := ShaderMaterial.new()
	tint.shader = TINT
	_body.material = tint
	add_child(_body)
	_body.draw.connect(_draw_body)
	if config:
		max_health = config.key_hits
		contact_damage = config.attack_damage
	super()
	_anchor_x = position.x
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


## Si un golpe ahora cuenta como impacto clave: mientras ataca (arriba: hay que saltar) o cansado (abajo, en el
## puente). Mientras anuncia la secuencia tiene escudo (los golpes rebotan y empujan a Kai).
func is_vulnerable() -> bool:
	return state in [State.EXECUTE_PATTERN, State.FATIGUE] and not hit_this_cycle


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
	position.x = ANCHORS[0]
	_anchor_x = position.x
	position.y = hover_y
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
	match state:
		State.PREPARE_PATTERN, State.FATIGUE, State.HIT_REACTION, State.TRANSFORMATION:
			_state_left -= delta
			if _state_left <= 0.0:
				_advance()
		State.EXECUTE_PATTERN:
			if _pattern_done:
				_enter(State.FATIGUE)
	_float(delta)


## Dónde flota: mientras ataca, arriba y yendo y viniendo sobre el puente (sin salirse de él); en lo demás,
## abajo en su lugar (al transformarse, va hacia el lugar del ciclo nuevo).
func _float(delta: float) -> void:
	if state in [State.INTRO, State.DEFEATED]:
		return
	var target := Vector2(_anchor_x, hover_y)
	var speed := 220.0 if state == State.TRANSFORMATION else 150.0
	if state == State.EXECUTE_PATTERN:
		target = Vector2(_anchor_x + sin(_clock * 1.3) * drift, hover_y - rise)
		speed = 190.0 * cycle_data().speed
	if perch.size.x > 0.0:
		target.x = clampf(target.x, perch.position.x + 16.0, perch.end.x - 16.0)
	position = position.move_toward(target, speed * delta)


## Empuja a Kai hacia el lado contrario (rebote en el escudo o al recibir un impacto).
func _push_player() -> void:
	var kai := get_player()
	if kai == null or kai.global_position.distance_to(global_position) > 90.0:
		return
	var away := 1.0 if kai.global_position.x >= global_position.x else -1.0
	kai.velocity = Vector2(away * push.x, push.y)


func _physics_process(delta: float) -> void:
	_clock += delta
	_flash = maxf(_flash - delta, 0.0)
	_shield_flash = maxf(_shield_flash - delta, 0.0)
	queue_redraw()
	_body.queue_redraw()
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
		State.HIT_REACTION:
			current_attack = &""
			_state_left = config.reaction_time
			contact.deactivate()
			BucleAttacks.clear(get_tree())
		State.TRANSFORMATION:
			_state_left = config.transformation_time
			stage = mini(impacts + 1, config.key_hits)
			transformed.emit(stage)
			# Se va a su lugar del ciclo nuevo (lo mueve _float).
			_anchor_x = ANCHORS[clampi(stage - 1, 0, ANCHORS.size() - 1)]
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
		# El golpe rebota (en el escudo o mientras reacciona): Kai sale despedido.
		_shield_flash = 0.3
		_push_player()
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
	_push_player()
	_enter(State.HIT_REACTION)


## --- La secuencia del ciclo ---

func _run_pattern(epoch: int) -> void:
	var data := cycle_data()
	if data.execution_error:
		execution_error.emit(cycle())
	for attack in data.attacks:
		if epoch != _epoch:
			return
		current_attack = attack
		await _attack(attack, data, epoch)
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
				if perch.size.x > 0.0:
					# Y por la plataforma donde está él (de la x de Bucle hacia sus dos bordes).
					BucleAttacks.pulse(get_parent(), Vector2(global_position.x, perch.position.y), Rect2(perch.position.x, 0.0, perch.size.x, perch.position.y), config.pulse_speed * data.speed, telegraph, damage)
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


## Espera con el tiempo de las amenazas (el Dominio Nulo la alarga).
func _wait(seconds: float) -> void:
	await CombatClock.wait(self, maxf(seconds, 0.0))


## --- Dibujo ---

func _draw() -> void:
	if state == State.PREPARE_PATTERN:
		# Anuncia la secuencia: un anillo que se cierra sobre él.
		var t := 1.0 - clampf(_state_left / maxf(config.prepare_time, 0.01), 0.0, 1.0)
		draw_arc(BucleArt.CENTER, 40.0 - t * 22.0, 0.0, TAU, 32, Color(BucleArt.body_color(stage), 0.6), 2.0)
		# Escudo: mientras anuncia, los golpes rebotan.
		var color := BucleArt.body_color(stage)
		draw_circle(BucleArt.CENTER, 17.0, Color(color, 0.12 + 0.25 * _shield_flash / 0.3))
		for k in 6:
			var a := _clock * 2.0 + k * TAU / 6.0
			draw_arc(BucleArt.CENTER, 17.0, a, a + 0.6, 6, Color(color.lightened(0.4), 0.8), 1.5)
	BucleArt.draw_around(self, _shown_stage(), _clock, GameSettings.glitch_factor())
	if state == State.FATIGUE:
		draw_string(ThemeDB.fallback_font, BucleArt.CENTER + Vector2(10, -16), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(Color.WHITE, 0.6))


## El cuerpo (los sprites de Ariel): va en su propio nodo, encima de lo de alrededor, con el shader que le da
## el color de la etapa.
func _draw_body() -> void:
	var anim := current_anim()
	if anim != _anim:
		_anim = anim
		_anim_since = _clock
	_body.material.set_shader_parameter(&"target", BucleArt.body_color(_shown_stage()))
	if not BucleArt.draw_sprite(_body, anim, _clock - _anim_since, _shown_stage(), _clock):
		BucleArt.draw_fallback(_body, _shown_stage(), _clock, _mood())
	if _flash > 0.0:
		_body.draw_circle(BucleArt.CENTER, BucleArt.BODY_RADIUS + 3.0, Color(1, 1, 1, _flash * 3.0))


## La animación de la hoja de Ariel para el estado actual (y, al atacar, para el ataque).
func current_anim() -> String:
	match state:
		State.PREPARE_PATTERN:
			return "preparar"
		State.EXECUTE_PATTERN:
			match current_attack:
				&"pulso":
					return "onda"
				&"lluvia":
					return "lluvia"
				&"anillo":
					return "anillo"
			return "preparar"
		State.FATIGUE:
			return "aturdido"
		State.HIT_REACTION:
			return "dano"
		State.TRANSFORMATION:
			return "recarga"
		State.DEFEATED:
			return "derrota"
	return "quieto"


func _mood() -> StringName:
	match state:
		State.FATIGUE:
			return &"cansado"
		State.HIT_REACTION:
			return &"golpe"
		State.PREPARE_PATTERN, State.EXECUTE_PATTERN:
			return &"preparando"
		State.DEFEATED:
			return &"libre"
	return &""


func _shown_stage() -> int:
	return stage if state != State.DEFEATED else 1
