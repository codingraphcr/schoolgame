@tool
class_name ArenaBarrier
extends StaticBody2D
## Barrera de combate (un pequeño firewall): cierra la zona mientras dura una pelea.
## Apagada no choca ni se ve. El origen es la base, apoyada en el suelo.

const CYAN := Color("3ef2ff")

@export var height := 160.0:
	set(value):
		height = value
		if _canvas:
			_canvas.queue_redraw()
@export var active := false:
	set(value):
		active = value
		_refresh()

var _shape: CollisionShape2D
var _canvas: VectorCanvas
var _strength := 0.0


func _ready() -> void:
	collision_layer = 1  # Mundo: detiene a Kai y a los enemigos
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8, height)
	_shape.shape = rect
	_shape.position = Vector2(0, -height / 2.0)
	add_child(_shape)
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)
	_strength = 1.0 if active else 0.0
	_refresh()


func _refresh() -> void:
	if _shape == null:
		return
	_shape.set_deferred("disabled", not active)
	if Engine.is_editor_hint() or not is_inside_tree():
		_strength = 1.0 if active else 0.0
		return
	create_tween().tween_property(self, "_strength", 1.0 if active else 0.0, 0.25)


func _paint(c: VectorCanvas, t: float) -> void:
	var strength := 0.35 if Engine.is_editor_hint() else _strength
	if strength <= 0.01:
		return
	c.glow(Vector2(0, -height / 2.0), 24.0, Color(CYAN, 0.15 * strength))
	for i in 3:
		var x := (i - 1) * 3.0
		var alpha := (0.35 + 0.35 * sin(t * 6.0 + i)) * strength
		c.draw_line(Vector2(x, 0), Vector2(x, -height), Color(CYAN, alpha), 1.0)
	# Hexágonos que suben.
	for i in 4:
		var y := -fmod(t * 40.0 + i * height / 4.0, height)
		c.draw_arc(Vector2(0, y), 3.0, 0.0, TAU, 6, Color(CYAN, 0.8 * strength), 1.0)
