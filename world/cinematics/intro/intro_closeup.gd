class_name IntroCloseup
extends Control
## Un primer plano de la cinemática inicial, como una viñeta de cómic que aparece sobre la escena: el despertador
## (time_text), el espejo con Kai y su mechón rebelde (cowlick: 0 = acomodado, 1 = levantado) o las medias
## diferentes. Dibujado por código (arte provisional); el retrato de Kai es el de los diálogos.

enum Kind { DESPERTADOR, ESPEJO, MEDIAS }

const PANEL_SIZE := Vector2(360, 210)
const PORTRAIT := preload("res://assets/art/characters/kai/retratos/kai_normal.png")
## El pelo de Kai (blanco lavanda, con contorno).
const HAIR := Color("e6def6")
const HAIR_LINE := Color("6e5ea0")

var kind := Kind.DESPERTADOR
var time_text := "6:00":
	set(value):
		time_text = value
		queue_redraw()
var ringing := false
var cowlick := 1.0:
	set(value):
		cowlick = value
		queue_redraw()

var _clock := 0.0


## Crea el primer plano (invisible) dentro de parent, centrado arriba de la caja de diálogo.
static func make(parent: Node, panel_kind: Kind) -> IntroCloseup:
	var panel := IntroCloseup.new()
	panel.kind = panel_kind
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.size = PANEL_SIZE
	panel.position = Vector2(-PANEL_SIZE.x / 2.0, 70)
	panel.pivot_offset = PANEL_SIZE / 2.0
	panel.scale = Vector2(0.6, 0.6)
	panel.modulate.a = 0.0
	parent.add_child(panel)
	return panel


func pop_in(seconds := 0.25) -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 1.0, seconds)
	tween.tween_property(self, "scale", Vector2.ONE, seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


func pop_out(seconds := 0.2) -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 0.0, seconds)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), seconds)
	await tween.finished
	queue_free()


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, PANEL_SIZE)
	draw_rect(rect.grow(4), Color("0a1124"))
	draw_rect(rect, Color("f4ecd8"))
	match kind:
		Kind.DESPERTADOR:
			_alarm(rect)
		Kind.ESPEJO:
			_mirror(rect)
		Kind.MEDIAS:
			_socks(rect)
	draw_rect(rect, Color("0a1124"), false, 3.0)


func _alarm(rect: Rect2) -> void:
	var shake := Vector2(sin(_clock * 70.0), cos(_clock * 53.0)) * 3.0 if ringing else Vector2.ZERO
	var c := rect.get_center() + shake
	draw_rect(Rect2(c - Vector2(110, 60), Vector2(220, 120)), Color("c83a3a"))
	draw_rect(Rect2(c - Vector2(96, 46), Vector2(192, 80)), Color("16161e"))
	draw_string(ThemeDB.fallback_font, c + Vector2(-96, 14), time_text, HORIZONTAL_ALIGNMENT_CENTER, 192, 56, Color("ff5a4a"))
	draw_string(ThemeDB.fallback_font, c + Vector2(-96, 50), "a. m.", HORIZONTAL_ALIGNMENT_CENTER, 192, 14, Color("f4ecd8"))
	for side in [-1.0, 1.0]:
		draw_circle(c + Vector2(side * 80, -66), 18.0, Color("e8c060"))
	if ringing:
		for k in 5:
			var a := -1.2 + k * 0.6
			var r := 128.0 + 8.0 * sin(_clock * 25.0 + k)
			var dir := Vector2(sin(a), -cos(a))
			draw_line(c + dir * r * Vector2(1.0, 0.7), c + dir * (r + 18.0) * Vector2(1.0, 0.7), Color("e0a020"), 4.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, 30), "¡RIIIIING!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("c83a3a"))


func _mirror(rect: Rect2) -> void:
	var frame := Rect2(rect.get_center() - Vector2(90, 96), Vector2(180, 192))
	draw_rect(frame, Color("c8a060"))
	draw_rect(frame.grow(-8), Color("cfe8f0"))
	var tex_size := Vector2(PORTRAIT.get_size())
	var scale_factor := minf((frame.size.y - 20.0) / tex_size.y, (frame.size.x - 20.0) / tex_size.x)
	var draw_size := tex_size * scale_factor
	var origin := Vector2(frame.get_center().x - draw_size.x / 2.0, frame.end.y - 8.0 - draw_size.y)
	draw_texture_rect(PORTRAIT, Rect2(origin, draw_size), false)
	# El mechón rebelde: sale de la coronilla y se levanta (con un resorte).
	var root := origin + Vector2(draw_size.x * 0.52, draw_size.y * 0.1)
	var wobble := sin(_clock * 14.0) * 0.12 * cowlick
	var angle := lerpf(1.25, -0.15, cowlick) + wobble
	var tip := root + Vector2(sin(angle), -cos(angle)) * 38.0
	var mid := root.lerp(tip, 0.5) + Vector2(-5, -2) * cowlick
	draw_polyline(PackedVector2Array([root, mid, tip]), HAIR_LINE, 10.0)
	draw_polyline(PackedVector2Array([root, mid, tip]), HAIR, 6.0)
	draw_line(Vector2(frame.position.x + 20, frame.position.y + 24), Vector2(frame.position.x + 50, frame.position.y + 60), Color(1, 1, 1, 0.5), 3.0)


func _socks(rect: Rect2) -> void:
	var floor_y := rect.end.y - 40.0
	draw_rect(Rect2(rect.position.x, floor_y, rect.size.x, 40), Color("c8a878"))
	var socks := [Color("e8e4d8"), Color("d84a8a")]
	for k in 2:
		var x := rect.get_center().x - 80.0 + k * 100.0
		draw_rect(Rect2(x, rect.position.y + 20, 44, floor_y - rect.position.y - 50), Color("2a3450"))
		draw_rect(Rect2(x, floor_y - 34, 44, 20), socks[k])
		if k == 1:
			for s in 3:
				draw_rect(Rect2(x + 6 + s * 13, floor_y - 30, 6, 6), Color("f0d060"))
		draw_rect(Rect2(x - 4, floor_y - 14, 70, 14), Color("1a1a22"))
		draw_rect(Rect2(x - 4, floor_y - 3, 70, 3), Color("e8e4d8"))
