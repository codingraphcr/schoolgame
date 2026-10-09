@tool
class_name Spikes
extends HitboxComponent
## Pinchos: peligro del escenario. Quitan medio cristal de integridad y devuelven al jugador al último
## suelo seguro.
## El origen es la esquina inferior izquierda, apoyada sobre el suelo. Se ven también en el editor.

@export var width := 32.0:
	set(value):
		width = maxf(value, 8.0)
		_rebuild()
@export var spike_color := Color(0.85, 0.32, 0.45)

const SPIKE_WIDTH := 8.0
const SPIKE_HEIGHT := 8.0

var _shape: CollisionShape2D


func _init() -> void:
	is_hazard = true
	damage = 0.5
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
	# Un poco más pequeño que el dibujo: rozar la punta no castiga.
	rect.size = Vector2(width - 4.0, SPIKE_HEIGHT - 2.0)
	_shape.shape = rect
	_shape.position = Vector2(width / 2.0, -(SPIKE_HEIGHT - 2.0) / 2.0)
	queue_redraw()


func _draw() -> void:
	var count := int(width / SPIKE_WIDTH)
	for i in count:
		var x := i * SPIKE_WIDTH
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, 0), Vector2(x + SPIKE_WIDTH / 2.0, -SPIKE_HEIGHT), Vector2(x + SPIKE_WIDTH, 0),
		]), spike_color)
		draw_line(Vector2(x + SPIKE_WIDTH / 2.0, -SPIKE_HEIGHT), Vector2(x + SPIKE_WIDTH / 2.0, -SPIKE_HEIGHT + 3.0), Color(1, 0.85, 0.9, 0.8), 1.0)
