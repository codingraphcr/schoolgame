@tool
extends Node2D
## Nota escondida en la red: solo se ve con la Visión Digital (grupo "digital_only"). Un papel
## de datos que tiembla con un glitch y deja una pista para un desafío, sin resolverlo.
## El origen es el centro de la nota. Se ve también en el editor.

const CYAN := Color("3ef2ff")
const MAG := Color("ff3ea5")

@export var lines: PackedStringArray = ["LO QUE BUSCAS", "NO SE VE", "A SIMPLE VISTA", "> ls -a"]
@export var note_size := Vector2(72, 54)

var _canvas: VectorCanvas


func _ready() -> void:
	add_to_group(&"digital_only")
	if not Engine.is_editor_hint():
		visible = false
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)


func _paint(c: VectorCanvas, t: float) -> void:
	# Cada tanto la nota salta unos píxeles a un costado (glitch).
	var jump := Vector2(2.0 * signf(sin(t * 37.0)), 0.0) if fmod(t, 2.3) < 0.12 else Vector2.ZERO
	var rect := Rect2(-note_size / 2.0 + jump, note_size)
	c.glow(rect.get_center(), 46.0, Color(CYAN, 0.18))
	c.draw_colored_polygon(VectorCanvas.rounded_rect(rect, 2.0), Color(0.04, 0.12, 0.2, 0.85))
	var border := VectorCanvas.rounded_rect(rect, 2.0)
	border.append(border[0])
	c.draw_polyline(border, Color(CYAN, 0.9), 1.0, true)
	# Esquina doblada.
	var corner := rect.end - Vector2(10, 10)
	c.draw_colored_polygon(PackedVector2Array([corner + Vector2(10, 0), corner + Vector2(0, 10), corner]), Color(CYAN, 0.35))
	for i in lines.size():
		var color := MAG if lines[i].begins_with(">") else CYAN
		var shift := Vector2(-1.5, 0) if jump != Vector2.ZERO and i % 2 == 0 else Vector2.ZERO
		c.crisp_text(rect.position + Vector2(0, 13 + i * 11) + shift, lines[i], 6, color, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
	# Líneas de interferencia.
	for k in 2:
		var y := rect.position.y + fmod(t * 18.0 + k * 27.0, rect.size.y)
		c.draw_line(Vector2(rect.position.x + 2, y), Vector2(rect.end.x - 2, y), Color(CYAN, 0.15), 1.0)
