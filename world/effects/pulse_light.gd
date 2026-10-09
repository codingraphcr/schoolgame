extends PointLight2D
## Luz que late suavemente (amenazas, equipos encendidos).

@export var base_energy := 1.1
@export var amplitude := 0.3
@export var speed := 5.0

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	energy = base_energy + sin(_time * speed) * amplitude
