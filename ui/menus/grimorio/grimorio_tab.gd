@tool
class_name GrimorioTab
extends Button
## Pestaña del Grimorio (MAPA, COMANDOS, AMENAZAS, CONCEPTOS, REGISTROS): oscura con borde lila;
## la elegida se ilumina en lila y sobresale. El ícono se dibuja con líneas (sin imágenes).

enum Icon { MAPA, COMANDOS, AMENAZAS, CONCEPTOS, REGISTROS, ARSENAL }

@export var icon_kind := Icon.MAPA:
	set(value):
		icon_kind = value
		queue_redraw()

const DARK := Color("1c1830")
const DARK_BORDER := Color("3d3560")
const LIT := Color("5f43dc")
const LIT_BORDER := Color("b9a6ff")
const ICON_COLOR := Color("e6deff")
const ICON_BOX := 52.0


func _ready() -> void:
	toggle_mode = true
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	toggled.connect(func(_on: bool) -> void: queue_redraw())
	var born := Time.get_ticks_msec()
	focus_entered.connect(func() -> void:
		if Time.get_ticks_msec() - born > 400:
			Sfx.play(&"book_page", randf_range(0.95, 1.1)))
	var normal := _style(DARK, DARK_BORDER)
	var lit := _style(LIT, LIT_BORDER)
	lit.shadow_color = Color(LIT_BORDER, 0.35)
	lit.shadow_size = 12
	for state in [&"normal", &"disabled"]:
		add_theme_stylebox_override(state, normal)
	add_theme_stylebox_override(&"hover", _style(DARK.lightened(0.08), LIT_BORDER))
	for state in [&"pressed", &"hover_pressed"]:
		add_theme_stylebox_override(state, lit)
	add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	add_theme_color_override(&"font_color", Color("b9b0dd"))
	add_theme_color_override(&"font_hover_color", ICON_COLOR)
	add_theme_color_override(&"font_focus_color", ICON_COLOR)
	add_theme_color_override(&"font_pressed_color", Color.WHITE)
	add_theme_color_override(&"font_hover_pressed_color", Color.WHITE)


func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.border_width_right = 0
	style.corner_radius_top_left = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = ICON_BOX + 14.0
	style.content_margin_right = 10.0
	return style


func _draw() -> void:
	# Separador del ícono y marca de foco (teclado o mando).
	draw_line(Vector2(ICON_BOX, 10), Vector2(ICON_BOX, size.y - 10), Color(LIT_BORDER, 0.35), 1.0)
	if has_focus():
		draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color(LIT_BORDER, 0.8), false, 1.0)
	var o := Vector2(ICON_BOX * 0.5 - 12.0, size.y * 0.5 - 12.0)
	var c := ICON_COLOR
	match icon_kind:
		Icon.MAPA:
			var outline := PackedVector2Array([Vector2(0, 4), Vector2(8, 0), Vector2(16, 4), Vector2(24, 0),
				Vector2(24, 20), Vector2(16, 24), Vector2(8, 20), Vector2(0, 24), Vector2(0, 4)])
			_poly(o, outline, c)
			draw_line(o + Vector2(8, 0), o + Vector2(8, 20), c, 2.0)
			draw_line(o + Vector2(16, 4), o + Vector2(16, 24), c, 2.0)
		Icon.COMANDOS:
			draw_rect(Rect2(o + Vector2(0, 2), Vector2(24, 20)), c, false, 2.0)
			_poly(o, PackedVector2Array([Vector2(5, 8), Vector2(9, 12), Vector2(5, 16)]), c)
			draw_line(o + Vector2(12, 17), o + Vector2(19, 17), c, 2.0)
		Icon.AMENAZAS:
			draw_circle(o + Vector2(12, 14), 6.0, c)
			draw_circle(o + Vector2(12, 6), 3.0, c)
			for y in [10.0, 14.0, 18.0]:
				draw_line(o + Vector2(6, y), o + Vector2(1, y + 2.0), c, 2.0)
				draw_line(o + Vector2(18, y), o + Vector2(23, y + 2.0), c, 2.0)
			draw_line(o + Vector2(10, 4), o + Vector2(7, 0), c, 2.0)
			draw_line(o + Vector2(14, 4), o + Vector2(17, 0), c, 2.0)
		Icon.CONCEPTOS:
			_poly(o, PackedVector2Array([Vector2(12, 6), Vector2(2, 2), Vector2(2, 20), Vector2(12, 24), Vector2(22, 20), Vector2(22, 2), Vector2(12, 6), Vector2(12, 24)]), c)
			for y in [8.0, 12.0, 16.0]:
				draw_line(o + Vector2(5, y), o + Vector2(9, y + 1.0), c, 1.0)
				draw_line(o + Vector2(15, y + 1.0), o + Vector2(19, y), c, 1.0)
		Icon.ARSENAL:
			# Espada en diagonal con la guarda y el núcleo en rombo (como la Nullblade).
			draw_line(o + Vector2(9, 15), o + Vector2(23, 1), c, 3.0)
			draw_line(o + Vector2(4, 12), o + Vector2(12, 20), c, 2.0)
			draw_line(o + Vector2(7, 17), o + Vector2(1, 23), c, 3.0)
			draw_colored_polygon(PackedVector2Array([o + Vector2(8, 13), o + Vector2(11, 16), o + Vector2(8, 19), o + Vector2(5, 16)]), c)
		Icon.REGISTROS:
			_poly(o, PackedVector2Array([Vector2(3, 0), Vector2(16, 0), Vector2(21, 5), Vector2(21, 24), Vector2(3, 24), Vector2(3, 0)]), c)
			_poly(o, PackedVector2Array([Vector2(16, 0), Vector2(16, 5), Vector2(21, 5)]), c)
			for y in [10.0, 14.0, 18.0]:
				draw_line(o + Vector2(7, y), o + Vector2(17, y), c, 2.0)


func _poly(origin: Vector2, points: PackedVector2Array, color: Color) -> void:
	var moved := PackedVector2Array()
	for p in points:
		moved.append(origin + p)
	draw_polyline(moved, color, 2.0)
