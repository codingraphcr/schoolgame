class_name GlitchBoss
extends SiblingBoss
## Glitch, el impulsivo (jefe doble del Capítulo 1, con Chip). Corre por el piso con amagues (cambios
## de dirección de golpe) y ataca de cerca: embestidas a lo ancho de la arena, saltos ofensivos que
## caen donde está Kai y combos de ataques cortos seguidos. Después de cada ataque queda un momento
## vulnerable (glitch_recover): es cuando hay que pegarle.
##
## Furia fraternal (si Chip cae primero): corre más rápido, encadena embestidas rebotando en las
## paredes y combina el salto con el combo sin pausa.
## Arte provisional por código: una criatura naranja con púas que tiembla como una imagen con fallas.

const ORANGE := Color("ff8a3a")

var _attack_cd := 1.4
var _feint_cd := 1.4
var _feint_time := 0.0
var _dir := -1
var _attack_index := 0


func _init() -> void:
	display_name = "Glitch"
	body_size = Vector2(22, 18)
	contact_damage = 1.0
	threat_type = &"malware"
	death_colors = [ORANGE, Color("ffc08a"), Color("a0401a")]


func _ready() -> void:
	max_health = _config_health()
	super()


func _config_health() -> float:
	return config.glitch_health if config else max_health


func speed_scale() -> float:
	return config.rage_glitch_speed_scale if enraged else 1.0


func _ai(delta: float) -> void:
	if busy:
		return
	_attack_cd -= delta
	_feint_cd -= delta
	var kai := player_position()
	var toward := 1 if kai.x > global_position.x else -1
	if _feint_time > 0.0:
		_feint_time -= delta
	elif _feint_cd <= 0.0:
		# Amague: cambia de dirección de golpe un instante.
		_feint_time = 0.25
		_feint_cd = config.glitch_feint_every
	_dir = -toward if _feint_time > 0.0 else toward
	var distance := absf(kai.x - global_position.x)
	velocity.x = _dir * config.glitch_run_speed * speed_scale() if distance > 24.0 or _feint_time > 0.0 else 0.0
	if global_position.x <= arena_left and _dir < 0 or global_position.x >= arena_right and _dir > 0:
		velocity.x = 0.0
	if _attack_cd <= 0.0 and is_on_floor():
		_attack_index += 1
		if distance > 150.0:
			charge()
		elif kai.y < global_position.y - 40.0 or _attack_index % 3 == 0:
			leap()
		else:
			combo()


## Embestida: se agacha (aviso) y cruza la arena hasta chocar o cansarse. En furia, encadena varias.
func charge() -> void:
	busy = true
	var epoch := _epoch
	var times := config.rage_glitch_chain if enraged else 1
	for k in times:
		var telegraph_time := config.glitch_charge_telegraph * (0.6 if enraged and k > 0 else 1.0)
		velocity.x = 0.0
		if not await telegraph(&"embestida", telegraph_time, epoch):
			busy = false
			return
		var dir := 1 if player_position().x > global_position.x else -1
		var elapsed := 0.0
		while elapsed < config.glitch_charge_time:
			velocity.x = dir * config.glitch_charge_speed * speed_scale()
			await get_tree().physics_frame
			if epoch != _epoch or is_dead or frozen:
				busy = false
				return
			elapsed += get_physics_process_delta_time()
			if (dir < 0 and global_position.x <= arena_left) or (dir > 0 and global_position.x >= arena_right) or is_on_wall():
				break
		velocity.x = 0.0
	await _recover(epoch)


## Salto ofensivo: se agacha (aviso) y cae donde estaba Kai. En furia, al caer sigue con un combo.
func leap() -> void:
	busy = true
	var epoch := _epoch
	velocity.x = 0.0
	if not await telegraph(&"salto", config.glitch_leap_telegraph, epoch):
		busy = false
		return
	var target_x := clampf(player_position().x, arena_left, arena_right)
	velocity = Vector2(clampf((target_x - global_position.x) / 0.8, -280.0, 280.0), -360.0)
	await get_tree().physics_frame
	var elapsed := 0.0
	while not is_on_floor() and elapsed < 1.6:
		await get_tree().physics_frame
		if epoch != _epoch or is_dead or frozen:
			busy = false
			return
		elapsed += get_physics_process_delta_time()
	velocity.x = 0.0
	if enraged:
		busy = false
		await combo()
		return
	await _recover(epoch)


## Combo: tres ataques cortos seguidos (cada uno con un aviso breve).
func combo() -> void:
	busy = true
	var epoch := _epoch
	for k in 3:
		velocity.x = 0.0
		if not await telegraph(&"combo", config.glitch_combo_telegraph, epoch):
			busy = false
			return
		var dir := 1 if player_position().x > global_position.x else -1
		velocity.x = dir * 260.0 * speed_scale()
		if not await wait(0.14, epoch):
			busy = false
			return
		velocity.x = 0.0
		if not await wait(0.1, epoch):
			busy = false
			return
	await _recover(epoch)


## Queda vulnerable un momento después de atacar.
func _recover(epoch: int) -> void:
	velocity.x = 0.0
	await wait(config.glitch_recover * (0.7 if enraged else 1.0), epoch)
	_attack_cd = config.glitch_attack_cooldown * (0.6 if enraged else 1.0)
	if epoch == _epoch:
		busy = false


func _frozen_move(_delta: float) -> void:
	# En la fase segura se sienta en la esquina derecha.
	velocity.x = clampf((arena_right - global_position.x) * 3.0, -170.0, 170.0)


func _on_restored() -> void:
	_attack_cd = 1.4
	_feint_cd = 1.4


func _on_rage() -> void:
	_attack_cd = 0.3
	modulate = Color(1.25, 0.9, 0.85)


func _draw() -> void:
	var body := SiblingArt.draw_glitch(self, _clock, 1.0 if velocity.x >= 0.0 else -1.0, is_telegraphing(), enraged, is_dead)
	if not is_dead:
		draw_telegraph(body.get_center(), Color(1, 0.4, 0.3) if enraged else ORANGE)
