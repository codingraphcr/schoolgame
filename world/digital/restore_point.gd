@tool
class_name RestorePoint
extends Area2D
## Punto de restauración (como el de Windows): al pasar Kai, pasa a ser el punto de control de la
## sala y, si muere, reaparece aquí en vez de al principio. No cura. Sirve para niveles largos.
## El origen es la base, apoyada en el suelo. Se ve también en el editor.

const CYAN := Color("3ef2ff")
const DIM := Color(0.45, 0.55, 0.75)

var active := false

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2  # Capa del jugador
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 48)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	var room := _room()
	if not body is Player or room == null or room.checkpoint == self:
		return
	room.checkpoint = self
	active = true
	get_tree().call_group(&"toast", &"show_message", "Punto de restauración creado", 2.0)


func _room() -> Room:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node as Room


func _paint(c: VectorCanvas, t: float) -> void:
	var color := CYAN if active else DIM
	var pulse := 0.5 + 0.5 * sin(t * (4.0 if active else 1.5))
	var icon := Vector2(0, -30)
	c.glow(icon, 16.0, Color(color, (0.25 if active else 0.08) + 0.1 * pulse))
	# Poste y base.
	c.draw_rect(Rect2(-1, -20, 2, 20), Color(color, 0.6))
	c.gradient_box(Rect2(-8, -3, 16, 3), 1.0, color.lightened(0.2), color.darkened(0.4), Color("0a0d1c"), 0.6)
	# Ícono: flecha circular de "restaurar".
	c.draw_arc(icon, 7.0, deg_to_rad(-60), deg_to_rad(230), 16, color, 1.6, true)
	var tip := icon + Vector2.from_angle(deg_to_rad(-60)) * 7.0
	c.shape(PackedVector2Array([tip + Vector2(-3.5, -1.5), tip + Vector2(2.5, -3.0), tip + Vector2(1.0, 3.0)]), color, color, 0.5)
	c.crisp_text(Vector2(-30, -44), "RESTAURAR" if not active else "GUARDADO", 4, Color(color, 0.7 + 0.3 * pulse), HORIZONTAL_ALIGNMENT_CENTER, 60)
