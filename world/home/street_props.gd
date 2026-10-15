@tool
extends Node2D
## Arte provisional de la calle del colegio a la casa de Kai (dibujado por código hasta que Ariel la
## dibuje): un barrio residencial inventado, de inspiración costarricense. Montañas al fondo, casas de
## colores con rejas y portones, postes con cables, árboles, una pulpería, la parada del bus, aceras con
## el cordón pintado y, al final, la casa de Kai. El cielo y las luces siguen el momento del día
## (DayPhase). Sin marcas ni lugares reales.

const OUTLINE := Color("1a1424")
const SIDEWALK := Color("b8b0a4")
const CURB := Color("e8c84a")
const STREET := Color("4a4a54")

@export var width := 1800.0
@export var floor_y := 304.0
@export var preview_phase := DayPhase.Phase.TARDE
## Casas del barrio: x del borde izquierdo → [ancho, alto, color de la fachada].
@export var houses: Dictionary = {}
## Árboles (x) y postes de luz (x).
@export var trees: PackedFloat32Array = []
@export var poles: PackedFloat32Array = []

var _canvas: VectorCanvas
var _phase := DayPhase.Phase.TARDE


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_phase = preview_phase
	elif has_node("/root/GameState"):
		_phase = DayPhase.current(get_node("/root/GameState"))


func _paint(c: VectorCanvas, t: float) -> void:
	var f := floor_y
	var lit := _phase == DayPhase.Phase.TARDE or _phase == DayPhase.Phase.NOCHE
	c.gradient_rect(Rect2(0, 0, width, f), DayPhase.sky_top(_phase), DayPhase.sky_bottom(_phase))
	if _phase == DayPhase.Phase.TARDE:
		c.glow(Vector2(width * 0.7, 150), 120.0, Color(1.0, 0.85, 0.5, 0.35))
		c.draw_circle(Vector2(width * 0.7, 150), 22.0, Color("fff0c0"))
	# Montañas del valle, al fondo (dos capas).
	_mountains(c, f - 120, Color("6a5a8a").lerp(DayPhase.sky_bottom(_phase), 0.35), 0.004, 50.0)
	_mountains(c, f - 90, Color("4a5a6a").lerp(DayPhase.sky_bottom(_phase), 0.15), 0.007, 34.0)
	# Terreno detrás de las casas (zacate y tierra), hasta la acera.
	c.gradient_rect(Rect2(0, f - 44, width, 44), Color("5a7a3a").lerp(DayPhase.sky_bottom(_phase), 0.2), Color("6a5a3a"))
	# Cables de luz entre los postes.
	for i in poles.size() - 1:
		for k in 2:
			c.draw_polyline(VectorCanvas.sag_curve(Vector2(poles[i], f - 150 + k * 8), Vector2(poles[i + 1], f - 150 + k * 8), 10.0), Color(0.1, 0.1, 0.12, 0.8), 1.0)
	_school_gate(c, f)
	for house_x: float in houses:
		var data: Array = houses[house_x]
		_house(c, house_x, f, data[0], data[1], data[2])
	_pulperia(c, 760.0, f, lit)
	_bus_stop(c, 520.0, f)
	_kai_house(c, width - 210.0, f, lit)
	for tree_x in trees:
		_tree(c, tree_x, f, t)
	for pole_x in poles:
		c.draw_rect(Rect2(pole_x - 3, f - 160, 6, 160), Color("6a6a70"))
		c.draw_rect(Rect2(pole_x - 12, f - 154, 24, 3), Color("6a6a70"))
		c.draw_rect(Rect2(pole_x, f - 140, 16, 3), Color("6a6a70"))
		c.draw_rect(Rect2(pole_x + 12, f - 142, 8, 6), Color("f4f0d0") if lit else Color("8a8a90"))
		if lit:
			c.glow(Vector2(pole_x + 16, f - 136), 60.0, Color(1.0, 0.85, 0.5, 0.18 if _phase == DayPhase.Phase.TARDE else 0.32))
	# Acera, cordón amarillo y calle.
	c.draw_rect(Rect2(0, f, width, 14), SIDEWALK)
	var x := 0.0
	while x < width:
		c.draw_line(Vector2(x, f), Vector2(x, f + 14), Color(0, 0, 0, 0.12), 1.0)
		x += 40.0
	c.draw_rect(Rect2(0, f + 14, width, 4), CURB)
	c.draw_rect(Rect2(0, f + 18, width, 50), STREET)
	x = 20.0
	while x < width:
		c.draw_rect(Rect2(x, f + 40, 40, 3), Color("e8e4d8"))
		x += 110.0


func _mountains(c: VectorCanvas, base: float, color: Color, freq: float, height: float) -> void:
	var points := PackedVector2Array([Vector2(0, base + 60)])
	var x := 0.0
	while x <= width:
		points.append(Vector2(x, base - (sin(x * freq) * 0.6 + sin(x * freq * 2.7 + 1.3) * 0.4 + 1.0) * height * 0.5))
		x += 20.0
	points.append(Vector2(width, base + 60))
	c.draw_colored_polygon(points, color)


func _school_gate(c: VectorCanvas, f: float) -> void:
	# Malla del colegio y el portón por donde sale Kai.
	c.draw_rect(Rect2(0, f - 120, 150, 120), Color("c8ccd8"))
	c.draw_rect(Rect2(0, f - 124, 150, 6), Color("3a6a9a"))
	for k in 8:
		c.draw_line(Vector2(k * 20, f - 118), Vector2(k * 20, f), Color(0.2, 0.25, 0.35, 0.5), 1.0)
	c.draw_rect(Rect2(150, f - 96, 60, 96), Color("2a3a5a"))
	for k in 6:
		c.draw_rect(Rect2(154 + k * 10, f - 92, 2, 92), Color("5a6a8a"))
	c.draw_rect(Rect2(140, f - 140, 84, 18), Color("1f6f5a"))
	c.crisp_text(Vector2(140, f - 127), "COLEGIO TÉCNICO", 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 84)


func _house(c: VectorCanvas, x: float, f: float, w: float, h: float, color: Color) -> void:
	# Fachada, techo de zinc, ventana con rejas, puerta y tapia con portón.
	c.draw_rect(Rect2(x, f - h, w, h), color)
	c.draw_rect(Rect2(x, f - h, w, 6), color.darkened(0.15))
	c.shape(PackedVector2Array([Vector2(x - 8, f - h), Vector2(x + w + 8, f - h), Vector2(x + w - 6, f - h - 22), Vector2(x + 6, f - h - 22)]), Color("9aa0aa"))
	var y := f - h - 20
	while y < f - h:
		c.draw_line(Vector2(x - 4, y), Vector2(x + w + 4, y), Color(0, 0, 0, 0.15), 1.0)
		y += 5.0
	var window := Rect2(x + 12, f - h + 18, w * 0.38, h * 0.36)
	c.draw_rect(window, Color("2a3a4a"))
	for k in int(window.size.x / 6.0):
		c.draw_rect(Rect2(window.position.x + 3 + k * 6, window.position.y, 2, window.size.y), Color("2a2a30"))
	c.draw_rect(Rect2(x + w - 34, f - 60, 22, 60), color.darkened(0.35))
	c.draw_rect(Rect2(x - 4, f - 34, w + 8, 34), color.lightened(0.15))  # Tapia
	c.draw_rect(Rect2(x + w * 0.45, f - 40, 30, 40), Color("2a2a30"))  # Portón
	for k in 5:
		c.draw_rect(Rect2(x + w * 0.45 + 3 + k * 6, f - 38, 2, 38), Color("5a5a64"))


func _pulperia(c: VectorCanvas, x: float, f: float, lit: bool) -> void:
	c.draw_rect(Rect2(x, f - 110, 130, 110), Color("e8c86a"))
	c.shape(PackedVector2Array([Vector2(x - 6, f - 84), Vector2(x + 136, f - 84), Vector2(x + 126, f - 104), Vector2(x + 4, f - 104)]), Color("c0504d"))
	for k in 7:
		c.draw_rect(Rect2(x + 4 + k * 18, f - 104, 9, 20), Color("f4f0e4"))
	c.draw_rect(Rect2(x + 10, f - 136, 110, 22), Color("1f4a7a"))
	c.crisp_text(Vector2(x + 10, f - 121), "PULPERÍA LA ESQUINA", 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 110)
	c.draw_rect(Rect2(x + 14, f - 74, 102, 40), Color("2a2a30") if not lit else Color("4a3a2a"))
	for k in 6:
		c.draw_rect(Rect2(x + 18 + k * 16, f - 70, 10, 14), [Color("f2c14e"), Color("c0504d"), Color("9bbb59")][k % 3])
	c.draw_rect(Rect2(x + 10, f - 34, 110, 34), Color("8a6440"))  # Mostrador
	if lit:
		c.glow(Vector2(x + 65, f - 54), 70.0, Color(1.0, 0.85, 0.5, 0.2))


func _bus_stop(c: VectorCanvas, x: float, f: float) -> void:
	c.draw_rect(Rect2(x, f - 90, 4, 90), Color("6a6a70"))
	c.draw_rect(Rect2(x - 14, f - 104, 32, 20), Color("2a6aaa"))
	c.crisp_text(Vector2(x - 14, f - 91), "PARADA", 7, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 32)
	c.draw_rect(Rect2(x + 14, f - 22, 44, 5), Color("6a6a70"))
	c.draw_rect(Rect2(x + 18, f - 17, 3, 17), Color("6a6a70"))
	c.draw_rect(Rect2(x + 52, f - 17, 3, 17), Color("6a6a70"))


func _kai_house(c: VectorCanvas, x: float, f: float, lit: bool) -> void:
	# La casa de Kai: celeste, techo de teja, jardincito, buzón, número y la puerta (al borde derecho).
	var w := 210.0
	var h := 140.0
	c.draw_rect(Rect2(x, f - h, w, h), Color("8ac0d8"))
	c.shape(PackedVector2Array([Vector2(x - 10, f - h), Vector2(x + w + 10, f - h), Vector2(x + w - 10, f - h - 34), Vector2(x + 10, f - h - 34)]), Color("b8603a"))
	for k in 10:
		c.draw_line(Vector2(x + k * 22, f - h - 30), Vector2(x + k * 22 - 4, f - h), Color(0, 0, 0, 0.15), 1.0)
	var window := Rect2(x + 30, f - h + 30, 60, 46)
	c.draw_rect(window.grow(3), Color("f4f0e4"))
	c.draw_rect(window, Color("f6d28a") if lit else Color("3a5a7a"))
	if lit:
		c.glow(window.get_center(), 50.0, Color(1.0, 0.8, 0.45, 0.25))
	for k in 9:
		c.draw_rect(Rect2(window.position.x + 3 + k * 6.5, window.position.y, 2, window.size.y), Color("3a3a40"))
	c.draw_rect(Rect2(x + w - 50, f - 92, 40, 92), Color("6a4228"))
	c.draw_rect(Rect2(x + w - 44, f - 86, 28, 22), Color("f4e0b0") if lit else Color("8a6a4a"))
	c.draw_circle(Vector2(x + w - 16, f - 46), 2.0, Color("d8c060"))
	c.draw_rect(Rect2(x + w - 62, f - 120, 18, 10), Color("f4f0e4"))
	c.crisp_text(Vector2(x + w - 62, f - 112), "24", 7, OUTLINE, HORIZONTAL_ALIGNMENT_CENTER, 18)
	c.draw_rect(Rect2(x + 110, f - 48, 12, 10), Color("c0504d"))  # Buzón
	c.draw_rect(Rect2(x + 115, f - 38, 2, 38), Color("6a6a70"))
	for k in 6:
		c.draw_circle(Vector2(x + 12 + k * 14, f - 6), 8.0, Color("4a8a3a").darkened((k % 2) * 0.1))
		c.draw_circle(Vector2(x + 14 + k * 14, f - 12), 2.0, [Color("f2c14e"), Color("ff6ab4")][k % 2])


func _tree(c: VectorCanvas, x: float, f: float, t: float) -> void:
	c.draw_rect(Rect2(x - 5, f - 80, 10, 80), Color("5a4030"))
	var sway := sin(t * 0.9 + x) * 2.0
	for k in 5:
		var p := Vector2(x + sway + [-18.0, 16.0, 0.0, -8.0, 10.0][k], f - 100 + [6.0, 4.0, -18.0, -6.0, -10.0][k])
		c.draw_circle(p, 22.0, Color("3a7a3a").lerp(Color("5a9a4a"), k / 5.0))
