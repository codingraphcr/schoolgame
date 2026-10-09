@tool
class_name GrimorioBook
extends Control
## Dibuja el Grimorio abierto (concepto de Ariel): tapas oscuras con borde lila, esquinas de metal,
## dos páginas de papel lila envejecido con su pila de hojas, el lomo y la cinta marcapáginas.
## Las medidas están pensadas para una pantalla de 1280×720; el contenido va encima (grimorio.tscn).

const BOOK := Rect2(190, 58, 1060, 628)
const LEFT_PAGE := Rect2(222, 82, 494, 568)
const RIGHT_PAGE := Rect2(734, 82, 494, 568)

const COVER := Color("120d22")
const COVER_EDGE := Color("2a2145")
const GLOW := Color("7b5cff")
const METAL := Color("3b3456")
const METAL_LIGHT := Color("6b6290")
const PAPER := Color(0.87, 0.84, 0.94)
const PAPER_SHADE := Color(0.69, 0.65, 0.8)
const PAGE_EDGE := Color(0.58, 0.54, 0.7)
const INK := Color(0.12, 0.09, 0.2)


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	_draw_cover()
	_draw_page_stack(LEFT_PAGE, -1.0)
	_draw_page_stack(RIGHT_PAGE, 1.0)
	_draw_page(LEFT_PAGE, false)
	_draw_page(RIGHT_PAGE, true)
	_draw_spine()
	_draw_ribbon()


func _draw_cover() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COVER
	style.set_corner_radius_all(18)
	style.set_border_width_all(3)
	style.border_color = Color(GLOW, 0.85)
	style.shadow_color = Color(GLOW, 0.3)
	style.shadow_size = 22
	draw_style_box(style, BOOK)
	var inner := StyleBoxFlat.new()
	inner.bg_color = Color(0, 0, 0, 0)
	inner.set_corner_radius_all(12)
	inner.set_border_width_all(2)
	inner.border_color = COVER_EDGE
	draw_style_box(inner, BOOK.grow(-9))
	# Esquinas de metal con un rombo lila.
	for corner in [BOOK.position, Vector2(BOOK.end.x, BOOK.position.y), BOOK.end, Vector2(BOOK.position.x, BOOK.end.y)]:
		var inward := Vector2(signf(BOOK.get_center().x - corner.x), signf(BOOK.get_center().y - corner.y))
		var a: Vector2 = corner + inward * 4.0
		draw_colored_polygon(PackedVector2Array([a, a + Vector2(inward.x * 46.0, 0), a + inward * 14.0, a + Vector2(0, inward.y * 46.0)]), METAL)
		draw_polyline(PackedVector2Array([a + Vector2(inward.x * 46.0, 0), a + inward * 14.0, a + Vector2(0, inward.y * 46.0)]), METAL_LIGHT, 2.0)
		_draw_diamond(a + inward * 12.0, 5.0, GLOW)


## Hojas debajo de la página, asomando por abajo y por el lado de afuera.
func _draw_page_stack(page: Rect2, outward: float) -> void:
	for i in range(4, 0, -1):
		var offset := Vector2(outward * i * 2.0, i * 2.5)
		draw_rect(Rect2(page.position + offset, page.size), PAGE_EDGE.darkened(0.06 * i))
		draw_line(Vector2(page.position.x, page.end.y) + offset, page.end + offset, Color(INK, 0.25), 1.0)


func _draw_page(page: Rect2, right_side: bool) -> void:
	# El lado del lomo es más oscuro (la hoja se curva hacia adentro).
	var spine_x := page.position.x if right_side else page.end.x
	var outer_x := page.end.x if right_side else page.position.x
	var points := PackedVector2Array([Vector2(outer_x, page.position.y), Vector2(spine_x, page.position.y),
		Vector2(spine_x, page.end.y), Vector2(outer_x, page.end.y)])
	draw_polygon(points, PackedColorArray([PAPER, PAPER_SHADE, PAPER_SHADE, PAPER.darkened(0.04)]))
	# Sombra junto al lomo.
	var shadow_width := 34.0
	var shadow := Rect2(spine_x if right_side else spine_x - shadow_width, page.position.y, shadow_width, page.size.y)
	var near := Color(INK, 0.18)
	var far := Color(INK, 0.0)
	var corners := PackedVector2Array([shadow.position, Vector2(shadow.end.x, shadow.position.y), shadow.end, Vector2(shadow.position.x, shadow.end.y)])
	var colors := PackedColorArray([near, far, far, near]) if right_side else PackedColorArray([far, near, near, far])
	draw_polygon(corners, colors)
	# Manchas y motas del papel (siempre las mismas).
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 if right_side else 3
	for i in 260:
		var p := Vector2(rng.randf_range(page.position.x, page.end.x), rng.randf_range(page.position.y, page.end.y))
		draw_rect(Rect2(p, Vector2.ONE * rng.randf_range(1.0, 2.0)), Color(INK, rng.randf_range(0.03, 0.09)))
	for i in 5:
		var c := Vector2(rng.randf_range(page.position.x + 40, page.end.x - 40), rng.randf_range(page.position.y + 40, page.end.y - 40))
		draw_circle(c, rng.randf_range(18.0, 46.0), Color(INK, 0.016))
	# Borde fino de la hoja.
	draw_rect(page, Color(INK, 0.22), false, 1.0)


func _draw_spine() -> void:
	var spine := Rect2(LEFT_PAGE.end.x, BOOK.position.y + 14, RIGHT_PAGE.position.x - LEFT_PAGE.end.x, BOOK.size.y - 28)
	draw_rect(spine, COVER)
	draw_line(Vector2(spine.get_center().x, spine.position.y + 10), Vector2(spine.get_center().x, spine.end.y - 10), Color(GLOW, 0.35), 2.0)


## Cinta marcapáginas lila que cuelga del lomo, con un rombo.
func _draw_ribbon() -> void:
	var x := LEFT_PAGE.end.x + (RIGHT_PAGE.position.x - LEFT_PAGE.end.x) * 0.5
	var top := RIGHT_PAGE.end.y - 8.0
	var bottom := BOOK.end.y + 44.0
	var half := 15.0
	var ribbon := PackedVector2Array([Vector2(x - half, top), Vector2(x + half, top), Vector2(x + half, bottom),
		Vector2(x, bottom - 12.0), Vector2(x - half, bottom)])
	draw_colored_polygon(ribbon, Color("5a3fd0"))
	ribbon.append(ribbon[0])
	draw_polyline(ribbon, Color("1a1235"), 2.0)
	draw_line(Vector2(x - half + 4, top), Vector2(x - half + 4, bottom - 4), Color(GLOW, 0.5), 1.0)
	_draw_diamond(Vector2(x, bottom - 34.0), 8.0, Color("d9ccff"))


func _draw_diamond(center: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0),
		center + Vector2(0, radius), center + Vector2(-radius, 0)]), color)
	var inner := radius * 0.45
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -inner), center + Vector2(inner, 0),
		center + Vector2(0, inner), center + Vector2(-inner, 0)]), COVER)
