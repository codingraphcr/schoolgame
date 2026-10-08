extends Control
## Fondo decorativo con degradado, cuadrícula y trazos de "circuito" que pulsan suavemente.
## Es solo visual: no recibe clics ni toques.

@export var top_color := Color(0.039, 0.067, 0.141)
@export var bottom_color := Color(0.055, 0.110, 0.220)
@export var grid_color := Color(0.133, 0.827, 0.933, 0.05)
@export var trace_color := Color(0.133, 0.827, 0.933, 0.18)
@export var node_color := Color(0.133, 0.827, 0.933, 0.7)
@export var grid_spacing := 48.0
@export var trace_count := 14
@export var pulse_speed := 1.4
## Semilla fija para que el patrón sea siempre el mismo.
@export var pattern_seed := 2026

# Cada trazo es una línea en forma de "L" sobre la cuadrícula: [inicio, esquina, fin].
var _traces: Array[PackedVector2Array] = []
var _phases: Array[float] = []
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_generate_traces)
	_generate_traces()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _generate_traces() -> void:
	_traces.clear()
	_phases.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = pattern_seed
	var columns := maxi(int(size.x / grid_spacing), 1)
	var rows := maxi(int(size.y / grid_spacing), 1)

	for i in trace_count:
		var start := Vector2(rng.randi_range(0, columns), rng.randi_range(0, rows))
		var dx := rng.randi_range(2, 6) * (1 if rng.randf() < 0.5 else -1)
		var dy := rng.randi_range(1, 4) * (1 if rng.randf() < 0.5 else -1)
		var corner := start + Vector2(dx, 0)
		var end := corner + Vector2(0, dy)
		_traces.append(PackedVector2Array([start * grid_spacing, corner * grid_spacing, end * grid_spacing]))
		_phases.append(rng.randf() * TAU)


func _draw() -> void:
	_draw_gradient()
	_draw_grid()
	_draw_traces()


func _draw_gradient() -> void:
	var points := PackedVector2Array([
		Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y),
	])
	var colors := PackedColorArray([top_color, top_color, bottom_color, bottom_color])
	draw_polygon(points, colors)


func _draw_grid() -> void:
	var x := 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
		x += grid_spacing
	var y := 0.0
	while y <= size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)
		y += grid_spacing


func _draw_traces() -> void:
	for i in _traces.size():
		var trace := _traces[i]
		var pulse := 0.5 + 0.5 * sin(_time * pulse_speed + _phases[i])
		draw_polyline(trace, trace_color, 2.0)

		var glow := Color(node_color, node_color.a * 0.12 * pulse)
		var dot := Color(node_color, node_color.a * (0.4 + 0.6 * pulse))
		for point in [trace[0], trace[trace.size() - 1]]:
			draw_circle(point, 10.0 + 6.0 * pulse, glow)
			draw_circle(point, 3.5, dot)
