class_name AegisShot
extends HitboxComponent
## Un disparo de Aegis Pulse: una bolita de luz cian que va hacia su objetivo (lo sigue) y desaparece al golpear o al
## pasar su tiempo. Es un ataque del jugador (capa 4). Los blancos del grupo «aegis_target» reciben pulse_hit().

const SPEED := 420.0
const LIFE := 1.2
const CYAN := Color("3ef2ff")

var target: Node2D
var _life := LIFE


func _init() -> void:
	damage = 1.0
	knockback_force = 120.0
	collision_layer = 8  # Capa 4: ataques_jugador
	collision_mask = 0


func _ready() -> void:
	super()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)
	hit_dealt.connect(func(_hurtbox: Node2D, _hit: HitData) -> void: queue_free())


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if target and is_instance_valid(target):
		var aim := target.global_position + Vector2(0, -8)
		global_position = global_position.move_toward(aim, SPEED * delta)
		if global_position.distance_to(aim) < 6.0 and target.has_method(&"pulse_hit"):
			target.pulse_hit()
			queue_free()
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color(CYAN, 0.25))
	draw_circle(Vector2.ZERO, 3.5, CYAN)
