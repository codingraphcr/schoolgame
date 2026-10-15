class_name DataShot
extends HitboxComponent
## Proyectil del jefe doble: una cuchilla de energía de Glitch (Lanzamiento de fragmentos, rosa y
## alargada) o un rombo de datos. Antes de salir parpadea warning segundos en su lugar (aviso).
## Quita medio cristal y desaparece al tocar a Kai, al salir de la arena o a los LIFETIME segundos.

const LIFETIME := 4.0

var velocity := Vector2.ZERO
var size := 10.0
var warning := 0.2
var color := SiblingArt.CHIP
## true: cuchilla alargada que apunta hacia donde va (los fragmentos de Glitch).
var blade := false
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


func _physics_process(real_delta: float) -> void:
	var delta := CombatClock.scaled(real_delta)  # El Dominio Nulo lo ralentiza.
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
		draw_circle(Vector2.ZERO, r * 1.4, Color(color, 0.25))
	draw_set_transform(Vector2.ZERO, velocity.angle() if blade else 0.0)
	var points := PackedVector2Array([Vector2(r * 1.3, 0), Vector2(-r * 0.2, r * 0.35), Vector2(-r, 0), Vector2(-r * 0.2, -r * 0.35)]) if blade \
		else PackedVector2Array([Vector2(r, 0), Vector2(0, r * 0.6), Vector2(-r, 0), Vector2(0, -r * 0.6)])
	draw_colored_polygon(points, Color(color, 0.85))
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 1.0)
	draw_set_transform(Vector2.ZERO)
	if _time >= warning:
		var back := -velocity.normalized() * r * 1.8
		draw_line(Vector2.ZERO, back, Color(color, 0.4), 2.0)
