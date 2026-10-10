class_name PixelBurst
extends Node2D
## Cuadritos que salen disparados y se desvanecen: el cuerpo de una amenaza que se desintegra
## en píxeles, o un BIT que se recoge. Uso: PixelBurst.spawn(sala, posición, colores, cantidad)

var _pixels: Array[Dictionary] = []
var _time := 0.0
var _life := 0.6


## area: tamaño de la zona de donde salen los píxeles (el cuerpo del enemigo).
static func spawn(parent: Node, at: Vector2, colors: Array, count := 24, speed := 90.0, area := Vector2.ZERO, life := 0.6) -> PixelBurst:
	var burst := PixelBurst.new()
	burst._life = life
	for i in count:
		var start := Vector2(randf_range(-0.5, 0.5) * area.x, randf_range(-1.0, 0.0) * area.y)
		var angle := randf_range(-PI, 0.0) if area != Vector2.ZERO else randf() * TAU
		burst._pixels.append({
			"pos": start,
			"vel": Vector2(cos(angle), sin(angle)) * randf_range(0.3, 1.0) * speed,
			"size": float([1, 1, 2, 2, 3].pick_random()),
			"color": colors.pick_random(),
			"delay": randf_range(0.0, 0.15) if area != Vector2.ZERO else 0.0,
		})
	parent.add_child(burst)
	burst.global_position = at
	return burst


func _process(delta: float) -> void:
	_time += delta
	for p in _pixels:
		if _time < p.delay:
			continue
		p.pos += p.vel * delta
		p.vel.y += 120.0 * delta
		p.vel *= 0.97
	queue_redraw()
	if _time >= _life + 0.15:
		queue_free()


func _draw() -> void:
	for p in _pixels:
		if _time < p.delay:
			# Mientras espera, el píxel sigue en el cuerpo (se "desarma" de a poco).
			draw_rect(Rect2(p.pos.round(), Vector2.ONE * p.size), p.color)
			continue
		var c: Color = p.color
		c.a = clampf(1.0 - (_time - p.delay) / _life, 0.0, 1.0)
		draw_rect(Rect2(p.pos.round(), Vector2.ONE * p.size), c)
