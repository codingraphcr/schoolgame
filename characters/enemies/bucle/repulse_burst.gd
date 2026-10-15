class_name RepulseBurst
extends HitboxComponent
## Repulsión de Bucle: si Kai se queda pegado a él mientras anuncia o ataca, un aro se cierra sobre Bucle
## (aviso de telegraph segundos, sin daño) y estalla alrededor (radio radius) un instante. Castiga quedarse
## al lado esperando a que se le pase el escudo. Corre con el tiempo de las amenazas (el Dominio lo frena).

const COLOR := Color("ffd166")

var radius := 52.0
var telegraph := 0.4
var color := COLOR
## Segundos que daña después del aviso.
var burst_time := 0.15

var _time := 0.0
var _shape: CollisionShape2D


func _init() -> void:
	collision_layer = 16  # Capa 5: ataques_enemigos
	collision_mask = 0
	threat_type = &"logica"
	knockback_force = 220.0
	active = false
	add_to_group(&"boss_attack")


func _ready() -> void:
	super()
	_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	_shape.shape = circle
	add_child(_shape)
	z_index = 4


func _physics_process(real_delta: float) -> void:
	_time += CombatClock.scaled(real_delta)
	queue_redraw()
	if _time >= telegraph and not active:
		active = true
		Sfx.play(&"boss_charge", 1.8, -6.0)
	if _time >= telegraph + burst_time:
		queue_free()


## Si ya estalla (pasado el aviso: ahora daña).
func is_live() -> bool:
	return _time >= telegraph


func _draw() -> void:
	if _time < telegraph:
		# Aviso: un aro que se cierra hasta el borde del estallido, y la zona que va a dañar.
		var t := _time / maxf(telegraph, 0.01)
		var blink := 0.3 + 0.4 * float(int(_time / 0.07) % 2)
		draw_circle(Vector2.ZERO, radius, Color(color, 0.08 + 0.1 * t))
		draw_arc(Vector2.ZERO, radius * (1.8 - 0.8 * t), 0.0, TAU, 40, Color(color, blink), 2.0)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(color, 0.35), 1.0)
		return
	var k := clampf((_time - telegraph) / maxf(burst_time, 0.01), 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(color, 0.45 * (1.0 - k)))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(Color.WHITE, 1.0 - k), 3.0)
