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
##   INTRO → PREPARE_PATTERN → EXECUTE_PATTERN → FATIGUE ─(sin golpe)→ PREPARE_PATTERN (el mismo ciclo otra vez)
##   en los ciclos sin descanso (no_fatigue): EXECUTE_PATTERN ─(sin golpe)→ PREPARE_PATTERN
##   golpe válido en EXECUTE / FATIGUE → HIT_REACTION → TRANSFORMATION → PREPARE (ciclo + 1)
##   el séptimo → HIT_REACTION → DEFEATED (se queda en la arena: no muere).
## Golpear durante EXECUTE es un golpe arriesgado (key_hit con risky = true: el controlador lo premia).
## Al cambiar de estado se cancelan los ataques en curso (época) y se borran los peligros.
##
## Ciclo infinito: cada vez que repite un ciclo sin recibir golpe va más rápido y suma un ataque (hasta
## BucleConfig.max_repeats), con un contador ×2, ×3... sobre él. Variantes de cada ciclo (BucleCycle): la
## Iteración, el Desbordamiento, la Recursión, ataques combinados («a+b»), las Copias del proceso (clones
## que también atacan: solo el verdadero recibe golpes), las tareas pendientes (romperlas todas corta la
## secuencia y lo cansa por más tiempo; si no, descansa muy poco), el descanso en distintos lugares y los
## Errores de ejecución.

signal state_changed(state: State)
## count: impactos hasta ahora (1 a 7). risky: llegó mientras atacaba.
signal key_hit(count: int, risky: bool)
## Golpe que no cuenta (invulnerable, ya recibió el de este ciclo o le pegó a una copia).
signal hit_ignored
## number: ciclo (1 a 7); repeat: veces que lo repitió sin recibir golpe.
signal cycle_started(number: int, repeat: int)
signal transformed(stage: int)
## Pide al controlador un Error de ejecución (apagar plataformas un rato: cycle_data().error_platforms).
signal execution_error(number: int)
signal finished
## Soltó una repulsión (Kai estaba pegado a él).
signal repulsed
## Aparecieron las tareas pendientes (count) / Kai las rompió todas (se cumplió la condición de salida).
signal tasks_spawned(count: int)
signal condition_broken
## Aparecieron las Copias del proceso.
signal copies_spawned

enum State { INTRO, PREPARE_PATTERN, EXECUTE_PATTERN, FATIGUE, HIT_REACTION, TRANSFORMATION, DEFEATED }

## Dónde se pone en cada ciclo (x): cambia de lugar en algunos; en el último queda atrapado en el centro.
const ANCHORS: Array[float] = [320.0, 320.0, 200.0, 440.0, 320.0, 200.0, 320.0]
## Altura donde flota si la escena no dice otra (hover_y): abajo, sobre el piso.
const HOVER_Y := 296.0
const TINT := preload("res://characters/enemies/bucle/bucle_tint.gdshader")
## Con las copias, cuánto va y viene cada uno (poco: si no, se cruzan).
const COPY_SWAY := 26.0

@export var config: BucleConfig
## Límites de la arena: x de las paredes, y de arriba y del suelo (los ataques la usan).
@export var arena := Rect2(40, 40, 560, 264)
## Dónde flota (y) y la plataforma sobre la que está (en la arena de Ariel, el puente de arriba). Si tiene
## ancho, el Pulso también corre por ella (si no, pararse junto a Bucle lo esquivaría siempre).
@export var hover_y := HOVER_Y
@export var perch := Rect2()
## Mientras ataca sube rise px (fuera del alcance de un tajo desde el puente: hay que saltar) y va y viene
## drift px a cada lado de su lugar. Cansado baja: la ventana clara para golpearlo.
@export var rise := 76.0
@export var drift := 70.0
## Empuje a Kai cuando un golpe rebota en el escudo o cuando recibe un impacto (para no quedarse pegado).
@export var push := Vector2(260, -150)
## Dónde puede cansarse en los ciclos con roam_fatigue (su posición: los pies, 5 px arriba de lo que pisa):
## puntos del puente y las plataformas de los costados. Nunca en una plataforma apagada.
@export var fatigue_spots: PackedVector2Array = []
## Dónde pueden aparecer las tareas pendientes (arriba de las plataformas).
@export var task_spots: PackedVector2Array = []
## Alturas (y del centro) del hueco de la Iteración: el suelo, las plataformas de los costados y el puente
## con los pilares.
@export var iteration_levels := PackedFloat32Array([280.0, 228.0, 178.0])

var state := State.INTRO
var impacts := 0
## Etapa visual (1 a 7).
var stage := 1
## Veces que repitió el ciclo actual sin recibir un golpe (el contador ×2, ×3...).
var repeats := 0
var hit_this_cycle := false
## Ataque que está ejecutando (para las pruebas y los efectos).
var current_attack: StringName = &""
var rng := RandomNumberGenerator.new()
## Tareas pendientes de esta secuencia y si Kai las rompió todas.
var tasks: Array[PendingTask] = []
var condition_met := false
## Copias del proceso en la arena.
var clones: Array[BucleClone] = []

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
## Espera hasta la próxima repulsión.
var _repulse_cd := 0.0
## Dónde se cansa esta vez, si ya llegó y el último lugar que usó (para no repetirlo).
var _rest := Vector2.ZERO
var _arrived := false
var _last_spot := -1
## Tareas que aparecieron en esta secuencia (0 = descanso normal).
var _tasks_total := 0
## Con las copias: los tres lugares (x) y cuál es el del verdadero (-1 = sin copias).
var _slots: Array[float] = []
var _real_slot := -1
var _counter_flash := 0.0


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
	_rest = position
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


## Velocidad de los ataques ahora: la del ciclo, más rápida cada vez que lo repite (ciclo infinito).
func attack_speed() -> float:
	return cycle_data().speed * (1.0 + config.repeat_speed * mini(repeats, config.max_repeats))


## La secuencia ahora: la del ciclo y, por cada repetición, un ataque más (ciclo infinito).
func sequence() -> Array[StringName]:
	var data := cycle_data()
	var steps: Array[StringName] = data.attacks.duplicate()
	for i in mini(repeats, config.max_repeats):
		steps.append(data.attacks[i % data.attacks.size()])
	return steps


## Si un golpe ahora cuenta como impacto clave: mientras ataca (arriba: hay que saltar) o cansado. Mientras
## anuncia la secuencia y mientras sube tiene escudo (los golpes rebotan y empujan a Kai).
func is_vulnerable() -> bool:
	if hit_this_cycle:
		return false
	# Mientras ataca, recién cuando llegó arriba (mientras sube sigue con el escudo).
	return state == State.FATIGUE or (state == State.EXECUTE_PATTERN and position.y <= hover_y - rise * 0.85)


## Dónde se cansa esta vez (su posición).
func rest_spot() -> Vector2:
	return _rest


## Si ya llegó a donde se cansa (desde ahí corre el descanso).
func is_resting() -> bool:
	return state == State.FATIGUE and _arrived


## Segundos desde que empezó la animación actual (las copias la siguen igual).
func anim_time() -> float:
	return _clock - _anim_since


## Vuelve a empezar (Kai perdió): ciclo 1, sin impactos, en su lugar.
func restore() -> void:
	_epoch += 1
	BucleAttacks.clear(get_tree())
	clones.clear()
	tasks.clear()
	_real_slot = -1
	_last_spot = -1
	condition_met = false
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
	repeats = 0
	ai_enabled = false
	contact.deactivate()
	hurtbox.set_physics_process(false)
	_set_state(State.DEFEATED)


func _ai(delta: float) -> void:
	velocity = Vector2.ZERO
	match state:
		State.PREPARE_PATTERN, State.HIT_REACTION, State.TRANSFORMATION:
			_tick(delta)
		State.FATIGUE:
			# El descanso corre desde que llegó a donde se cansa.
			_arrived = _arrived or position.distance_to(_rest) < 2.0
			if _arrived:
				_tick(delta)
		State.EXECUTE_PATTERN:
			if _pattern_done:
				_end_sequence()
	_float(delta)
	_check_repulse(delta)


func _tick(delta: float) -> void:
	_state_left -= delta
	if _state_left <= 0.0:
		_advance()


## Terminó la secuencia sin recibir golpe: se cansa o, en los ciclos sin descanso, vuelve a empezar.
func _end_sequence() -> void:
	if cycle_data().no_fatigue:
		repeats += 1
		_enter(State.PREPARE_PATTERN)
	else:
		_enter(State.FATIGUE)


## Dónde flota: mientras ataca, arriba y yendo y viniendo sobre el puente (sin salirse de él); cansado, donde
## se cansa (puede ser una plataforma de un costado); en lo demás, abajo en su lugar (al transformarse, va
## hacia el lugar del ciclo nuevo).
func _float(delta: float) -> void:
	if state in [State.INTRO, State.DEFEATED]:
		return
	var target := Vector2(_anchor_x, hover_y)
	var rate := 150.0
	var on_perch := true
	match state:
		State.EXECUTE_PATTERN:
			var home := _slots[_real_slot] if _real_slot >= 0 else _anchor_x
			var sway := COPY_SWAY if _real_slot >= 0 else drift
			target = Vector2(home + sin(_clock * 1.3) * sway, hover_y - rise)
			rate = 190.0 * attack_speed()
		State.FATIGUE:
			target = _rest
			rate = 320.0
			on_perch = false
		State.PREPARE_PATTERN:
			rate = 280.0  # Vuelve a su lugar (si se cansó en otra parte).
		State.TRANSFORMATION:
			rate = 220.0
	if on_perch and perch.size.x > 0.0:
		target.x = clampf(target.x, perch.position.x + 16.0, perch.end.x - 16.0)
	position = position.move_toward(target, rate * delta)
	_move_clones(delta)


## Repulsión: si Kai se queda pegado mientras Bucle anuncia o ataca, estalla alrededor (con aviso).
func _check_repulse(delta: float) -> void:
	_repulse_cd = maxf(_repulse_cd - CombatClock.scaled(delta), 0.0)
	if _repulse_cd > 0.0 or state not in [State.PREPARE_PATTERN, State.EXECUTE_PATTERN]:
		return
	var kai := get_player()
	var center := global_position + BucleArt.CENTER
	if kai == null or (kai.global_position + Vector2(0, -20)).distance_to(center) > config.repulse_range:
		return
	_repulse_cd = config.repulse_cooldown / maxf(attack_speed(), 0.1)
	var burst := RepulseBurst.new()
	burst.radius = config.repulse_radius
	burst.telegraph = maxf(config.repulse_telegraph / attack_speed(), config.min_telegraph)
	burst.damage = config.attack_damage
	burst.color = BucleArt.body_color(stage)
	get_parent().add_child(burst)
	burst.global_position = center
	repulsed.emit()


## Empuja a Kai hacia el lado contrario (rebote en el escudo, en una copia o al recibir un impacto).
func _push_player(from := Vector2.INF) -> void:
	var kai := get_player()
	var origin := global_position if from == Vector2.INF else from
	if kai == null or kai.global_position.distance_to(origin) > 90.0:
		return
	var away := 1.0 if kai.global_position.x >= origin.x else -1.0
	kai.velocity = Vector2(away * push.x, push.y)


func _physics_process(delta: float) -> void:
	_clock += delta
	_flash = maxf(_flash - delta, 0.0)
	_shield_flash = maxf(_shield_flash - delta, 0.0)
	_counter_flash = maxf(_counter_flash - delta, 0.0)
	queue_redraw()
	_body.queue_redraw()
	super(delta)


## Siguiente estado al terminar el reloj del actual.
func _advance() -> void:
	match state:
		State.PREPARE_PATTERN:
			_enter(State.EXECUTE_PATTERN)
		State.FATIGUE:
			# Nadie lo golpeó: se recupera y repite el ciclo, más rápido y con un ataque más (ciclo infinito).
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
			_state_left = config.prepare_time / maxf(attack_speed(), 0.1)
			contact.activate()
			condition_met = false
			_tasks_total = 0
			if repeats > 0:
				_counter_flash = 0.5
			cycle_started.emit(cycle(), repeats)
		State.EXECUTE_PATTERN:
			_pattern_done = false
			_run_pattern(_epoch)
		State.FATIGUE:
			current_attack = &""
			_clear_clones()
			_clear_tasks()
			_rest = _pick_rest()
			_arrived = false
			_state_left = _fatigue_time()
			contact.deactivate()  # Cansado: se puede acercar sin que el contacto dañe.
		State.HIT_REACTION:
			current_attack = &""
			_state_left = config.reaction_time
			contact.deactivate()
			BucleAttacks.clear(get_tree())
			_clear_clones()
			tasks.clear()
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
			_clear_clones()
			tasks.clear()
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


## Una copia recibió un tajo: no cuenta y Kai rebota.
func copy_hit(clone: BucleClone) -> void:
	hit_ignored.emit()
	Sfx.play(&"enemy_hit", 1.8, -8.0)
	_push_player(clone.global_position)


## --- Dónde se cansa ---

func _fatigue_time() -> float:
	var data := cycle_data()
	if _tasks_total <= 0:
		return data.fatigue_time
	# Romper la condición: rotas todas las tareas, descansa más; si no, casi nada.
	return data.fatigue_time + config.condition_bonus if condition_met else config.unbroken_fatigue


func _pick_rest() -> Vector2:
	var home := Vector2(_anchor_x, hover_y)
	if perch.size.x > 0.0:
		home.x = clampf(home.x, perch.position.x + 16.0, perch.end.x - 16.0)
	if not cycle_data().roam_fatigue or fatigue_spots.is_empty():
		return home
	var options: Array[int] = []
	for i in fatigue_spots.size():
		if i != _last_spot and _ground_open(fatigue_spots[i] + Vector2(0, 5)):
			options.append(i)
	if options.is_empty():
		return home
	_last_spot = options[rng.randi_range(0, options.size() - 1)]
	return fatigue_spots[_last_spot]


## Si lo que hay en at (arriba de una plataforma) se puede pisar: no está apagado por un Error de ejecución.
func _ground_open(at: Vector2) -> bool:
	for node in get_tree().get_nodes_in_group(&"unsafe_ground"):
		var platform := node as DataPlatform
		if platform and absf(platform.global_position.y - at.y) <= 8.0 and at.x >= platform.global_position.x - 4.0 \
				and at.x <= platform.global_position.x + platform.width + 4.0:
			return false
	return true


## --- Romper la condición ---

func _spawn_tasks(count: int) -> void:
	tasks.clear()
	var options: Array[Vector2] = []
	for spot in task_spots:
		if _ground_open(spot):
			options.append(spot)
	while tasks.size() < count and not options.is_empty():
		var spot: Vector2 = options.pop_at(rng.randi_range(0, options.size() - 1))
		var task := PendingTask.new()
		get_parent().add_child(task)
		task.global_position = spot
		task.broken.connect(_on_task_broken.bind(_epoch))
		tasks.append(task)
	_tasks_total = tasks.size()
	if _tasks_total > 0:
		tasks_spawned.emit(_tasks_total)


func _on_task_broken(epoch: int) -> void:
	if epoch != _epoch or state != State.EXECUTE_PATTERN:
		return
	for task in tasks:
		if is_instance_valid(task) and not task.is_broken():
			return
	# Todas rotas: se cumple la condición de salida. La secuencia se corta y se cansa por más tiempo.
	condition_met = true
	condition_broken.emit()
	SpeechBark.say(self, "¿La condición... se cumplió?", Vector2(0, -52))
	BucleAttacks.clear(get_tree())
	_enter(State.FATIGUE)


func _clear_tasks() -> void:
	for task in tasks:
		if is_instance_valid(task) and not task.is_queued_for_deletion():
			PixelBurst.spawn(get_parent(), task.global_position + Vector2(0, -PendingTask.LIFT), [PendingTask.COLOR], 6, 40.0, PendingTask.SIZE, 0.3)
			task.queue_free()
	tasks.clear()


## --- Copias del proceso ---

## Aparecen las dos copias: los tres en sus lugares a la vez (con un destello), así no se puede seguir al
## verdadero con la vista; lo delata la flecha de ciclo (BucleArt.draw_cycle_arrow).
func _spawn_clones() -> void:
	_clear_clones()
	var middle := perch.get_center().x if perch.size.x > 0.0 else _anchor_x
	var half := perch.size.x / 2.0 - 56.0 if perch.size.x > 0.0 else 120.0
	_slots = [middle - half, middle, middle + half]
	_real_slot = rng.randi_range(0, 2)
	position.x = _slots[_real_slot]
	_flash = 0.2
	for i in _slots.size():
		PixelBurst.spawn(get_parent(), Vector2(_slots[i], position.y) + BucleArt.CENTER, [BucleArt.body_color(stage), Color.WHITE], 10, 80.0, Vector2(20, 20), 0.35)
		if i == _real_slot:
			continue
		var clone := BucleClone.new()
		clone.boss = self
		get_parent().add_child(clone)
		clone.global_position = Vector2(_slots[i], global_position.y)
		clones.append(clone)
	copies_spawned.emit()


func _move_clones(delta: float) -> void:
	if _real_slot < 0:
		return
	var others := _slots.duplicate()
	others.remove_at(_real_slot)
	for i in clones.size():
		var clone := clones[i]
		if not is_instance_valid(clone) or i >= others.size():
			continue
		var target := Vector2(others[i] + sin(_clock * 1.3) * COPY_SWAY, global_position.y)
		clone.global_position = clone.global_position.move_toward(target, 190.0 * attack_speed() * delta)


## Cada copia tira un mini anillo hacia Kai (con aviso).
func _copies_shoot(telegraph: float, damage: float) -> void:
	var kai := get_player()
	if kai == null:
		return
	for clone in clones:
		if is_instance_valid(clone):
			var aim := kai.global_position + Vector2(0, -10) - clone.center()
			BucleAttacks.shard(get_parent(), clone.center(), aim, config.copy_shot_speed * attack_speed(), 560.0, telegraph, damage,
				BucleArt.body_color(stage))


func _clear_clones() -> void:
	for clone in clones:
		if is_instance_valid(clone) and not clone.is_queued_for_deletion():
			clone.vanish()
	clones.clear()
	_real_slot = -1


## --- La secuencia del ciclo ---

func _run_pattern(epoch: int) -> void:
	var data := cycle_data()
	if data.execution_error:
		execution_error.emit(cycle())
	if data.copies:
		_spawn_clones()
	if data.condition_nodes > 0:
		_spawn_tasks(data.condition_nodes)
	for step in sequence():
		if epoch != _epoch:
			return
		await _attack_step(step, data, epoch)
		if epoch != _epoch:
			return
		await _wait(data.gap / maxf(attack_speed(), 0.1))
	if epoch == _epoch:
		current_attack = &""
		_pattern_done = true


## Un paso de la secuencia: un ataque, o dos a la vez («pulso+anillo»). Las copias tiran lo suyo.
func _attack_step(step: StringName, data: BucleCycle, epoch: int) -> void:
	var parts := String(step).split("+", false)
	current_attack = StringName(parts[0])
	if not clones.is_empty():
		_copies_shoot(maxf(data.telegraph, config.min_telegraph), config.attack_damage)
	if parts.size() == 1:
		await _attack(current_attack, data, epoch)
		return
	# Combinados: los lanza a la vez y sigue cuando terminaron todos.
	var running := [parts.size()]
	for part in parts:
		_attack_counted(StringName(part), data, epoch, running)
	while running[0] > 0 and epoch == _epoch and is_inside_tree():
		await get_tree().physics_frame


func _attack_counted(attack: StringName, data: BucleCycle, epoch: int, running: Array) -> void:
	await _attack(attack, data, epoch)
	running[0] -= 1


func _attack(attack: StringName, data: BucleCycle, epoch: int) -> void:
	var telegraph := maxf(data.telegraph, config.min_telegraph)
	var damage := config.attack_damage
	var center := global_position + BucleArt.CENTER
	var rate := attack_speed()
	match attack:
		&"pulso":
			for i in maxi(data.pulse_count, 1):
				if epoch != _epoch:
					return
				BucleAttacks.pulse(get_parent(), global_position, arena, config.pulse_speed * rate, telegraph, damage)
				if perch.size.x > 0.0:
					# Y por la plataforma donde está él (de la x de Bucle hacia sus dos bordes).
					BucleAttacks.pulse(get_parent(), Vector2(global_position.x, perch.position.y), Rect2(perch.position.x, 0.0, perch.size.x, perch.position.y), config.pulse_speed * rate, telegraph, damage)
				await _wait(telegraph + 0.45 / rate)
		&"lluvia":
			var lane_width := arena.size.x / config.rain_lanes
			var kai := get_player()
			var target := int((kai.global_position.x - arena.position.x) / lane_width) if kai else -1
			# Desbordamiento: los bloques apilados cuentan como carriles tapados (siempre quedan libres).
			var taken: Array[int] = []
			if data.overflow:
				taken = BucleAttacks.stacked_lanes(get_tree())
			var lanes := BucleAttacks.rain_lanes(data.rain_blocks, config.rain_lanes, config.min_free_lanes, target, rng, taken)
			BucleAttacks.rain(get_parent(), arena, lanes, config.rain_lanes, config.rain_fall_speed * rate, telegraph, damage,
				config.overflow_time if data.overflow else 0.0, config.overflow_stack)
			await _wait(telegraph + 0.6)
		&"anillo":
			var angle := rng.randf_range(0.0, 180.0)
			var ring := BucleAttacks.ring(get_parent(), center, config.ring_speed * rate, config.ring_width, data.ring_gap, data.ring_spin,
				angle, telegraph, damage)
			if data.ring_split:
				# Recursión: lejos se divide en anillos chicos que vuelven.
				ring.split_radius = config.split_radius
				ring.split_count = config.split_count
				ring.split_speed = config.split_speed * rate
				ring.split_telegraph = config.min_telegraph
			await _wait(telegraph + 0.9)
		&"iteracion":
			# Sale del lado contrario a Kai: le da tiempo de ver el camino del hueco y llegar.
			var kai := get_player()
			var from_left := kai == null or kai.global_position.x >= arena.get_center().x
			var left_x := arena.position.x - 46.0
			var right_x := arena.end.x + 46.0
			var level := rng.randi_range(0, iteration_levels.size() - 1)
			for i in maxi(data.iteration_beams, 1):
				if epoch != _epoch:
					return
				var next := _other_level(level)
				var second := iteration_levels[next] if data.iteration_split else iteration_levels[level]
				BucleAttacks.iteration(get_parent(), left_x if from_left else right_x, right_x if from_left else left_x, 0.0, arena.end.y,
					config.iteration_speed * rate, iteration_levels[level], second, config.iteration_gap, telegraph, damage)
				level = next
				await _wait(telegraph + 1.4 / rate)
			await _wait(0.5 / rate)


## Otra altura de hueco (distinta de level).
func _other_level(level: int) -> int:
	var count := iteration_levels.size()
	if count < 2:
		return level
	return (level + rng.randi_range(1, count - 1)) % count


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
	if not clones.is_empty():
		BucleArt.draw_cycle_arrow(self, _clock, 1.0, BucleArt.body_color(stage))
	if state == State.FATIGUE:
		draw_string(ThemeDB.fallback_font, BucleArt.CENTER + Vector2(10, -16), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(Color.WHITE, 0.6))
	draw_counter(self)


## Ciclo infinito: cuántas veces va repitiendo el mismo ciclo (×2, ×3...). Las copias lo muestran igual (si
## no, lo delataría).
func draw_counter(c: CanvasItem) -> void:
	if repeats <= 0 or state not in [State.PREPARE_PATTERN, State.EXECUTE_PATTERN, State.FATIGUE]:
		return
	var font := ThemeDB.fallback_font
	var text := "×%d" % (repeats + 1)
	c.draw_set_transform(Vector2(30, -40), 0.0, Vector2.ONE * (1.0 + _counter_flash))
	c.draw_string_outline(font, Vector2(-6, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, BucleArt.OUTLINE)
	c.draw_string(font, Vector2(-6, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ff5a3c").lightened(0.3 * _counter_flash))
	c.draw_set_transform(Vector2.ZERO)


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
				&"pulso", &"iteracion":
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
