class_name LifeFragmentIcon
extends Control
## El cristal de vida en negro que se va llenando con los fragmentos de vida juntados (un cuarto del
## cristal cada uno; con GameState.LIFE_FRAGMENTS_PER_MASK (4) se forma una vida). Lo usan la ventana
## del fragmento (LifeFragmentWindow) y la página del Grimorio. Al sumar uno, el pedazo nuevo destella.
## Mismo cristal que MaskIcon (docs/arte/referencias/vidas_concepto.webp); se escala a su tamaño.

## Pedazos juntados (0 a 4; con 4 el cristal está completo).
var count := 0:
	set(value):
		var gained := value > count
		count = clampi(value, 0, 4)
		if gained:
			_flash = 1.0
		queue_redraw()

var _flash := 0.0
var _time := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(38, 46)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(_flash - delta * 1.5, 0.0)
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	# Misma forma que una vida (38 × 46) aunque el recuadro sea más ancho o más alto.
	var unit := minf(size.x / 38.0, size.y / 46.0)
	var half := Vector2(19.0, 21.6) * unit * 0.82
	# Bordes proporcionales al tamaño (en el Grimorio y en la ventana se ve grande).
	var line := maxf(1.0, unit)
	var outer := _points(center, half, 1.0)
	# Contorno apagado de la vida que falta.
	draw_colored_polygon(outer, Color("07050d"))
	var edge := outer.duplicate()
	edge.append(edge[0])
	draw_polyline(edge, Color(MaskIcon.EMPTY_EDGE, 0.9), line, true)
	# Pedazos: arriba a la derecha, abajo a la derecha, abajo a la izquierda (el último cierra la vida).
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	for i in count:
		var piece := _piece(center, half, i)
		var fill := MaskIcon.BRIGHT.lerp(MaskIcon.PALE, 0.25 + 0.15 * pulse)
		draw_colored_polygon(piece, MaskIcon.DEEP)
		draw_colored_polygon(_shrink(piece, 0.6), fill)
		var outline := piece.duplicate()
		outline.append(outline[0])
		draw_polyline(outline, Color.WHITE if i == count - 1 and _flash > 0.0 else MaskIcon.PALE, line, true)
		if i == count - 1 and _flash > 0.0:
			draw_colored_polygon(piece, Color(1, 1, 1, _flash * 0.7))
	# Grietas: el borde roto entre los pedazos.
	var core := center + Vector2(0, half.y * -0.05)
	draw_polyline(PackedVector2Array([center + Vector2(0, -half.y), core + Vector2(1, -half.y * 0.4), core,
		core + Vector2(-1, half.y * 0.45), center + Vector2(0, half.y)]), Color("0d0a1a"), line * 1.5)
	draw_polyline(PackedVector2Array([center + Vector2(-half.x * 0.62, core.y - center.y), core + Vector2(-half.x * 0.3, 1),
		core, core + Vector2(half.x * 0.3, -1), center + Vector2(half.x * 0.62, core.y - center.y)]), Color("0d0a1a"), line * 1.5)


## Cuarto del cristal número index (0 arriba a la derecha, luego en el sentido del reloj).
func _piece(center: Vector2, half: Vector2, index: int) -> PackedVector2Array:
	var p := _points(center, half, 1.0)
	var core := center + Vector2(0, half.y * -0.05)
	var quarters: Array[PackedVector2Array] = [
		PackedVector2Array([core, p[0], p[1], p[2]]),
		PackedVector2Array([core, p[2], p[3], p[4]]),
		PackedVector2Array([core, p[4], p[5], p[6]]),
		PackedVector2Array([core, p[6], p[7], p[0]]),
	]
	return quarters[index]


func _points(center: Vector2, half: Vector2, scale_factor: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for p in MaskIcon.SHAPE:
		points.append(center + Vector2(p.x * half.x, p.y * half.y) * scale_factor)
	return points


## El polígono achicado hacia su centro (para la cara interior del pedazo).
func _shrink(points: PackedVector2Array, factor: float) -> PackedVector2Array:
	var middle := Vector2.ZERO
	for p in points:
		middle += p
	middle /= points.size()
	var result := PackedVector2Array()
	for p in points:
		result.append(middle.lerp(p, factor))
	return result
