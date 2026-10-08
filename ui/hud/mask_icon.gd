class_name MaskIcon
extends Control
## Una máscara de integridad del HUD (núcleo hexagonal). Llena = vida disponible.
## Al romperse destella y se encoge; al recuperarse crece.

const FULL_FILL := Color(0.133, 0.827, 0.933)
const FULL_BORDER := Color(0.93, 0.98, 1.0)
const EMPTY_FILL := Color(0.08, 0.12, 0.22, 0.85)
const EMPTY_BORDER := Color(0.3, 0.4, 0.58)

var filled := true:
	set(value):
		if value == filled:
			return
		filled = value
		_animate(value)
		queue_redraw()

var _flash := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(30, 34)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) * 0.45
	var points := PackedVector2Array()
	for i in 6:
		var angle := TAU * i / 6.0 - PI / 2.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	var fill := FULL_FILL if filled else EMPTY_FILL
	fill = fill.lerp(Color.WHITE, _flash)
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, FULL_BORDER if filled else EMPTY_BORDER, 2.0, true)
	if filled:
		# Brillo interior: núcleo de energía.
		draw_circle(center + Vector2(-radius * 0.25, -radius * 0.25), radius * 0.18, Color(1, 1, 1, 0.55))


func _animate(gained: bool) -> void:
	pivot_offset = size / 2.0
	var tween := create_tween().set_parallel()
	_flash = 1.0
	tween.tween_method(_set_flash, 1.0, 0.0, 0.25)
	if gained:
		scale = Vector2(1.4, 1.4)
	else:
		scale = Vector2(0.6, 0.6)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_flash(value: float) -> void:
	_flash = value
	queue_redraw()
