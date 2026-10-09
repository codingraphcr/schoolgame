class_name HitboxComponent
extends Area2D
## Zona que causa daño: ataques, cuerpos de enemigos, proyectiles y peligros.
## La detecta un HurtboxComponent, que pide el golpe con try_hit().
##
## Capas: los ataques del jugador van en la capa 4 (ataques_jugador);
## los de enemigos y peligros, en la capa 5 (ataques_enemigos).

## Cada vez que este Hitbox golpea a un Hurtbox (para efectos del atacante: retroceso, energía).
signal hit_dealt(hurtbox: Node2D, hit: HitData)

@export var damage := 1.0
@export var threat_type: StringName = &""
@export var knockback_force := 200.0
@export var is_hazard := false
## Si está activo, golpea una sola vez a cada objetivo hasta la próxima activación
## (un tajo de espada daña una vez, no en cada cuadro).
@export var once_per_activation := false
## Desactivado no causa daño (p. ej. fuera de la ventana activa de un ataque).
@export var active := true

var _already_hit: Array[Node] = []


func _ready() -> void:
	monitoring = false
	monitorable = true


## Activa el Hitbox y olvida a quién golpeó en la activación anterior.
func activate() -> void:
	_already_hit.clear()
	active = true


func deactivate() -> void:
	active = false


## Devuelve el golpe para este Hurtbox, o null si no debe dañarlo ahora.
func try_hit(hurtbox: Node2D) -> HitData:
	if not active:
		return null
	if once_per_activation:
		if hurtbox in _already_hit:
			return null
		_already_hit.append(hurtbox)
	var hit := create_hit(hurtbox)
	hit_dealt.emit(hurtbox, hit)
	return hit


func create_hit(target: Node2D) -> HitData:
	var hit := HitData.new()
	hit.damage = damage
	hit.threat_type = threat_type
	hit.is_hazard = is_hazard
	hit.source = owner if owner else self
	var direction := signf(target.global_position.x - global_position.x)
	if is_zero_approx(direction):
		direction = 1.0
	hit.knockback = Vector2(direction * knockback_force, -knockback_force * 0.6)
	return hit
