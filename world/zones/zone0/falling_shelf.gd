class_name FallingShelf
extends Node2D
## Estantería del pasillo (Capítulo 1, persecución de Chip y Glitch): parada contra la pared no estorba.
## knock() la hace temblar (aviso) y caer hacia direction; al caer golpea lo que esté debajo (medio
## cristal) y queda tirada en el piso como un obstáculo sólido que hay que saltar, con libros
## desparramados. reset() la vuelve a parar. Dibujo provisional por código. El origen es la base.

signal fell

enum State { UPRIGHT, SHAKING, FALLING, FALLEN }

const WOOD := Color("6a4a32")
const WOOD_DARK := Color("3e2a1c")
const BOOKS: Array[Color] = [Color("c0504d"), Color("4f81bd"), Color("9bbb59"), Color("f2c14e"), Color("8064a2")]

## -1: cae hacia la izquierda (hacia donde viene Kai); 1: hacia la derecha.
@export var direction := -1.0
@export var height := 60.0
@export var depth := 22.0
@export var warning := 0.45
## Golpe enemigo normal (1): medio cristal.
@export var damage := 1.0

var state := State.UPRIGHT
var _angle := 0.0
var _shake := 0.0
var _solid: StaticBody2D
var _solid_shape: CollisionShape2D
var _hit: HitboxComponent


func _ready() -> void:
	_solid = StaticBody2D.new()
	_solid.collision_layer = 1
	_solid.collision_mask = 0
	_solid_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(height, depth)
	_solid_shape.shape = rect
	_solid_shape.position = Vector2(direction * height / 2.0, -depth / 2.0)
	_solid_shape.disabled = true
	_solid.add_child(_solid_shape)
	add_child(_solid)
	_hit = HitboxComponent.new()
	_hit.collision_layer = 16  # Capa 5: ataques_enemigos
	_hit.collision_mask = 0
	_hit.damage = damage
	_hit.knockback_force = 180.0
	_hit.active = false
	var hit_shape := CollisionShape2D.new()
	var hit_rect := RectangleShape2D.new()
	hit_rect.size = Vector2(height, depth + 6.0)
	hit_shape.shape = hit_rect
	hit_shape.position = Vector2(direction * height / 2.0, -(depth + 6.0) / 2.0)
	_hit.add_child(hit_shape)
	add_child(_hit)


func knock() -> void:
	if state != State.UPRIGHT:
		return
	state = State.SHAKING
	_shake = warning
	Sfx.play(&"enemy_hit", 0.6, -10.0)
	await get_tree().create_timer(warning, false, true).timeout
	state = State.FALLING
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "_angle", direction * PI / 2.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	state = State.FALLEN
	_solid_shape.set_deferred(&"disabled", false)
	_hit.activate()
	Sfx.play(&"enemy_death", 0.5, -6.0)
	PixelBurst.spawn(get_parent(), global_position + Vector2(direction * height / 2.0, -6), BOOKS, 14, 90.0, Vector2(height, 8), 0.5)
	fell.emit()
	await get_tree().create_timer(0.15, false, true).timeout
	_hit.deactivate()


func reset() -> void:
	state = State.UPRIGHT
	_angle = 0.0
	_shake = 0.0
	_solid_shape.set_deferred(&"disabled", true)
	_hit.deactivate()
	queue_redraw()


func is_blocking() -> bool:
	return state == State.FALLEN


func _physics_process(delta: float) -> void:
	_shake = maxf(_shake - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	if state == State.FALLEN:
		# Acostada en el piso (igual que su cuerpo sólido), con libros desparramados.
		var lying := Rect2(Vector2(minf(0.0, direction * height), -depth), Vector2(height, depth))
		draw_rect(lying, WOOD_DARK)
		draw_rect(lying.grow(-2.0), WOOD)
		for k in 3:
			var x := lying.position.x + 4.0 + k * (height - 8.0) / 3.0
			draw_rect(Rect2(Vector2(x + (height - 8.0) / 3.0 - 3.0, lying.position.y + 2.0), Vector2(2.0, depth - 4.0)), WOOD_DARK)
		for k in 5:
			draw_rect(Rect2(Vector2(direction * (height + 6.0 + k * 9.0) - 3.0, -3.0), Vector2(7.0, 3.0)), BOOKS[k])
		return
	var wobble := sin(Time.get_ticks_msec() / 25.0) * 0.06 if state == State.SHAKING else 0.0
	draw_set_transform(Vector2.ZERO, _angle + wobble)
	var body := Rect2(Vector2(-depth / 2.0, -height), Vector2(depth, height))
	draw_rect(body, WOOD_DARK)
	draw_rect(body.grow(-2.0), WOOD)
	for row in 3:
		var shelf_y := body.position.y + 4.0 + row * (height - 8.0) / 3.0
		draw_rect(Rect2(Vector2(body.position.x + 2.0, shelf_y + (height - 8.0) / 3.0 - 3.0), Vector2(depth - 4.0, 2.0)), WOOD_DARK)
		for k in 4:
			var color: Color = BOOKS[(row * 4 + k) % BOOKS.size()]
			draw_rect(Rect2(Vector2(body.position.x + 3.0 + k * 4.0, shelf_y + 2.0), Vector2(3.0, (height - 8.0) / 3.0 - 6.0)), color)
	draw_set_transform(Vector2.ZERO)
	if state == State.SHAKING:
		draw_string(ThemeDB.fallback_font, Vector2(-4, -height - 6), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ff3ea5"))
