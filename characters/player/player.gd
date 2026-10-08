class_name Player
extends CharacterBody2D
## Jugador: movimiento de plataformas con coyote time, jump buffer y salto de altura variable.
## El origen del nodo está a la altura de los pies.
## Todos los valores de movimiento se ajustan desde el Inspector (16 px = 1 tile).

signal state_changed(previous: State, current: State)
signal jumped
signal landed

enum State { IDLE, RUN, JUMP, FALL }

@export_group("Movimiento horizontal")
@export var max_speed := 140.0
@export var ground_acceleration := 1400.0
@export var ground_deceleration := 1800.0
@export var air_acceleration := 1000.0
@export var air_deceleration := 700.0

@export_group("Salto")
## Altura máxima del salto en píxeles.
@export var jump_height := 72.0
## Segundos que tarda en llegar al punto más alto.
@export var time_to_apex := 0.4
## Gravedad extra al caer (> 1 = caída más rápida y firme).
@export var fall_gravity_multiplier := 1.5
@export var max_fall_speed := 420.0
## Al soltar el botón durante la subida, la velocidad vertical se multiplica por este valor.
@export_range(0.0, 1.0) var jump_cut_multiplier := 0.45
## Gravedad reducida cerca del punto más alto mientras se mantiene el botón (sensación de flotar).
@export_range(0.0, 1.0) var apex_gravity_multiplier := 0.6
@export var apex_speed_threshold := 40.0
## Tiempo para saltar después de salir de un borde.
@export var coyote_time := 0.1
## Tiempo que se recuerda una pulsación de salto antes de tocar el suelo.
@export var jump_buffer_time := 0.12

var state: State = State.IDLE
var facing := 1
var coyote_timer := 0.0
var jump_buffer_timer := 0.0

var jump_velocity: float:
	get:
		return 2.0 * jump_height / time_to_apex

var jump_gravity: float:
	get:
		return 2.0 * jump_height / (time_to_apex * time_to_apex)

# Verdadero desde que salta hasta que empieza a caer o suelta el botón (para el salto variable).
var _is_jump_rising := false

@onready var _visual: Node2D = $Visual
@onready var _body: Node2D = $Visual/Body


func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()

	_update_timers(delta, was_on_floor)
	_apply_gravity(delta)
	_try_jump()
	_apply_jump_cut()
	_apply_horizontal_movement(delta)
	move_and_slide()

	if not was_on_floor and is_on_floor():
		_on_landed()
	_update_state()


func _update_timers(delta: float, on_floor: bool) -> void:
	if on_floor:
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var gravity := jump_gravity
	if velocity.y > 0.0:
		gravity *= fall_gravity_multiplier
	if Input.is_action_pressed("jump") and absf(velocity.y) < apex_speed_threshold:
		gravity *= apex_gravity_multiplier
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


func _try_jump() -> void:
	if jump_buffer_timer <= 0.0 or coyote_timer <= 0.0:
		return
	velocity.y = -jump_velocity
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	_is_jump_rising = true
	_squash(Vector2(0.8, 1.2))
	jumped.emit()


func _apply_jump_cut() -> void:
	if not _is_jump_rising:
		return
	if velocity.y >= 0.0:
		_is_jump_rising = false
	elif not Input.is_action_pressed("jump"):
		velocity.y *= jump_cut_multiplier
		_is_jump_rising = false


func _apply_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var on_floor := is_on_floor()
	var rate: float
	if is_zero_approx(direction):
		rate = ground_deceleration if on_floor else air_deceleration
	elif signf(direction) != signf(velocity.x) and not is_zero_approx(velocity.x):
		# Al girar se usa la desaceleración para cambiar de sentido con rapidez.
		rate = ground_deceleration if on_floor else air_deceleration + air_acceleration
	else:
		rate = ground_acceleration if on_floor else air_acceleration
	velocity.x = move_toward(velocity.x, direction * max_speed, rate * delta)

	if not is_zero_approx(direction):
		facing = 1 if direction > 0.0 else -1
		_visual.scale.x = facing


func _on_landed() -> void:
	_is_jump_rising = false
	_squash(Vector2(1.25, 0.8))
	landed.emit()


func _update_state() -> void:
	var new_state: State
	if is_on_floor():
		new_state = State.RUN if absf(velocity.x) > 5.0 else State.IDLE
	else:
		new_state = State.JUMP if velocity.y < 0.0 else State.FALL
	if new_state != state:
		var previous := state
		state = new_state
		state_changed.emit(previous, new_state)


## Deformación breve del dibujo (no afecta a la colisión).
func _squash(amount: Vector2) -> void:
	_body.scale = amount
	var tween := create_tween()
	tween.tween_property(_body, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Coloca al jugador en una posición y lo detiene (al aparecer o reaparecer).
func teleport_to(target_position: Vector2) -> void:
	global_position = target_position
	velocity = Vector2.ZERO
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	_is_jump_rising = false
