extends Node2D
## Flota arriba y abajo alrededor de su posición inicial, en pasos de píxel enteros (pixel art).

@export var amplitude := 2.0
@export var speed := 2.0

var _origin := Vector2.ZERO
var _time := 0.0


func _ready() -> void:
	_origin = position


func _process(delta: float) -> void:
	_time += delta
	position.y = _origin.y + roundf(sin(_time * speed) * amplitude)
