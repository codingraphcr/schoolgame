class_name SiblingBoss
extends EnemyBase
## Base de Glitch y Chip, el jefe doble del Capítulo 1 (diseño de Ariel: glitch_chip_concepto.webp).
## Los ataques los ordena el DualBossController (secuencias fijas por fase: «más rápidos, pero no
## aleatorios»); entre ataque y ataque cada hermano se mueve por su cuenta (_idle_move).
##
## - Vida compartida: share_health() hace que los dos usen la misma barra (funcionan como una unidad).
## - Aturdido: stagger_hits golpes seguidos lo dejan mareado stun_time segundos (incapacitated). El
##   controlador hace que el otro deje su ataque y lo proteja (guard_for).
## - Nunca mueren: con la vida en cero quedan **neutralizados** (mareados en el piso) y no se borran.
## - Todo ataque empieza con telegraph(): una señal de aviso esquivable (un «!» de su color).
## - frozen: la fase segura del escudo (no hacen nada). busy: están en un ataque.
## - tempo / telegraph_scale: la Fase 3 (Furia fraternal) los hace más rápidos.
## Los tiempos corren con la física (siempre igual aunque la computadora vaya lenta).

signal neutralized(boss: SiblingBoss)
signal attack_started(attack: StringName)
signal incapacitated(boss: SiblingBoss)
signal recovered(boss: SiblingBoss)

const FLOOR_Y := 304.0

@export var config: DualBossConfig
## Límites de la arena (x mínima y máxima donde se mueven).
var arena_left := 40.0
var arena_right := 600.0
var enraged := false
var busy := false
var stunned := false
## Si está protegiendo a su hermano aturdido.
var guarding: SiblingBoss
var frozen := false:
	set(value):
		frozen = value
		if value:
			interrupt()
## 1 = normal; en la Fase 3 se mueven y atacan más rápido.
var tempo := 1.0
var telegraph_scale := 1.0
## Hacia dónde mira (1 derecha, −1 izquierda).
var face := -1.0
## Lugar donde empiezan (para restore()).
var home := Vector2.ZERO
## Ataque del último aviso (para dibujarlo y para las pruebas).
var last_attack: StringName = &""

var _telegraph := 0.0
var _telegraph_kind: StringName = &""
var _clock := 0.0
## Cambia cada vez que se interrumpen los ataques (aturdido, congelado, neutralizado, reinicio): un
## ataque en curso que ve otra época se termina solo.
var _epoch := 0
var _stun_left := 0.0
var _hits: Array[float] = []
var _trail: Array[Vector2] = []
var _lean := 0.0
var _squash := Vector2.ONE


func _ready() -> void:
	rank = Rank.JEFE
	ecos_reward = 0  # La recompensa la da el final del capítulo (una sola vez).
	knockback_resistance = 0.9
	hurt_time = 0.1
	body_size = Vector2(18, 42)
	super()
	home = global_position
	hurtbox.hit_blocked.connect(_on_hit_blocked)


## Los dos hermanos usan la misma vida (una sola barra).
func share_health(shared: HealthComponent) -> void:
	if health.died.is_connected(_die):
		health.died.disconnect(_die)
	health = shared


func _physics_process(delta: float) -> void:
	_clock += delta
	if _telegraph > 0.0:
		_telegraph = maxf(_telegraph - delta, 0.0)
	_trail.append(global_position)
	if _trail.size() > 7:
		_trail.remove_at(0)
	_lean = lerpf(_lean, clampf(velocity.x / 900.0, -0.25, 0.25), 1.0 - exp(-delta * 12.0))
	_squash = _squash.lerp(Vector2.ONE, 1.0 - exp(-delta * 10.0))
	queue_redraw()
	velocity.y = minf(velocity.y + _gravity() * delta, max_fall_speed)
	if is_dead or stunned or frozen:
		velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
		if stunned and not is_dead:
			_stun_left -= delta
			if _stun_left <= 0.0:
				_end_stun()
		elif frozen and not is_dead:
			_frozen_move(delta)
		move_and_slide()
		return
	if not busy and ai_enabled:
		if guarding:
			_guard_move(delta)
		else:
			_idle_move(delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, arena_left - 20.0, arena_right + 20.0)


func _gravity() -> float:
	return gravity if gravity > 0.0 else 900.0


## Corta lo que esté haciendo (ataque o espera).
func interrupt() -> void:
	_epoch += 1
	busy = false
	_telegraph = 0.0


func is_telegraphing() -> bool:
	return _telegraph > 0.0


func telegraph_kind() -> StringName:
	return _telegraph_kind


func player_position() -> Vector2:
	var player := get_player()
	return player.global_position if player else global_position


func face_player() -> void:
	face = 1.0 if player_position().x >= global_position.x else -1.0


## Espera seconds de juego. Devuelve false si se interrumpió mientras tanto.
func wait(seconds: float, epoch: int) -> bool:
	await get_tree().create_timer(seconds, false, true).timeout
	return still(epoch)


## Si el ataque de esta época puede seguir.
func still(epoch: int) -> bool:
	return epoch == _epoch and not is_dead and not frozen and not stunned


## Aviso visual antes de un ataque (un «!» de su color). Devuelve false si se interrumpió.
func telegraph(kind: StringName, seconds: float, epoch: int) -> bool:
	_telegraph_kind = kind
	_telegraph = seconds * telegraph_scale
	last_attack = kind
	attack_started.emit(kind)
	return await wait(seconds * telegraph_scale, epoch)


## Empieza un ataque: devuelve su época (para revisar si sigue) o −1 si no puede atacar ahora.
func begin_attack() -> int:
	if is_dead or stunned or frozen:
		return -1
	busy = true
	return _epoch


func end_attack(epoch: int) -> void:
	if epoch == _epoch:
		busy = false


## Camina hasta x (o hasta que pasen max_time segundos). Devuelve false si se interrumpió.
func walk_to(x: float, speed: float, epoch: int, max_time := 2.5) -> bool:
	x = clampf(x, arena_left, arena_right)
	var elapsed := 0.0
	while absf(global_position.x - x) > 6.0 and elapsed < max_time:
		velocity.x = signf(x - global_position.x) * speed * tempo
		face = signf(velocity.x)
		await get_tree().physics_frame
		if not still(epoch):
			return false
		elapsed += get_physics_process_delta_time()
	velocity.x = 0.0
	return true


## Desaparece en un parpadeo de interferencia y aparece en x (Cambio de posición).
func blink_to(x: float, epoch: int) -> bool:
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -22), _colors(), 10, 60.0, Vector2(18, 40), 0.35)
	modulate.a = 0.0
	if not await wait(0.18, epoch):
		modulate.a = 1.0
		return false
	global_position = Vector2(clampf(x, arena_left, arena_right), FLOOR_Y)
	velocity = Vector2.ZERO
	face_player()
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -22), _colors(), 10, 60.0, Vector2(18, 40), 0.35)
	modulate.a = 1.0
	return true


## Salta (con altura height) y espera a que caiga. Devuelve false si se interrumpió.
func jump(height: float, epoch: int, horizontal := 0.0) -> bool:
	velocity = Vector2(horizontal, -sqrt(2.0 * _gravity() * height))
	_squash = Vector2(0.8, 1.2)
	await get_tree().physics_frame
	var elapsed := 0.0
	while not is_on_floor() and elapsed < 2.0:
		await get_tree().physics_frame
		if not still(epoch):
			return false
		elapsed += get_physics_process_delta_time()
	_squash = Vector2(1.2, 0.85)
	velocity.x = 0.0
	return true


## --- Aturdido y protección ---

func _on_damaged(_hit: HitData) -> void:
	_squash = Vector2(1.15, 0.88)
	if stunned or is_dead or guarding:
		return
	var now := _clock
	_hits.append(now)
	while not _hits.is_empty() and now - _hits[0] > config.stagger_window:
		_hits.remove_at(0)
	if _hits.size() >= config.stagger_hits:
		incapacitate()


## Queda mareado unos segundos (deja lo que estaba haciendo).
func incapacitate() -> void:
	if stunned or is_dead:
		return
	_hits.clear()
	interrupt()
	stunned = true
	_stun_left = config.stun_time
	velocity.x = 0.0
	Sfx.play(&"enemy_hit", 0.6)
	incapacitated.emit(self)


func _end_stun() -> void:
	stunned = false
	_stun_left = 0.0
	recovered.emit(self)


## Deja lo que estaba haciendo y se pone entre Kai y su hermano aturdido.
func guard_for(sibling: SiblingBoss) -> void:
	interrupt()
	guarding = sibling
	_on_guard_started()


func stop_guarding() -> void:
	guarding = null
	_on_guard_ended()


## Dónde se para para proteger: entre Kai y su hermano.
func guard_x() -> float:
	if guarding == null:
		return global_position.x
	var side := 1.0 if player_position().x >= guarding.global_position.x else -1.0
	return clampf(guarding.global_position.x + side * 26.0, arena_left, arena_right)


func _guard_move(_delta: float) -> void:
	var x := guard_x()
	velocity.x = clampf((x - global_position.x) * 8.0, -260.0, 260.0)
	face_player()


## Un golpe que rebota (en el escudo): empuja a Kai hacia atrás.
func _on_hit_blocked(_hit: HitData) -> void:
	var kai := get_player()
	if kai == null:
		return
	var away := 1.0 if kai.global_position.x >= global_position.x else -1.0
	kai.velocity = Vector2(away * 260.0, -140.0)
	Sfx.play(&"enemy_hit", 1.6, -6.0)
	PixelBurst.spawn(get_parent(), global_position + Vector2(away * 16.0, -26), [SiblingArt.CHIP_LIGHT, Color.WHITE], 8, 80.0)


## --- Final y reinicio ---

## Neutralizado: no muere ni se borra. Queda mareado donde cayó.
func neutralize() -> void:
	if is_dead:
		return
	is_dead = true
	interrupt()
	stunned = false
	guarding = null
	contact.deactivate()
	hurtbox.set_physics_process(false)
	collision_layer = 0
	velocity = Vector2(0, -60)
	Sfx.play(&"enemy_death", 1.2)
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -22), death_colors, 18, 70.0, Vector2(18, 40), 0.5)
	neutralized.emit(self)


## La vida compartida llegó a cero: lo resuelve el controlador (neutraliza a los dos).
func _die() -> void:
	neutralize()


func enter_rage() -> void:
	enraged = true


## Vuelve a empezar la pelea (en su lugar, sin furia).
func restore() -> void:
	interrupt()
	is_dead = false
	enraged = false
	stunned = false
	guarding = null
	frozen = false
	tempo = 1.0
	telegraph_scale = 1.0
	_hits.clear()
	contact.activate()
	hurtbox.set_physics_process(true)
	hurtbox.immune = false
	collision_layer = 4
	modulate = Color.WHITE
	global_position = home
	velocity = Vector2.ZERO
	_on_restored()


## --- Para cada hermano ---

func _idle_move(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * get_physics_process_delta_time())


func _frozen_move(_delta: float) -> void:
	pass


func _on_guard_started() -> void:
	pass


func _on_guard_ended() -> void:
	pass


func _on_restored() -> void:
	pass


func _kind() -> StringName:
	return &""


func _colors() -> Array:
	return death_colors


## --- Dibujo ---

func _draw() -> void:
	var color := SiblingArt.GLITCH if _kind() == &"glitch" else SiblingArt.CHIP
	# Rastro (fantasmas de su color) cuando va rápido.
	if absf(velocity.x) > 200.0 or absf(velocity.y) > 300.0:
		for i in _trail.size():
			var k := float(i + 1) / _trail.size()
			SiblingArt.draw_twin(self, _kind(), _clock, face, { "offset": _trail[i] - global_position, "alpha": 0.18 * k, "tint": color * 2.0 })
	_draw_effects_behind()
	SiblingArt.draw_twin(self, _kind(), _clock, face, {
		"lean": _lean, "squash": _squash, "dizzy": stunned or is_dead, "enraged": enraged and not is_dead,
		"shielded": _shield_visible(),
	})
	_draw_effects_front()
	if is_telegraphing() and not is_dead:
		var blink := int(_clock / 0.06) % 2 == 0
		var top := Vector2(0, -58 - _telegraph * 10.0)
		draw_string(ThemeDB.fallback_font, top + Vector2(-3, 0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(color, 1.0 if blink else 0.5))
		draw_arc(Vector2(0, -24), 16.0 + _telegraph * 14.0, 0.0, TAU, 24, Color(color, 0.8 if blink else 0.35), 1.5)


func _shield_visible() -> bool:
	return false


func _draw_effects_behind() -> void:
	pass


func _draw_effects_front() -> void:
	pass
