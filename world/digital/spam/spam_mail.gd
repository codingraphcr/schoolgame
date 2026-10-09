class_name SpamMail
extends HitboxComponent
## Correo SPAM que cae: primero parpadea arriba un instante (aviso) y luego cae balanceándose.
## Quita 1 máscara y empuja. Se deshace al llegar al suelo.

const MAG := Color("ff3ea5")

var fall_speed := 90.0
var floor_y := 304.0

var _warning := 0.35
var _time := 0.0
var _origin_x := 0.0


func _init() -> void:
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0
	damage = 1.0
	knockback_force = 150.0
	active = false


func _ready() -> void:
	super._ready()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 8)
	shape.shape = rect
	add_child(shape)
	_origin_x = position.x


func _physics_process(delta: float) -> void:
	_time += delta
	if _warning > 0.0:
		_warning -= delta
		modulate.a = 0.4 + 0.6 * absf(sin(_time * 20.0))
		if _warning <= 0.0:
			active = true
			modulate.a = 1.0
		return
	position.y += fall_speed * delta
	position.x = _origin_x + sin(_time * 4.0) * 3.0
	rotation = sin(_time * 4.0) * 0.15
	if global_position.y >= floor_y - 4.0:
		RingBurst.spawn(get_parent(), global_position, MAG)
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(-6, -4, 12, 8), Color("f4f7ff"))
	draw_rect(Rect2(-6, -4, 12, 8), Color("0a0d1c"), false, 1.0)
	draw_polyline(PackedVector2Array([Vector2(-6, -4), Vector2(0, 1), Vector2(6, -4)]), Color("0a0d1c"), 1.0)
	draw_circle(Vector2(4, 2), 2.5, MAG)
