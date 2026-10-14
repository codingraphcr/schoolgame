class_name DataTrap
extends HitboxComponent
## Trampa temporal de Chip: una franja de datos en el suelo. Primero se arma (arm_time segundos,
## parpadea en contorno: aviso), después pincha duration segundos y se va. El origen es el centro
## de la base, apoyada en el suelo.

const AMBER := Color("ffc24a")
const RED := Color("ff4a6a")

var arm_time := 0.6
var duration := 3.0
var width := 40.0
var _time := 0.0


func _init() -> void:
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0
	damage = 1.0
	threat_type = &"malware"
	knockback_force = 180.0
	active = false
	add_to_group(&"boss_attack")


func _ready() -> void:
	super()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 12)
	shape.shape = rect
	shape.position = Vector2(0, -6)
	add_child(shape)


func is_armed() -> bool:
	return active


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	active = _time >= arm_time
	if _time >= arm_time + duration:
		queue_free()


func _draw() -> void:
	var rect := Rect2(-width / 2.0, -12, width, 12)
	if _time < arm_time:
		if int(_time / 0.08) % 2 == 0:
			draw_rect(rect, Color(AMBER, 0.9), false, 1.5)
		return
	draw_rect(rect, Color(RED, 0.35))
	for k in int(width / 8.0):
		var x := rect.position.x + 4.0 + k * 8.0
		draw_colored_polygon(PackedVector2Array([Vector2(x - 3, 0), Vector2(x, -10), Vector2(x + 3, 0)]), RED)
