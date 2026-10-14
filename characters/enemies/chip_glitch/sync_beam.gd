class_name SyncBeam
extends HitboxComponent
## Rayo de sincronía de Chip: un ataque en línea de largo alcance. Primero se ve una línea punteada
## (aviso) que marca por dónde va a pasar; después el rayo dura un instante y se apaga. Se esquiva
## saltando o quedándose fuera de la línea. El origen es la punta de donde sale; va hacia direction.

const THICKNESS := 12.0

var direction := Vector2.RIGHT
var length := 640.0
var warning := 0.8
var duration := 0.35
var _time := 0.0
var _shape: CollisionShape2D


func _init() -> void:
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0
	damage = 1.0
	threat_type = &"malware"
	knockback_force = 170.0
	active = false
	add_to_group(&"boss_attack")


func _ready() -> void:
	super()
	rotation = direction.angle()
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(length, THICKNESS - 4.0)
	_shape.shape = rect
	_shape.position = Vector2(length / 2.0, 0)
	add_child(_shape)
	z_index = 5


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	active = _time >= warning and _time < warning + duration
	if _time >= warning + duration + 0.15:
		queue_free()


func _draw() -> void:
	if _time < warning:
		# Línea punteada que se afina a medida que se acerca el disparo.
		var k := _time / warning
		for x in range(0, int(length), 10):
			draw_line(Vector2(x, 0), Vector2(x + 5, 0), Color(SiblingArt.CHIP_LIGHT, 0.35 + 0.5 * k), 1.0)
		draw_circle(Vector2.ZERO, 3.0 + 5.0 * k, Color(SiblingArt.CHIP, 0.6))
		return
	var fade := clampf(1.0 - (_time - warning - duration) / 0.15, 0.0, 1.0)
	var width := THICKNESS * (1.0 if active else 0.5)
	draw_rect(Rect2(0, -width, length, width * 2.0), Color(SiblingArt.CHIP, 0.25 * fade))
	draw_rect(Rect2(0, -width / 2.0, length, width), Color(SiblingArt.CHIP, 0.8 * fade))
	draw_rect(Rect2(0, -width / 6.0, length, width / 3.0), Color(1, 1, 1, fade))
