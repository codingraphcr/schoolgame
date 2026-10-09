class_name KaiVisual
extends Node2D
## Apariencia de Kai: el esqueleto (kai_esqueleto.tscn) animado según el estado del jugador
## y dibujado a resolución de pixel art con PixelatedRig.
## Se coloca dentro de Visual/Body del jugador: así hereda el giro y la deformación de player.gd.
## El pelo, los mechones, el faldón y la mochila se mueven solos con resortes (movimiento secundario).

const SKELETON := preload("res://characters/player/kai/kai_esqueleto.tscn")
## Lienzo donde se dibuja Kai (deja espacio para brazos arriba, dash, pelo y el arma).
const CANVAS := Vector2i(84, 84)
## Punto del lienzo donde están los pies.
const FEET := Vector2i(42, 74)
const BLEND := 0.1
## Velocidad (px/s) a la que avanza la zancada de "correr" con la animación a velocidad normal.
const RUN_STRIDE_SPEED := 100.0

const ANIMATIONS := {
	Player.State.IDLE: &"quieto",
	Player.State.RUN: &"correr",
	Player.State.JUMP: &"saltar",
	Player.State.FALL: &"caer",
	Player.State.DASH: &"dash",
	Player.State.WALL_SLIDE: &"pared",
}

## Cómo reacciona cada pieza suelta. Ángulos en grados; positivo = hacia atrás.
## run: inclinación al correr · fall: al subir (−) o caer (+) · sway: balanceo al estar quieto
## stiffness/damping: resorte (menos amortiguación = rebota más).
const SPRINGS := {
	"PeloAtras": { "run": 28.0, "fall": -22.0, "sway": 3.0, "stiffness": 110.0, "damping": 9.0 },
	"MechonAtras": { "run": -30.0, "fall": 25.0, "sway": 5.0, "stiffness": 140.0, "damping": 8.0 },
	"MechonFrente": { "run": 35.0, "fall": -30.0, "sway": 4.0, "stiffness": 130.0, "damping": 8.0 },
	"Faldon": { "run": 30.0, "fall": -25.0, "sway": 2.0, "stiffness": 120.0, "damping": 10.0 },
	"Mochila": { "run": 8.0, "fall": -10.0, "sway": 1.0, "stiffness": 220.0, "damping": 16.0 },
}

## Si queda vacío, se usa el jugador dueño de la escena (como dentro de player.tscn).
@export var player: Player

var _animation: AnimationPlayer
var _springs: Array[Dictionary] = []
var _attack_left := 0.0
var _time := 0.0
var _last_velocity := Vector2.ZERO


func _ready() -> void:
	# Las estelas del dash duplican este nodo con todo su contenido: no se vuelve a construir.
	if get_child_count() > 0:
		return
	if player == null:
		player = owner as Player
	var skeleton := SKELETON.instantiate()
	var rig := PixelatedRig.new()
	rig.setup(skeleton, CANVAS, FEET, false)
	add_child(rig)
	_animation = skeleton.get_node("AnimationPlayer")
	for bone_name: String in SPRINGS:
		var bone := skeleton.get_node(KaiPiezas.bone_path(bone_name)) as Bone2D
		_springs.append({ "bone": bone, "config": SPRINGS[bone_name], "angle": 0.0, "speed": 0.0 })


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
		# La zancada avanza unos RUN_STRIDE_SPEED px/s a velocidad 1: así los pies no patinan.
		var speed := clampf(absf(player.velocity.x) / RUN_STRIDE_SPEED, 0.6, 1.6)
		_animation.speed_scale = speed if wanted == &"correr" else 1.0
	_update_springs(delta)


## Resortes amortiguados: cada pieza persigue su ángulo objetivo con inercia, se pasa un poco
## y vuelve. Al frenar de golpe, la aceleración la empuja hacia adelante.
func _update_springs(delta: float) -> void:
	var run := clampf(absf(player.velocity.x) / player.max_speed, 0.0, 1.0)
	var vertical := clampf(player.velocity.y / 300.0, -1.0, 1.0)
	var accel := (player.velocity - _last_velocity) / maxf(delta, 0.001)
	_last_velocity = player.velocity
	# Aceleración en la dirección en la que mira Kai (positiva = acelera hacia adelante).
	var forward_accel := clampf(accel.x * player.facing / 2000.0, -1.0, 1.0)
	var step := minf(delta, 1.0 / 30.0)
	for spring in _springs:
		var config: Dictionary = spring.config
		var target: float = config.run * run + config.fall * vertical + sin(_time * 2.2 + config.stiffness) * config.sway
		spring.speed += (config.stiffness * (target - spring.angle) - config.damping * spring.speed) * step
		spring.speed += forward_accel * config.run * 2.0 * step * 60.0
		spring.angle += spring.speed * step
		spring.angle = clampf(spring.angle, -70.0, 70.0)
		(spring.bone as Bone2D).rotation = deg_to_rad(spring.angle)
