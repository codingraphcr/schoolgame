class_name Player
extends CharacterBody2D
## Jugador: movimiento de plataformas con coyote time, jump buffer, salto variable,
## dash, doble salto y deslizamiento/salto de pared.
## El daño y la vida los gestiona el nodo hijo Damage (PlayerDamage) con Health (HealthComponent).
## El origen del nodo está a la altura de los pies.
## Todos los valores se ajustan desde el Inspector (16 px = 1 tile).

signal state_changed(previous: State, current: State)
signal jumped
signal double_jumped
signal wall_jumped
signal dashed
signal landed
## Cambió la energía (en barritas): la muestra el HUD.
signal energy_changed(current: float, maximum: float)

enum State { IDLE, RUN, JUMP, FALL, DASH, WALL_SLIDE }

@export_group("Habilidades")
## 0 = sin dash · 1 = Dash (no protege del daño) · 2 = Dash Fantasma (atraviesa enemigos
## y ataques sin daño) · 3 = Esquiva Perfecta (pendiente, tarea C7).
## El dash se adquiere con la historia y se mejora con créditos.
@export_range(0, 3) var dash_level := 0
## Se desbloquea durante la historia.
@export var can_double_jump := false
## Deslizar por paredes y saltar desde ellas. Se desbloquea durante la historia.
@export var can_wall_jump := false

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
@export var fall_gravity_multiplier := 2.0
@export var max_fall_speed := 500.0
## Al soltar el botón durante la subida, la velocidad vertical se multiplica por este valor.
@export_range(0.0, 1.0) var jump_cut_multiplier := 0.45
## Gravedad reducida cerca del punto más alto mientras se mantiene el botón (sensación de flotar).
@export_range(0.0, 1.0) var apex_gravity_multiplier := 0.8
@export var apex_speed_threshold := 30.0
## Tiempo para saltar después de salir de un borde.
@export var coyote_time := 0.1
## Tiempo que se recuerda una pulsación de salto antes de tocar el suelo o una pared.
@export var jump_buffer_time := 0.12

@export_group("Doble salto")
@export var double_jump_height := 56.0
@export var max_air_jumps := 1

@export_group("Pared")
## Velocidad máxima de caída mientras se desliza por una pared.
@export var wall_slide_speed := 60.0
@export var wall_jump_height := 56.0
## Velocidad horizontal con la que el salto de pared aleja al jugador.
@export var wall_jump_push := 160.0
## Tiempo tras un salto de pared en el que se ignora la dirección (evita volver de golpe a la pared).
@export var wall_jump_input_lock := 0.12
## Tiempo para saltar después de separarse de una pared.
@export var wall_coyote_time := 0.1

@export_group("Dash")
@export var dash_speed := 340.0
@export var dash_duration := 0.15
@export var dash_cooldown := 0.35
@export var afterimage_interval := 0.035

@export_group("Daño")
## Tiempo tras recibir un golpe en el que se ignora la dirección (el empuje se nota).
@export var knockback_input_lock := 0.15

var state: State = State.IDLE
var facing := 1
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var air_jumps_left := 0
var is_dashing := false
var is_wall_sliding := false
var dash_cooldown_timer := 0.0
## Bloquea los controles (reaparición, cinemáticas). La gravedad sigue actuando.
var controls_locked := false
## Energía para habilidades, en barritas (la curación gasta media). El máximo sale de GameState.
var energy := 2.0
var max_energy := 2.0

var jump_velocity: float:
	get:
		return 2.0 * jump_height / time_to_apex

var jump_gravity: float:
	get:
		return 2.0 * jump_height / (time_to_apex * time_to_apex)

# Verdadero desde que salta hasta que empieza a caer o suelta el botón (para el salto variable).
var _is_jump_rising := false
var _wall_coyote_timer := 0.0
var _wall_normal_x := 0.0
var _input_lock_timer := 0.0
var _air_dash_available := true
var _dash_timer := 0.0
var _dash_direction := 1
var _afterimage_timer := 0.0

@onready var health: HealthComponent = $Health
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var damage: PlayerDamage = $Damage
@onready var heal: PlayerHeal = $Heal
@onready var _visual: Node2D = $Visual
@onready var _body: Node2D = $Visual/Body


func _ready() -> void:
	# Así otros sistemas encuentran a Kai sin conocer la sala (p. ej. la lluvia de correos SPAM).
	add_to_group(&"player")


func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()
	_update_timers(delta, was_on_floor)

	if heal.active:
		# Curándose: quieto en el suelo o flotando en el aire.
		heal.update(delta, _action_pressed("heal"))
		velocity = Vector2.ZERO
		move_and_slide()
	elif is_dashing:
		_process_dash(delta)
	elif _action_just_pressed("dash") and _can_start_dash():
		_start_dash()
	elif _action_pressed("heal") and heal.can_start():
		heal.start()
		velocity = Vector2.ZERO
	else:
		_apply_gravity(delta)
		_handle_jump()
		_apply_jump_cut()
		_apply_horizontal_movement(delta)
		move_and_slide()

	_update_wall_state()
	if not was_on_floor and is_on_floor():
		_on_landed()
	_update_state()


## Verdadero mientras el jugador no puede recibir daño: tras un golpe, al reaparecer
## o durante el dash desde el nivel 2 (Dash Fantasma).
func is_invulnerable() -> bool:
	if is_dashing and dash_level >= 2:
		return true
	return damage != null and damage.is_invulnerable()


## Aplica el progreso de la partida (GameState): el jugador solo puede usar lo que ya adquirió.
## Con full_health se llenan las máscaras (al entrar a una sala); si no, se conserva la vida actual.
func apply_progress(progress: Node, full_health := false) -> void:
	dash_level = progress.dash_level
	can_double_jump = progress.can_double_jump
	can_wall_jump = progress.can_wall_jump
	health.max_health = progress.max_masks
	if full_health:
		health.restore_full()
	else:
		health.health_changed.emit(health.current, health.max_health)
	max_energy = progress.max_energy_cells
	set_energy(max_energy if full_health else energy)


## Fija la energía (en barritas, sin pasar del máximo) y avisa al HUD.
func set_energy(value: float) -> void:
	energy = clampf(value, 0.0, max_energy)
	energy_changed.emit(energy, max_energy)


## Suma energía (para habilidades y recompensas futuras).
func add_energy(amount: float) -> void:
	set_energy(energy + amount)


## Gasta energía si alcanza. Devuelve false si no había suficiente.
func spend_energy(amount: float) -> bool:
	if energy + 0.0001 < amount:
		return false
	set_energy(energy - amount)
	return true


## Hace que Kai mire hacia un lado (1 = derecha, -1 = izquierda).
func face(direction: int) -> void:
	_set_facing(1 if direction >= 0 else -1)


## Empuje al recibir un golpe: interrumpe el dash y bloquea la dirección un instante.
func apply_knockback(force: Vector2) -> void:
	if is_dashing:
		_end_dash()
	velocity = force
	_is_jump_rising = false
	_input_lock_timer = knockback_input_lock


## Coloca al jugador en una posición y lo detiene (al aparecer o reaparecer).
func teleport_to(target_position: Vector2) -> void:
	global_position = target_position
	velocity = Vector2.ZERO
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	_is_jump_rising = false
	_wall_coyote_timer = 0.0
	_input_lock_timer = 0.0
	is_wall_sliding = false
	if is_dashing:
		_end_dash()


# --- Temporizadores y estados -------------------------------------------------

func _update_timers(delta: float, on_floor: bool) -> void:
	if on_floor:
		coyote_timer = coyote_time
		_restore_air_moves()
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if _action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	_wall_coyote_timer = maxf(_wall_coyote_timer - delta, 0.0)
	_input_lock_timer = maxf(_input_lock_timer - delta, 0.0)
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)


func _restore_air_moves() -> void:
	air_jumps_left = max_air_jumps if can_double_jump else 0
	_air_dash_available = true


func _update_wall_state() -> void:
	is_wall_sliding = false
	if not can_wall_jump or is_dashing or is_on_floor() or not is_on_wall_only():
		return
	var normal_x := get_wall_normal().x
	var direction := _input_axis()
	# Solo cuenta como agarre si el jugador empuja hacia la pared.
	if is_zero_approx(direction) or signf(direction) != -signf(normal_x):
		return
	_wall_normal_x = signf(normal_x)
	_wall_coyote_timer = wall_coyote_time
	if velocity.y >= 0.0:
		is_wall_sliding = true
		_restore_air_moves()
		_set_facing(int(_wall_normal_x))


func _update_state() -> void:
	var new_state: State
	if is_dashing:
		new_state = State.DASH
	elif is_wall_sliding:
		new_state = State.WALL_SLIDE
	elif is_on_floor():
		new_state = State.RUN if absf(velocity.x) > 5.0 else State.IDLE
	else:
		new_state = State.JUMP if velocity.y < 0.0 else State.FALL
	if new_state != state:
		var previous := state
		state = new_state
		state_changed.emit(previous, new_state)


func _on_landed() -> void:
	_is_jump_rising = false
	_squash(Vector2(1.25, 0.8))
	landed.emit()


# --- Gravedad y movimiento horizontal ----------------------------------------

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var gravity := jump_gravity
	if velocity.y > 0.0:
		gravity *= fall_gravity_multiplier
	if _action_pressed("jump") and absf(velocity.y) < apex_speed_threshold:
		gravity *= apex_gravity_multiplier
	var fall_limit := wall_slide_speed if is_wall_sliding else max_fall_speed
	velocity.y = minf(velocity.y + gravity * delta, fall_limit)


func _apply_horizontal_movement(delta: float) -> void:
	# Durante el bloqueo (salto de pared, empuje) se conserva la velocidad horizontal.
	if _input_lock_timer > 0.0:
		return
	var direction := _input_axis()
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

	if not is_zero_approx(direction) and not is_wall_sliding:
		_set_facing(1 if direction > 0.0 else -1)


func _set_facing(direction: int) -> void:
	facing = direction
	_visual.scale.x = facing


# --- Saltos -------------------------------------------------------------------

## Prioridad: salto desde el suelo (incluye coyote time) > salto de pared > doble salto.
## Si ninguno es posible, la pulsación queda guardada (jump buffer) para el aterrizaje.
func _handle_jump() -> void:
	if jump_buffer_timer <= 0.0:
		return
	if coyote_timer > 0.0:
		_jump(jump_velocity)
		_squash(Vector2(0.8, 1.2))
		jumped.emit()
	elif can_wall_jump and _wall_coyote_timer > 0.0:
		_wall_jump()
	elif can_double_jump and air_jumps_left > 0 and _action_just_pressed("jump"):
		air_jumps_left -= 1
		_jump(_velocity_for_height(double_jump_height))
		_squash(Vector2(0.75, 1.25))
		RingBurst.spawn(get_parent(), global_position, Color(0.133, 0.827, 0.933))
		double_jumped.emit()


func _jump(vertical_speed: float) -> void:
	velocity.y = -vertical_speed
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	_wall_coyote_timer = 0.0
	_is_jump_rising = true


func _wall_jump() -> void:
	_jump(_velocity_for_height(wall_jump_height))
	velocity.x = _wall_normal_x * wall_jump_push
	_input_lock_timer = wall_jump_input_lock
	is_wall_sliding = false
	_set_facing(int(_wall_normal_x))
	_squash(Vector2(0.8, 1.2))
	wall_jumped.emit()


func _apply_jump_cut() -> void:
	if not _is_jump_rising:
		return
	if velocity.y >= 0.0:
		_is_jump_rising = false
	elif not _action_pressed("jump"):
		velocity.y *= jump_cut_multiplier
		_is_jump_rising = false


func _velocity_for_height(height: float) -> float:
	return sqrt(2.0 * jump_gravity * height)


# --- Dash ---------------------------------------------------------------------

func _can_start_dash() -> bool:
	if dash_level < 1 or dash_cooldown_timer > 0.0:
		return false
	return is_on_floor() or is_wall_sliding or _air_dash_available


func _start_dash() -> void:
	if is_wall_sliding:
		_dash_direction = int(_wall_normal_x)
	else:
		var direction := _input_axis()
		_dash_direction = facing if is_zero_approx(direction) else (1 if direction > 0.0 else -1)
	if not is_on_floor():
		_air_dash_available = false
	is_dashing = true
	is_wall_sliding = false
	_is_jump_rising = false
	_dash_timer = dash_duration
	_afterimage_timer = 0.0
	_set_facing(_dash_direction)
	_squash(Vector2(1.3, 0.8))
	dashed.emit()
	# El dash empieza a moverse en el mismo cuadro en que se pulsa (cuenta como su primer cuadro).
	_process_dash(get_physics_process_delta_time())


func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = Vector2(_dash_direction * dash_speed, 0.0)
	move_and_slide()

	_afterimage_timer -= delta
	if _afterimage_timer <= 0.0:
		_afterimage_timer = afterimage_interval
		_spawn_afterimage()

	if _dash_timer <= 0.0 or is_on_wall():
		_end_dash()


func _end_dash() -> void:
	is_dashing = false
	dash_cooldown_timer = dash_cooldown
	# Conserva el impulso a velocidad normal para que la salida del dash sea suave.
	velocity.x = _dash_direction * max_speed if not is_on_wall() else 0.0


## Copia congelada del dibujo actual. Con personajes por huesos (PixelatedRig) usa una
## instantánea; con dibujos simples, duplica Visual y lo congela.
func _make_afterimage() -> Node2D:
	var rigs := _visual.find_children("*", "PixelatedRig", true, false)
	if rigs.is_empty():
		var copy := _visual.duplicate() as Node2D
		copy.process_mode = Node.PROCESS_MODE_DISABLED
		copy.top_level = true
		copy.global_transform = _visual.global_transform
		return copy
	var rig := rigs[0] as PixelatedRig
	var snap := rig.snapshot()
	if snap == null:
		return null
	snap.top_level = true
	snap.global_transform = rig.global_transform
	return snap


## Silueta que se desvanece detrás del jugador durante el dash.
func _spawn_afterimage() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var ghost := _make_afterimage()
	if ghost == null:
		return
	parent.add_child(ghost)
	# Justo detrás del jugador y delante del escenario.
	parent.move_child(ghost, get_index())
	ghost.modulate = Color(0.4, 0.9, 1.0, 0.55)
	var tween := create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.2)
	tween.tween_callback(ghost.queue_free)


# --- Controles (respetan controls_locked) --------------------------------------

func _input_axis() -> float:
	return 0.0 if controls_locked else Input.get_axis("move_left", "move_right")


func _action_pressed(action: StringName) -> bool:
	return not controls_locked and Input.is_action_pressed(action)


func _action_just_pressed(action: StringName) -> bool:
	return not controls_locked and Input.is_action_just_pressed(action)


# --- Efectos visuales ---------------------------------------------------------

## Deformación breve del dibujo (no afecta a la colisión).
func _squash(amount: Vector2) -> void:
	_body.scale = amount
	var tween := create_tween()
	tween.tween_property(_body, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
