class_name ThrownBox
extends HitboxComponent
## Caja que Glitch tira en la persecución (Capítulo 1): sale con un saltito y rueda por el piso hacia
## donde va (direction), girando. Quita medio cristal si toca a Kai (se salta). Se rompe contra Kai, al
## recorrer max_distance o al pasar mucho tiempo. Dibujo provisional por código.

const SIZE := 14.0
const CARDBOARD := Color("c8a06a")
const TAPE := Color("e8d8b0")

var direction := -1.0
var speed := 170.0
var floor_y := 304.0
var max_distance := 560.0

var _travelled := 0.0
var _vy := -150.0
var _spin := 0.0


func _init() -> void:
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0
	damage = 1.0  # Golpe enemigo normal: medio cristal.
	knockback_force = 160.0
	add_to_group(&"boss_attack")


func _ready() -> void:
	super()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(SIZE - 2.0, SIZE - 2.0)
	shape.shape = rect
	shape.position = Vector2(0, -SIZE / 2.0)
	add_child(shape)
	z_index = 4
	hit_dealt.connect(func(_hurtbox: Node2D, _hit: HitData) -> void: _break())


func _physics_process(delta: float) -> void:
	var step := speed * delta
	position.x += direction * step
	_travelled += step
	_vy += 700.0 * delta
	position.y = minf(position.y + _vy * delta, floor_y)
	if position.y >= floor_y:
		_vy = 0.0
	_spin += direction * step / (SIZE / 2.0)
	queue_redraw()
	if _travelled >= max_distance:
		_break()


func _break() -> void:
	if is_queued_for_deletion():
		return
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -6), [CARDBOARD, TAPE], 8, 60.0, Vector2(SIZE, SIZE), 0.4)
	queue_free()


func _draw() -> void:
	draw_set_transform(Vector2(0, -SIZE / 2.0), _spin)
	var box := Rect2(Vector2(-SIZE / 2.0, -SIZE / 2.0), Vector2(SIZE, SIZE))
	draw_rect(box, CARDBOARD)
	draw_rect(box, Color(0.3, 0.2, 0.1), false, 1.0)
	draw_line(Vector2(0, -SIZE / 2.0), Vector2(0, SIZE / 2.0), TAPE, 2.0)
	draw_set_transform(Vector2.ZERO)
