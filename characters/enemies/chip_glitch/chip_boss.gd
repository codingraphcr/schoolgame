class_name ChipBoss
extends SiblingBoss
## Chip, el estratega (jefe doble del Capítulo 1, con Glitch). Flota a media altura y controla el
## espacio desde lejos: disparos digitales apuntados, trampas temporales en el suelo, barreras
## pequeñas, apaga plataformas de la arena y, al bajar a la mitad de su vida, se protege con un escudo
## de datos (ligado a una configuración insegura: el controlador abre la fase segura y la terminal).
##
## Furia fraternal (si Glitch cae primero): pierde la calma calculadora. Dispara en abanico, sus
## trampas se arman más rápido y de a dos, y defiende su espacio con pulsos de datos si Kai se acerca.
## Arte provisional por código: un cubito cian con un ojo grande y una antena.

signal shield_requested

const CYAN := Color("5ad8ff")
const DARK := Color("0d2238")

var shielded := false
var shield_used := false
## Plataformas de la arena que puede apagar.
var platforms: Array[DataPlatform] = []

var _shot_cd := 1.2
var _trap_cd := 3.0
var _platform_cd := 5.0
var _pulse_cd := 0.0
var _side := 1


func _init() -> void:
	display_name = "Chip"
	body_size = Vector2(20, 20)
	contact_damage = 1.0
	threat_type = &"malware"
	gravity = 0.0
	death_colors = [CYAN, Color("a8eeff"), Color("1f6f9a")]


func _ready() -> void:
	max_health = _config_health()
	super()


func _config_health() -> float:
	return config.chip_health if config else max_health


func _ai(delta: float) -> void:
	var scale_cd := config.rage_chip_cooldown_scale if enraged else 1.0
	_shot_cd -= delta / scale_cd
	_trap_cd -= delta / scale_cd
	_platform_cd -= delta
	_pulse_cd -= delta
	_hover(delta)
	if busy:
		return
	var kai := player_position()
	if enraged and _pulse_cd <= 0.0 and kai.distance_to(global_position) < 80.0:
		_pulse()
	elif _shot_cd <= 0.0:
		_shoot()
	elif _trap_cd <= 0.0:
		_traps()
	elif _platform_cd <= 0.0 and not platforms.is_empty():
		_alter_platform()


## Flota a su altura y se mantiene a distancia de Kai, del lado donde está.
func _hover(_delta: float) -> void:
	var kai := player_position()
	if absf(kai.x - global_position.x) < 60.0:
		_side = 1 if global_position.x > kai.x else -1
	var target_x := clampf(kai.x + _side * 140.0, arena_left, arena_right)
	if target_x == arena_left or target_x == arena_right:
		_side = -_side if absf(kai.x - target_x) < 80.0 else _side
	var speed := config.chip_move_speed * (1.3 if enraged else 1.0)
	velocity.x = clampf((target_x - global_position.x) * 2.0, -speed, speed) if not busy else velocity.x * 0.9
	velocity.y = (config.chip_hover_y - global_position.y + sin(_clock * 2.0) * 6.0) * 4.0


func _frozen_move(_delta: float) -> void:
	# En la fase segura vuelve a su esquina (arriba a la derecha) y espera.
	velocity.x = clampf((arena_right - global_position.x) * 2.0, -80.0, 80.0)
	velocity.y = (config.chip_hover_y - 40.0 - global_position.y) * 4.0


func _idle_gravity() -> float:
	return 900.0 if is_dead else 0.0


## Disparo digital apuntado a Kai (en furia, abanico de varios).
func _shoot() -> void:
	busy = true
	var epoch := _epoch
	var telegraph_time := config.chip_shot_telegraph * (0.6 if enraged else 1.0)
	if not await telegraph(&"disparo", telegraph_time, epoch):
		busy = false
		return
	fire_at(player_position() + Vector2(0, -20), config.rage_chip_spread if enraged else 1, 1.0)
	_shot_cd = config.chip_shot_cooldown
	busy = false


## Dispara count rombos hacia target (en abanico si son varios). size_scale agranda el disparo.
func fire_at(target: Vector2, count := 1, size_scale := 1.0) -> void:
	var origin := global_position + Vector2(0, -10)
	var base := (target - origin).normalized()
	for k in count:
		var angle := (k - (count - 1) / 2.0) * 0.28
		BossAttacks.shot(get_parent(), origin, base.rotated(angle) * config.chip_shot_speed, 10.0 * size_scale, 0.12)
	Sfx.play(&"popup_open", 1.4, -6.0)


## Trampas en el suelo donde está Kai (en furia, dos y más rápidas).
func _traps() -> void:
	busy = true
	var epoch := _epoch
	if not await telegraph(&"trampa", config.chip_trap_telegraph, epoch):
		busy = false
		return
	var kai_x := player_position().x
	place_traps([kai_x - 50.0, kai_x + 50.0] if enraged else [kai_x])
	_trap_cd = config.chip_trap_cooldown
	busy = false


func place_traps(xs: Array) -> void:
	var arm := config.chip_trap_arm * (0.6 if enraged else 1.0)
	for x in xs:
		BossAttacks.trap(get_parent(), Vector2(clampf(x, arena_left, arena_right), floor_y()), arm, config.chip_trap_duration)


## Barrera pequeña que cierra el paso en x.
func place_wall(x: float) -> ChipWall:
	return BossAttacks.wall(get_parent(), Vector2(clampf(x, arena_left - 20.0, arena_right + 20.0), floor_y()), config.chip_wall_duration)


## Apaga la plataforma de la arena más cercana a Kai (parpadea antes de apagarse).
func _alter_platform() -> void:
	busy = true
	var epoch := _epoch
	var kai := player_position()
	var nearest: DataPlatform = null
	for platform in platforms:
		if nearest == null or platform.global_position.distance_to(kai) < nearest.global_position.distance_to(kai):
			nearest = platform
	if not await telegraph(&"plataforma", 0.4, epoch):
		busy = false
		return
	nearest.force_close(config.chip_platform_off)
	_platform_cd = config.chip_platform_cooldown
	busy = false


## Defensa agresiva (furia): un pulso de datos que sale en todas direcciones si Kai se acerca.
func _pulse() -> void:
	busy = true
	var epoch := _epoch
	if not await telegraph(&"pulso", 0.35, epoch):
		busy = false
		return
	for k in 8:
		BossAttacks.shot(get_parent(), global_position + Vector2(0, -10), Vector2.RIGHT.rotated(k * TAU / 8.0) * 120.0, 8.0, 0.0)
	_pulse_cd = 2.5
	busy = false


## Orden del controlador (Distracción): un disparo grande con un aviso largo.
func command_big_shot() -> void:
	busy = true
	var epoch := _epoch
	if await telegraph(&"disparo_grande", config.chip_shot_telegraph * 1.6, epoch):
		fire_at(player_position() + Vector2(0, -20), 1, 1.8)
	_shot_cd = config.chip_shot_cooldown
	busy = false


## Orden del controlador (Camino cerrado / Trampa sincronizada).
func command_wall(x: float) -> void:
	busy = true
	var epoch := _epoch
	if await telegraph(&"barrera", 0.4, epoch):
		place_wall(x)
	busy = false


func command_traps(xs: Array) -> void:
	busy = true
	var epoch := _epoch
	if await telegraph(&"trampa", config.chip_trap_telegraph, epoch):
		place_traps(xs)
	_trap_cd = config.chip_trap_cooldown
	busy = false


func shield_on() -> void:
	shielded = true
	hurtbox.immune = true


func shield_off() -> void:
	shielded = false
	hurtbox.immune = false


func _on_damaged(_hit: HitData) -> void:
	if not shield_used and not is_dead and health.current <= health.max_health * config.chip_shield_at:
		shield_used = true
		shield_on()
		shield_requested.emit()


func _on_restored() -> void:
	shielded = false
	shield_used = false
	_shot_cd = 1.2
	_trap_cd = 3.0
	_platform_cd = 5.0


func _on_rage() -> void:
	_shot_cd = 0.4
	_trap_cd = 1.0
	modulate = Color(1.2, 0.9, 1.0)


## Altura del piso de la arena (las trampas y barreras se apoyan ahí).
func floor_y() -> float:
	return 304.0


func _draw() -> void:
	var center := Vector2(0, -10)
	if is_dead:
		draw_rect(Rect2(-10, -14, 20, 14), DARK)
		draw_rect(Rect2(-10, -14, 20, 14), Color(CYAN, 0.6), false, 1.0)
		draw_dizzy(Vector2(0, -20))
		return
	if shielded:
		draw_circle(center, 20.0, Color(CYAN, 0.18 + 0.08 * sin(_clock * 6.0)))
		draw_arc(center, 20.0, 0.0, TAU, 24, Color(CYAN, 0.9), 1.5)
	var body := Rect2(-10, -20, 20, 20)
	draw_rect(body, DARK)
	draw_rect(body, Color(CYAN, 0.9), false, 1.5)
	# Ojo grande (el estratega).
	var look := (player_position() - global_position).normalized() * 2.0
	draw_circle(center + Vector2(0, -1), 5.5, Color(0.9, 1, 1))
	draw_circle(center + Vector2(0, -1) + look, 2.4, Color(1, 0.4, 0.5) if enraged else Color(0.05, 0.1, 0.2))
	# Antena.
	draw_line(Vector2(4, -20), Vector2(7, -28), CYAN, 1.0)
	draw_circle(Vector2(7, -29), 1.6, Color(1, 0.4, 0.5) if enraged else CYAN)
	# Patitas que cuelgan (flota).
	for x in [-6.0, 6.0]:
		draw_line(Vector2(x, 0), Vector2(x + sin(_clock * 8.0 + x) * 1.5, 4), Color(CYAN, 0.7), 1.0)
	draw_telegraph(center, Color(1, 0.5, 0.6) if enraged else CYAN)
