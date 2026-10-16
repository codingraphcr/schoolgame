@tool
extends Node2D
## Arte provisional del patio del colegio (dibujado por código hasta que Ariel lo dibuje): el punto de encuentro.
## Al fondo, la fachada del colegio (dos pisos con ventanas y el mural de la especialidad); el corredor techado
## con columnas que lleva a las escaleras de la entrada; el piso de cemento con jardineras, almendros con su
## sombra, bancas, el bebedero, el asta con la bandera y la cancha multiuso. A la izquierda, la puerta de la
## soda. El cielo sigue el momento del día (DayPhase).

const WALL := Color("d8c8a8")
const WALL_DARK := Color("b8a888")
const WINDOW := Color("6a8ab8")
const CONCRETE := Color("b8b4ac")
const CONCRETE_LINE := Color("9c988f")
const GRASS := Color("5a9a4a")
const WOOD := Color("8a5a36")
const ROOF := Color("8a3a2a")
const OUTLINE := Color("2a1a10")

@export var width := 1500.0
@export var floor_y := 304.0
@export var preview_phase := DayPhase.Phase.DIA

var _canvas: VectorCanvas
var _phase := DayPhase.Phase.DIA


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
	c.gradient_rect(Rect2(0, 0, width, f), DayPhase.sky_top(_phase), DayPhase.sky_bottom(_phase))
	# La fachada del colegio al fondo (dos pisos).
	c.draw_rect(Rect2(0, 60, width, f - 60), WALL)
	c.draw_rect(Rect2(0, 60, width, 8), WALL_DARK)
	c.draw_rect(Rect2(0, 172, width, 6), WALL_DARK)
	var x := 40.0
	while x < width - 40.0:
		if x < 560.0 or x > 820.0:  # El mural ocupa el medio.
			for row in 2:
				var window := Rect2(x, 84 + row * 104, 44, 52)
				c.draw_rect(window.grow(2), Color("f4f0e4"))
				c.gradient_rect(window, WINDOW.lightened(0.15), WINDOW)
				c.draw_line(Vector2(window.get_center().x, window.position.y), Vector2(window.get_center().x, window.end.y), Color("f4f0e4"), 2.0)
		x += 96.0
	_mural(c, Rect2(580, 92, 220, 150))
	# Corredor techado hacia la entrada (derecha) con columnas.
	c.draw_rect(Rect2(1180, f - 120, width - 1180, 10), ROOF)
	c.draw_rect(Rect2(1180, f - 112, width - 1180, 4), ROOF.darkened(0.3))
	for col_x in [1200.0, 1330.0, 1460.0]:
		c.draw_rect(Rect2(col_x - 5, f - 110, 10, 110), Color("e8e0d0"))
	# Piso de cemento y jardineras.
	c.draw_rect(Rect2(0, f, width, 60), CONCRETE)
	x = 0.0
	while x < width:
		c.draw_line(Vector2(x, f), Vector2(x, f + 60), CONCRETE_LINE, 1.0)
		x += 64.0
	c.draw_line(Vector2(0, f + 20), Vector2(width, f + 20), CONCRETE_LINE, 1.0)
	for planter in [Rect2(240, f - 14, 150, 14), Rect2(880, f - 14, 170, 14)]:
		c.draw_rect(planter, Color("8a6440"))
		c.draw_rect(Rect2(planter.position + Vector2(3, 2), Vector2(planter.size.x - 6, 6)), GRASS)
	# Almendros (copa ancha en capas) con sombra.
	for tree_x in [315.0, 965.0]:
		_almond_tree(c, tree_x, f, t)
	# Bancas.
	for bench_x in [180.0, 470.0, 760.0, 1100.0]:
		_bench(c, bench_x, f)
	# Bebedero.
	c.draw_rect(Rect2(1040, f - 34, 22, 34), Color("a8b0b8"))
	c.draw_rect(Rect2(1036, f - 38, 30, 6), Color("c8d0d8"))
	c.draw_line(Vector2(1051, f - 38), Vector2(1056, f - 44), Color("9bd0e8"), 2.0)
	# Asta con la bandera (franjas azul, blanco, rojo, blanco, azul) que ondea.
	c.draw_rect(Rect2(1146, f - 190, 4, 190), Color("c8c8d0"))
	var wave := sin(t * 2.2) * 3.0
	var stripes: Array[Color] = [Color("1a3a8a"), Color.WHITE, Color("c8202a"), Color("c8202a"), Color.WHITE, Color("1a3a8a")]
	for k in stripes.size():
		var y := f - 186 + k * 6.0
		c.shape(PackedVector2Array([Vector2(1150, y), Vector2(1196, y + wave * 0.4), Vector2(1196, y + 6 + wave * 0.4), Vector2(1150, y + 6)]), stripes[k], OUTLINE, 0.0)
	# La puerta de la soda (izquierda) con su cartel.
	c.draw_rect(Rect2(8, f - 96, 48, 96), Color("3e2a1c"))
	c.gradient_rect(Rect2(12, f - 92, 40, 92), Color("c8863a"), Color("a86a2a"))
	c.draw_rect(Rect2(4, f - 122, 64, 18), Color("c0504d"))
	c.crisp_text(Vector2(4, f - 109), "SODA", 9, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 64)


func _mural(c: VectorCanvas, rect: Rect2) -> void:
	c.draw_rect(rect.grow(3), Color("3a4a6a"))
	c.gradient_rect(rect, Color("1f3a6a"), Color("102040"))
	# Un candado y un circuito: la especialidad de ciberseguridad.
	var center := rect.get_center() + Vector2(0, -6)
	c.draw_arc(center + Vector2(0, -22), 16.0, PI, TAU, 16, Color("f2c14e"), 5.0)
	c.draw_rect(Rect2(center + Vector2(-24, -22), Vector2(48, 40)), Color("f2c14e"))
	c.draw_circle(center + Vector2(0, -6), 5.0, Color("1f3a6a"))
	c.draw_rect(Rect2(center + Vector2(-2, -4), Vector2(4, 12)), Color("1f3a6a"))
	for k in 4:
		var y := rect.position.y + 24 + k * 30.0
		c.draw_line(Vector2(rect.position.x + 8, y), Vector2(rect.position.x + 50, y), Color("3ef2ff"), 2.0)
		c.draw_circle(Vector2(rect.position.x + 50, y), 3.0, Color("3ef2ff"))
		c.draw_line(Vector2(rect.end.x - 8, y + 10), Vector2(rect.end.x - 50, y + 10), Color("9bbb59"), 2.0)
		c.draw_circle(Vector2(rect.end.x - 50, y + 10), 3.0, Color("9bbb59"))
	c.crisp_text(Vector2(rect.position.x, rect.end.y - 10), "CIBERSEGURIDAD", 9, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)


func _almond_tree(c: VectorCanvas, x: float, f: float, t: float) -> void:
	c.draw_rect(Rect2(x - 70, f - 4, 140, 6), Color(0, 0, 0, 0.12))  # Sombra
	c.draw_rect(Rect2(x - 6, f - 120, 12, 120), Color("5a4030"))
	var sway := sin(t * 0.8 + x) * 2.0
	for layer in 3:
		var y := f - 150 + layer * 26.0
		var half := 90.0 - layer * 18.0
		c.gradient_box(Rect2(x - half + sway, y, half * 2.0, 24), 10.0, Color("4a8a3a").lightened(layer * 0.05), Color("3a6a2a"), OUTLINE, 0.0)
	# Algunas hojas rojizas (los almendros cambian de color).
	for k in 4:
		c.draw_circle(Vector2(x - 50 + k * 32 + sway, f - 136 + (k % 2) * 14), 4.0, Color("c8603a"))


func _bench(c: VectorCanvas, x: float, f: float) -> void:
	c.draw_rect(Rect2(x - 34, f - 22, 68, 6), WOOD)
	c.draw_rect(Rect2(x - 34, f - 36, 68, 5), WOOD)
	c.draw_rect(Rect2(x - 30, f - 16, 4, 16), Color("3a3a40"))
	c.draw_rect(Rect2(x + 26, f - 16, 4, 16), Color("3a3a40"))
	c.draw_rect(Rect2(x - 30, f - 36, 3, 20), Color("3a3a40"))
	c.draw_rect(Rect2(x + 27, f - 36, 3, 20), Color("3a3a40"))
