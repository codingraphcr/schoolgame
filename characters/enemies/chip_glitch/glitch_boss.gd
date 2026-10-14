class_name GlitchBoss
extends SiblingBoss
## Glitch, el impulsivo (jefe doble del Capítulo 1, con Chip). Ataques rápidos y movimiento agresivo;
## inicia la mayoría de los ataques en conjunto. Sus ataques (hoja de Ariel):
##   1. Corte acelerado: dash con varios cortes (arcos rosas).
##   2. Salto en picada: sube sobre Kai, marca el piso y cae en diagonal.
##   3. Embestida en cadena: serie de dashes rápidos.
##   4. Lanzamiento de fragmentos: cuchillas de energía en abanico.
## Después de cada ataque queda un momento vulnerable (glitch_recover): es cuando hay que pegarle.
## Protegiendo a Chip: se para delante con la espada y contraataca si Kai se acerca.

var _slashes: Array[Dictionary] = []
var _dive_mark := Vector2.INF
var _guard_cd := 0.0


func _init() -> void:
	display_name = "Glitch"
	contact_damage = 1.0
	threat_type = &"malware"
	death_colors = [SiblingArt.GLITCH, SiblingArt.GLITCH_LIGHT, Color("6a1846")]


func _kind() -> StringName:
	return &"glitch"


func _physics_process(delta: float) -> void:
	for slash in _slashes:
		slash.t += delta
	_slashes = _slashes.filter(func(s: Dictionary) -> bool: return s.t < 0.25)
	_guard_cd -= delta
	super(delta)


## Entre ataques: se acerca a Kai sin pegarse (presión constante).
func _idle_move(delta: float) -> void:
	var kai := player_position()
	var gap := kai.x - global_position.x
	face = signf(gap) if gap != 0.0 else face
	var want := 0.0
	if absf(gap) > 90.0:
		want = signf(gap) * config.glitch_run_speed * tempo
	elif absf(gap) < 50.0:
		want = -signf(gap) * config.glitch_run_speed * 0.6 * tempo
	velocity.x = move_toward(velocity.x, want, 900.0 * delta)


## 1. Corte acelerado: aviso, y cruza hacia Kai cortando (deja arcos rosas).
func corte_acelerado(direction := 0.0) -> void:
	var epoch := begin_attack()
	if epoch < 0:
		return
	velocity.x = 0.0
	face = direction if direction != 0.0 else (1.0 if player_position().x >= global_position.x else -1.0)
	_squash = Vector2(1.15, 0.85)
	if not await telegraph(&"corte_acelerado", config.glitch_cut_telegraph, epoch):
		end_attack(epoch)
		return
	var elapsed := 0.0
	var next_slash := 0.0
	Sfx.play(&"dash", 1.2)
	while elapsed < config.glitch_cut_time:
		velocity.x = face * config.glitch_cut_speed * tempo
		if elapsed >= next_slash:
			next_slash += 0.1
			_slashes.append({ "t": 0.0, "at": global_position, "flip": randf() < 0.5 })
		await get_tree().physics_frame
		if not still(epoch):
			end_attack(epoch)
			return
		elapsed += get_physics_process_delta_time()
		if (face < 0.0 and global_position.x <= arena_left) or (face > 0.0 and global_position.x >= arena_right):
			break
	await _recover(epoch)


## 2. Salto en picada: salta sobre Kai, marca dónde va a caer y cae en diagonal.
func salto_en_picada(target_x := INF) -> void:
	var epoch := begin_attack()
	if epoch < 0:
		return
	velocity.x = 0.0
	face_player()
	_squash = Vector2(1.2, 0.8)
	if not await telegraph(&"salto_en_picada", config.glitch_dive_telegraph * 0.5, epoch):
		end_attack(epoch)
		return
	# Sube alto, pasándose un poco del lado de Kai (para caer en diagonal).
	var aim := clampf(player_position().x if target_x == INF else target_x, arena_left, arena_right)
	var side := -signf(aim - global_position.x) if aim != global_position.x else 1.0
	var apex_x := clampf(aim + side * 50.0, arena_left, arena_right)
	velocity = Vector2((apex_x - global_position.x) / 0.45, -430.0)
	var elapsed := 0.0
	while velocity.y < 0.0 and elapsed < 1.0:
		await get_tree().physics_frame
		if not still(epoch):
			end_attack(epoch)
			return
		elapsed += get_physics_process_delta_time()
	# Queda arriba un instante: la marca en el piso dice dónde va a caer.
	_dive_mark = Vector2(aim, FLOOR_Y)
	velocity = Vector2.ZERO
	var hang := config.glitch_dive_telegraph * telegraph_scale
	_telegraph_kind = &"salto_en_picada"
	_telegraph = hang
	elapsed = 0.0
	while elapsed < hang:
		velocity = Vector2.ZERO
		await get_tree().physics_frame
		if not still(epoch):
			_dive_mark = Vector2.INF
			end_attack(epoch)
			return
		elapsed += get_physics_process_delta_time()
	var dir := (_dive_mark - global_position).normalized()
	face = signf(dir.x) if dir.x != 0.0 else face
	elapsed = 0.0
	while not is_on_floor() and elapsed < 1.2:
		velocity = dir * config.glitch_dive_speed * tempo
		await get_tree().physics_frame
		if not still(epoch):
			_dive_mark = Vector2.INF
			end_attack(epoch)
			return
		elapsed += get_physics_process_delta_time()
	_dive_mark = Vector2.INF
	velocity = Vector2.ZERO
	_squash = Vector2(1.3, 0.75)
	PixelBurst.spawn(get_parent(), global_position, [SiblingArt.GLITCH, SiblingArt.GLITCH_LIGHT], 14, 110.0)
	Sfx.play(&"boss_charge", 1.4, -4.0)
	await _recover(epoch)


## 3. Embestida en cadena: varios dashes cortos seguidos, cada uno hacia donde está Kai.
func embestida_en_cadena(count := -1) -> void:
	var epoch := begin_attack()
	if epoch < 0:
		return
	var dashes := config.glitch_chain_dashes if count < 0 else count
	for k in dashes:
		velocity.x = 0.0
		face_player()
		if not await telegraph(&"embestida_en_cadena", config.glitch_chain_telegraph, epoch):
			end_attack(epoch)
			return
		var elapsed := 0.0
		Sfx.play(&"dash", 1.3 + k * 0.1)
		while elapsed < 0.22:
			velocity.x = face * config.glitch_cut_speed * 1.05 * tempo
			if int(elapsed / 0.11) != int((elapsed - get_physics_process_delta_time()) / 0.11):
				_slashes.append({ "t": 0.0, "at": global_position, "flip": k % 2 == 0 })
			await get_tree().physics_frame
			if not still(epoch):
				end_attack(epoch)
				return
			elapsed += get_physics_process_delta_time()
		velocity.x = 0.0
		if not await wait(0.08, epoch):
			end_attack(epoch)
			return
	await _recover(epoch)


## 4. Lanzamiento de fragmentos: cuchillas de energía en abanico hacia Kai.
func lanzamiento_de_fragmentos(count := -1) -> void:
	var epoch := begin_attack()
	if epoch < 0:
		return
	velocity.x = 0.0
	face_player()
	if not await telegraph(&"lanzamiento_de_fragmentos", config.glitch_fragment_telegraph, epoch):
		end_attack(epoch)
		return
	throw_fragments(player_position() + Vector2(0, -16), config.glitch_fragments if count < 0 else count)
	await _recover(epoch)


## Lanza las cuchillas (también las usa el Campo Dual).
func throw_fragments(target: Vector2, count: int) -> void:
	var origin := global_position + Vector2(face * 10.0, -28)
	var base := (target - origin).normalized()
	for k in count:
		var angle := (k - (count - 1) / 2.0) * 0.22
		BossAttacks.shot(get_parent(), origin, base.rotated(angle) * config.glitch_fragment_speed * tempo, 9.0, 0.12, SiblingArt.GLITCH, true)
	Sfx.play(&"popup_open", 1.6, -6.0)
	_squash = Vector2(0.9, 1.1)


## Queda vulnerable un momento después de atacar.
func _recover(epoch: int) -> void:
	velocity.x = 0.0
	await wait(config.glitch_recover / tempo, epoch)
	end_attack(epoch)


## Protegiendo a Chip: contraataca si Kai se acerca demasiado.
func _guard_move(delta: float) -> void:
	super(delta)
	var kai := player_position()
	if _guard_cd <= 0.0 and absf(kai.x - global_position.x) < 46.0 and absf(kai.y - global_position.y) < 40.0:
		_guard_cd = 0.9
		_guard_counter()


func _guard_counter() -> void:
	var epoch := _epoch
	_telegraph_kind = &"contraataque"
	_telegraph = 0.25
	await get_tree().create_timer(0.25, false, true).timeout
	if epoch != _epoch or guarding == null or is_dead:
		return
	_slashes.append({ "t": 0.0, "at": global_position + Vector2(face * 16.0, 0), "flip": false })
	velocity.x = face * 240.0
	Sfx.play(&"dash", 1.5, -4.0)


func _on_restored() -> void:
	_slashes.clear()
	_dive_mark = Vector2.INF


func _frozen_move(_delta: float) -> void:
	# En la fase segura se va a la izquierda de la arena y espera.
	velocity.x = clampf((arena_left + 40.0 - global_position.x) * 3.0, -170.0, 170.0)


func _draw_effects_behind() -> void:
	if _dive_mark != Vector2.INF:
		var mark := _dive_mark - global_position
		var blink := int(_clock / 0.07) % 2 == 0
		draw_line(mark + Vector2(-16, 0), mark + Vector2(16, 0), Color(SiblingArt.GLITCH, 0.9 if blink else 0.4), 2.0)
		draw_line(mark + Vector2(-8, -8), mark + Vector2(8, 8), Color(SiblingArt.GLITCH_LIGHT, 0.7), 1.0)
		draw_line(mark + Vector2(-8, 8), mark + Vector2(8, -8), Color(SiblingArt.GLITCH_LIGHT, 0.7), 1.0)
		for k in 6:
			var p := Vector2.ZERO.lerp(mark, k / 6.0)
			draw_circle(p + Vector2(0, -22), 1.0, Color(SiblingArt.GLITCH, 0.5))


func _draw_effects_front() -> void:
	# Arcos de los cortes (rosa claro, se abren y se apagan).
	for slash in _slashes:
		var k: float = slash.t / 0.25
		var center: Vector2 = slash.at - global_position + Vector2(face * 10.0, -24)
		var start := -1.2 if slash.flip else 0.2
		draw_arc(center, 14.0 + 10.0 * k, start * face, (start + 1.6) * face, 12, Color(SiblingArt.GLITCH_LIGHT, 1.0 - k), 3.0 * (1.0 - k) + 1.0)
		draw_arc(center, 10.0 + 10.0 * k, start * face, (start + 1.6) * face, 12, Color(SiblingArt.GLITCH, 0.8 * (1.0 - k)), 1.0)
