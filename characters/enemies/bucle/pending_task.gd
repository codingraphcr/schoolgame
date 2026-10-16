class_name PendingTask
extends Node2D
## «tarea_pendiente()» (Bucle, romper la condición): aparece sobre una plataforma mientras Bucle ejecuta su
## secuencia. Un tajo de la Nullblade la rompe. Si Kai las rompe todas, la condición del bucle se cumple y
## Bucle se cansa antes y por más tiempo (BucleBoss). No daña. El origen es donde se apoya (arriba de la
## plataforma).

signal broken

const COLOR := Color("5ef0ff")
const SIZE := Vector2(22, 18)
const LIFT := 16.0

var _time := 0.0
var _hurt: HurtboxComponent
var _done := false


func _init() -> void:
	add_to_group(&"boss_attack")


func _ready() -> void:
	z_index = 4
	_hurt = HurtboxComponent.new()
	_hurt.collision_layer = 0
	_hurt.collision_mask = 8  # Capa 4: ataques_jugador
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE + Vector2(6, 8)
	shape.shape = rect
	shape.position = Vector2(0, -LIFT)
	_hurt.add_child(shape)
	add_child(_hurt)
	_hurt.hit_received.connect(_on_hit)
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -LIFT), [COLOR, Color.WHITE], 8, 50.0, SIZE, 0.35)


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()


func is_broken() -> bool:
	return _done


func _on_hit(_hit: HitData) -> void:
	if _done:
		return
	_done = true
	Sfx.play(&"enemy_hit", 1.4)
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -LIFT), [COLOR, Color.WHITE, Color("ffcb57")], 16, 110.0, SIZE, 0.5)
	broken.emit()
	queue_free()


func _draw() -> void:
	var grow := clampf(_time / 0.25, 0.0, 1.0)
	var bob := sin(_time * 4.0) * 1.5
	draw_set_transform(Vector2(0, -LIFT + bob), 0.0, Vector2.ONE * grow)
	var box := Rect2(-SIZE / 2.0, SIZE)
	draw_rect(box.grow(2.0), Color(COLOR, 0.15 + 0.1 * sin(_time * 6.0)))
	draw_rect(box, Color(0.02, 0.1, 0.14, 0.9))
	draw_rect(box, COLOR, false, 1.5)
	# Una flecha de ciclo que gira: la tarea que nunca termina.
	var spin := _time * 4.0
	draw_arc(Vector2.ZERO, 5.0, spin, spin + TAU * 0.75, 12, COLOR, 1.5)
	var tip := Vector2.from_angle(spin + TAU * 0.75) * 5.0
	var ahead := Vector2.from_angle(spin + TAU * 0.75 + PI / 2.0)
	draw_line(tip, tip - ahead * 3.0 + tip.normalized() * 2.5, COLOR, 1.5)
	draw_line(tip, tip - ahead * 3.0 - tip.normalized() * 2.5, COLOR, 1.5)
	draw_set_transform(Vector2.ZERO)
	var label := "tarea_pendiente()"
	draw_string(ThemeDB.fallback_font, Vector2(-40, -LIFT - SIZE.y / 2.0 - 4.0 + bob), label, HORIZONTAL_ALIGNMENT_CENTER, 80, 6,
		Color(COLOR, 0.85 * grow))
