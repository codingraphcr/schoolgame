class_name FallOverlay
extends CanvasLayer
## La caída accidental de Kai por un conducto digital (Capítulo 3): pantalla completa, líneas de datos que suben a toda
## velocidad, Kai dando vueltas en el centro y sus comentarios en globitos, uno tras otro, con sonidos. Es una escena:
## no hay daño ni se pierde nada. Uso: await FallOverlay.play(nodo, ["¡AAAAH!", ...], 5.0).finished

signal finished

const CYAN := Color("3ef2ff")
const VIOLET := Color("b46bff")

var lines: PackedStringArray = []
var seconds := 5.0

var _clock := 0.0
var _canvas: Control
var _shown := 0


static func play(from: Node, comment_lines: PackedStringArray, duration := 5.0) -> FallOverlay:
	var overlay := FallOverlay.new()
	overlay.lines = comment_lines
	overlay.seconds = duration
	from.get_tree().current_scene.add_child(overlay)
	return overlay


func _ready() -> void:
	layer = 80
	add_to_group(&"fall_overlay")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_fall)
	add_child(_canvas)
	Sfx.play(&"dash")


func _process(delta: float) -> void:
	_clock += delta
	var next := int(_clock / maxf(seconds / maxf(lines.size(), 1.0), 0.01))
	if next > _shown and _shown < lines.size():
		_shown = mini(next, lines.size())
		Sfx.play(&"jump")
	_canvas.queue_redraw()
	if _clock >= seconds:
		set_process(false)
		finished.emit()
		queue_free()


func _draw_fall() -> void:
	var size := _canvas.size
	_canvas.draw_rect(Rect2(Vector2.ZERO, size), Color("05030c"))
	# Líneas de datos que suben (Kai cae).
	for k in 40:
		var x := fmod(k * 97.0, size.x)
		var y := size.y - fmod(_clock * (900.0 + (k % 5) * 160.0) + k * 53.0, size.y + 200.0)
		_canvas.draw_line(Vector2(x, y), Vector2(x, y + 60.0 + (k % 3) * 30.0), Color(CYAN if k % 3 else VIOLET, 0.35), 2.0)
	# Kai dando vueltas (silueta provisional: pelo blanco, chaqueta oscura).
	var center := size / 2.0 + Vector2(sin(_clock * 3.0) * 30.0, 0)
	var angle := _clock * 5.0
	var body := Transform2D(angle, center)
	_canvas.draw_set_transform_matrix(body)
	_canvas.draw_rect(Rect2(-14, -10, 28, 40), Color("2a3048"))
	_canvas.draw_circle(Vector2(0, -24), 16.0, Color("f0e6d8"))
	for k in 6:
		_canvas.draw_circle(Vector2(-14 + k * 6, -38 + (k % 2) * 4), 7.0, Color("eef4ff"))
	_canvas.draw_line(Vector2(-14, 0), Vector2(-34, -16 + sin(_clock * 12.0) * 8.0), Color("2a3048"), 7.0)
	_canvas.draw_line(Vector2(14, 0), Vector2(34, -16 - sin(_clock * 12.0) * 8.0), Color("2a3048"), 7.0)
	_canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
	# Los comentarios, el último más grande.
	var font := ThemeDB.fallback_font
	for i in _shown:
		var text := lines[i]
		var font_size := 28 if i == _shown - 1 else 18
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 28.0
		var pos := Vector2(size.x / 2.0 - width / 2.0 + (i % 2 * 2 - 1) * 180.0, 90.0 + i * 64.0)
		var bubble := Rect2(pos, Vector2(width, font_size + 18.0))
		_canvas.draw_rect(bubble, Color(1, 1, 1, 0.95 if i == _shown - 1 else 0.6))
		_canvas.draw_string(font, pos + Vector2(14, font_size + 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("1a1424"))
