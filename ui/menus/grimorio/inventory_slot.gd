class_name InventorySlot
extends Button
## Una casilla del INVENTARIO del Grimorio (estilo Hollow Knight): el objeto que Kai tiene (su
## imagen, el cristal de vida en negro que se llena con los fragmentos, o un núcleo si no tiene
## imagen) y, si es un recurso, la cantidad (p. ej. los Ecos). Elegida, se ilumina en lila.

const SIZE := Vector2(84, 84)
const DARK := Color("1c1830")
const EDGE := Color("3d3560")
const LIT := Color("5f43dc")
const LIT_EDGE := Color("b9a6ff")
const INK := Color("e6deff")

var entry: GrimorioEntry
## Cantidad que se muestra abajo a la derecha (-1 = ninguna).
var amount := -1
## Fragmentos de vida juntados (solo para la casilla de los fragmentos).
var fragments := 0

var _fragment_icon: LifeFragmentIcon


func _ready() -> void:
	toggle_mode = true
	custom_minimum_size = SIZE
	focus_mode = Control.FOCUS_ALL
	var empty := StyleBoxEmpty.new()
	for state in [&"normal", &"hover", &"pressed", &"hover_pressed", &"focus", &"disabled"]:
		add_theme_stylebox_override(state, empty)
	tooltip_text = entry.title if entry else ""
	if entry and entry.shows_life_fragments:
		_fragment_icon = LifeFragmentIcon.new()
		_fragment_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fragment_icon.position = Vector2(14, 10)
		_fragment_icon.size = SIZE - Vector2(28, 20)
		_fragment_icon.count = fragments
		add_child(_fragment_icon)
	toggled.connect(func(_on: bool) -> void: queue_redraw())
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func _draw() -> void:
	var rect := Rect2(Vector2(3, 3), SIZE - Vector2(6, 6))
	var lit := button_pressed
	var hover := is_hovered() or has_focus()
	# Brillo detrás del objeto elegido.
	if lit:
		for i in 3:
			draw_circle(SIZE / 2.0, 30.0 + i * 6.0, Color(LIT_EDGE, 0.08))
	draw_rect(rect, Color(LIT, 0.35) if lit else DARK)
	draw_rect(rect, LIT_EDGE if lit or hover else EDGE, false, 2.0 if lit else 1.0)
	if entry == null:
		return
	if entry.image and not entry.shows_life_fragments:
		var tex_size := entry.image.get_size()
		var fit := minf((SIZE.x - 18.0) / tex_size.x, (SIZE.y - 18.0) / tex_size.y)
		var shown := tex_size * fit
		draw_texture_rect(entry.image, Rect2(SIZE / 2.0 - shown / 2.0, shown), false)
	elif not entry.shows_life_fragments:
		# Sin imagen: un núcleo en rombo (como el emblema del Grimorio).
		var c := SIZE / 2.0
		var s := 18.0
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.7, 0), c + Vector2(0, s), c + Vector2(-s * 0.7, 0)]), Color("5b2fe0"))
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.5), c + Vector2(s * 0.35, 0), c + Vector2(0, s * 0.5), c + Vector2(-s * 0.35, 0)]), Color("e4dbff"))
	if amount >= 0:
		var text := str(amount)
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		var at := Vector2(SIZE.x - 8.0 - width, SIZE.y - 8.0)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color("0b0716"))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
