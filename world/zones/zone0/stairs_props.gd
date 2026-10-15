@tool
extends Node2D
## Arte provisional de las escaleras del colegio (M3), dibujado por código hasta que Ariel lo dibuje:
## los descansos (las plataformas donde se para Kai), los tramos de escalera entre ellos, la baranda,
## una ventana por piso, los carteles de cada piso y cosas de colegio (basureros, reciclaje, macetas, un
## bebedero, extintores, diarios murales y afiches). Las posiciones se ajustan en el Inspector y
## deben coincidir con las colisiones (Collisions/Landing*). Se ve también en el editor.

const CONCRETE := Color("5a6274")
const CONCRETE_DARK := Color("3a4152")
const RAIL := Color("8a96b8")
const GLASS := Color("2a4a7a")
const SIGN := Color("1f6f5a")
## Basureros de reciclaje: papel (azul), plástico (amarillo) y vidrio (verde).
const RECYCLING: Array[Color] = [Color("2f6fb8"), Color("d8b23a"), Color("3f9a52")]

## Descansos de la escalera (rectángulos de las plataformas, arriba = donde pisa Kai).
@export var landings: Array[Rect2] = []
## Descansos sueltos, sin tramo de escalera hacia el siguiente (p. ej. el del cuarto técnico).
@export var ledges: Array[Rect2] = []
## Ventanas (una por piso).
@export var windows: Array[Rect2] = []
## Carteles: posición (centro) → texto.
@export var signs: Dictionary = {}
## Cosas de colegio (posición = donde se apoyan en el piso, o el centro si van en la pared):
## basureros, basureros de reciclaje (papel, plástico y vidrio), macetas, bebederos y extintores.
@export var bins: Array[Vector2] = []
@export var recycling: Array[Vector2] = []
@export var plants: Array[Vector2] = []
@export var fountains: Array[Vector2] = []
@export var extinguishers: Array[Vector2] = []
## Diarios murales (corcho con papeles clavados).
@export var boards: Array[Rect2] = []
## Afiches: posición (centro) → texto.
@export var posters: Dictionary = {}

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	add_child(_canvas)


func _paint(c: VectorCanvas, _t: float) -> void:
	for window in windows:
		c.draw_rect(window.grow(3), CONCRETE_DARK)
		c.gradient_rect(window, GLASS.lightened(0.2), GLASS)
		c.draw_line(Vector2(window.get_center().x, window.position.y), Vector2(window.get_center().x, window.end.y), CONCRETE_DARK, 2.0)
		c.draw_line(Vector2(window.position.x, window.get_center().y), Vector2(window.end.x, window.get_center().y), CONCRETE_DARK, 2.0)
	# En la pared: diarios murales, afiches, bebederos y extintores.
	for board in boards:
		_paint_board(c, board)
	for pos: Vector2 in posters:
		_paint_poster(c, pos, String(posters[pos]))
	for pos in fountains:
		_paint_fountain(c, pos)
	for pos in extinguishers:
		_paint_extinguisher(c, pos)
	# Tramos: de cada descanso al siguiente, una franja de escalones en diagonal.
	for i in landings.size() - 1:
		_paint_flight(c, landings[i], landings[i + 1])
	for landing in landings + ledges:
		c.gradient_box(landing, 1.0, CONCRETE, CONCRETE_DARK)
		c.draw_line(landing.position + Vector2(0, -14), Vector2(landing.end.x, landing.position.y - 14), RAIL, 1.0)
		for k in int(landing.size.x / 24.0) + 1:
			var x := minf(landing.position.x + k * 24.0, landing.end.x)
			c.draw_line(Vector2(x, landing.position.y - 14), Vector2(x, landing.position.y), RAIL, 1.0)
	for pos: Vector2 in signs:
		var text := String(signs[pos])
		var box := Rect2(pos - Vector2(text.length() * 3.0 + 6, 7), Vector2(text.length() * 6.0 + 12, 14))
		c.draw_rect(box, SIGN)
		c.crisp_text(Vector2(box.position.x, box.end.y - 4), text, 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	# En el piso (delante de todo): basureros, reciclaje y macetas.
	for pos in bins:
		_paint_bin(c, pos, Color("5e6b62"), true)
	for pos in recycling:
		for k in RECYCLING.size():
			_paint_bin(c, pos + Vector2(k * 14.0, 0), RECYCLING[k], false)
	for pos in plants:
		_paint_plant(c, pos)


## Basurero (los pies en pos): cuerpo un poco más angosto abajo, tapa y franjas. trash: con un papel
## asomando. Los de reciclaje llevan el símbolo (un triángulo de flechas) en blanco.
func _paint_bin(c: VectorCanvas, pos: Vector2, color: Color, trash: bool) -> void:
	var w := 12.0 if trash else 11.0
	var h := 18.0
	c.shape(PackedVector2Array([pos + Vector2(-w * 0.5, -h), pos + Vector2(w * 0.5, -h),
		pos + Vector2(w * 0.4, 0), pos + Vector2(-w * 0.4, 0)]), color)
	c.draw_line(pos + Vector2(-w * 0.45, -h * 0.55), pos + Vector2(w * 0.45, -h * 0.55), color.darkened(0.25), 1.0)
	c.gradient_box(Rect2(pos + Vector2(-w * 0.5 - 1.0, -h - 3.0), Vector2(w + 2.0, 3.0)), 1.0, color.lightened(0.25), color.darkened(0.15))
	if trash:
		c.shape(PackedVector2Array([pos + Vector2(-3, -h - 3), pos + Vector2(1, -h - 7), pos + Vector2(3, -h - 3)]), Color("d8d4c8"))
	else:
		var center := pos + Vector2(0, -h * 0.3)
		var tri := PackedVector2Array([center + Vector2(0, -3), center + Vector2(3, 2), center + Vector2(-3, 2), center + Vector2(0, -3)])
		c.draw_polyline(tri, Color(1, 1, 1, 0.85), 1.0)


## Maceta con una planta (los pies en pos).
func _paint_plant(c: VectorCanvas, pos: Vector2) -> void:
	var leaf := Color("3f7a4a")
	for k in 7:
		var angle := lerpf(-2.6, -0.5, k / 6.0)
		var tip := pos + Vector2(0, -12) + Vector2(cos(angle), sin(angle)) * (12.0 + (k % 2) * 5.0)
		var side := Vector2(cos(angle + PI * 0.5), sin(angle + PI * 0.5)) * 2.5
		c.shape(PackedVector2Array([pos + Vector2(0, -12) + side, tip, pos + Vector2(0, -12) - side]),
			leaf.lightened(0.15 * (k % 3)), VectorCanvas.OUTLINE, 0.5)
	c.shape(PackedVector2Array([pos + Vector2(-7, -12), pos + Vector2(7, -12), pos + Vector2(5, 0), pos + Vector2(-5, 0)]), Color("a5583a"))
	c.draw_rect(Rect2(pos + Vector2(-8, -14), Vector2(16, 3)), Color("8c4630"))


## Diario mural: marco de madera, corcho y papeles de colores clavados con chinches.
func _paint_board(c: VectorCanvas, rect: Rect2) -> void:
	c.gradient_box(rect.grow(2.0), 1.0, Color("6b4a32"), Color("4a3222"))
	c.gradient_rect(rect, Color("b08a5c"), Color("96714a"))
	var papers := [[0.06, 0.1, 0.28, 0.42, Color("e9e4d4")], [0.4, 0.08, 0.24, 0.5, Color("f2d27a")],
		[0.7, 0.16, 0.24, 0.34, Color("9fc8e8")], [0.1, 0.6, 0.34, 0.3, Color("f0a8b8")], [0.52, 0.64, 0.4, 0.28, Color("e9e4d4")]]
	for p in papers:
		var paper := Rect2(rect.position + rect.size * Vector2(p[0], p[1]), rect.size * Vector2(p[2], p[3]))
		c.draw_rect(paper, p[4])
		for line in int(paper.size.y / 4.0) - 1:
			var y := paper.position.y + 4.0 + line * 4.0
			c.draw_line(Vector2(paper.position.x + 2.0, y), Vector2(paper.end.x - 2.0, y), Color(0.2, 0.2, 0.3, 0.35), 1.0)
		c.draw_circle(Vector2(paper.get_center().x, paper.position.y + 1.5), 1.3, Color("c8323c"))


## Afiche en la pared (centro en pos): franja de color arriba y el texto.
func _paint_poster(c: VectorCanvas, pos: Vector2, text: String) -> void:
	var box := Rect2(pos - Vector2(text.length() * 2.6 + 6.0, 11.0), Vector2(text.length() * 5.2 + 12.0, 22.0))
	c.gradient_box(box, 1.0, Color("e9e4d4"), Color("cfc9b6"))
	c.draw_rect(Rect2(box.position, Vector2(box.size.x, 5.0)), Color("c8323c"))
	c.crisp_text(Vector2(box.position.x, box.end.y - 4.0), text, 7, Color("2a2440"), HORIZONTAL_ALIGNMENT_CENTER, box.size.x)


## Bebedero de pared (los pies en pos): la caja de metal con su pileta y el caño hasta el piso.
func _paint_fountain(c: VectorCanvas, pos: Vector2) -> void:
	c.draw_rect(Rect2(pos + Vector2(-1.5, -22), Vector2(3, 22)), Color("6c7486"))
	c.gradient_box(Rect2(pos + Vector2(-11, -34), Vector2(22, 12)), 2.0, Color("c3cad6"), Color("8a92a4"))
	c.draw_rect(Rect2(pos + Vector2(-8, -32), Vector2(16, 3)), Color("4a5468"))
	c.draw_circle(pos + Vector2(6, -27), 1.5, Color("5ab0e0"))


## Extintor colgado en la pared (pos = abajo del extintor), con su cartel arriba.
func _paint_extinguisher(c: VectorCanvas, pos: Vector2) -> void:
	c.gradient_box(Rect2(pos + Vector2(-4, -18), Vector2(8, 18)), 3.0, Color("e0443c"), Color("9a2420"))
	c.draw_rect(Rect2(pos + Vector2(-2, -21), Vector2(4, 3)), Color("2a2a30"))
	c.draw_polyline(PackedVector2Array([pos + Vector2(2, -20), pos + Vector2(6, -17), pos + Vector2(6, -8)]), Color("2a2a30"), 1.2)
	c.draw_rect(Rect2(pos + Vector2(-3, -12), Vector2(6, 4)), Color("f0e6d0"))
	var label := Rect2(pos + Vector2(-17, -33), Vector2(34, 9))
	c.draw_rect(label, Color("c8323c"))
	c.crisp_text(Vector2(label.position.x, label.end.y - 2.0), "EXTINTOR", 6, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, label.size.x)


## Escalones entre dos descansos (solo dibujo: Kai sube saltando de descanso en descanso).
func _paint_flight(c: VectorCanvas, from: Rect2, to: Rect2) -> void:
	var start := Vector2(from.end.x if to.position.x > from.position.x else from.position.x, from.position.y)
	var finish := Vector2(to.position.x if to.position.x > from.position.x else to.end.x, to.position.y)
	var steps := 6
	for k in steps:
		var a := start.lerp(finish, float(k) / steps)
		var b := start.lerp(finish, float(k + 1) / steps)
		c.draw_rect(Rect2(Vector2(minf(a.x, b.x), b.y), Vector2(absf(b.x - a.x) + 1.0, a.y - b.y + 4.0)), CONCRETE_DARK.darkened(0.2))
	c.draw_line(start + Vector2(0, -14), finish + Vector2(0, -14), RAIL, 1.0)
