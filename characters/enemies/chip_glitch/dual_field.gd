class_name DualField
extends HitboxComponent
## Campo Dual (ataque definitivo de la Fase 3): Glitch y Chip combinan sus habilidades y el piso de la
## arena se vuelve peligroso (energía rosa y azul), salvo un hueco seguro. Las plataformas también son
## seguras. Primero parpadea (aviso, el hueco ya se ve), después quema un rato y se apaga.
## El origen es el piso, en x = 0 de la arena (left / right son los bordes).

const HEIGHT := 18.0

var left := 0.0
var right := 640.0
## Centro y ancho del hueco seguro.
var gap_x := 320.0
var gap := 80.0
var warning := 1.1
var duration := 2.6
var _time := 0.0


func _init() -> void:
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0
	damage = 1.0
	threat_type = &"malware"
	knockback_force = 120.0
	active = false
	add_to_group(&"boss_attack")


func _ready() -> void:
	super()
	for part in _parts():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(part.y - part.x, HEIGHT)
		shape.shape = rect
		shape.position = Vector2((part.x + part.y) / 2.0, -HEIGHT / 2.0)
		add_child(shape)
	z_index = 4


## Tramos peligrosos (x desde, x hasta): a los dos lados del hueco.
func _parts() -> Array[Vector2]:
	return [Vector2(left, gap_x - gap / 2.0), Vector2(gap_x + gap / 2.0, right)]


func is_safe(x: float) -> bool:
	return absf(x - gap_x) <= gap / 2.0


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	active = _time >= warning and _time < warning + duration
	if _time >= warning + duration + 0.2:
		queue_free()


func _draw() -> void:
	var on := _time >= warning
	var fade := clampf(1.0 - (_time - warning - duration) / 0.2, 0.0, 1.0)
	for part in _parts():
		var rect := Rect2(part.x, -HEIGHT, part.y - part.x, HEIGHT)
		if not on:
			var blink := int(_time / 0.1) % 2 == 0
			draw_line(Vector2(part.x, 0), Vector2(part.y, 0), Color(SiblingArt.GLITCH if blink else SiblingArt.CHIP, 0.9), 2.0)
			continue
		draw_rect(rect, Color(0.5, 0.2, 0.8, 0.25 * fade))
		for x in range(int(part.x), int(part.y), 6):
			var pink := (x / 6) % 2 == 0
			var h := HEIGHT * (0.5 + 0.5 * absf(sin(_time * 9.0 + x * 0.21)))
			draw_line(Vector2(x, 0), Vector2(x, -h), Color(SiblingArt.GLITCH if pink else SiblingArt.CHIP, 0.8 * fade), 2.0)
	# El hueco seguro, marcado con una luz clara.
	draw_rect(Rect2(gap_x - gap / 2.0, -3, gap, 3), Color(1, 1, 1, 0.5 if on else 0.8))
