class_name SiblingBoss
extends EnemyBase
## Base de Glitch y Chip, el jefe doble del Capítulo 1 (diseño de Ariel: glitch_chip_concepto.webp).
## Los ataques los ordena el DualBossController (secuencias fijas por fase: «más rápidos, pero no
## aleatorios»); entre ataque y ataque cada hermano se mueve por su cuenta (_idle_move).
##
## - Vida compartida: share_health() hace que los dos usen la misma barra (funcionan como una unidad).
## - Aturdido: stagger_hits golpes seguidos lo dejan mareado stun_time segundos (incapacitated). El
##   controlador hace que el otro deje su ataque y lo proteja (guard_for).
## - Vencido (Fases 1 y 2): con su vida propia en cero queda **vencido** (knock_down): mareado en el piso,
##   sin atacar ni recibir golpes, hasta que el controlador lo levanta (get_up) para la Fase 3.
## - Nunca mueren: con la vida compartida en cero quedan **neutralizados** (mareados en el piso) y no se
##   borran.
## - Todo ataque empieza con telegraph(): una señal de aviso esquivable (un «!» de su color).
## - frozen: la fase segura del escudo (no hacen nada). busy: están en un ataque.
## - tempo / telegraph_scale: la Fase 3 (Furia fraternal) los hace más rápidos.
## Los tiempos corren con la física (siempre igual aunque la computadora vaya lenta).

signal neutralized(boss: SiblingBoss)
signal attack_started(attack: StringName)
signal incapacitated(boss: SiblingBoss)
signal recovered(boss: SiblingBoss)
## Su vida propia llegó a cero antes de la Fase 3: queda vencido (aturdido en el piso).
signal knocked_down(boss: SiblingBoss)

const FLOOR_Y := 304.0

## Prefijo de las animaciones de cada ataque (hojas de ataques de Ariel, cuadro por cuadro): <prefijo>_aviso
## mientras avisa, la acción y <prefijo>_fin mientras queda vulnerable (y en la picada y la caída, _subir,
## _arriba y _caer). Los ataques en conjunto usan las de cada uno.
const ATTACK_ANIMS := {
	&"corte_acelerado": "corte", &"salto_en_picada": "picada", &"embestida_en_cadena": "embestida",
	&"lanzamiento_de_fragmentos": "fragmentos", &"barrido": "barrido", &"caida": "caida",
	&"discos_orbitales": "discos", &"zona_de_control": "zona", &"proyecciones": "proyecciones",
	&"rayo_de_sincronia": "rayo",
}

@export var config: DualBossConfig
## Límites de la arena (x mínima y máxima donde se mueven).
var arena_left := 40.0
var arena_right := 600.0
var enraged := false
var busy := false
var stunned := false
## Si puede caer (Fase 3, con la vida compartida). Antes, al llegar a cero queda vencido (downed).
var mortal := false
## Vencido antes de la Fase 3: aturdido en el piso hasta que vencen también al otro.
var downed := false
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
## Pose del sprite (SiblingArt): la cambian los ataques; vuelve a «quieto» al terminar.
var _pose: StringName = &"quieto"
var _pose_until := 0.0
## Cuándo empezó la pose (las animaciones de ataque arrancan desde su primer cuadro).
var _pose_since := 0.0
## Altura a la que se sostiene en el aire (INF = con gravedad, en el piso).
var _hover := INF
## x donde se sostiene en el aire (hold_at; INF = libre en x).
var _hold_x := INF
## Dónde va a caer en la picada (INF = no está en una).
var _dive_mark := Vector2.INF
## Su vida propia (en la Fase 3 usa la compartida).
var _own_health: HealthComponent
## Altura (pies) del barrido en curso (INF = no está barriendo; para las pruebas).
var sweep_line := INF


func _ready() -> void:
	rank = Rank.JEFE
	ecos_reward = 0  # La recompensa la da el final del capítulo (una sola vez).
	knockback_resistance = 0.9
	hurt_time = 0.1
	body_size = Vector2(16, 30)
	super()
	home = global_position
	hurtbox.hit_blocked.connect(_on_hit_blocked)
	_own_health = health


## Fase 3: los dos hermanos pasan a usar la misma vida (una sola barra).
func share_health(shared: HealthComponent) -> void:
	health = shared
	mortal = true


## Vuelve a su vida propia (antes de la Fase 3 cada uno tiene su barra), llena.
func use_own_health(maximum: float) -> void:
	health = _own_health
	health.max_health = maximum
	health.restore_full()
	mortal = false


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
	if _hover != INF and not is_dead and not stunned and not downed:
		velocity.y = (_hover - global_position.y) * 12.0
		if _hold_x != INF:
			velocity.x = clampf((_hold_x - global_position.x) * 12.0, -600.0, 600.0)
			face = signf(player_position().x - global_position.x) if player_position().x != global_position.x else face
	else:
		velocity.y = minf(velocity.y + _gravity() * delta, max_fall_speed)
	if is_dead or stunned or frozen or downed:
		velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
		if stunned and not is_dead:
			_stun_left -= delta
			if _stun_left <= 0.0:
				_end_stun()
		elif frozen and not is_dead and not downed:
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
	_hover = INF
	_hold_x = INF
	_dive_mark = Vector2.INF
	_pose = &"quieto"


## Cambia la pose del sprite (si hold > 0, solo por ese tiempo; si no, hasta que termine el ataque).
func set_pose(pose: StringName, hold := 0.0) -> void:
	if pose != _pose:
		_pose_since = _clock
	_pose = pose
	_pose_until = _clock + hold if hold > 0.0 else INF


## La animación de una fase de un ataque ("aviso", "fin", "caer"…; "" = la acción) si este hermano la
## tiene; si no, fallback.
func attack_pose(attack: StringName, phase: String, fallback: StringName) -> StringName:
	var prefix: String = ATTACK_ANIMS.get(attack, "")
	if prefix.is_empty():
		return fallback
	var pose := StringName(prefix if phase.is_empty() else "%s_%s" % [prefix, phase])
	return pose if SiblingArt.has_pose(_kind(), pose) else fallback


## Mientras queda vulnerable después de un ataque: la animación de recuperación de ese ataque (después de
## la pose que esté mostrando por un rato, como lanzar el disco).
func show_recovery(seconds: float) -> void:
	var pose := attack_pose(last_attack, "fin", &"")
	if pose == &"":
		return
	var before := _pose_until - _clock if _pose_until != INF and _pose_until > _clock else 0.0
	if before > 0.0:
		var epoch := _epoch
		await get_tree().create_timer(before, false, true).timeout
		if epoch != _epoch:
			return
	set_pose(pose, maxf(seconds - before, 0.05))


## Pose del sprite: la del ataque si hay una; si no, según cómo se mueve (caminar, correr, saltar,
## aire, caer). Aturdido o neutralizado: tirado en el piso.
func current_pose() -> StringName:
	if stunned or is_dead or downed:
		return &"aturdido"
	if _pose != &"quieto" and (busy or _clock < _pose_until):
		return _pose
	if not is_on_floor():
		if velocity.y < -80.0:
			return &"saltar"
		return &"caer" if velocity.y > 80.0 else &"aire"
	var speed := absf(velocity.x)
	if speed > 150.0:
		return &"correr"
	return &"caminar" if speed > 15.0 else &"quieto"


## Segundos de la animación en curso: desde que empezó la pose del ataque (o el reloj, si se mueve).
func _anim_time() -> float:
	return _clock - _pose_since if current_pose() == _pose else _clock


## Pose mientras avisa un ataque.
func _ready_pose() -> StringName:
	return &"quieto"


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
	if not is_inside_tree():
		return false
	await get_tree().create_timer(seconds, false, true).timeout
	return still(epoch)


## Si el ataque de esta época puede seguir (si la sala se cerró a mitad, no).
func still(epoch: int) -> bool:
	return epoch == _epoch and not is_dead and not frozen and not stunned and not downed and is_inside_tree()


## Aviso visual antes de un ataque (un «!» de su color). Devuelve false si se interrumpió.
func telegraph(kind: StringName, seconds: float, epoch: int) -> bool:
	_telegraph_kind = kind
	_telegraph = seconds * telegraph_scale
	last_attack = kind
	set_pose(attack_pose(kind, "aviso", _ready_pose()))
	_squash = Vector2(1.1, 0.9)
	attack_started.emit(kind)
	return await wait(seconds * telegraph_scale, epoch)


## Empieza un ataque: devuelve su época (para revisar si sigue) o −1 si no puede atacar ahora.
func begin_attack() -> int:
	if is_dead or stunned or frozen or downed:
		return -1
	busy = true
	return _epoch


func end_attack(epoch: int) -> void:
	if epoch == _epoch:
		busy = false
		_hover = INF
		_hold_x = INF
		if _clock >= _pose_until or _pose_until == INF:
			_pose = &"quieto"


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
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -16), _colors(), 10, 60.0, Vector2(16, 30), 0.35)
	modulate.a = 0.0
	if not await wait(0.18, epoch):
		modulate.a = 1.0
		return false
	global_position = Vector2(clampf(x, arena_left, arena_right), FLOOR_Y)
	velocity = Vector2.ZERO
	face_player()
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -16), _colors(), 10, 60.0, Vector2(16, 30), 0.35)
	modulate.a = 1.0
	return true


## Salta (con altura height) y espera a que caiga. Devuelve false si se interrumpió.
func jump(height: float, epoch: int, horizontal := 0.0) -> bool:
	velocity = Vector2(horizontal, -sqrt(2.0 * _gravity() * height))
	_squash = Vector2(0.8, 1.2)
	if not await FrameWait.physics(self):
		return false
	var elapsed := 0.0
	while not is_on_floor() and elapsed < 2.0:
		await get_tree().physics_frame
		if not still(epoch):
			return false
		elapsed += get_physics_process_delta_time()
	_squash = Vector2(1.2, 0.85)
	velocity.x = 0.0
	return true


## Salto en picada (los dos lo hacen; en las Picadas alternas se turnan): sube sobre Kai, marca dónde
## va a caer y cae en diagonal.
func salto_en_picada(target_x := INF) -> void:
	var epoch := begin_attack()
	if epoch < 0:
		return
	velocity.x = 0.0
	face_player()
	if not await telegraph(&"salto_en_picada", config.glitch_dive_telegraph * 0.5, epoch):
		end_attack(epoch)
		return
	# Sube alto, pasándose un poco del lado de Kai (para caer en diagonal).
	var aim := clampf(player_position().x if target_x == INF else target_x, arena_left, arena_right)
	var side := -signf(aim - global_position.x) if aim != global_position.x else 1.0
	var apex_x := clampf(aim + side * 50.0, arena_left, arena_right)
	velocity = Vector2((apex_x - global_position.x) / 0.45, -430.0)
	set_pose(attack_pose(&"salto_en_picada", "subir", _dive_pose()))
	var elapsed := 0.0
	while velocity.y < 0.0 and elapsed < 1.0:
		await get_tree().physics_frame
		if not still(epoch):
			end_attack(epoch)
			return
		elapsed += get_physics_process_delta_time()
	# Queda arriba un instante: la marca en el piso dice dónde va a caer.
	_dive_mark = Vector2(aim, kai_ground_y())
	_hover = global_position.y
	set_pose(attack_pose(&"salto_en_picada", "arriba", _dive_pose()))
	var hang := config.glitch_dive_telegraph * telegraph_scale
	_telegraph_kind = &"salto_en_picada"
	_telegraph = hang
	elapsed = 0.0
	while elapsed < hang:
		velocity.x = 0.0
		face = signf(aim - global_position.x) if aim != global_position.x else face
		await get_tree().physics_frame
		if not still(epoch):
			end_attack(epoch)
			return
		elapsed += get_physics_process_delta_time()
	_hover = INF
	set_pose(attack_pose(&"salto_en_picada", "caer", _dive_pose()))
	if not await fall_to(_dive_mark, config.glitch_dive_speed * tempo, epoch):
		end_attack(epoch)
		return
	_dive_mark = Vector2.INF
	velocity = Vector2.ZERO
	_squash = Vector2(1.3, 0.75)
	PixelBurst.spawn(get_parent(), global_position, _colors(), 14, 110.0)
	Sfx.play(&"boss_charge", 1.4, -4.0)
	await _recover(epoch)


## Cruza la arena en línea recta hasta to_x (Danza espejo): por el piso (height 0) o volando a esa altura.
## Hace daño al tocarlo (su cuerpo). Devuelve false si se interrumpió.
func dash_across(to_x: float, height: float, epoch: int) -> bool:
	face = signf(to_x - global_position.x) if to_x != global_position.x else face
	_hold_x = INF
	set_pose(_dash_pose())
	if height > 0.0:
		_hover = FLOOR_Y - height
	var elapsed := 0.0
	Sfx.play(&"dash", 1.1 if _kind() == &"glitch" else 0.9)
	while (to_x - global_position.x) * face > 4.0 and elapsed < 2.5:
		velocity.x = face * config.glitch_cut_speed * 1.1 * tempo
		await get_tree().physics_frame
		if not still(epoch):
			return false
		elapsed += get_physics_process_delta_time()
	velocity.x = 0.0
	_hover = INF
	return true


## Aparece en pos con un parpadeo de interferencia (en el aire se queda flotando ahí).
func appear_at(pos: Vector2, epoch: int) -> bool:
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -16), _colors(), 8, 60.0, Vector2(16, 30), 0.3)
	modulate.a = 0.0
	if not await wait(0.14, epoch):
		modulate.a = 1.0
		return false
	global_position = Vector2(clampf(pos.x, arena_left, arena_right), minf(pos.y, FLOOR_Y))
	velocity = Vector2.ZERO
	if pos.y < FLOOR_Y - 2.0:
		hold_at(global_position)
	else:
		release_hold()
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -16), _colors(), 8, 60.0, Vector2(16, 30), 0.3)
	modulate.a = 1.0
	return true


## Altura a la que apuntar (los pies): la de Kai (en el piso, en una plataforma o en el aire) o,
## si height >= 0, esa altura sobre el piso.
func aim_y(height := -1.0) -> float:
	if height >= 0.0:
		return FLOOR_Y - height
	return clampf(player_position().y, 60.0, FLOOR_Y)


## Barrido (como las Mantis Lords): aparece en una pared y cruza la arena en línea recta a la altura de
## Kai. Durante el aviso lo sigue (si sube a una plataforma, el barrido va ahí); al lanzarse ya no.
## height >= 0: cruza a esa altura fija. lead: espera más antes de lanzarse (para encadenar con el otro).
func barrido(from_left: bool, height := -1.0, lead := 0.0) -> void:
	var epoch := begin_attack()
	if epoch < 0:
		return
	var x := arena_left + 4.0 if from_left else arena_right - 4.0
	var y := aim_y(height)
	if not await appear_at(Vector2(x, y), epoch):
		end_attack(epoch)
		return
	face = 1.0 if from_left else -1.0
	last_attack = &"barrido"
	set_pose(attack_pose(&"barrido", "aviso", _ready_pose()))
	_telegraph_kind = &"barrido"
	attack_started.emit(&"barrido")
	var total := config.sweep_telegraph * telegraph_scale + lead
	var elapsed := 0.0
	while elapsed < total:
		_telegraph = maxf(total - elapsed, 0.01)
		if elapsed < total - 0.15:
			y = aim_y(height)
		if y < FLOOR_Y - 2.0:
			hold_at(Vector2(x, y))
		face = 1.0 if from_left else -1.0
		await get_tree().physics_frame
		if not still(epoch):
			end_attack(epoch)
			return
		elapsed += get_physics_process_delta_time()
	_telegraph = 0.0
	sweep_line = y
	_hold_x = INF
	_hover = y if y < FLOOR_Y - 2.0 else INF
	set_pose(attack_pose(&"barrido", "", _dash_pose()))
	Sfx.play(&"dash", 1.0 if _kind() == &"glitch" else 0.85)
	var to_x := arena_right + 10.0 if from_left else arena_left - 10.0
	elapsed = 0.0
	while (to_x - global_position.x) * face > 6.0 and elapsed < 2.0:
		velocity.x = face * config.sweep_speed * tempo
		await get_tree().physics_frame
		if not still(epoch):
			sweep_line = INF
			end_attack(epoch)
			return
		elapsed += get_physics_process_delta_time()
		if is_on_wall():
			break
	sweep_line = INF
	velocity.x = 0.0
	release_hold()
	await _recover(epoch)


## Caída (como las Mantis Lords): aparece arriba de Kai, lo sigue un instante (marca en el piso) y
## cae en vertical. offset: cae corrido de Kai (en la Doble caída, uno a cada lado).
func caida(offset := 0.0) -> void:
	var epoch := begin_attack()
	if epoch < 0:
		return
	var top := 72.0  # Debajo de la barra de vida del HUD.
	var x := clampf(player_position().x + offset, arena_left, arena_right)
	if not await appear_at(Vector2(x, top), epoch):
		end_attack(epoch)
		return
	last_attack = &"caida"
	set_pose(attack_pose(&"caida", "aviso", _dive_pose()))
	_telegraph_kind = &"caida"
	attack_started.emit(&"caida")
	var total := config.drop_telegraph * telegraph_scale
	var elapsed := 0.0
	while elapsed < total:
		_telegraph = maxf(total - elapsed, 0.01)
		if elapsed < total * 0.65:
			x = clampf(player_position().x + offset, arena_left, arena_right)
		hold_at(Vector2(x, top))
		_dive_mark = Vector2(x, kai_ground_y())
		await get_tree().physics_frame
		if not still(epoch):
			end_attack(epoch)
			return
		elapsed += get_physics_process_delta_time()
	_telegraph = 0.0
	release_hold()
	set_pose(attack_pose(&"caida", "caer", _dive_pose()))
	if not await fall_to(_dive_mark, config.drop_speed * tempo, epoch):
		end_attack(epoch)
		return
	_dive_mark = Vector2.INF
	velocity = Vector2.ZERO
	_squash = Vector2(1.3, 0.75)
	PixelBurst.spawn(get_parent(), global_position, _colors(), 14, 110.0)
	Sfx.play(&"boss_charge", 1.5, -4.0)
	await _recover(epoch)


## Dónde está parado Kai: su altura si está en el piso o en una plataforma; si está en el aire, el piso.
func kai_ground_y() -> float:
	var kai := get_player()
	if kai and kai.is_on_floor():
		return kai.global_position.y
	return FLOOR_Y


## Cae en línea recta hasta target atravesando las plataformas (no choca con nada mientras cae): llega
## justo a la altura de Kai aunque esté debajo de una plataforma. Devuelve false si se interrumpió.
func fall_to(target: Vector2, speed: float, epoch: int) -> bool:
	var mask := collision_mask
	collision_mask = 0
	var dir := (target - global_position).normalized()
	var elapsed := 0.0
	while global_position.y < target.y - 1.0 and elapsed < 1.5:
		var step := dir * speed * get_physics_process_delta_time()
		if global_position.y + step.y >= target.y:
			break
		velocity = dir * speed
		face = signf(dir.x) if absf(dir.x) > 0.1 else face
		await get_tree().physics_frame
		if not still(epoch):
			collision_mask = mask
			return false
		elapsed += get_physics_process_delta_time()
	global_position = Vector2(clampf(target.x, arena_left, arena_right), target.y)
	velocity = Vector2.ZERO
	collision_mask = mask
	return true


## Se sostiene en el aire en target (lo usa el Remolino doble, cuadro a cuadro).
func hold_at(target: Vector2) -> void:
	_hover = target.y
	_hold_x = target.x


func release_hold() -> void:
	_hover = INF
	_hold_x = INF


## Pose para lanzarse en picada y para los dashes (cada hermano la suya).
func _dive_pose() -> StringName:
	return &"quieto"


func _dash_pose() -> StringName:
	return &"quieto"


func _recover(epoch: int) -> void:
	velocity.x = 0.0
	show_recovery(0.5 / tempo)
	await wait(0.5 / tempo, epoch)
	end_attack(epoch)


## --- Aturdido y protección ---

func _on_damaged(_hit: HitData) -> void:
	_squash = Vector2(1.15, 0.88)
	if stunned or is_dead or downed or guarding:
		return
	var now := _clock
	_hits.append(now)
	while not _hits.is_empty() and now - _hits[0] > config.stagger_window:
		_hits.remove_at(0)
	if _hits.size() >= config.stagger_hits:
		incapacitate()


## Queda mareado unos segundos (deja lo que estaba haciendo).
func incapacitate() -> void:
	if stunned or is_dead or downed:
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
	PixelBurst.spawn(get_parent(), global_position + Vector2(away * 12.0, -18), [SiblingArt.CHIP_LIGHT, Color.WHITE], 8, 80.0)


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
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -16), death_colors, 18, 70.0, Vector2(16, 30), 0.5)
	neutralized.emit(self)


## Su vida propia llegó a cero antes de la Fase 3: queda vencido. En la Fase 3 la vida es compartida y
## la resuelve el controlador.
func _die() -> void:
	if mortal:
		neutralize()
		return
	knock_down()


## Vencido (antes de la Fase 3): deja lo que estaba haciendo y queda mareado en el piso, sin atacar ni
## recibir golpes (tampoco hace daño al tocarlo), hasta que vencen también al otro.
func knock_down() -> void:
	if downed or is_dead:
		return
	interrupt()
	downed = true
	stunned = false
	guarding = null
	_hits.clear()
	contact.deactivate()
	hurtbox.immune = true
	velocity = Vector2(0, -80)
	Sfx.play(&"enemy_death", 1.4, -4.0)
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -16), death_colors, 12, 60.0, Vector2(16, 30), 0.4)
	knocked_down.emit(self)


## Se levanta (para la Fase 3).
func get_up() -> void:
	if not downed:
		return
	downed = false
	contact.activate()
	hurtbox.immune = false
	_squash = Vector2(0.85, 1.2)


func enter_rage() -> void:
	enraged = true


## Vuelve a empezar la pelea (en su lugar, sin furia).
func restore() -> void:
	interrupt()
	is_dead = false
	downed = false
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
			SiblingArt.draw_twin(self, _kind(), _clock, face, { "pose": current_pose(), "anim_time": _anim_time(), "offset": _trail[i] - global_position, "alpha": 0.18 * k, "tint": color * 2.0 })
	_draw_dive_mark(color)
	_draw_effects_behind()
	SiblingArt.draw_twin(self, _kind(), _clock, face, {
		"pose": current_pose(), "anim_time": _anim_time(),
		"lean": _lean, "squash": _squash, "dizzy": stunned or is_dead or downed, "enraged": enraged and not is_dead,
		"shielded": _shield_visible(),
	})
	_draw_effects_front()
	if is_telegraphing() and not is_dead:
		var blink := int(_clock / 0.06) % 2 == 0
		var top := Vector2(0, -44 - _telegraph * 10.0)
		draw_string(ThemeDB.fallback_font, top + Vector2(-3, 0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(color, 1.0 if blink else 0.5))
		draw_arc(Vector2(0, -16), 13.0 + _telegraph * 12.0, 0.0, TAU, 24, Color(color, 0.8 if blink else 0.35), 1.5)


func _shield_visible() -> bool:
	return false


func _draw_effects_behind() -> void:
	pass


func _draw_effects_front() -> void:
	pass


## La marca en el piso de la picada (dónde va a caer) y la línea de puntos hasta ella.
func _draw_dive_mark(color: Color) -> void:
	if _dive_mark == Vector2.INF:
		return
	var mark := _dive_mark - global_position
	var blink := int(_clock / 0.07) % 2 == 0
	draw_line(mark + Vector2(-16, 0), mark + Vector2(16, 0), Color(color, 0.9 if blink else 0.4), 2.0)
	draw_line(mark + Vector2(-8, -8), mark + Vector2(8, 8), Color(Color.WHITE, 0.6), 1.0)
	draw_line(mark + Vector2(-8, 8), mark + Vector2(8, -8), Color(Color.WHITE, 0.6), 1.0)
	for k in 6:
		draw_circle(Vector2.ZERO.lerp(mark, k / 6.0) + Vector2(0, -16), 1.0, Color(color, 0.5))
