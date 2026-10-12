class_name LifeFragmentIcon
extends Control
## Símbolo de los fragmentos de mejora, dividido en cuatro partes: cada fragmento juntado ilumina una
## parte; con los cuatro se completa. Lo usan la ventana del fragmento (LifeFragmentWindow) y el
## INVENTARIO del Grimorio. Al sumar uno, la parte nueva destella. Se escala a su tamaño.
##   Vida (energy = false): el cristal de integridad violeta, como MaskIcon
##     (docs/arte/referencias/vidas_concepto.webp); con 4 se forma una vida (GameState.LIFE_FRAGMENTS_PER_MASK).
##   Energía (energy = true): un núcleo hexagonal cian con un rayo en el centro; con 4 se gana una
##     barrita de energía (GameState.ENERGY_FRAGMENTS_PER_CELL).

## Hexágono del núcleo de energía (en unidades; se escala al tamaño del ícono).
const ENERGY_SHAPE: Array[Vector2] = [
	Vector2(0, -1), Vector2(0.62, -0.5), Vector2(0.62, 0.5), Vector2(0, 1), Vector2(-0.62, 0.5), Vector2(-0.62, -0.5),
]
const CYAN_DEEP := Color("0f6c8a")
const CYAN := Color("3ef2ff")
const CYAN_PALE := Color("d6fbff")
const CYAN_EDGE := Color("1f4a5c")

## Pedazos juntados (0 a 4; con 4 el símbolo está completo).
var count := 0:
	set(value):
		var gained := value > count
		count = clampi(value, 0, 4)
		if gained:
			_flash = 1.0
		queue_redraw()
## Fragmento de energía (cian, hexagonal) en vez de vida.
var energy := false

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
	# Proporción fija (38 × 46) aunque el recuadro sea más ancho o más alto.
	var unit := minf(size.x / 38.0, size.y / 46.0)
	var half := Vector2(19.0, 21.6) * unit * 0.82
	var line := maxf(1.0, unit)
	var outer := _points(center, half)
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	if count >= 4:
		for i in 4:
			draw_circle(center, half.x * (1.1 + i * 0.25), Color(_bright(), 0.06))
	# El símbolo apagado (en negro) con su borde.
	draw_colored_polygon(outer, Color("07050d"))
	var edge := outer.duplicate()
	edge.append(edge[0])
	draw_polyline(edge, Color(_edge(), 0.95), line, true)
	# Partes iluminadas.
	for i in count:
		var piece := _piece(center, half, i)
		draw_colored_polygon(piece, _deep())
		draw_colored_polygon(_shrink(piece, 0.6), _bright().lerp(_pale(), 0.25 + 0.15 * pulse))
		var outline := piece.duplicate()
		outline.append(outline[0])
		draw_polyline(outline, Color.WHITE if i == count - 1 and _flash > 0.0 else _pale(), line, true)
		if i == count - 1 and _flash > 0.0:
			draw_colored_polygon(piece, Color(1, 1, 1, _flash * 0.7))
	# Grietas entre las partes.
	var core := _core(center, half)
	var crack := Color("0d0a1a")
	draw_polyline(PackedVector2Array([center + Vector2(0, -half.y), core + Vector2(1, -half.y * 0.4), core,
		core + Vector2(-1, half.y * 0.45), center + Vector2(0, half.y)]), crack, line * 1.5)
	var side := half.x * 0.62
	draw_polyline(PackedVector2Array([Vector2(center.x - side, core.y), core + Vector2(-side * 0.5, 1), core,
		core + Vector2(side * 0.5, -1), Vector2(center.x + side, core.y)]), crack, line * 1.5)
	if energy:
		# Rayo en el centro (se enciende con el núcleo completo).
		var bolt := PackedVector2Array([core + Vector2(2, -9), core + Vector2(-3, 1), core + Vector2(1, 1), core + Vector2(-2, 9)])
		for i in bolt.size():
			bolt[i] = core + (bolt[i] - core) * unit * 0.9
		draw_polyline(bolt, CYAN_PALE if count >= 4 else Color(CYAN_EDGE, 0.9), line * 1.5)


## Parte número index (0 arriba a la derecha, luego en el sentido del reloj).
func _piece(center: Vector2, half: Vector2, index: int) -> PackedVector2Array:
	var p := _points(center, half)
	var core := _core(center, half)
	if energy:
		# Hexágono: arriba a la derecha, abajo a la derecha, abajo a la izquierda, arriba a la izquierda.
		var right := Vector2(p[1].x, core.y)
		var left := Vector2(p[5].x, core.y)
		var quarters: Array[PackedVector2Array] = [
			PackedVector2Array([core, p[0], p[1], right]),
			PackedVector2Array([core, right, p[2], p[3]]),
			PackedVector2Array([core, p[3], p[4], left]),
			PackedVector2Array([core, left, p[5], p[0]]),
		]
		return quarters[index]
	var crystal: Array[PackedVector2Array] = [
		PackedVector2Array([core, p[0], p[1], p[2]]),
		PackedVector2Array([core, p[2], p[3], p[4]]),
		PackedVector2Array([core, p[4], p[5], p[6]]),
		PackedVector2Array([core, p[6], p[7], p[0]]),
	]
	return crystal[index]


func _core(center: Vector2, half: Vector2) -> Vector2:
	return center if energy else center + Vector2(0, half.y * -0.05)


func _points(center: Vector2, half: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for p in (ENERGY_SHAPE if energy else MaskIcon.SHAPE):
		points.append(center + Vector2(p.x * half.x, p.y * half.y))
	return points


func _deep() -> Color:
	return CYAN_DEEP if energy else MaskIcon.DEEP


func _bright() -> Color:
	return CYAN if energy else MaskIcon.BRIGHT


func _pale() -> Color:
	return CYAN_PALE if energy else MaskIcon.PALE


func _edge() -> Color:
	return CYAN_EDGE if energy else MaskIcon.EMPTY_EDGE


## El polígono achicado hacia su centro (para la cara interior de la parte).
func _shrink(points: PackedVector2Array, factor: float) -> PackedVector2Array:
	var middle := Vector2.ZERO
	for p in points:
		middle += p
	middle /= points.size()
	var result := PackedVector2Array()
	for p in points:
		result.append(middle.lerp(p, factor))
	return result
