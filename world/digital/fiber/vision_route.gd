@tool
class_name VisionRoute
extends Node2D
## Un camino oculto del Bosque de Fibra que solo existe con la Visión Digital: plataformas de luz (cuerpos en la
## capa de colisión 7, «mundo digital», que DigitalWorld activa en Kai con la Visión) y su dibujo, que solo se ve
## con la Visión (grupo "digital_only"). Cada plataforma es un rectángulo local (se pisa desde arriba).

const DIGITAL_LAYER := 64  # Capa 7: mundo_digital

@export var platforms: Array[Rect2] = []

var _canvas: Node2D


func _ready() -> void:
	_canvas = _RouteCanvas.new()
	_canvas.route = self
	add_child(_canvas)
	if Engine.is_editor_hint():
		return
	_canvas.add_to_group(&"digital_only")
	_canvas.visible = get_node("/root/DigitalVision").is_active()
	var body := StaticBody2D.new()
	body.collision_layer = DIGITAL_LAYER
	body.collision_mask = 0
	for rect in platforms:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		shape.one_way_collision = true
		body.add_child(shape)
	add_child(body)


class _RouteCanvas extends Node2D:
	var route: VisionRoute
	var _clock := 0.0

	func _process(delta: float) -> void:
		_clock += delta
		queue_redraw()

	func _draw() -> void:
		for i in route.platforms.size():
			var rect: Rect2 = route.platforms[i]
			var pulse := 0.6 + 0.4 * sin(_clock * 2.5 + i)
			draw_rect(rect.grow(3.0), Color(0.24, 0.95, 1.0, 0.12 * pulse))
			draw_rect(rect, Color(0.6, 1.0, 1.0, 0.75 * pulse))
			draw_line(rect.position, Vector2(rect.end.x, rect.position.y), Color.WHITE, 1.5)
