@tool
class_name Spikes
extends HitboxComponent
## Pinchos: peligro del escenario. Quitan medio cristal de integridad y devuelven al jugador al último
## suelo seguro. Como en Hollow Knight, sirven para rebotar con el ataque hacia abajo (tienen una
## zona que recibe los ataques de Kai: PlayerCombat rebota al golpearla).
## El origen es la esquina inferior izquierda, apoyada sobre el suelo. Se ven también en el editor.

@export var width := 32.0:
	set(value):
		width = maxf(value, 8.0)
		_rebuild()
@export var spike_color := Color(0.85, 0.32, 0.45)
## Dibujo en vez de los pinchos de código (el piso corrupto del cuarto viejo): dónde va su esquina de arriba a
## la izquierda (desde el origen) y a qué escala (los dibujos vienen al doble: 0,5).
@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
@export var texture_offset := Vector2.ZERO
@export var texture_scale := 0.5

const SPIKE_WIDTH := 8.0
const SPIKE_HEIGHT := 8.0

var _shape: CollisionShape2D
var _pogo: HurtboxComponent
var _pogo_shape: CollisionShape2D


func _init() -> void:
	is_hazard = true
	damage = 0.5
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0


func _ready() -> void:
	if not Engine.is_editor_hint():
		super._ready()
		# Zona de rebote: detecta los ataques de Kai (capa 4). Se crea al jugar (no queda en la escena).
		_pogo = HurtboxComponent.new()
		_pogo.name = "PogoZone"
		_pogo.collision_layer = 0
		_pogo.collision_mask = 8  # Capa 4: ataques_jugador
		_pogo_shape = CollisionShape2D.new()
		_pogo.add_child(_pogo_shape)
		add_child(_pogo)
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
	if _pogo_shape:
		var pogo_rect := RectangleShape2D.new()
		pogo_rect.size = Vector2(width, SPIKE_HEIGHT)
		_pogo_shape.shape = pogo_rect
		_pogo_shape.position = Vector2(width / 2.0, -SPIKE_HEIGHT / 2.0)
	queue_redraw()


func _draw() -> void:
	if texture:
		draw_set_transform(texture_offset, 0.0, Vector2.ONE * texture_scale)
		draw_texture(texture, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO)
		return
	var count := int(width / SPIKE_WIDTH)
	for i in count:
		var x := i * SPIKE_WIDTH
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, 0), Vector2(x + SPIKE_WIDTH / 2.0, -SPIKE_HEIGHT), Vector2(x + SPIKE_WIDTH, 0),
		]), spike_color)
		draw_line(Vector2(x + SPIKE_WIDTH / 2.0, -SPIKE_HEIGHT), Vector2(x + SPIKE_WIDTH / 2.0, -SPIKE_HEIGHT + 3.0), Color(1, 0.85, 0.9, 0.8), 1.0)
