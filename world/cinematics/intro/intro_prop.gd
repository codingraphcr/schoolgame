@tool
class_name IntroProp
extends Node2D
## Piezas de la cinemática inicial dibujadas por código (arte provisional, hasta que Ariel las dibuje), en el estilo
## del cuarto, la casa y la calle de Kai. Cada una es un kind; la cinemática cambia su estado (la hora del
## despertador, si suena, si el perro ladra...). El origen es el piso, al centro de la pieza (el bus: sus ruedas).

enum Kind { DESPERTADOR, MOCHILA, ESPEJO, CUADERNO, DESAYUNO, LONCHERA, VERJA_PERRO, MURO_GATO, BUS }

const INK := Color("2a2230")
const WOOD := Color("8a5a3a")
const WOOD_DARK := Color("5e3c26")

@export var kind := Kind.DESPERTADOR:
	set(value):
		kind = value
		queue_redraw()
## Lo que marca el despertador.
@export var time_text := "6:00":
	set(value):
		time_text = value
		queue_redraw()
## El despertador suena / el perro ladra (se sacude).
@export var active := false
## Color del cuaderno (o del bus).
@export var color := Color("d8504a")

var _clock := 0.0


func _process(delta: float) -> void:
	_clock += delta
	if active or kind in [Kind.MURO_GATO, Kind.VERJA_PERRO]:
		queue_redraw()


func _draw() -> void:
	match kind:
		Kind.DESPERTADOR:
			_alarm_clock()
		Kind.MOCHILA:
			_backpack()
		Kind.ESPEJO:
			_mirror()
		Kind.CUADERNO:
			draw_rect(Rect2(-9, -4, 18, 4), color)
			draw_rect(Rect2(-9, -4, 18, 1), color.lightened(0.3))
			draw_rect(Rect2(-9, -1, 18, 1), Color("f4f0e4"))
		Kind.DESAYUNO:
			_breakfast()
		Kind.LONCHERA:
			draw_rect(Rect2(-8, -10, 16, 10), Color("3a8adf"))
			draw_rect(Rect2(-8, -10, 16, 2), Color("6aaaf0"))
			draw_arc(Vector2(0, -10), 4.0, PI, TAU, 8, INK, 1.5)
		Kind.VERJA_PERRO:
			_fence_and_dog()
		Kind.MURO_GATO:
			_wall_and_cat()
		Kind.BUS:
			_bus()


func _shake() -> Vector2:
	return Vector2(sin(_clock * 60.0), cos(_clock * 47.0)) * 1.2 if active else Vector2.ZERO


func _alarm_clock() -> void:
	var o := _shake()
	# La mesita de noche y el reloj encima.
	draw_rect(Rect2(-14, -26, 28, 26), WOOD)
	draw_rect(Rect2(-14, -26, 28, 3), WOOD.lightened(0.15))
	draw_rect(Rect2(-12, -14, 24, 1), WOOD_DARK)
	draw_circle(Vector2(0, -8), 1.5, Color("e8c060"))
	draw_rect(Rect2(Vector2(-10, -40) + o, Vector2(20, 14)), Color("c83a3a"))
	draw_rect(Rect2(Vector2(-8, -38) + o, Vector2(16, 9)), Color("1a1a22"))
	draw_string(ThemeDB.fallback_font, Vector2(-8, -31) + o, time_text, HORIZONTAL_ALIGNMENT_CENTER, 16, 8, Color("ff6a5a"))
	draw_circle(Vector2(-7, -41) + o, 3.0, Color("e8c060"))
	draw_circle(Vector2(7, -41) + o, 3.0, Color("e8c060"))
	if active:
		for k in 3:
			var a := -0.9 + k * 0.9
			var r := 14.0 + 4.0 * sin(_clock * 20.0 + k)
			draw_line(Vector2(0, -36) + Vector2(sin(a), -cos(a)) * r, Vector2(0, -36) + Vector2(sin(a), -cos(a)) * (r + 5.0), Color("ffd166"), 1.5)


func _backpack() -> void:
	draw_rect(Rect2(-10, -18, 20, 18), Color("3a5a8a"))
	draw_rect(Rect2(-10, -18, 20, 4), Color("4a6ea6"))
	draw_rect(Rect2(-7, -9, 14, 7), Color("2e4a72"))
	draw_arc(Vector2(0, -18), 5.0, PI, TAU, 8, Color("2a3a5a"), 2.0)
	draw_circle(Vector2(6, -5), 1.5, Color("e8c060"))


func _mirror() -> void:
	# A la altura de la cara de Kai.
	draw_rect(Rect2(-16, -88, 32, 52), Color("c8a060"))
	draw_rect(Rect2(-13, -85, 26, 46), Color("bfe0ec"))
	draw_line(Vector2(-8, -78), Vector2(2, -63), Color(1, 1, 1, 0.6), 2.0)
	draw_line(Vector2(-3, -82), Vector2(6, -70), Color(1, 1, 1, 0.4), 1.0)


func _breakfast() -> void:
	# Gallo pinto, huevo y la taza de café (sobre la mesa del comedor: el origen es la superficie de la mesa).
	draw_circle(Vector2(-4, -2), 6.0, Color("f4f0e4"))
	draw_circle(Vector2(-6, -3), 3.0, Color("6a3a2a"))
	draw_circle(Vector2(-2, -3), 2.5, Color("fff8e8"))
	draw_circle(Vector2(-2, -3), 1.0, Color("f0b030"))
	draw_rect(Rect2(6, -8, 5, 7), Color("e8e4d8"))
	draw_rect(Rect2(6, -8, 5, 2), Color("5a3a2a"))


func _fence_and_dog() -> void:
	# Un muro bajo con verja de hierro; detrás, un perrito que ladra (salta) cuando active.
	var hop := absf(sin(_clock * 14.0)) * 6.0 if active else absf(sin(_clock * 2.0)) * 0.6
	var dog := Vector2(0, -hop)
	draw_rect(Rect2(Vector2(-11, -14) + dog, Vector2(22, 10)), Color("c8a070"))
	draw_rect(Rect2(Vector2(5, -22) + dog, Vector2(10, 10)), Color("c8a070"))
	draw_rect(Rect2(Vector2(5, -24) + dog, Vector2(3, 4)), Color("8a6040"))
	draw_rect(Rect2(Vector2(12, -24) + dog, Vector2(3, 4)), Color("8a6040"))
	draw_rect(Rect2(Vector2(11, -19) + dog, Vector2(2, 2)), INK)
	draw_line(Vector2(-11, -12) + dog, Vector2(-16, -18 + sin(_clock * 18.0) * 3.0) + dog, Color("c8a070"), 2.0)
	if active:
		draw_rect(Rect2(Vector2(13, -15) + dog, Vector2(3, 2)), Color("d84a5a"))
	draw_rect(Rect2(-30, -10, 60, 10), Color("d8d0c0"))
	draw_rect(Rect2(-30, -10, 60, 2), Color("e8e0d0"))
	for k in 9:
		var x := -28.0 + k * 7.0
		draw_line(Vector2(x, -10), Vector2(x, -40), Color("3a3a42"), 1.5)
		draw_circle(Vector2(x, -41), 1.2, Color("3a3a42"))
	draw_line(Vector2(-30, -36), Vector2(30, -36), Color("3a3a42"), 1.5)
	draw_line(Vector2(-30, -20), Vector2(30, -20), Color("3a3a42"), 1.5)


func _wall_and_cat() -> void:
	draw_rect(Rect2(-24, -28, 48, 28), Color("e0b878"))
	draw_rect(Rect2(-24, -28, 48, 3), Color("f0d098"))
	for k in 3:
		draw_line(Vector2(-24, -20 + k * 7), Vector2(24, -20 + k * 7), Color(0, 0, 0, 0.08), 1.0)
	# El gato echado, con la cola que se mueve despacio.
	var breathe := sin(_clock * 1.5) * 0.6
	draw_rect(Rect2(-10, -36 - breathe, 18, 8 + breathe), Color("6a6a72"))
	draw_rect(Rect2(6, -40, 8, 7), Color("6a6a72"))
	draw_colored_polygon(PackedVector2Array([Vector2(6, -40), Vector2(8, -44), Vector2(10, -40)]), Color("6a6a72"))
	draw_colored_polygon(PackedVector2Array([Vector2(10, -40), Vector2(12, -44), Vector2(14, -40)]), Color("6a6a72"))
	draw_line(Vector2(8, -37), Vector2(10, -37), INK, 1.0)
	draw_line(Vector2(11, -37), Vector2(13, -37), INK, 1.0)
	var tail := Vector2(-16, -30 + sin(_clock * 1.2) * 4.0)
	draw_line(Vector2(-10, -32), tail, Color("6a6a72"), 2.0)


func _bus() -> void:
	# Un bus de barrio (blanco con franja de color), 120 px de largo.
	draw_rect(Rect2(-60, -46, 120, 38), Color("f0f0ea"))
	draw_rect(Rect2(-60, -24, 120, 6), color)
	for k in 6:
		draw_rect(Rect2(-52 + k * 18, -42, 14, 12), Color("8ab8d8"))
	draw_rect(Rect2(50, -42, 8, 30), Color("8ab8d8"))
	draw_rect(Rect2(-60, -10, 120, 2), Color("3a3a42"))
	for wx in [-38.0, 38.0]:
		draw_circle(Vector2(wx, -6), 7.0, Color("2a2a30"))
		draw_circle(Vector2(wx, -6), 3.0, Color("9a9aa2"))
	draw_rect(Rect2(56, -16, 4, 4), Color("ffd166"))
