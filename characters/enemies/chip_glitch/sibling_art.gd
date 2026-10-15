class_name SiblingArt
extends RefCounted
## Dibujo de Glitch y Chip con los sprites en pixel art del diseño nuevo de Ariel
## (docs/arte/referencias/glitch_chip_v2.webp → tools/art/extraer_personajes_concepto.gd -- hermanos_juego
## → assets/art/characters/hermanos/hd/hermanos_px_*). Animaciones de los dos: quieto, caminar, correr, saltar,
## aire, caer y aturdido. Los ataques, cuadro por cuadro, salen de las hojas de ataques de Ariel (glitch_ataques y
## chip_ataques → hermanos_glitch_* / hermanos_chip_*): por ataque, <ataque>_aviso, la acción y <ataque>_fin.
## Lo usan el jefe (GlitchBoss / ChipBoss) y los personajes de las escenas (SiblingActor). Los pies en
## el origen; el movimiento (inclinarse, estirarse, temblar) lo da el código.

const GLITCH := Color("ff454f")
const GLITCH_LIGHT := Color("ffb3a7")
const CHIP := Color("4fa8ff")
const CHIP_LIGHT := Color("b8dcff")
const ANGRY := Color(1, 0.3, 0.45)
const DIR := "res://assets/art/characters/hermanos/hd/"
## Los cuadros se ven a mitad de escala, como Kai.
const SCALE := 0.5
## Zona del cuerpo (en el mundo, con los pies en el origen).
const BODY := Rect2(-9, -32, 18, 32)
## Las animaciones (salen de la hoja de sprites).
const SHEETS: Array[String] = ["hermanos_px.json", "hermanos_glitch.json", "hermanos_chip.json"]
## Poses dibujadas mirando a la izquierda (el resto mira a la derecha).
const FACING_LEFT: Array[StringName] = []

static var _poses: Dictionary = {}
static var _disc: Texture2D
static var _disc_rect := Rect2()


## Datos de una pose (&"glitch_corte", …): textura, tamaño de cuadro, pies, cuadros y velocidad.
static func pose_info(name: StringName) -> Dictionary:
	if _poses.is_empty():
		for json: String in SHEETS:
			var file := FileAccess.open(DIR + json, FileAccess.READ)
			var data: Dictionary = JSON.parse_string(file.get_as_text()) if file else {}
			for anim: String in data.get("animations", {}):
				var info: Dictionary = data.animations[anim]
				_poses[StringName(anim)] = {
					"texture": load(DIR + String(info.file)), "size": Vector2(info.frame_size[0], info.frame_size[1]),
					"feet": Vector2(info.feet[0], info.feet[1]), "frames": int(info.frames), "fps": float(info.fps),
					"loop": bool(info.get("loop", true)),
				}
	return _poses.get(name, {})


## Si kind (&"glitch" / &"chip") tiene esa pose (p. ej. &"corte_aviso").
static func has_pose(kind: StringName, pose: StringName) -> bool:
	return not pose_info(StringName("%s_%s" % [kind, pose])).is_empty()


## La textura de una pose (para las pruebas y para quien la necesite).
static func texture(kind: StringName, pose := &"quieto") -> Texture2D:
	if kind == &"disco":
		return disc_texture()
	var info := pose_info(StringName("%s_%s" % [kind, pose]))
	return info.get("texture")


## Dibuja a Glitch (&"glitch") o a Chip (&"chip"). face: 1 mira a la derecha, −1 a la izquierda.
## Opciones: pose (&"quieto", &"caminar", &"correr", &"saltar", &"aire", &"caer", &"aturdido" y las de sus
## ataques), lean (inclinación en radianes), squash (Vector2), dizzy (mareado: la pose aturdido), enraged
## (furia), shielded (escudo de discos de Chip), alpha, tint, offset y anim_time (segundos desde que empezó la
## pose; sin él, el reloj).
static func draw_twin(ci: CanvasItem, kind: StringName, clock: float, face := 1.0, options := {}) -> Rect2:
	var pose: StringName = options.get("pose", &"quieto")
	# Mareado: su animación de aturdido (tirado en el piso, con estrellitas).
	var dizzy: bool = options.get("dizzy", false)
	if dizzy:
		pose = &"aturdido"
	var name := StringName("%s_%s" % [kind, pose])
	var info := pose_info(name)
	if info.is_empty():
		name = StringName("%s_quieto" % kind)
		info = pose_info(name)
	var lean: float = options.get("lean", 0.0)
	var squash: Vector2 = options.get("squash", Vector2.ONE)
	var alpha: float = options.get("alpha", 1.0)
	var offset: Vector2 = options.get("offset", Vector2.ZERO)
	var tint: Color = options.get("tint", Color.WHITE)
	# Glitch tiembla de vez en cuando (es una falla con patas).
	if kind == &"glitch" and not dizzy and (int(clock * 7.0) % 6 == 0 or options.get("enraged", false)):
		offset.x += sin(clock * 50.0) * 1.0
	if options.get("enraged", false):
		ci.draw_circle(offset + Vector2(0, -16), 20.0, Color(ANGRY, 0.12 + 0.06 * sin(clock * 8.0)))
	if not info.is_empty():
		var size: Vector2 = info.size
		# anim_time: segundos desde que empezó la pose (las de ataque no se repiten: quedan en el último cuadro).
		var time: float = options.get("anim_time", clock)
		var frame := int(time * float(info.fps))
		frame = (frame % int(info.frames)) if info.loop else mini(frame, int(info.frames) - 1)
		var flip := face * (-1.0 if name in FACING_LEFT else 1.0)
		ci.draw_set_transform(offset, lean, Vector2(SCALE * flip * squash.x, SCALE * squash.y))
		ci.draw_texture_rect_region(info.texture, Rect2(-info.feet, size), Rect2(Vector2(frame * size.x, 0), size), Color(tint, alpha))
		ci.draw_set_transform(Vector2.ZERO)
	if options.get("shielded", false):
		var center := offset + Vector2(face * 11.0, -16)
		ci.draw_circle(center, 17.0, Color(CHIP, 0.16 + 0.06 * sin(clock * 6.0)))
		ci.draw_arc(center, 17.0, 0.0, TAU, 28, Color(CHIP_LIGHT, 0.9), 1.5)
		ci.draw_arc(center, 11.0, clock * 3.0, clock * 3.0 + PI * 1.3, 16, Color(CHIP, 0.8), 1.0)
	return Rect2(BODY.position + offset, BODY.size)


## Compatibilidad (escenas del Capítulo 1): Chip mirando hacia look.
static func draw_chip(ci: CanvasItem, clock: float, look: Vector2, enraged := false, shielded := false, dizzy := false) -> void:
	draw_twin(ci, &"chip", clock, 1.0 if look.x >= 0.0 else -1.0, { "enraged": enraged, "shielded": shielded, "dizzy": dizzy })


## Compatibilidad (escenas del Capítulo 1): Glitch mirando hacia face.
static func draw_glitch(ci: CanvasItem, clock: float, face := 1.0, crouch := false, enraged := false, dizzy := false) -> Rect2:
	return draw_twin(ci, &"glitch", clock, face, { "pose": &"guardia" if crouch else &"quieto", "enraged": enraged, "dizzy": dizzy })


static func disc_texture() -> Texture2D:
	if _disc == null:
		_disc = load(DIR + "hermanos_hd_disco.png")
		_disc_rect = Rect2(_disc.get_image().get_used_rect())
	return _disc


## El disco de Chip (centrado en el origen), girando.
static func draw_disc(ci: CanvasItem, angle: float, radius := 10.0, alpha := 1.0) -> void:
	var tex := disc_texture()
	var s := radius * 2.0 / maxf(_disc_rect.size.x, _disc_rect.size.y)
	ci.draw_set_transform(Vector2.ZERO, angle, Vector2(s, s))
	ci.draw_texture_rect_region(tex, Rect2(-_disc_rect.size / 2.0, _disc_rect.size), _disc_rect, Color(1, 1, 1, alpha))
	ci.draw_set_transform(Vector2.ZERO)

