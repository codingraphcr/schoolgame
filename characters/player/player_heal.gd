class_name PlayerHeal
extends Node
## Curación de Kai (mantener L, acción "heal"): canaliza su propia energía para restaurar integridad.
## Cada curación gasta media barrita de energía y devuelve 1,5 cristales. La primera tarda 1,141 s
## (incluye 0,30 s de inicio); si se sigue manteniendo y queda energía, cada curación siguiente
## tarda 0,9 s más. Soltar la tecla antes de tiempo cancela sin gastar energía; un golpe la corta.
## Para volver a curarse después de terminar o de un golpe hay que soltar L y presionarla otra vez.
## En el suelo Kai se arrodilla; en el aire se queda flotando mientras se cura.

signal started(in_air: bool)
signal healed(amount: float)
## completed: si llegó a curar al menos una vez.
signal finished(completed: bool)

@export var health: HealthComponent
## Segundos de inicio antes de que empiece a canalizar (Kai se arrodilla o se detiene en el aire).
@export var startup_time := 0.30
## Segundos hasta la primera curación (incluye el inicio).
@export var first_heal_time := 1.141
## Segundos entre una curación y la siguiente.
@export var next_heal_time := 0.9
## Cristales que devuelve cada curación.
@export var heal_amount := 1.5
## Barritas de energía que gasta cada curación.
@export var energy_cost := 0.5

var active := false
var in_air := false
## Curaciones hechas en esta canalización.
var heals_done := 0

var _elapsed := 0.0
var _next_heal := 0.0
## Después de terminar o de un golpe, hay que soltar L antes de volver a curarse.
var _needs_release := false

@onready var player: Player = get_parent()


func _ready() -> void:
	var damage := player.get_node_or_null("Damage") as PlayerDamage
	if damage:
		damage.hurt.connect(func(_hit: HitData) -> void: stop())


func _physics_process(_delta: float) -> void:
	if _needs_release and not Input.is_action_pressed(&"heal"):
		_needs_release = false


## Verdadero mientras Kai se arrodilla o se detiene antes de canalizar.
func is_starting() -> bool:
	return active and _elapsed < startup_time


## Avance hasta la próxima curación (0 a 1), para efectos visuales.
func progress() -> float:
	if not active:
		return 0.0
	var span := first_heal_time if heals_done == 0 else next_heal_time
	return clampf(1.0 - (_next_heal - _elapsed) / span, 0.0, 1.0)


func can_start() -> bool:
	return not active and not _needs_release and not player.controls_locked and not player.is_dashing \
		and not player.is_wall_sliding and not health.is_dead() \
		and health.current < health.max_health and player.energy >= energy_cost \
		and not (player.damage and player.damage.is_respawning)


func start() -> void:
	active = true
	in_air = not player.is_on_floor()
	heals_done = 0
	_elapsed = 0.0
	_next_heal = first_heal_time
	started.emit(in_air)


## Lo llama el jugador cada cuadro de física mientras se cura. holding: si sigue manteniendo L.
func update(delta: float, holding: bool) -> void:
	if not holding:
		stop()
		return
	_elapsed += delta
	if _elapsed < _next_heal:
		return
	if player.spend_energy(energy_cost):
		health.heal(heal_amount)
		heals_done += 1
		healed.emit(heal_amount)
	if health.current >= health.max_health or player.energy < energy_cost:
		stop()
	else:
		_next_heal += next_heal_time


func stop() -> void:
	if not active:
		return
	active = false
	_needs_release = true
	finished.emit(heals_done > 0)
