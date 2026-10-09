class_name KaiVisual
extends Node2D
## Apariencia de Kai según el estado del jugador. Se coloca dentro de Visual/Body del jugador:
## así hereda el giro y la deformación de player.gd.
##
## Tres apariencias:
##   CONCEPTO: sprites de la hoja de concepto de Ariel (assets/art/characters/kai/hd/, 96 px de alto
##             mostrados a mitad de escala: con la cámara ×2, un píxel del dibujo = un píxel de pantalla).
##   HUESOS:   el esqueleto (kai_esqueleto.tscn) dibujado como pixel art, con resortes en pelo y ropa.
##   CUADROS:  tiras exportadas desde el esqueleto para retocar a mano (assets/art/characters/kai/cuadros/).

enum Apariencia { CONCEPTO, HUESOS, CUADROS }

const SKELETON := preload("res://characters/player/kai/kai_esqueleto.tscn")
## Lienzo donde se dibuja Kai con huesos (deja espacio para brazos arriba, dash, pelo y el arma).
const CANVAS := Vector2i(84, 84)
## Punto del lienzo donde están los pies.
const FEET := Vector2i(42, 74)
const BLEND := 0.1
## Velocidad (px/s) a la que avanza la zancada de "correr" con la animación a velocidad normal.
const RUN_STRIDE_SPEED := 100.0

## Carpeta y archivo de descripción de cada apariencia por cuadros.
const FRAME_SETS := {
	Apariencia.CONCEPTO: ["res://assets/art/characters/kai/hd/", "kai_hd.json"],
	Apariencia.CUADROS: ["res://assets/art/characters/kai/cuadros/", "kai_cuadros.json"],
}
## Cuánto dura cada golpe del combo y el margen para encadenar el segundo.
const ATTACK_TIME := 0.3
const COMBO_WINDOW := 0.45
const HURT_TIME := 0.35
const DEATH_TIME := 1.2
## Rebote al correr con la apariencia por cuadros (en píxeles del dibujo).
const RUN_BOB := 2.0

const ANIMATIONS := {
	Player.State.IDLE: &"quieto",
	Player.State.RUN: &"correr",
	Player.State.JUMP: &"saltar",
	Player.State.FALL: &"caer",
	Player.State.DASH: &"dash",
	Player.State.WALL_SLIDE: &"pared",
}

## Cómo reacciona cada pieza suelta del esqueleto. Ángulos en grados; positivo = hacia atrás.
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
@export var apariencia := Apariencia.CONCEPTO

var _animation: AnimationPlayer
var _sprite: AnimatedSprite2D
var _sprite_offsets := {}
var _springs: Array[Dictionary] = []
## Animación que tiene prioridad sobre el movimiento (ataque, daño, muerte) y cuánto le queda.
var _override := &""
var _override_left := 0.0
var _combo_left := 0.0
## Animación que sigue cuando termina la actual (preparación → tajo) y cuánto dura.
var _next_override := &""
var _next_left := 0.0
var _time := 0.0
var _last_velocity := Vector2.ZERO


func _ready() -> void:
	# Las estelas del dash duplican este nodo con todo su contenido: no se vuelve a construir.
	if get_child_count() > 0:
		return
	if player == null:
		player = owner as Player
	if player and player.has_node("Damage"):
		var damage := player.get_node("Damage") as PlayerDamage
		damage.hurt.connect(func(_hit: HitData) -> void: _play_override(&"dano", HURT_TIME))
		damage.died.connect(func() -> void: _play_override(&"muerte", DEATH_TIME))
	if FRAME_SETS.has(apariencia) and _build_frames(FRAME_SETS[apariencia][0], FRAME_SETS[apariencia][1]):
		return
	_build_skeleton()


## Nombre de la animación que se ve ahora (sirve para las pruebas automáticas).
func current_animation() -> StringName:
	if _sprite:
		return _sprite.animation
	if _animation:
		return _animation.current_animation
	return &""


## Ataque con el Nullblade. Si se vuelve a atacar enseguida, encadena el segundo golpe.
## Con windup y la hoja de concepto (un cuadro por pose), cada ataque muestra la preparación
## (ataque_1) durante windup y luego el tajo (ataque_2), justo cuando el golpe hace daño.
func attack(windup := 0.0) -> void:
	if _sprite and windup > 0.0 and _has_animation(&"ataque_1") and _has_animation(&"ataque_2"):
		_play_override(&"ataque_1", windup)
		_next_override = &"ataque_2"
		_next_left = maxf(ATTACK_TIME - windup, 0.05)
		return
	var second := _combo_left > 0.0 and _override == &"ataque_1"
	_play_override(&"ataque_2" if second and _has_animation(&"ataque_2") else &"ataque_1", ATTACK_TIME)
	_combo_left = 0.0 if second else COMBO_WINDOW


func _process(delta: float) -> void:
	if player == null or (_animation == null and _sprite == null):
		return
	_time += delta
	_combo_left = maxf(_combo_left - delta, 0.0)
	if _override_left > 0.0:
		_override_left -= delta
		if _override_left <= 0.0:
			_override = &""
			if _next_override != &"":
				_play_override(_next_override, _next_left)
	if _override == &"":
		_play_state_animation()
	if _sprite:
		_update_sprite_motion()
	else:
		_update_springs(delta)


func _play_state_animation() -> void:
	var wanted: StringName = ANIMATIONS.get(player.state, &"quieto")
	if _sprite:
		if _sprite.animation != wanted or not _sprite.is_playing():
			_play_sprite(wanted)
		var ratio := clampf(absf(player.velocity.x) / player.max_speed, 0.5, 1.2)
		_sprite.speed_scale = ratio if wanted == &"correr" else 1.0
		return
	if _animation.current_animation != wanted:
		_animation.play(wanted, BLEND)
	# La zancada avanza unos RUN_STRIDE_SPEED px/s a velocidad 1: así los pies no patinan.
	var speed := clampf(absf(player.velocity.x) / RUN_STRIDE_SPEED, 0.6, 1.6)
	_animation.speed_scale = speed if wanted == &"correr" else 1.0


func _play_override(anim: StringName, duration: float) -> void:
	_next_override = &""
	if not _has_animation(anim):
		return
	_override = anim
	_override_left = duration
	if _sprite:
		_play_sprite(anim)
		_sprite.frame = 0
	elif _animation:
		_animation.play(anim, 0.0)
		_animation.seek(0.0, true)


func _has_animation(anim: StringName) -> bool:
	if _sprite:
		return _sprite.sprite_frames.has_animation(anim)
	return _animation != null and _animation.has_animation(anim)


# --- Apariencia por cuadros (CONCEPTO y CUADROS) ---

## Crea un AnimatedSprite2D con las tiras descritas en el JSON. Devuelve false si no existen.
func _build_frames(directory: String, json_name: String) -> bool:
	var file := FileAccess.open(directory + json_name, FileAccess.READ)
	if file == null:
		push_warning("KaiVisual: no hay cuadros en %s; se usa el esqueleto." % directory)
		return false
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim_name: String in data.animations:
		var info: Dictionary = data.animations[anim_name]
		var texture: Texture2D = load(directory + info.get("file", "kai_%s.png" % anim_name))
		if texture == null:
			continue
		var size_values: Array = info.get("frame_size", data.get("frame_size"))
		var feet_values: Array = info.get("feet", data.get("feet"))
		var size := Vector2(size_values[0], size_values[1])
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, info.fps)
		frames.set_animation_loop(anim_name, info.loop)
		for i in int(info.frames):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * size.x, 0, size.x, size.y)
			frames.add_frame(anim_name, atlas)
		# Los pies quedan en el origen del jugador.
		_sprite_offsets[StringName(anim_name)] = size * 0.5 - Vector2(feet_values[0], feet_values[1])
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE * float(data.get("scale", 1.0))
	add_child(_sprite)
	_play_sprite(&"quieto")
	return true


func _play_sprite(anim: StringName) -> void:
	if not _sprite.sprite_frames.has_animation(anim):
		anim = &"quieto"
	_sprite.play(anim)
	_sprite.offset = _sprite_offsets.get(anim, Vector2.ZERO)


## Con pocos cuadros, un rebote suave al correr hace que el movimiento no se vea tieso.
func _update_sprite_motion() -> void:
	var base: Vector2 = _sprite_offsets.get(_sprite.animation, Vector2.ZERO)
	var bob := 0.0
	if _sprite.animation == &"correr" and player.is_on_floor():
		var rate := 18.0 * clampf(absf(player.velocity.x) / player.max_speed, 0.5, 1.2)
		bob = -absf(sin(_time * rate)) * RUN_BOB
	_sprite.offset = base + Vector2(0, roundf(bob))


# --- Apariencia por huesos ---

func _build_skeleton() -> void:
	var skeleton := SKELETON.instantiate()
	var rig := PixelatedRig.new()
	rig.setup(skeleton, CANVAS, FEET, false)
	add_child(rig)
	_animation = skeleton.get_node("AnimationPlayer")
	for bone_name: String in SPRINGS:
		var bone := skeleton.get_node(KaiPiezas.bone_path(bone_name)) as Bone2D
		_springs.append({ "bone": bone, "config": SPRINGS[bone_name], "angle": 0.0, "speed": 0.0 })


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
