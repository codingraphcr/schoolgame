class_name PlayerDamage
extends Node
## Reacción del jugador al daño, al estilo Hollow Knight:
## cada golpe quita integridad (medio cristal los enemigos y los pinchos), congela la acción un instante, empuja y da invulnerabilidad breve
## (el personaje parpadea). Los peligros (pinchos, vacío) devuelven al jugador al último
## suelo seguro. Al perder todas las máscaras emite died: la sala decide dónde reaparece.

signal hurt(hit: HitData)
signal died
signal hazard_respawned

@export var health: HealthComponent
@export var hurtbox: HurtboxComponent
@export var safe_ground_left: RayCast2D
@export var safe_ground_right: RayCast2D
@export var invulnerability_time := 1.0
@export var hit_stop_time := 0.08
## Segundos de pie sobre suelo firme para guardar esa posición como punto seguro.
@export var safe_ground_delay := 0.1
## Al reaparecer se usa el suelo seguro de hace este tiempo, para no aparecer pegado al peligro.
@export var safe_ground_rewind := 0.3
@export var blink_interval := 0.08
## Multiplicador del daño de los enemigos: un golpe enemigo normal (daño 1) quita medio cristal de
## integridad; uno más fuerte, proporcionalmente más. Los peligros del
## escenario quitan lo que diga su golpe (pinchos: medio cristal; anuncios trampa y caídas: uno).
@export var enemy_damage_scale := 0.5

var invulnerable_timer := 0.0
var last_safe_position := Vector2.ZERO
## Verdadero mientras se reaparece tras un peligro o la muerte (no recibe daño).
var is_respawning := false

var _safe_timer := 0.0
var _clock := 0.0
## Historial reciente de posiciones seguras: [[tiempo, posición], ...]
var _safe_history: Array = []
var _respawn_position := Vector2.ZERO

@onready var player: Player = get_parent()
@onready var _visual: Node2D = get_parent().get_node("Visual")


func _ready() -> void:
	last_safe_position = player.global_position
	hurtbox.can_be_hit = func() -> bool: return not player.is_invulnerable()
	hurtbox.hit_received.connect(_on_hit_received)


func _physics_process(delta: float) -> void:
	if invulnerable_timer > 0.0:
		invulnerable_timer = maxf(invulnerable_timer - delta, 0.0)
		var blink_on := int(invulnerable_timer / blink_interval) % 2 == 0
		_visual.modulate.a = 1.0 if invulnerable_timer <= 0.0 or blink_on else 0.35
	_clock += delta
	_track_safe_ground(delta)


func is_invulnerable() -> bool:
	return invulnerable_timer > 0.0 or is_respawning


## Caída fuera de la sala: se trata como un peligro (1 máscara y vuelta al suelo seguro).
func fall_out_of_bounds() -> void:
	if is_respawning:
		return
	if is_invulnerable():
		_hazard_respawn()
		return
	var hit := HitData.new()
	hit.damage = 1.0
	hit.is_hazard = true
	_on_hit_received(hit)


## Devuelve al jugador a la vida tras morir (lo llama la sala al reaparecer).
func revive() -> void:
	health.restore_full()
	last_safe_position = player.global_position
	_safe_history.clear()
	is_respawning = false
	player.controls_locked = false
	invulnerable_timer = invulnerability_time


func _on_hit_received(hit: HitData) -> void:
	health.take_damage(hit.damage if hit.is_hazard else hit.damage * enemy_damage_scale)
	invulnerable_timer = invulnerability_time
	hurt.emit(hit)
	HitStop.freeze(self, hit_stop_time)
	if health.is_dead():
		is_respawning = true
		player.controls_locked = true
		player.velocity = Vector2.ZERO
		died.emit()
	elif hit.is_hazard:
		_hazard_respawn()
	else:
		player.apply_knockback(hit.knockback)


func _hazard_respawn() -> void:
	is_respawning = true
	player.controls_locked = true
	# Se calcula ya: durante el fundido el reloj sigue avanzando.
	_respawn_position = _rewound_safe_position()
	await _scene_manager().transition(_move_to_safe_ground)
	is_respawning = false
	player.controls_locked = false
	invulnerable_timer = invulnerability_time


func _move_to_safe_ground() -> void:
	player.teleport_to(_respawn_position)
	_safe_history.clear()
	last_safe_position = player.global_position
	hazard_respawned.emit()


## Suelo seguro más reciente que tenga al menos safe_ground_rewind segundos de antigüedad.
func _rewound_safe_position() -> Vector2:
	for i in range(_safe_history.size() - 1, -1, -1):
		if _clock - _safe_history[i][0] >= safe_ground_rewind:
			return _safe_history[i][1]
	return _safe_history[0][1] if not _safe_history.is_empty() else last_safe_position


## Guarda la posición como segura si el jugador está de pie con los dos lados del cuerpo
## sobre suelo firme (no al borde de un precipicio) y no está tocando un peligro.
func _track_safe_ground(delta: float) -> void:
	var on_solid_ground := player.is_on_floor() and safe_ground_left.is_colliding() and safe_ground_right.is_colliding()
	if not on_solid_ground or is_respawning or invulnerable_timer > 0.0 or _touching_hazard():
		_safe_timer = 0.0
		return
	_safe_timer += delta
	if _safe_timer >= safe_ground_delay:
		last_safe_position = player.global_position
		_safe_history.append([_clock, last_safe_position])
		# Basta con el último segundo de historial.
		while _safe_history.size() > 1 and _clock - _safe_history[0][0] > 1.0:
			_safe_history.pop_front()


func _touching_hazard() -> bool:
	for area in hurtbox.get_overlapping_areas():
		var hitbox := area as HitboxComponent
		if hitbox and hitbox.is_hazard:
			return true
	return false


## El autoload se obtiene por ruta (no por nombre global) para que este script también compile
## en las pruebas de línea de comandos, donde los autoloads se registran después.
func _scene_manager() -> Node:
	return get_node("/root/SceneManager")
