@tool
class_name PogoNode
extends HurtboxComponent
## Nodo de rebote: un cristal de datos que flota. No hace daño ni se rompe; sirve para rebotar con
## el ataque hacia abajo (abajo + J en el aire), como las estructuras de Hollow Knight. Sirve para
## cruzar huecos o subir rebotando de un nodo a otro. Al golpearlo destella y se aplasta un instante.
## Se ve también en el editor.

const VIOLET := Color("8a5cff")
const CYAN := Color("3ef2ff")
const LIGHT := Color("e9e1ff")
const DARK := Color("1a0f3a")
## Radio del cristal (px).
const SIZE := 7.0

var _time := 0.0
var _flash := 0.0


func _init() -> void:
	collision_layer = 0
	collision_mask = 8  # Capa 4: ataques_jugador


func _ready() -> void:
	if get_node_or_null("Shape") == null:
		var shape := CollisionShape2D.new()
		shape.name = "Shape"
		var circle := CircleShape2D.new()
		# Un poco más grande que el dibujo: el rebote perdona un poco.
		circle.radius = SIZE + 3.0
		shape.shape = circle
		add_child(shape)
	if Engine.is_editor_hint():
		return
	super._ready()
	hit_received.connect(_on_hit)


func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		super._physics_process(delta)


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(_flash - delta * 4.0, 0.0)
	queue_redraw()


func _on_hit(_hit: HitData) -> void:
	_flash = 1.0
	RingBurst.spawn(get_parent(), global_position, CYAN)


func _draw() -> void:
	var bob := sin(_time * 2.2) * 1.5
	var squash := 1.0 - 0.35 * _flash
	var center := Vector2(0, bob + (SIZE * (1.0 - squash)))
	# Brillo alrededor y anillo de datos que gira.
	draw_circle(center, SIZE * 2.0, Color(VIOLET, 0.12 + 0.25 * _flash))
	draw_arc(center, SIZE + 4.0, _time * 1.5, _time * 1.5 + PI * 1.3, 16, Color(CYAN, 0.55), 1.0)
	draw_arc(center, SIZE + 4.0, _time * 1.5 + PI, _time * 1.5 + PI * 1.4, 8, Color(LIGHT, 0.7), 1.0)
	# Cristal: rombo con el borde oscuro, cara violeta y un brillo.
	var w := SIZE * (2.0 - squash)
	var h := SIZE * squash * 1.3
	var outer := PackedVector2Array([center + Vector2(0, -h - 1), center + Vector2(w + 1, 0), center + Vector2(0, h + 1), center + Vector2(-w - 1, 0)])
	var inner := PackedVector2Array([center + Vector2(0, -h), center + Vector2(w, 0), center + Vector2(0, h), center + Vector2(-w, 0)])
	draw_colored_polygon(outer, DARK)
	draw_colored_polygon(inner, VIOLET.lerp(LIGHT, _flash))
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -h), center + Vector2(w, 0), center]), Color(CYAN, 0.6))
	draw_rect(Rect2(center + Vector2(-w * 0.45, -h * 0.4), Vector2(2, 2)), LIGHT)
