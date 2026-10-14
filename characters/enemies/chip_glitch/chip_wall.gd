class_name ChipWall
extends StaticBody2D
## Barrera pequeña de Chip: cierra el paso duration segundos (no hace daño: se salta o se espera).
## Aparece y se va con un parpadeo. El origen es la base, apoyada en el suelo.

const CYAN := Color("5ad8ff")

var duration := 2.6
var height := 64.0
var _time := 0.0


func _init() -> void:
	collision_layer = 1  # Mundo: detiene a Kai
	collision_mask = 0
	add_to_group(&"boss_attack")


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, height)
	shape.shape = rect
	shape.position = Vector2(0, -height / 2.0)
	add_child(shape)


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time >= duration:
		queue_free()


func _draw() -> void:
	var fading := _time > duration - 0.5 and int(_time / 0.08) % 2 == 0
	var alpha := 0.35 if fading else 0.85
	draw_rect(Rect2(-5, -height, 10, height), Color(0.04, 0.12, 0.22, alpha))
	draw_rect(Rect2(-5, -height, 10, height), Color(CYAN, alpha), false, 1.5)
	for k in int(height / 10.0):
		draw_line(Vector2(-4, -height + 5 + k * 10.0), Vector2(4, -height + 5 + k * 10.0), Color(CYAN, alpha * 0.5), 1.0)
