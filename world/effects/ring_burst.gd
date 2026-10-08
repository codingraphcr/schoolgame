class_name RingBurst
extends Node2D
## Anillo que se expande y se desvanece. Efecto reutilizable (doble salto, impactos…).
## Uso: RingBurst.spawn(padre, posición_global, color)

@export var color := Color(0.133, 0.827, 0.933)
@export var start_radius := 2.0
@export var end_radius := 14.0
@export var duration := 0.25
@export var line_width := 2.0

var _progress := 0.0


static func spawn(parent: Node, at: Vector2, ring_color: Color) -> RingBurst:
	var ring := RingBurst.new()
	ring.color = ring_color
	if parent:
		parent.add_child(ring)
		ring.global_position = at
	return ring


func _ready() -> void:
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(queue_free)


func _set_progress(value: float) -> void:
	_progress = value
	queue_redraw()


func _draw() -> void:
	var radius := lerpf(start_radius, end_radius, _progress)
	var ring_color := Color(color, 1.0 - _progress)
	# Elipse achatada: se lee como una onda bajo los pies.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, ring_color, line_width)
