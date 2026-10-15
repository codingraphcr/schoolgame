class_name ResonanceOverlay
extends CanvasLayer
## La Resonancia Digital (Capítulo 1, la primera noche en casa): mientras Kai duerme, interferencias en
## la imagen, una señal digital lejana y, por un instante, datos de un dispositivo cercano que aparecen
## escritos con fallas. No se explica nada: termina sola (finished) y Kai despierta confundido.
## Uso: await ResonanceOverlay.play(nodo, líneas).finished

signal finished

const CYAN := Color("3ef2ff")
const MAGENTA := Color("ff3ea5")

var lines: PackedStringArray = []
## Segundos por línea (las pruebas lo acortan).
var line_time := 1.6

var _view: _Noise
var _label: Label
var _shown := 0


static func play(from: Node, text_lines: PackedStringArray, seconds_per_line := 1.6) -> ResonanceOverlay:
	var overlay := ResonanceOverlay.new()
	overlay.lines = text_lines
	overlay.line_time = seconds_per_line
	from.get_tree().current_scene.add_child(overlay)
	return overlay


func _ready() -> void:
	layer = 65
	add_to_group(&"resonance_overlay")
	_view = _Noise.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view)
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_label.offset_left = -360.0
	_label.offset_right = 360.0
	_label.offset_top = -90.0
	_label.offset_bottom = 90.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override(&"font_size", 22)
	_label.add_theme_color_override(&"font_color", CYAN)
	_label.add_theme_color_override(&"font_outline_color", Color(0.0, 0.02, 0.05))
	_label.add_theme_constant_override(&"outline_size", 6)
	add_child(_label)
	_run()


func _run() -> void:
	Sfx.play(&"monitor_static", 0.7, -6.0)
	_view.burst(0.5)
	await _wait(line_time * 0.6)
	Sfx.play(&"distant_signal")
	for i in lines.size():
		_shown = i + 1
		_label.text = "\n".join(lines.slice(0, _shown))
		_view.burst(0.25)
		if i % 2 == 0:
			Sfx.play(&"monitor_static", 1.3, -14.0)
		await _wait(line_time)
	_view.burst(0.8)
	Sfx.play(&"monitor_off")
	await _wait(line_time * 0.5)
	finished.emit()
	queue_free()


func _process(_delta: float) -> void:
	# El texto tiembla y a veces se corre de color (falla de señal).
	var jitter := randf() < 0.12
	var shift := randf_range(-6.0, 6.0) if jitter else 0.0
	_label.offset_left = -360.0 + shift
	_label.offset_right = 360.0 + shift
	_label.add_theme_color_override(&"font_color", MAGENTA if jitter and randf() < 0.4 else CYAN)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false, true).timeout


## Fondo: oscurece la escena, líneas de barrido e interferencias (barras de colores) en ráfagas.
class _Noise extends Control:
	var _burst := 0.0
	var _clock := 0.0

	func burst(seconds: float) -> void:
		_burst = maxf(_burst, seconds)

	func _process(delta: float) -> void:
		_clock += delta
		_burst = maxf(_burst - delta, 0.0)
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.02, 0.06, 0.55))
		var y := fmod(_clock * 40.0, 4.0)
		while y < size.y:
			draw_rect(Rect2(0, y, size.x, 1), Color(0.24, 0.95, 1.0, 0.05))
			y += 4.0
		if _burst > 0.0:
			for k in 7:
				var bar_y := randf() * size.y
				var color := ResonanceOverlay.CYAN if k % 2 == 0 else ResonanceOverlay.MAGENTA
				draw_rect(Rect2(randf_range(-80.0, 40.0), bar_y, size.x * randf_range(0.3, 1.1), randf_range(2.0, 14.0)), Color(color, 0.25))
