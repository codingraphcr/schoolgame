@tool
extends Node2D
## Arte provisional del pasillo viejo (H5), dibujado por código hasta que Ariel lo dibuje: cajas
## de cartón apiladas, sillas viejas, telarañas en las esquinas, cinta de «NO PASAR» en la puerta
## del fondo y el cartel apagado «LAB 2». Las posiciones se ajustan en el Inspector. Se ve también
## en el editor. La puerta se ve entreabierta (y sin cinta) desde que la misión llega a open_step.

const CARDBOARD := Color("6b5236")
const CARDBOARD_DARK := Color("4a3826")
const TAPE := Color("d9b43a")
const WEB := Color(0.85, 0.88, 1.0, 0.35)

## Pilas de cajas: x del centro y cuántas cajas (de abajo hacia arriba).
@export var box_stacks: Array[Vector2] = [Vector2(220, 3), Vector2(252, 1), Vector2(610, 2)]
@export var chairs: Array[float] = [330.0, 690.0]
@export var webs: Array[Vector2] = [Vector2(0, 48), Vector2(560, 48)]
## Puerta del fondo (centro del marco, al nivel del suelo).
@export var door_center := Vector2(900, 304)
@export var floor_y := 304.0
@export var open_quest: StringName = &"cuarto_viejo"
## Paso desde el que la puerta está abierta.
@export var open_step: StringName = &"explorar_cuarto"

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	add_child(_canvas)
	if not Engine.is_editor_hint():
		get_node("/root/GameState").quest_step_changed.connect(func(_quest: StringName) -> void: _canvas.queue_redraw())


func is_door_open() -> bool:
	if Engine.is_editor_hint() or open_quest == &"":
		return false
	return get_node("/root/GameState").has_reached_step(open_quest, open_step)


func _paint(c: VectorCanvas, _t: float) -> void:
	for stack in box_stacks:
		for i in int(stack.y):
			var w := 30.0 - (i % 2) * 4.0
			var rect := Rect2(stack.x - w / 2.0 + (i % 2) * 3.0, floor_y - 22.0 * (i + 1), w, 22.0)
			c.gradient_box(rect, 1.0, CARDBOARD, CARDBOARD_DARK, VectorCanvas.OUTLINE, 0.8)
			c.draw_line(Vector2(rect.position.x + 2, rect.position.y + 6), Vector2(rect.end.x - 2, rect.position.y + 6), Color(TAPE, 0.5), 1.0)
	for x in chairs:
		_paint_chair(c, x)
	for corner in webs:
		_paint_web(c, corner)
	_paint_door(c)


func _paint_chair(c: VectorCanvas, x: float) -> void:
	var color := Color("3a4258")
	c.draw_rect(Rect2(x - 9, floor_y - 16, 18, 3), color)
	c.draw_rect(Rect2(x + 6, floor_y - 30, 3, 17), color)
	c.draw_line(Vector2(x - 8, floor_y - 13), Vector2(x - 8, floor_y), color, 2.0)
	c.draw_line(Vector2(x + 7, floor_y - 13), Vector2(x + 7, floor_y), color, 2.0)


func _paint_web(c: VectorCanvas, corner: Vector2) -> void:
	for i in 4:
		var r := 8.0 + i * 7.0
		c.draw_arc(corner, r, 0.0, PI / 2.0, 8, WEB, 0.6, true)
	for a in [0.15, 0.55, 0.95, 1.35]:
		c.draw_line(corner, corner + Vector2.from_angle(a) * 32.0, WEB, 0.6, true)


func _paint_door(c: VectorCanvas) -> void:
	var frame := Rect2(door_center.x - 20, door_center.y - 56, 40, 56)
	c.gradient_box(frame.grow(3), 1.0, Color("2a3142"), Color("1a1f2c"))
	if is_door_open():
		# Entreabierta: adentro, oscuridad; la hoja se ve de canto.
		c.draw_rect(frame, Color("05070d"))
		c.gradient_box(Rect2(frame.position.x, frame.position.y, 9, frame.size.y), 1.0, Color("3b4560"), Color("262d3e"))
	else:
		c.gradient_box(frame, 1.0, Color("3b4560"), Color("262d3e"))
		c.draw_rect(Rect2(frame.end.x - 8, frame.get_center().y, 3, 3), Color("9aa3b8"))
	# Cartel apagado.
	var sign_rect := Rect2(door_center.x - 18, frame.position.y - 16, 36, 10)
	c.gradient_box(sign_rect, 1.0, Color("1c2230"), Color("141925"), Color("3a4560"), 0.6)
	c.crisp_text(sign_rect.position + Vector2(0, 8), "LAB 2", 6, Color("4f5f80"), HORIZONTAL_ALIGNMENT_CENTER, sign_rect.size.x)
	# Cinta cruzada (cortada y colgando si la puerta ya se abrió).
	if is_door_open():
		for k in 2:
			var top := frame.position + Vector2(-6, 10 + k * 22)
			c.draw_line(top, top + Vector2(3, 18), TAPE, 3.0)
		return
	for k in 2:
		var from := frame.position + Vector2(-6, 10 + k * 22)
		var to := Vector2(frame.end.x + 6, frame.position.y + 30 + k * 18)
		c.draw_line(from, to, TAPE, 3.0)
		for s in 4:
			var p := from.lerp(to, (s + 0.5) / 4.0)
			c.draw_line(p - Vector2(2, 1), p + Vector2(2, 1), Color.BLACK, 1.5)
