@tool
class_name TrapAd
extends HitboxComponent
## Anuncio trampa ("¡DESCARGAR GRATIS!"): tocarlo es como pisar pinchos (1 máscara y vuelta al
## último suelo seguro). Enseña a no hacer clic en botones de descarga sospechosos.
## El origen es la esquina inferior izquierda, apoyada en el suelo. Se ve también en el editor.

@export var size := Vector2(64, 14):
	set(value):
		size = value.max(Vector2(16, 8))
		_rebuild()
@export var label := "¡DESCARGAR GRATIS!":
	set(value):
		label = value
		if _canvas:
			_canvas.queue_redraw()
@export var button_color := Color("2fbf5a")

var _canvas: VectorCanvas
var _shape: CollisionShape2D


func _init() -> void:
	is_hazard = true
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0


func _ready() -> void:
	if not Engine.is_editor_hint():
		super._ready()
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape == null:
		_shape = get_node_or_null("Shape") as CollisionShape2D
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.name = "Shape"
		add_child(_shape)
	var rect := RectangleShape2D.new()
	# Un poco más pequeña que el dibujo: rozar el borde no castiga.
	rect.size = Vector2(size.x - 4.0, size.y - 3.0)
	_shape.shape = rect
	_shape.position = Vector2(size.x / 2.0, -(size.y - 3.0) / 2.0)
	if _canvas == null:
		_canvas = VectorCanvas.new()
		_canvas.painter = _paint
		_canvas.animated = true
		add_child(_canvas)
	_canvas.queue_redraw()


func _paint(c: VectorCanvas, t: float) -> void:
	var rect := Rect2(0, -size.y, size.x, size.y)
	var flash := 0.5 + 0.5 * sin(t * 8.0)
	c.glow(rect.get_center(), size.x * 0.6, Color(1.0, 0.3, 0.5, 0.18 + 0.12 * flash))
	c.gradient_box(rect, 3.0, button_color.lightened(0.25 * flash), button_color.darkened(0.25), Color("0a0d1c"), 1.0)
	c.crisp_text(Vector2(0, -size.y / 2.0 + 2.5), label, 5, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x)
