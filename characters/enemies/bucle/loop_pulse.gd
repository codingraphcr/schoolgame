class_name LoopPulse
extends HitboxComponent
## Pulso repetitivo de Bucle: una onda de energía que recorre el suelo en una dirección. Antes de salir,
## el suelo brilla telegraph segundos donde nace (aviso, sin daño). Se esquiva saltando, desde una
## plataforma o con el dash. Desaparece al llegar al borde de la arena. Corre con la física.

const HEIGHT := 16.0
const WIDTH := 18.0
const COLOR := Color("ffb347")

var direction := 1.0
var speed := 210.0
var telegraph := 0.6
## Hasta dónde llega (x del borde de la arena en su dirección).
var limit_x := 640.0

var _time := 0.0
var _shape: CollisionShape2D


func _init() -> void:
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0
	threat_type = &"logica"
	knockback_force = 160.0
	active = false
	add_to_group(&"boss_attack")


func _ready() -> void:
	super()
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH, HEIGHT)
	_shape.shape = rect
	_shape.position = Vector2(0, -HEIGHT / 2.0)
	add_child(_shape)
	z_index = 4


## Si ya salió (pasado el aviso: ahora daña).
func is_live() -> bool:
	return _time >= telegraph


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time < telegraph:
		return
	active = true
	position.x += direction * speed * delta
	if (direction > 0.0 and position.x >= limit_x) or (direction < 0.0 and position.x <= limit_x):
		queue_free()


func _draw() -> void:
	if _time < telegraph:
		# Aviso: el suelo brilla donde va a nacer la onda (y hacia dónde va).
		var blink := 0.35 + 0.35 * float(int(_time / 0.08) % 2)
		draw_rect(Rect2(Vector2(-WIDTH, -3), Vector2(WIDTH * 2.0, 3)), Color(COLOR, blink))
		draw_line(Vector2(0, -6), Vector2(direction * 26.0, -6), Color(COLOR, blink), 2.0)
		draw_line(Vector2(direction * 26.0, -6), Vector2(direction * 20.0, -10), Color(COLOR, blink), 2.0)
		draw_line(Vector2(direction * 26.0, -6), Vector2(direction * 20.0, -2), Color(COLOR, blink), 2.0)
		return
	# La onda: un arco de energía con una estela.
	var points := PackedVector2Array()
	for k in 9:
		var t := k / 8.0
		points.append(Vector2(-WIDTH / 2.0 + t * WIDTH, -sin(t * PI) * HEIGHT))
	draw_colored_polygon(points + PackedVector2Array([Vector2(WIDTH / 2.0, 0), Vector2(-WIDTH / 2.0, 0)]), Color(COLOR, 0.75))
	draw_polyline(points, Color.WHITE, 1.5)
	draw_line(Vector2(-direction * WIDTH / 2.0, -2), Vector2(-direction * WIDTH * 2.0, -2), Color(COLOR, 0.35), 3.0)
