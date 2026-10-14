class_name SiblingArt
extends RefCounted
## Dibujo provisional de Chip y Glitch (por código, hasta que Ariel los dibuje). Lo usan el jefe
## (ChipBoss / GlitchBoss) y los personajes de las escenas (SiblingActor). Los pies en el origen.

const CHIP := Color("5ad8ff")
const CHIP_DARK := Color("0d2238")
const GLITCH := Color("ff8a3a")
const GLITCH_DARK := Color("2a1408")
const ANGRY := Color(1, 0.4, 0.5)


## Chip: un cubito cian con un ojo grande y una antena. look: hacia dónde mira (unitario).
static func draw_chip(ci: CanvasItem, clock: float, look: Vector2, enraged := false, shielded := false, dizzy := false) -> void:
	var center := Vector2(0, -10)
	if dizzy:
		ci.draw_rect(Rect2(-10, -14, 20, 14), CHIP_DARK)
		ci.draw_rect(Rect2(-10, -14, 20, 14), Color(CHIP, 0.6), false, 1.0)
		draw_dizzy(ci, clock, Vector2(0, -20))
		return
	if shielded:
		ci.draw_circle(center, 20.0, Color(CHIP, 0.18 + 0.08 * sin(clock * 6.0)))
		ci.draw_arc(center, 20.0, 0.0, TAU, 24, Color(CHIP, 0.9), 1.5)
	var body := Rect2(-10, -20, 20, 20)
	ci.draw_rect(body, CHIP_DARK)
	ci.draw_rect(body, Color(CHIP, 0.9), false, 1.5)
	ci.draw_circle(center + Vector2(0, -1), 5.5, Color(0.9, 1, 1))
	ci.draw_circle(center + Vector2(0, -1) + look * 2.0, 2.4, ANGRY if enraged else Color(0.05, 0.1, 0.2))
	ci.draw_line(Vector2(4, -20), Vector2(7, -28), CHIP, 1.0)
	ci.draw_circle(Vector2(7, -29), 1.6, ANGRY if enraged else CHIP)
	for x in [-6.0, 6.0]:
		ci.draw_line(Vector2(x, 0), Vector2(x + sin(clock * 8.0 + x) * 1.5, 4), Color(CHIP, 0.7), 1.0)


## Glitch: una criatura naranja con púas que tiembla como una imagen con fallas. face: 1 o −1.
static func draw_glitch(ci: CanvasItem, clock: float, face := 1.0, crouch := false, enraged := false, dizzy := false) -> Rect2:
	var jitter := Vector2(sin(clock * 40.0) * 1.5, 0) if (int(clock * 7.0) % 5 == 0 or enraged) else Vector2.ZERO
	if dizzy:
		ci.draw_rect(Rect2(-11, -10, 22, 10), GLITCH_DARK)
		ci.draw_rect(Rect2(-11, -10, 22, 10), Color(GLITCH, 0.6), false, 1.0)
		draw_dizzy(ci, clock, Vector2(0, -16))
		return Rect2(-11, -10, 22, 10)
	var lowered := 4.0 if crouch else 0.0
	var body := Rect2(-11, -18 + lowered, 22, 18 - lowered)
	body.position += jitter
	ci.draw_rect(body, GLITCH_DARK)
	ci.draw_rect(body, Color(GLITCH, 0.95), false, 1.5)
	for k in 4:
		var x := body.position.x + 3.0 + k * 5.5
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, body.position.y), Vector2(x + 2.5, body.position.y - 6), Vector2(x + 5, body.position.y)]), GLITCH)
	for eye in [-3.0, 4.0]:
		ci.draw_rect(Rect2(body.get_center() + Vector2(eye + face * 2.0, -4), Vector2(3, 4)), Color(1, 1, 0.9))
	if jitter != Vector2.ZERO:
		ci.draw_rect(Rect2(body.position.x - 4, body.get_center().y, body.size.x + 8, 2), Color(GLITCH, 0.5))
	return body


## Estrellitas de mareo (neutralizado).
static func draw_dizzy(ci: CanvasItem, clock: float, center: Vector2) -> void:
	for k in 3:
		var angle := clock * 3.0 + k * TAU / 3.0
		ci.draw_circle(center + Vector2(cos(angle) * 10.0, sin(angle) * 3.0), 1.6, Color(1, 0.95, 0.5))
