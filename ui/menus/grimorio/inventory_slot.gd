class_name InventorySlot
extends Button
## Una casilla del INVENTARIO del Grimorio: un objeto, habilidad o recurso que se puede elegir (con
## el mouse, el teclado o el mando) para ver su descripción a la derecha. Tiene un marco (cuadro,
## círculo, hexágono o ninguno) y su dibujo lo hace InventoryPage (painter). Elegida o con el foco,
## brilla en lila con esquinas de selección.

enum Frame { NONE, SQUARE, CIRCLE, HEX }

const EDGE := Color("3d2f6e")
const LIT := Color("b9a6ff")
const GLOW := Color("8a5cff")
const FILL := Color("120c24")

var entry: GrimorioEntry
var unlocked := false
var frame := Frame.SQUARE
## Dibuja el contenido: func(slot: InventorySlot, rect: Rect2) (rect = el interior de la casilla).
var painter: Callable


func _ready() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	var empty := StyleBoxEmpty.new()
	for state in [&"normal", &"hover", &"pressed", &"hover_pressed", &"focus", &"disabled"]:
		add_theme_stylebox_override(state, empty)
	tooltip_text = entry.title if entry and unlocked else ""
	toggled.connect(func(_on: bool) -> void: queue_redraw())
	for sig: Signal in [focus_entered, focus_exited, mouse_entered, mouse_exited]:
		sig.connect(queue_redraw)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var lit := button_pressed or has_focus()
	var hover := is_hovered()
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	if lit:
		for i in 4:
			draw_circle(center, radius * (0.8 + i * 0.16), Color(GLOW, 0.07))
	var edge := LIT if lit else (LIT.darkened(0.3) if hover else EDGE)
	match frame:
		Frame.SQUARE:
			draw_rect(rect.grow(-2), FILL)
			draw_rect(rect.grow(-2), edge, false, 1.5 if lit else 1.0)
		Frame.CIRCLE:
			draw_circle(center, radius - 2.0, FILL)
			draw_arc(center, radius - 2.0, 0.0, TAU, 48, edge, 2.0 if lit else 1.5, true)
			draw_arc(center, radius - 7.0, 0.0, TAU, 48, Color(edge, 0.45), 1.0, true)
		Frame.HEX:
			var hex := PackedVector2Array()
			for i in 6:
				var angle := TAU * i / 6.0 + PI / 6.0
				hex.append(center + Vector2(cos(angle), sin(angle)) * (radius - 2.0))
			draw_colored_polygon(hex, FILL)
			hex.append(hex[0])
			draw_polyline(hex, edge, 1.5 if lit else 1.0, true)
	if painter.is_valid():
		painter.call(self, rect.grow(-8))
	if lit:
		# Esquinas de selección.
		var c := rect.grow(2)
		var l := 8.0
		for corner: Vector2 in [c.position, Vector2(c.end.x, c.position.y), c.end, Vector2(c.position.x, c.end.y)]:
			var sx := 1.0 if corner.x <= center.x else -1.0
			var sy := 1.0 if corner.y <= center.y else -1.0
			draw_line(corner, corner + Vector2(l * sx, 0), LIT, 2.0)
			draw_line(corner, corner + Vector2(0, l * sy), LIT, 2.0)
