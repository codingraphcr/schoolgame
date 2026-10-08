class_name KaiVisual
extends Node2D
## Apariencia de Kai: el esqueleto (kai_esqueleto.tscn) animado según el estado del jugador
## y dibujado a resolución de pixel art con PixelatedRig.
## Se coloca dentro de Visual/Body del jugador: así hereda el giro y la deformación de player.gd.

const SKELETON := preload("res://characters/player/kai/kai_esqueleto.tscn")
## Lienzo donde se dibuja Kai (deja espacio para brazos arriba, dash y el arma).
const CANVAS := Vector2i(72, 72)
## Punto del lienzo donde están los pies.
const FEET := Vector2i(36, 62)
const BLEND := 0.08

const ANIMATIONS := {
	Player.State.IDLE: &"quieto",
	Player.State.RUN: &"correr",
	Player.State.JUMP: &"saltar",
	Player.State.FALL: &"caer",
	Player.State.DASH: &"dash",
	Player.State.WALL_SLIDE: &"pared",
}

@export var player: Player

var _animation: AnimationPlayer
var _lock: Bone2D
var _backpack: Bone2D
var _attack_left := 0.0
var _time := 0.0


func _ready() -> void:
	# Las estelas del dash duplican este nodo con todo su contenido: no se vuelve a construir.
	if get_child_count() > 0:
		return
	var skeleton := SKELETON.instantiate()
	var rig := PixelatedRig.new()
	rig.setup(skeleton, CANVAS, FEET, false)
	add_child(rig)
	_animation = skeleton.get_node("AnimationPlayer")
	_lock = skeleton.get_node("Skeleton2D/Cadera/Torso/Cuello/Mechon")
	_backpack = skeleton.get_node("Skeleton2D/Cadera/Torso/Mochila")


## Reproduce el ataque con el Nullblade (mientras dura, tiene prioridad sobre el movimiento).
func attack() -> void:
	if _animation == null:
		return
	_attack_left = _animation.get_animation(&"ataque_1").length
	_animation.play(&"ataque_1", 0.0)
	_animation.seek(0.0, true)


func _process(delta: float) -> void:
	if player == null or _animation == null:
		return
	_time += delta
	if _attack_left > 0.0:
		_attack_left -= delta
	else:
		var wanted: StringName = ANIMATIONS.get(player.state, &"quieto")
		if _animation.current_animation != wanted:
			_animation.play(wanted, BLEND)
		var speed := clampf(absf(player.velocity.x) / player.max_speed, 0.6, 1.3)
		_animation.speed_scale = speed if wanted == &"correr" else 1.0
	_update_secondary_motion(delta)


## Movimiento secundario por código: el mechón y la mochila reaccionan a la velocidad.
func _update_secondary_motion(delta: float) -> void:
	var run := clampf(absf(player.velocity.x) / player.max_speed, 0.0, 1.0)
	var vertical := clampf(player.velocity.y / 300.0, -1.0, 1.0)
	# Positivo = hacia atrás (el viento lo empuja al correr; al caer, el mechón se levanta).
	var lock_target := deg_to_rad(run * 35.0 + vertical * -25.0 + sin(_time * 9.0) * 4.0 * run)
	_lock.rotation = lerp_angle(_lock.rotation, lock_target, 1.0 - exp(-14.0 * delta))
	var bounce := sin(_time * 22.0) * 5.0 * run if player.is_on_floor() else vertical * -10.0
	var backpack_target := deg_to_rad(run * 8.0 + bounce)
	_backpack.rotation = lerp_angle(_backpack.rotation, backpack_target, 1.0 - exp(-12.0 * delta))
