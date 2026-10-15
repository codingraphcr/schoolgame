@tool
extends Node2D
## Arte provisional del cuarto de Kai (dibujado por código hasta que Ariel lo dibuje): la puerta, el
## ropero, la caja de juguetes de cuando era chiquito, el escritorio (la computadora es KaiComputer), los
## afiches, la ventana sobre la cama y las estrellitas pegadas en la pared que brillan de noche. Las
## estanterías, el soporte de la Nullblade, la cama y la computadora son nodos aparte (interactivos).
## Décimo: un cuarto sencillo, con cosas de niño que todavía no se van; crecerá con Kai.

const WALL := Color("9ab8d8")
const WALL_DARK := Color("86a4c4")
const CEILING := Color("7a98b8")
const BASEBOARD := Color("4a5a7a")
const FLOOR := Color("8a6440")
const FLOOR_DARK := Color("6e4e30")
const WOOD := Color("7a5236")
const WOOD_DARK := Color("4a3020")
const OUTLINE := Color("1a1424")

@export var width := 640.0
@export var floor_y := 304.0
@export var preview_phase := DayPhase.Phase.NOCHE

var _canvas: VectorCanvas
var _phase := DayPhase.Phase.NOCHE


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
	c.draw_rect(Rect2(0, 0, width, f), WALL)
	c.draw_rect(Rect2(0, 0, width, 30), CEILING)
	c.draw_rect(Rect2(0, f - 120, width, 2), WALL_DARK)
	c.draw_rect(Rect2(0, f - 10, width, 10), BASEBOARD)
	c.gradient_rect(Rect2(0, f, width, 60), FLOOR, FLOOR_DARK)
	var x := 0.0
	while x < width:
		c.draw_line(Vector2(x, f), Vector2(x, f + 60), Color(0, 0, 0, 0.18), 1.0)
		x += 48.0
	# Estrellitas que brillan en la oscuridad (de noche se notan).
	var night := _phase == DayPhase.Phase.NOCHE
	for k in 9:
		var p := Vector2(120 + k * 53.0, 46 + (k * 37 % 50))
		var color := Color(0.75, 1.0, 0.7, 0.85 if night else 0.35)
		c.draw_circle(p, 2.0, color)
		if night:
			c.glow(p, 7.0 + sin(t * 1.5 + k) * 1.5, Color(0.75, 1.0, 0.7, 0.25), 4)
	# Puerta al pasillo.
	c.draw_rect(Rect2(10, f - 100, 42, 100), WOOD_DARK)
	c.gradient_rect(Rect2(14, f - 96, 34, 96), Color("9a6a42"), Color("7a5232"))
	c.draw_circle(Vector2(44, f - 48), 2.0, Color("d8c060"))
	# Ropero.
	c.gradient_box(Rect2(64, f - 116, 56, 116), 3.0, Color("a07850"), Color("805a38"), OUTLINE)
	c.draw_line(Vector2(92, f - 112), Vector2(92, f - 4), WOOD_DARK, 1.5)
	c.draw_circle(Vector2(88, f - 60), 1.5, Color("d8c060"))
	c.draw_circle(Vector2(96, f - 60), 1.5, Color("d8c060"))
	# Caja de juguetes de chiquito: un carrito, una pelota, un dinosaurio.
	c.draw_rect(Rect2(126, f - 22, 34, 22), Color("4f81bd"))
	c.draw_rect(Rect2(126, f - 22, 34, 4), Color("3a6aa0"))
	c.draw_circle(Vector2(134, f - 26), 5.0, Color("e84a4a"))
	c.draw_rect(Rect2(142, f - 30, 12, 8), Color("9bbb59"))
	c.draw_circle(Vector2(152, f - 32), 3.0, Color("9bbb59"))
	# Escritorio con silla, lámpara y cuadernos (la computadora va encima: KaiComputer).
	c.draw_rect(Rect2(170, f - 42, 104, 6), WOOD)
	c.draw_rect(Rect2(174, f - 36, 6, 36), WOOD_DARK)
	c.draw_rect(Rect2(264, f - 36, 6, 36), WOOD_DARK)
	c.draw_rect(Rect2(232, f - 36, 34, 22), WOOD)
	c.draw_rect(Rect2(196, f - 30, 22, 4), Color("3a3a48"))  # Silla
	c.draw_rect(Rect2(214, f - 56, 4, 56), Color("3a3a48"))
	c.draw_rect(Rect2(176, f - 48, 14, 6), Color("f2c14e"))  # Cuadernos
	c.draw_rect(Rect2(178, f - 52, 12, 4), Color("c0504d"))
	c.draw_line(Vector2(258, f - 42), Vector2(250, f - 64), Color("3a3a48"), 2.0)  # Lámpara
	c.shape(PackedVector2Array([Vector2(242, f - 64), Vector2(258, f - 64), Vector2(254, f - 72), Vector2(246, f - 72)]), Color("3ef2ff").darkened(0.3))
	if night:
		c.glow(Vector2(250, f - 58), 40.0, Color(1.0, 0.9, 0.6, 0.18))
	# Afiches (inventados): robótica, el sistema solar y un juego.
	_poster(c, Rect2(178, 96, 40, 52), Color("1f3a6a"), "ROBÓTICA")
	_poster(c, Rect2(226, 104, 44, 36), Color("101a3a"), "")
	for k in 4:
		c.draw_circle(Vector2(234 + k * 10, 122 + (k % 2) * 4), 2.0 + k * 0.6, [Color("f2c14e"), Color("c0504d"), Color("4f81bd"), Color("e8a060")][k])
	# Ventana sobre la cama.
	var window := Rect2(500, 100, 92, 70)
	c.draw_rect(window.grow(4), Color("f4f0e4"))
	c.gradient_rect(window, DayPhase.sky_top(_phase), DayPhase.sky_bottom(_phase))
	if night:
		c.draw_circle(window.position + Vector2(68, 20), 8.0, Color("f4f0d0"))
		c.draw_circle(window.position + Vector2(72, 17), 7.0, DayPhase.sky_top(_phase))
	c.draw_line(Vector2(window.get_center().x, window.position.y), Vector2(window.get_center().x, window.end.y), Color("f4f0e4"), 3.0)
	c.draw_rect(Rect2(492, 92, 108, 4), WOOD_DARK)
	# Alfombra.
	c.draw_rect(Rect2(300, f - 2, 150, 5), Color("3ef2ff").darkened(0.45))


func _poster(c: VectorCanvas, rect: Rect2, color: Color, text: String) -> void:
	c.draw_rect(rect.grow(1), OUTLINE)
	c.draw_rect(rect, color)
	if not text.is_empty():
		c.draw_rect(Rect2(rect.position + Vector2(rect.size.x / 2.0 - 8, 10), Vector2(16, 18)), Color("9aa6b8"))
		c.draw_rect(Rect2(rect.position + Vector2(rect.size.x / 2.0 - 5, 14), Vector2(3, 3)), Color("3ef2ff"))
		c.draw_rect(Rect2(rect.position + Vector2(rect.size.x / 2.0 + 2, 14), Vector2(3, 3)), Color("3ef2ff"))
		c.crisp_text(rect.position + Vector2(0, rect.size.y - 8), text, 6, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
