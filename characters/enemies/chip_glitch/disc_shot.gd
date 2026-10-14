class_name DiscShot
extends HitboxComponent
## Disco de Chip (Discos orbitales): sale en una dirección girando, se curva un poco hacia Kai (Chip
## lo controla), llega a su alcance y vuelve a quien lo lanzó. Quita medio cristal; no se rompe al
## golpear (sigue su vuelo). Desaparece al volver o a los LIFETIME segundos.

const LIFETIME := 5.0
const RADIUS := 9.0
## Cuánto lo corrige hacia Kai mientras va (radianes por segundo).
const STEER := 1.6

var velocity := Vector2.ZERO
var reach := 230.0
## A quién vuelve (Chip o una de sus copias). Si ya no está, se va derecho.
var thrower: Node2D
var warning := 0.0
var _travel := 0.0
var _returning := false
var _time := 0.0
var _spin := 0.0
var _trail: Array[Vector2] = []


func _init() -> void:
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0
	damage = 1.0
	threat_type = &"malware"
	knockback_force = 150.0
	active = false
	add_to_group(&"boss_attack")


func _ready() -> void:
	super()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS - 2.0
	shape.shape = circle
	add_child(shape)
	z_index = 5


func _physics_process(delta: float) -> void:
	_time += delta
	_spin += delta * 14.0
	queue_redraw()
	if _time < warning:
		return
	active = true
	var speed := velocity.length()
	if not _returning:
		var kai := get_tree().get_first_node_in_group(&"player") as Node2D
		if kai:
			var want := (kai.global_position + Vector2(0, -14) - global_position).angle()
			velocity = Vector2.from_angle(rotate_toward(velocity.angle(), want, STEER * delta)) * speed
		_travel += speed * delta
		if _travel >= reach:
			_returning = true
	elif is_instance_valid(thrower):
		var home := thrower.global_position + Vector2(0, -18)
		velocity = (home - global_position).normalized() * speed * 1.1
		if global_position.distance_to(home) < 12.0:
			queue_free()
			return
	global_position += velocity * delta
	_trail.append(global_position)
	if _trail.size() > 6:
		_trail.remove_at(0)
	if _time >= LIFETIME:
		queue_free()


func _draw() -> void:
	if _time < warning:
		var blink := int(_time / 0.06) % 2 == 0
		draw_arc(Vector2.ZERO, RADIUS + 4.0, 0.0, TAU, 20, Color(SiblingArt.CHIP_LIGHT, 0.9 if blink else 0.3), 1.0)
	for i in _trail.size():
		var k := float(i + 1) / _trail.size()
		draw_circle(_trail[i] - global_position, RADIUS * 0.6 * k, Color(SiblingArt.CHIP, 0.18 * k))
	draw_circle(Vector2.ZERO, RADIUS + 3.0, Color(SiblingArt.CHIP, 0.2))
	SiblingArt.draw_disc(self, _spin, RADIUS)
