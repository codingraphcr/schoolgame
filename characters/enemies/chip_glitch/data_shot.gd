class_name DataShot
extends HitboxComponent
## Disparo digital de Chip: un rombo de datos que vuela en línea recta. Antes de salir parpadea
## warning segundos en su lugar (aviso). Quita medio cristal y desaparece al tocar a Kai, al salir
## de la arena o a los LIFETIME segundos.

const CYAN := Color("5ad8ff")
const LIFETIME := 4.0

var velocity := Vector2.ZERO
var size := 10.0
var warning := 0.2
var _time := 0.0


func _init() -> void:
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0
	damage = 1.0
	threat_type = &"malware"
	knockback_force = 140.0
	active = false
	add_to_group(&"boss_attack")


func _ready() -> void:
	super()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size * 0.6
	shape.shape = circle
	add_child(shape)
	z_index = 5
	hit_dealt.connect(func(_hurtbox: Node2D, _hit: HitData) -> void: queue_free())


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time < warning:
		return
	active = true
	global_position += velocity * delta
	if _time >= LIFETIME or absf(global_position.x) > 10000.0:
		queue_free()


func _draw() -> void:
	var r := size
	if _time < warning and int(_time / 0.06) % 2 == 0:
		draw_circle(Vector2.ZERO, r * 1.4, Color(CYAN, 0.25))
	var points := PackedVector2Array([Vector2(r, 0), Vector2(0, r * 0.6), Vector2(-r, 0), Vector2(0, -r * 0.6)])
	draw_colored_polygon(points, Color(CYAN, 0.85))
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 1.0)
	if _time >= warning:
		var back := -velocity.normalized() * r * 1.6
		draw_line(Vector2.ZERO, back, Color(CYAN, 0.4), 2.0)
