@tool
class_name LazaroGate
extends StaticBody2D
## Una barrera de energía de la Estación Lázaro: bloquea el paso (un muro de luz) hasta que la partida tiene open_flag
## (p. ej. «guardian_procesamiento»); también puede cerrarse con close_flag (las rutas que se cierran en el escape).
## El origen es el piso, al centro de la barrera.

const CYAN := Color("3ef2ff")
const RED := Color("ff5a6a")

@export var open_flag: StringName = &""
@export var close_flag: StringName = &""
@export var height := 120.0

var _shape: CollisionShape2D
var _clock := 0.0


func _ready() -> void:
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, height)
	_shape.shape = rect
	_shape.position = Vector2(0, -height / 2.0)
	add_child(_shape)
	collision_layer = 1
	collision_mask = 0


func is_open() -> bool:
	if Engine.is_editor_hint():
		return false
	var state := get_node("/root/GameState")
	if close_flag != &"" and state.has_flag(close_flag):
		return false
	return open_flag != &"" and state.has_flag(open_flag)


func _process(delta: float) -> void:
	_clock += delta
	if not Engine.is_editor_hint():
		_shape.disabled = is_open()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-12, -height - 6, 24, 6), Color("dfe6f0"))
	draw_rect(Rect2(-12, 0, 24, 4), Color("dfe6f0"))
	if is_open():
		return
	var closing: bool = close_flag != &"" and not Engine.is_editor_hint() and get_node("/root/GameState").has_flag(close_flag)
	var color := RED if closing else CYAN
	draw_rect(Rect2(-6, -height, 12, height), Color(color, 0.25 + 0.1 * sin(_clock * 6.0)))
	var y := -fmod(_clock * 60.0, height)
	draw_line(Vector2(-6, y), Vector2(6, y), Color(color, 0.8), 2.0)
	draw_line(Vector2(-6, -height / 2.0 + y / 2.0), Vector2(6, -height / 2.0 + y / 2.0), Color(color, 0.5), 1.0)
