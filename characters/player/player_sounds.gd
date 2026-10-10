extends Node
## Sonidos de Kai (nodo "Sounds" del jugador): escucha lo que hace el jugador y reproduce el efecto
## que corresponde con Sfx. Pasos (distintos en el colegio y dentro de una computadora), saltos,
## caída, dash, daño (con el crujido del cristal), muerte, curación, tajos, golpes y energía.

## Segundos entre pasos al correr.
const STEP_TIME := 0.27

var _step_left := 0.0
var _heal_sound: AudioStreamPlayer
var _last_energy := -1.0
var _last_health := -1.0

@onready var player: Player = get_parent()


func _ready() -> void:
	# Los hijos están listos antes que el jugador: sus @onready (heal, combat…) aún no existen.
	_connect.call_deferred()


func _connect() -> void:
	player.jumped.connect(func() -> void: Sfx.play(&"jump"))
	player.double_jumped.connect(func() -> void: Sfx.play(&"double_jump"))
	player.wall_jumped.connect(func() -> void: Sfx.play(&"wall_jump"))
	player.landed.connect(func() -> void: Sfx.play(&"land"))
	player.dashed.connect(func() -> void: Sfx.play(&"dash"))
	player.damage.hurt.connect(_on_hurt)
	player.damage.died.connect(func() -> void: Sfx.play(&"death"))
	player.heal.started.connect(_on_heal_started)
	player.heal.healed.connect(_on_healed)
	player.heal.finished.connect(func(_completed: bool) -> void: Sfx.stop(_heal_sound))
	player.combat.attacked.connect(func() -> void: Sfx.play(&"slash", randf_range(0.95, 1.08)))
	player.combat.hit_landed.connect(func(_target: Node2D) -> void: Sfx.play(&"hit"))
	player.energy_changed.connect(_on_energy_changed)
	player.health.health_changed.connect(func(current: float, _maximum: float) -> void: _last_health = current)
	_last_health = player.health.current


func _physics_process(delta: float) -> void:
	if player.heal == null:
		return
	var running := player.is_on_floor() and absf(player.velocity.x) > 30.0 and not player.heal.active
	if not running:
		_step_left = 0.05
		return
	_step_left -= delta
	if _step_left <= 0.0:
		_step_left = STEP_TIME
		Sfx.play(_footstep(), randf_range(0.9, 1.1))


## Pasos dentro de una computadora (mundo digital) o en el colegio.
func _footstep() -> StringName:
	var room := player.owner as Room
	return room.footstep if room and "footstep" in room else &"step_school"


func _on_hurt(hit: HitData) -> void:
	Sfx.play(&"hurt")
	# El cristal que pierde integridad cruje.
	Sfx.play(&"crystal_crack", randf_range(0.95, 1.1), -3.0)
	if hit.source is TrapAd:
		Sfx.play(&"error")


func _on_heal_started(_in_air: bool) -> void:
	_heal_sound = Sfx.play(&"heal_charge")


func _on_healed(_amount: float) -> void:
	Sfx.play(&"heal_done")
	# Si sigue curándose, la carga vuelve a sonar (más corta, por eso un poco más aguda).
	if player.heal.active:
		_heal_sound = Sfx.play(&"heal_charge", 1.25)


func _on_energy_changed(current: float, _maximum: float) -> void:
	if _last_energy >= 0.0 and current > _last_energy + 0.001 and player.combat.is_attacking():
		Sfx.play(&"energy_gain")
	_last_energy = current
