class_name FiberJunction
extends Node2D
## Un empalme de fibra del Bosque de Fibra: un nodo con un brazo que apunta a una de cuatro direcciones
## (0 derecha, 1 abajo, 2 izquierda, 3 arriba). Con E gira un cuarto de vuelta. Es parte de un FiberCircuit,
## que decide hacia dónde tiene que apuntar (al siguiente tramo) y cuándo se puede tocar.

signal turned(junction: FiberJunction)

const DIRECTIONS: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

@export var orientation := 2

## La que pide el circuito (−1 = ninguna todavía).
var correct := -1
var lit := false
var interactable: Interactable


func _ready() -> void:
	interactable = Interactable.new()
	interactable.prompt_text = "E: girar el empalme"
	interactable.prompt_offset = Vector2(-44, -44)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	shape.position = Vector2(0, 10)
	interactable.add_child(shape)
	add_child(interactable)
	interactable.interacted.connect(func(_player: Player) -> void: turn())


func turn() -> void:
	orientation = (orientation + 1) % 4
	Sfx.play(&"pogo", 1.4, -8.0)
	queue_redraw()
	turned.emit(self)


func is_correct() -> bool:
	return orientation == correct


func _draw() -> void:
	var color := Color("fff0a0") if lit else Color("5a7aa0")
	draw_circle(Vector2.ZERO, 11.0, Color("0c1a2a"))
	draw_circle(Vector2.ZERO, 11.0, color, false, 2.0)
	var arm := DIRECTIONS[orientation] * 16.0
	draw_line(Vector2.ZERO, arm, color, 4.0)
	draw_circle(arm, 3.0, color)
	if lit:
		draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.94, 0.6, 0.15))
