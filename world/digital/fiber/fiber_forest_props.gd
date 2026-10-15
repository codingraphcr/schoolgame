@tool
extends Node2D
## Arte provisional del Bosque de Fibra (dibujado por código hasta que Ariel lo dibuje): naturaleza digital.
## Árboles de fibra óptica con puntas que brillan, raíces de cables en el piso, plantas luminosas y motas
## de luz que viajan entre nodos. Mientras la conexión del barrio está cortada (restored_flag no está), el
## bosque está apagado y algunos cables chisporrotean en rojo; al restaurarla, vuelve a brillar.

const SKY_TOP := Color("0a0f24")
const SKY_BOTTOM := Color("142a3a")
const TRUNK := Color("1e3048")
const FIBER := Color("3ef2ff")
const WARM := Color("fff0a0")
const BROKEN := Color("ff4a6a")

@export var width := 960.0
@export var floor_y := 304.0
@export var restored_flag: StringName = &"bosque_fibra_enlace_restaurado"
## Árboles (x) y plantas luminosas (x).
@export var trees: PackedFloat32Array = []
@export var plants: PackedFloat32Array = []
@export var preview_restored := true

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)


func is_restored() -> bool:
	if Engine.is_editor_hint():
		return preview_restored
	var state := get_node_or_null("/root/GameState")
	return state != null and state.has_flag(restored_flag)


func _paint(c: VectorCanvas, t: float) -> void:
	var f := floor_y
	var on := is_restored()
	var glow := 1.0 if on else 0.4
	c.gradient_rect(Rect2(0, 0, width, f + 60), SKY_TOP, SKY_BOTTOM)
	# Fondo lejano: copas de fibra muy tenues.
	for k in int(width / 70.0) + 1:
		var x := k * 70.0 + 20.0
		c.draw_line(Vector2(x, f), Vector2(x + sin(k) * 10.0, f - 170 - (k % 3) * 20), Color(TRUNK, 0.6), 6.0)
		c.draw_circle(Vector2(x + sin(k) * 10.0, f - 175 - (k % 3) * 20), 26.0, Color(FIBER, 0.04 * glow))
	# Motas de luz que viajan (datos).
	for k in 24:
		var x := fmod(k * 97.0 + t * (18.0 + k % 5 * 6.0), width)
		var y := 40.0 + fmod(k * 53.0, f - 80.0) + sin(t * 1.3 + k) * 6.0
		c.draw_circle(Vector2(x, y), 1.5, Color(WARM if k % 4 == 0 else FIBER, 0.5 * glow))
	for x in trees:
		_tree(c, x, f, t, glow)
	# Piso: raíces de cable.
	c.draw_rect(Rect2(0, f, width, 60), Color("0e1a28"))
	for k in 6:
		var points := PackedVector2Array()
		var x := 0.0
		while x <= width:
			points.append(Vector2(x, f + 6 + k * 7 + sin(x * 0.02 + k * 1.7) * 3.0))
			x += 24.0
		c.draw_polyline(points, Color(FIBER, (0.25 if k % 2 == 0 else 0.12) * glow), 1.5)
	c.draw_line(Vector2(0, f), Vector2(width, f), Color(FIBER, 0.5 * glow), 2.0)
	for x in plants:
		_plant(c, x, f, t, glow)
	# Sin señal: cables rotos que chisporrotean.
	if not on:
		for k in 3:
			var x := width * (0.25 + k * 0.25)
			if fmod(t * 3.0 + k, 2.0) < 0.3:
				c.draw_line(Vector2(x - 8, f - 4), Vector2(x + 6, f - 14), BROKEN, 2.0)
				c.draw_circle(Vector2(x + 6, f - 14), 2.5, Color(BROKEN, 0.8))


func _tree(c: VectorCanvas, x: float, f: float, t: float, glow: float) -> void:
	# Tronco hecho de varios cables trenzados que se abren en la copa.
	for k in 5:
		var top := Vector2(x + (k - 2) * 14.0, f - 150 - absf(k - 2) * -8.0)
		var points := VectorCanvas.sag_curve(Vector2(x + (k - 2) * 2.0, f), top, -6.0 + k, 10)
		c.draw_polyline(points, TRUNK.lightened(k * 0.04), 3.0)
		var pulse := 0.5 + 0.5 * sin(t * 2.0 + k + x)
		c.draw_circle(top, 3.0, Color(FIBER, (0.5 + pulse * 0.5) * glow))
		c.glow(top, 12.0, Color(FIBER, 0.35 * glow), 4)
	c.glow(Vector2(x, f - 150), 60.0, Color(FIBER, 0.08 * glow), 6)


func _plant(c: VectorCanvas, x: float, f: float, t: float, glow: float) -> void:
	for k in 3:
		var tip := Vector2(x + (k - 1) * 6.0 + sin(t * 1.5 + k) * 1.5, f - 16 - k * 5.0)
		c.draw_line(Vector2(x + (k - 1) * 2.0, f), tip, Color("2a6a5a"), 2.0)
		c.draw_circle(tip, 2.5, Color(WARM if k == 1 else FIBER, 0.9 * glow))
