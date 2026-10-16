@tool
extends Node2D
## Arte provisional de la tienda de la soda (dibujado por código hasta que Ariel la dibuje): un cuartito al lado de la
## soda, con paredes moradas, estantes con frascos de energía, cristales de vida, piedras de afilar, mapas enrollados y
## un afiche «¡DOBLE SALTO!», el mostrador con una caja registradora y un abanico. La puerta al patio va a la izquierda.

const WALL := Color("5a4a7a")
const WALL_DARK := Color("473a63")
const FLOOR := Color("6a4a3a")
const WOOD := Color("8a5a36")
const OUTLINE := Color("1a1424")
const CYAN := Color("3ef2ff")
const VIOLET := Color("b46bff")

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
	var x := 0.0
	while x < width:
		c.draw_rect(Rect2(x, 0, 16, f), WALL_DARK)
		x += 48.0
	c.draw_rect(Rect2(0, f - 40, width, 40), WALL_DARK.darkened(0.2))
	c.draw_rect(Rect2(0, f, width, 60), FLOOR)
	x = 0.0
	while x < width:
		c.draw_line(Vector2(x, f), Vector2(x, f + 60), FLOOR.darkened(0.2), 1.0)
		x += 40.0
	# Rótulo de la tienda.
	var sign_rect := Rect2(220, 34, 200, 30)
	c.draw_rect(sign_rect.grow(2), OUTLINE)
	c.draw_rect(sign_rect, Color("6a4a8a"))
	c.crisp_text(sign_rect.position + Vector2(0, 20), "TIENDA DE LA SODA", 11, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, sign_rect.size.x)
	# Estantes con mercadería.
	for shelf_y in [110.0, 160.0, 210.0]:
		c.draw_rect(Rect2(200, shelf_y, 240, 6), WOOD)
	for k in 5:
		var glow := 0.6 + 0.4 * sin(t * 2.0 + k)
		# Frascos de energía (violeta) y cristales de vida (celeste).
		c.draw_rect(Rect2(212 + k * 46, 90, 12, 20), Color(VIOLET, 0.5 + 0.3 * glow))
		c.draw_rect(Rect2(214 + k * 46, 86, 8, 4), Color("3a3048"))
		c.shape(PackedVector2Array([Vector2(236 + k * 46, 140), Vector2(242 + k * 46, 150), Vector2(236 + k * 46, 160), Vector2(230 + k * 46, 150)]),
			Color(CYAN, 0.5 + 0.3 * glow), OUTLINE, 0.6)
	for k in 4:
		c.draw_rect(Rect2(214 + k * 56, 196, 22, 14), Color("8a8a96"))  # Piedras de afilar
		c.draw_rect(Rect2(242 + k * 56, 190, 8, 20), Color("e8dcc0"))   # Mapas enrollados
		c.draw_line(Vector2(242 + k * 56, 196), Vector2(250 + k * 56, 196), Color("c0504d"), 1.0)
	# Afiche del doble salto.
	var poster := Rect2(480, 90, 90, 110)
	c.draw_rect(poster, Color("f4f0e4"))
	c.draw_rect(poster, OUTLINE, false, 1.0)
	c.crisp_text(poster.position + Vector2(0, 16), "¡DOBLE", 9, Color("c0504d"), HORIZONTAL_ALIGNMENT_CENTER, poster.size.x)
	c.crisp_text(poster.position + Vector2(0, 28), "SALTO!", 9, Color("c0504d"), HORIZONTAL_ALIGNMENT_CENTER, poster.size.x)
	var hop := absf(sin(t * 2.5)) * 18.0
	c.draw_circle(poster.position + Vector2(45, 82 - hop), 6.0, Color("4f81bd"))
	c.draw_line(poster.position + Vector2(36, 100), poster.position + Vector2(54, 100), OUTLINE, 1.0)
	c.crisp_text(poster.position + Vector2(0, 108), "Pregunte", 7, Color("6a6a72"), HORIZONTAL_ALIGNMENT_CENTER, poster.size.x)
	# Mostrador con caja registradora.
	c.draw_rect(Rect2(250, f - 56, 200, 56), WOOD)
	c.draw_rect(Rect2(254, f - 52, 192, 48), WOOD.lightened(0.1))
	c.draw_rect(Rect2(400, f - 76, 36, 20), Color("4a4a56"))
	c.draw_rect(Rect2(404, f - 72, 16, 8), Color("7ee08a"))
	# Abanico.
	c.draw_line(Vector2(320, 0), Vector2(320, 14), Color("3a3a40"), 2.0)
	for k in 3:
		var angle := t * 6.0 + k * TAU / 3.0
		c.draw_line(Vector2(320, 16), Vector2(320, 16) + Vector2(cos(angle) * 24.0, sin(angle) * 4.0), Color("6a6a72"), 4.0)
	# Puerta al patio (izquierda).
	c.draw_rect(Rect2(36, f - 96, 48, 96), Color("3e2a1c"))
	c.gradient_rect(Rect2(40, f - 92, 40, 92), Color("9bd0e8"), Color("6a9ab8"))
	c.crisp_text(Vector2(28, f - 104), "PATIO", 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 64)
