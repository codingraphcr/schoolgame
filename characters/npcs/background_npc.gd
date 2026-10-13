class_name BackgroundNpc
extends Node2D
## NPC de fondo (hoja de Ariel docs/arte/referencias/npcs_fondo_concepto.webp): no se habla con él ni
## choca con nada; solo le da vida al colegio. Sprites en assets/art/characters/npcs_fondo/ (salen de
## tools/art/extraer_personajes_concepto.gd -- npcs_fondo). Se pone en la sala antes que Player
## (queda detrás de Kai), con los pies en el suelo.
##
## character: m1-m3 y f1-f3 (estudiantes), pm / pf (profesor y profesora), cj (conserje), x1-x3 y
## v1-v21 (variantes de un solo cuadro: solo están quietas, aunque se les pida otra cosa).
## mode:
##   QUIETO  : parado; respira y de vez en cuando mira para el otro lado.
##   CAMINAR : va y viene entre walk_left y walk_right (desde donde empieza), con pausas en las puntas.
##   CHARLAR : conversa con partner (otro BackgroundNpc con el mismo chat_offset): por turnos, el que
##             habla gesticula y le sale un globito; el otro asiente. talks_first: quién empieza.
##   BARRER  : el conserje camina despacio de un lado a otro con el trapeador y levanta un poco de polvo.
##   ESPALDA : de espaldas (en un casillero, mirando un cartel).

enum Mode { QUIETO, CAMINAR, CHARLAR, BARRER, ESPALDA }

const DIR := "res://assets/art/characters/npcs_fondo/"
const WALK_SPEED := 22.0
const SWEEP_SPEED := 9.0
## Duración de una vuelta de la charla: habla uno, silencio, habla el otro, silencio.
const CHAT_CYCLE := 6.0
const CHAT_TURN := 2.4
const BUBBLE_TEXTS: Array[String] = ["...", "!", "?", "jaja", "...", "!!", "?!"]
const BUBBLE := Color("e9e6f5")
const BUBBLE_TEXT := Color("2a2440")
const DUST: Array[Color] = [Color("8a8fa8"), Color("5b6080"), Color("b5b9cc")]
## Un poco más apagados que Kai: son el fondo.
const TINT := Color(0.85, 0.85, 0.92)

@export var character := "m1"
@export var mode := Mode.QUIETO
## 1 = mira a la derecha, -1 = a la izquierda (al charlar mira solo hacia partner).
@export var facing := 1
@export var walk_left := -80.0
@export var walk_right := 80.0
@export var partner: NodePath
@export var talks_first := true
## Desfase de la charla (la pareja usa el mismo, así se turnan).
@export var chat_offset := 0.0

## Las animaciones de todos los NPC de fondo (se arman una sola vez).
static var _shared: SpriteFrames

var _sprite: AnimatedSprite2D
var _bubble: VectorCanvas
var _home := Vector2.ZERO
var _time := 0.0
var _timer := 0.0
var _pause := 0.0
var _dust_left := 0.0


func _ready() -> void:
	_home = position
	_time = randf() * 10.0
	_timer = randf_range(3.0, 8.0)
	_sprite = AnimatedSprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.sprite_frames = _frames()
	_sprite.scale = Vector2(0.5, 0.5)
	_sprite.offset = Vector2(0, -55)
	_sprite.modulate = TINT
	add_child(_sprite)
	_bubble = VectorCanvas.new()
	_bubble.painter = _paint_bubble
	_bubble.animated = true
	_bubble.position = Vector2(0, -_head_height())
	add_child(_bubble)
	if mode == Mode.CHARLAR and has_node(partner):
		var other := get_node(partner) as Node2D
		facing = 1 if other.global_position.x >= global_position.x else -1
	_play(&"quieto")


func _process(delta: float) -> void:
	_time += delta
	match mode:
		Mode.QUIETO:
			_play(&"quieto")
			_breathe()
			_timer -= delta
			if _timer <= 0.0:
				facing = -facing
				_timer = randf_range(4.0, 9.0)
		Mode.CAMINAR:
			_walk(delta, WALK_SPEED, walk_left, walk_right, &"caminar", Vector2(1.0, 3.0))
		Mode.BARRER:
			if _walk(delta, SWEEP_SPEED, walk_left, walk_right, &"caminar", Vector2(1.5, 3.0)):
				_dust_left -= delta
				if _dust_left <= 0.0:
					_dust_left = randf_range(0.5, 0.9)
					PixelBurst.spawn(get_parent(), global_position + Vector2(facing * 20.0, -1.0), DUST, 3, 16.0, Vector2.ZERO, 0.5)
		Mode.ESPALDA:
			_play(&"espalda")
			_breathe()
		Mode.CHARLAR:
			_play(&"quieto")
			if is_talking():
				# Gesticula: rebota un poquito mientras habla.
				_sprite.position.y = -1.0 if sin(_time * 9.0) > 0.2 else 0.0
			else:
				# Escucha y asiente de vez en cuando.
				_sprite.position.y = 1.0 if fmod(_time, 1.3) < 0.15 else 0.0
	_sprite.flip_h = facing < 0


## True mientras este NPC tiene el turno de hablar en la charla.
func is_talking() -> bool:
	if mode != Mode.CHARLAR:
		return false
	var t := fposmod(_chat_clock(), CHAT_CYCLE)
	var first := t < CHAT_TURN
	var second := t >= CHAT_CYCLE * 0.5 and t < CHAT_CYCLE * 0.5 + CHAT_TURN
	return first if talks_first else second


func _chat_clock() -> float:
	return Time.get_ticks_msec() / 1000.0 + chat_offset


## Va y viene entre las puntas (con pausas en cada una). Devuelve true mientras se mueve.
func _walk(delta: float, speed: float, left: float, right: float, anim: StringName, pause_range: Vector2) -> bool:
	if _pause > 0.0:
		_pause -= delta
		_play(&"quieto")
		_breathe()
		return false
	_play(anim)
	# Rebote del paso: un píxel arriba en los cuadros de en medio.
	_sprite.position.y = -1.0 if _sprite.frame % 2 == 1 else 0.0
	position.x += facing * speed * delta
	var offset := position.x - _home.x
	if (facing > 0 and offset >= right) or (facing < 0 and offset <= left):
		position.x = _home.x + clampf(offset, left, right)
		facing = -facing
		_pause = randf_range(pause_range.x, pause_range.y)
	return true


## Respira: sube un píxel un rato y baja.
func _breathe() -> void:
	_sprite.position.y = -1.0 if sin(_time * 2.4) > 0.6 else 0.0


## Reproduce <personaje>_<animación>; si este personaje no la tiene (las variantes de un cuadro),
## se queda quieto.
func _play(anim: StringName) -> void:
	var full := StringName(character + "_" + String(anim))
	if not _sprite.sprite_frames.has_animation(full):
		full = StringName(character + "_quieto")
	if _sprite.animation != full:
		_sprite.play(full)


## Alto de la cabeza (dónde va el globito): los adultos son más altos.
func _head_height() -> float:
	return 62.0 if character in ["pm", "pf", "cj"] else 54.0


func _paint_bubble(c: VectorCanvas, _t: float) -> void:
	if not is_talking():
		return
	var turn := int(floor(_chat_clock() / CHAT_CYCLE)) * 2 + (0 if talks_first else 1)
	var text: String = BUBBLE_TEXTS[posmod(turn * 5, BUBBLE_TEXTS.size())]
	# Los puntos suspensivos aparecen de a uno.
	if text == "...":
		text = ".".repeat(1 + int(fposmod(_chat_clock(), CHAT_CYCLE * 0.5) / 0.4) % 3)
	var width := maxf(text.length() * 4.0 + 6.0, 12.0)
	var rect := Rect2(Vector2(facing * 4.0 - width / 2.0, -9.0), Vector2(width, 9.0))
	c.draw_rect(rect.grow(1.0), BUBBLE_TEXT)
	c.draw_rect(rect, BUBBLE)
	# Colita hacia la boca.
	var tail := Vector2(facing * 1.0, 0.0)
	c.draw_colored_polygon(PackedVector2Array([tail + Vector2(-2, -0.5), tail + Vector2(2, -0.5), tail + Vector2(-facing * 1.0, 3)]), BUBBLE)
	c.crisp_text(Vector2(rect.position.x, -2.0), text, 5, BUBBLE_TEXT, HORIZONTAL_ALIGNMENT_CENTER, width)


## Arma (una vez) las animaciones de npc.json: cada tira se corta en sus cuadros.
static func _frames() -> SpriteFrames:
	if _shared != null:
		return _shared
	_shared = SpriteFrames.new()
	_shared.remove_animation(&"default")
	var file := FileAccess.open(DIR + "npc.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text()) if file else {}
	var animations: Dictionary = data.get("animations", {})
	for anim_name: String in animations:
		var info: Dictionary = animations[anim_name]
		var texture: Texture2D = load(DIR + String(info.file))
		var size := Vector2(info.frame_size[0], info.frame_size[1])
		_shared.add_animation(anim_name)
		_shared.set_animation_speed(anim_name, float(info.fps))
		_shared.set_animation_loop(anim_name, bool(info.loop))
		for i in int(info.frames):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(Vector2(i * size.x, 0), size)
			_shared.add_frame(anim_name, atlas)
	return _shared
