@tool
extends Node2D
## Arte provisional de la soda estudiantil (dibujado por código hasta que Ariel la dibuje): paredes amarillas
## con azulejos, la pizarra del menú, el mostrador con la vitrina (empanadas, pan, arroz con leche), la refri de
## refrescos, mesas con bancos, un abanico de techo que gira y la radio. La puerta al patio va a la derecha.
## Es una zona social: no hay economía de comida ni hambre.

const WALL := Color("f2d27a")
const TILE := Color("e8e4d8")
const TILE_LINE := Color("c8c0b0")
const FLOOR := Color("a86a4a")
const WOOD := Color("8a5a36")
const OUTLINE := Color("2a1a10")

@export var width := 640.0
@export var floor_y := 304.0

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)


func _paint(c: VectorCanvas, t: float) -> void:
	var f := floor_y
	c.draw_rect(Rect2(0, 0, width, f), WALL)
	c.draw_rect(Rect2(0, 0, width, 28), WALL.darkened(0.15))
	# Azulejos hasta media pared.
	c.draw_rect(Rect2(0, f - 80, width, 80), TILE)
	var x := 0.0
	while x < width:
		c.draw_line(Vector2(x, f - 80), Vector2(x, f), TILE_LINE, 1.0)
		x += 16.0
	for y in [f - 64.0, f - 48.0, f - 32.0, f - 16.0]:
		c.draw_line(Vector2(0, y), Vector2(width, y), TILE_LINE, 1.0)
	c.draw_rect(Rect2(0, f - 82, width, 3), Color("c0504d"))
	c.draw_rect(Rect2(0, f, width, 60), FLOOR)
	x = 0.0
	while x < width:
		c.draw_rect(Rect2(x, f, 32, 30), FLOOR.darkened(0.08 * float(int(x / 32.0) % 2)))
		x += 32.0
	# Abanico de techo que gira.
	c.draw_line(Vector2(320, 28), Vector2(320, 44), Color("3a3a40"), 2.0)
	for k in 3:
		var angle := t * 6.0 + k * TAU / 3.0
		c.draw_line(Vector2(320, 46), Vector2(320, 46) + Vector2(cos(angle) * 26.0, sin(angle) * 4.0), Color("6a6a72"), 4.0)
	c.draw_circle(Vector2(320, 46), 4.0, Color("3a3a40"))
	# La pizarra del menú.
	var board := Rect2(60, 70, 150, 100)
	c.draw_rect(board.grow(4), WOOD)
	c.draw_rect(board, Color("2a3a2a"))
	c.crisp_text(board.position + Vector2(0, 16), "MENÚ DEL DÍA", 9, Color("f2c14e"), HORIZONTAL_ALIGNMENT_CENTER, board.size.x)
	var items := ["Casado", "Empanada", "Gallo pinto", "Fresco de cas", "Arroz con leche"]
	for k in items.size():
		c.crisp_text(board.position + Vector2(12, 34 + k * 14), "· " + items[k], 8, Color(0.95, 0.95, 0.9), HORIZONTAL_ALIGNMENT_LEFT, board.size.x)
	# Mostrador con vitrina.
	c.draw_rect(Rect2(230, f - 58, 220, 58), WOOD)
	c.draw_rect(Rect2(234, f - 54, 212, 50), WOOD.lightened(0.1))
	var glass := Rect2(244, f - 96, 190, 38)
	c.draw_rect(glass.grow(2), Color("a8b0b8"))
	c.draw_rect(glass, Color(0.75, 0.9, 1.0, 0.35))
	for k in 5:
		c.draw_circle(Vector2(262 + k * 20, f - 66), 7.0, Color("e8a050"))  # Empanadas
	for k in 3:
		c.draw_rect(Rect2(372 + k * 18, f - 76, 12, 14), Color("f4f0e4"))  # Arroz con leche
	c.draw_line(glass.position + Vector2(6, 4), glass.position + Vector2(40, 30), Color(1, 1, 1, 0.4), 2.0)
	# Refri de refrescos con luz.
	c.gradient_box(Rect2(470, f - 130, 56, 130), 3.0, Color("e8e8f0"), Color("c8ccd8"), OUTLINE, 0.8)
	c.draw_rect(Rect2(476, f - 124, 44, 80), Color(0.6, 0.85, 1.0, 0.5))
	for row in 3:
		for k in 4:
			c.draw_rect(Rect2(480 + k * 10, f - 118 + row * 26, 6, 18), [Color("c0504d"), Color("9bbb59"), Color("f2c14e"), Color("4f81bd")][(row + k) % 4])
	# Mesas con bancos.
	for table_x in [110.0, 580.0]:
		c.draw_rect(Rect2(table_x - 36, f - 34, 72, 6), WOOD)
		c.draw_rect(Rect2(table_x - 4, f - 28, 8, 28), WOOD.darkened(0.2))
		c.draw_rect(Rect2(table_x - 46, f - 16, 18, 4), WOOD.darkened(0.1))
		c.draw_rect(Rect2(table_x + 28, f - 16, 18, 4), WOOD.darkened(0.1))
	# Radio sobre una repisa.
	c.draw_rect(Rect2(250, 120, 60, 4), WOOD)
	c.draw_rect(Rect2(262, 102, 36, 18), Color("3a3a48"))
	c.draw_circle(Vector2(272, 111), 5.0, Color("6a6a72"))
	if fmod(t, 1.2) < 0.6:
		c.draw_string(ThemeDB.fallback_font, Vector2(304, 104), "♪", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("3a3a48"))
	# Puerta al patio (derecha).
	c.draw_rect(Rect2(width - 52, f - 96, 46, 96), Color("3e2a1c"))
	c.gradient_rect(Rect2(width - 48, f - 92, 38, 92), Color("9bd0e8"), Color("6a9ab8"))
	c.crisp_text(Vector2(width - 60, f - 104), "PATIO", 8, OUTLINE, HORIZONTAL_ALIGNMENT_CENTER, 60)
