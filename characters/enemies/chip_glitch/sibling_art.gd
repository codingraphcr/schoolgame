class_name SiblingArt
extends RefCounted
## Dibujo de Glitch y Chip con los sprites de la hoja de Ariel (docs/arte/referencias/glitch_chip_concepto.webp
## → tools/art/extraer_personajes_concepto.gd -- hermanos → assets/art/characters/hermanos/hd/).
## Lo usan el jefe (GlitchBoss / ChipBoss) y los personajes de las escenas (SiblingActor). Los pies en
## el origen; el movimiento (inclinarse, estirarse, temblar) lo da el código.

const GLITCH := Color("ff4fb4")
const GLITCH_LIGHT := Color("ffb3df")
const CHIP := Color("4fa8ff")
const CHIP_LIGHT := Color("b8dcff")
const ANGRY := Color(1, 0.3, 0.45)
const DIR := "res://assets/art/characters/hermanos/hd/"
## Los cuadros son de 96×128 con los pies en (48, 119); se ven a mitad de escala, como Kai.
const FEET := Vector2(48, 119)
const SCALE := 0.5
## Zona del cuerpo (en el mundo, con los pies en el origen).
const BODY := Rect2(-12, -46, 24, 46)

static var _textures: Dictionary[StringName, Texture2D] = {}
static var _disc_rect := Rect2()


static func texture(kind: StringName) -> Texture2D:
	if not _textures.has(kind):
		_textures[kind] = load(DIR + "hermanos_hd_%s.png" % kind)
	return _textures[kind]


## Dibuja a Glitch (&"glitch") o a Chip (&"chip"). face: 1 mira a la derecha, −1 a la izquierda.
## Opciones: lean (inclinación en radianes), squash (Vector2), dizzy (mareado), enraged (furia),
## shielded (escudo de discos de Chip), alpha, tint, offset.
static func draw_twin(ci: CanvasItem, kind: StringName, clock: float, face := 1.0, options := {}) -> Rect2:
	var color := GLITCH if kind == &"glitch" else CHIP
	var lean: float = options.get("lean", 0.0)
	var squash: Vector2 = options.get("squash", Vector2.ONE)
	var dizzy: bool = options.get("dizzy", false)
	var alpha: float = options.get("alpha", 1.0)
	var offset: Vector2 = options.get("offset", Vector2.ZERO)
	var tint: Color = options.get("tint", Color.WHITE)
	if dizzy:
		lean = 0.32 * face
		offset += Vector2(0, 2)
	# Glitch tiembla de vez en cuando (es una falla con patas).
	if kind == &"glitch" and not dizzy and (int(clock * 7.0) % 6 == 0 or options.get("enraged", false)):
		offset.x += sin(clock * 50.0) * 1.0
	if options.get("enraged", false):
		ci.draw_circle(offset + Vector2(0, -24), 26.0, Color(ANGRY, 0.12 + 0.06 * sin(clock * 8.0)))
	ci.draw_set_transform(offset, lean, Vector2(SCALE * face * squash.x, SCALE * squash.y))
	ci.draw_texture(texture(kind), -FEET, Color(tint, alpha))
	ci.draw_set_transform(Vector2.ZERO)
	if options.get("shielded", false):
		var center := offset + Vector2(face * 14.0, -24)
		ci.draw_circle(center, 22.0, Color(CHIP, 0.16 + 0.06 * sin(clock * 6.0)))
		ci.draw_arc(center, 22.0, 0.0, TAU, 28, Color(CHIP_LIGHT, 0.9), 1.5)
		ci.draw_arc(center, 15.0, clock * 3.0, clock * 3.0 + PI * 1.3, 16, Color(CHIP, 0.8), 1.0)
	if dizzy:
		draw_dizzy(ci, clock, offset + Vector2(0, -50))
	return Rect2(BODY.position + offset, BODY.size)


## Compatibilidad (escenas del Capítulo 1): Chip mirando hacia look.
static func draw_chip(ci: CanvasItem, clock: float, look: Vector2, enraged := false, shielded := false, dizzy := false) -> void:
	draw_twin(ci, &"chip", clock, 1.0 if look.x >= 0.0 else -1.0, { "enraged": enraged, "shielded": shielded, "dizzy": dizzy })


## Compatibilidad (escenas del Capítulo 1): Glitch mirando hacia face.
static func draw_glitch(ci: CanvasItem, clock: float, face := 1.0, crouch := false, enraged := false, dizzy := false) -> Rect2:
	return draw_twin(ci, &"glitch", clock, face, { "squash": Vector2(1.08, 0.9) if crouch else Vector2.ONE, "enraged": enraged, "dizzy": dizzy })


## El disco de Chip (centrado en el origen), girando.
static func draw_disc(ci: CanvasItem, angle: float, radius := 10.0, alpha := 1.0) -> void:
	var tex := texture(&"disco")
	if _disc_rect.size == Vector2.ZERO:
		_disc_rect = Rect2(tex.get_image().get_used_rect())
	var s := radius * 2.0 / maxf(_disc_rect.size.x, _disc_rect.size.y)
	ci.draw_set_transform(Vector2.ZERO, angle, Vector2(s, s))
	ci.draw_texture_rect_region(tex, Rect2(-_disc_rect.size / 2.0, _disc_rect.size), _disc_rect, Color(1, 1, 1, alpha))
	ci.draw_set_transform(Vector2.ZERO)


## Estrellitas de mareo (aturdido o neutralizado).
static func draw_dizzy(ci: CanvasItem, clock: float, center: Vector2) -> void:
	for k in 3:
		var angle := clock * 3.0 + k * TAU / 3.0
		ci.draw_circle(center + Vector2(cos(angle) * 10.0, sin(angle) * 3.0), 1.6, Color(1, 0.95, 0.5))
