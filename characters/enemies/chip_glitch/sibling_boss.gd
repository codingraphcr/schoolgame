class_name SiblingBoss
extends EnemyBase
## Base de Chip y Glitch, el jefe doble del Capítulo 1. Cada hermano tiene su barra de vida, su
## propia máquina de estados (en _ai) y sus tiempos de espera; los valores están en un DualBossConfig.
##
## - Nunca mueren: al llegar a cero quedan **neutralizados** (mareados en el piso) y no se borran
##   (la historia dice que pueden volver). Emite neutralized.
## - Todo ataque empieza con telegraph(): una señal visual de aviso de unos segundos (esquivable).
## - frozen: la fase segura del escudo (no hacen nada). busy: están en un ataque o en una orden del
##   controlador (los ataques combinados).
## - enter_rage(): la Furia fraternal (una sola vez); cada hermano la cambia a su manera (_on_rage).
## - restore(): vuelven a empezar (si Kai pierde y reaparece).
## Los tiempos corren con la física (siempre igual aunque la computadora vaya lenta).

signal neutralized(boss: SiblingBoss)
signal attack_started(attack: StringName)

@export var config: DualBossConfig
## Límites de la arena (x mínima y máxima donde se mueven).
var arena_left := 40.0
var arena_right := 600.0
var enraged := false
var busy := false
var frozen := false:
	set(value):
		frozen = value
		if value:
			_epoch += 1
			busy = false
## Lugar donde empiezan (para restore()).
var home := Vector2.ZERO

var _telegraph := 0.0
var _telegraph_kind: StringName = &""
var _clock := 0.0
## Cambia cada vez que se interrumpen los ataques (congelados, neutralizados, reinicio): un ataque en
## curso que ve otra época se termina solo.
var _epoch := 0


func _ready() -> void:
	rank = Rank.JEFE
	ecos_reward = 0  # La recompensa la da el final del capítulo (una sola vez).
	knockback_resistance = 0.85
	hurt_time = 0.12
	super()
	home = global_position


func _physics_process(delta: float) -> void:
	_clock += delta
	if _telegraph > 0.0:
		_telegraph = maxf(_telegraph - delta, 0.0)
	queue_redraw()
	if is_dead or frozen:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		velocity.y = minf(velocity.y + _idle_gravity() * delta, max_fall_speed)
		if frozen and not is_dead:
			_frozen_move(delta)
		move_and_slide()
		return
	super(delta)


## Usa estos valores (vida incluida: empieza con la vida llena).
func apply_config(new_config: DualBossConfig) -> void:
	config = new_config
	max_health = _config_health()
	if health:
		health.max_health = max_health
		health.restore_full()


## Vida que le corresponde según el DualBossConfig.
func _config_health() -> float:
	return max_health


## Si está en medio de un aviso de ataque (para dibujarlo y para las pruebas).
func is_telegraphing() -> bool:
	return _telegraph > 0.0


func telegraph_kind() -> StringName:
	return _telegraph_kind


func player_position() -> Vector2:
	var player := get_player()
	return player.global_position if player else global_position


## Espera seconds de juego. Devuelve false si el ataque se interrumpió mientras tanto.
func wait(seconds: float, epoch: int) -> bool:
	await get_tree().create_timer(seconds, false, true).timeout
	return epoch == _epoch and not is_dead and not frozen


## Aviso visual antes de un ataque. Devuelve false si se interrumpió.
func telegraph(kind: StringName, seconds: float, epoch: int) -> bool:
	_telegraph_kind = kind
	_telegraph = seconds
	attack_started.emit(kind)
	return await wait(seconds, epoch)


func enter_rage() -> void:
	if enraged or is_dead:
		return
	enraged = true
	_epoch += 1
	busy = false
	_on_rage()


## Vuelve a empezar la pelea (vida llena, sin furia, en su lugar).
func restore() -> void:
	_epoch += 1
	is_dead = false
	enraged = false
	busy = false
	frozen = false
	health.restore_full()
	contact.activate()
	hurtbox.set_physics_process(true)
	hurtbox.immune = false
	collision_layer = 4
	modulate = Color.WHITE
	scale = Vector2.ONE
	global_position = home
	velocity = Vector2.ZERO
	_on_restored()


## Neutralizado: no muere ni se borra. Queda mareado donde cayó.
func _die() -> void:
	is_dead = true
	_epoch += 1
	busy = false
	contact.deactivate()
	hurtbox.set_physics_process(false)
	collision_layer = 0
	velocity = Vector2(0, -60)
	Sfx.play(&"enemy_death", 1.2)
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -body_size.y / 2.0), death_colors, 18, 70.0, body_size, 0.5)
	died.emit()
	neutralized.emit(self)
	_on_died()


func _idle_gravity() -> float:
	return gravity if gravity > 0.0 else 900.0


## Movimiento mientras está congelado (Chip vuelve a flotar en su esquina).
func _frozen_move(_delta: float) -> void:
	pass


func _on_rage() -> void:
	pass


func _on_restored() -> void:
	pass


## Anillo de aviso (se cierra mientras dura el telegrafiado).
func draw_telegraph(center: Vector2, color: Color) -> void:
	if not is_telegraphing():
		return
	var pulse := int(_clock / 0.06) % 2 == 0
	draw_arc(center, 14.0 + _telegraph * 20.0, 0.0, TAU, 20, Color(color, 0.9 if pulse else 0.4), 1.5)
	draw_string(ThemeDB.fallback_font, center + Vector2(-3, -16 - _telegraph * 20.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
