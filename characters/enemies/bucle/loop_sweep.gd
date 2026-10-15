class_name LoopSweep
extends HitboxComponent
## Barrido de Bucle: una línea de energía que cruza toda la arena a la altura donde estaba Kai. Primero una
## línea fina parpadea telegraph segundos (aviso, sin daño); después la franja daña durante live_time. Se
## esquiva saltando por encima, bajando de la plataforma o con el dash. Corre con la física.

const COLOR := Color("ff5ad8")
const HEIGHT := 14.0

var telegraph := 0.6
var live_time := 0.35
## Ancho de la arena (la línea va de 0 a width, desde el borde izquierdo).
var width := 560.0

var _time := 0.0


func _init() -> void:
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0
	threat_type = &"logica"
	knockback_force = 140.0
	active = false
	add_to_group(&"boss_attack")


func _ready() -> void:
	super()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, HEIGHT)
	shape.shape = rect
	shape.position = Vector2(width / 2.0, 0)
	add_child(shape)
	z_index = 4


func is_live() -> bool:
	return _time >= telegraph


func _physics_process(real_delta: float) -> void:
	_time += CombatClock.scaled(real_delta)
	queue_redraw()
	active = _time >= telegraph
	if _time >= telegraph + live_time:
		queue_free()


func _draw() -> void:
	if _time < telegraph:
		var blink := 0.3 + 0.4 * float(int(_time / 0.07) % 2)
		draw_line(Vector2(0, 0), Vector2(width, 0), Color(COLOR, blink), 1.5)
		for x in range(0, int(width), 40):
			draw_line(Vector2(x, -4), Vector2(x, 4), Color(COLOR, blink * 0.8), 1.0)
		return
	var fade := 1.0 - (_time - telegraph) / live_time
	draw_rect(Rect2(0, -HEIGHT / 2.0 - 3.0, width, HEIGHT + 6.0), Color(COLOR, 0.2 * fade))
	draw_rect(Rect2(0, -HEIGHT / 2.0, width, HEIGHT), Color(COLOR, 0.75 * fade))
	draw_line(Vector2(0, 0), Vector2(width, 0), Color(1, 1, 1, fade), 2.0)
