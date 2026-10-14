@tool
class_name CorruptionBarrier
extends Area2D
## Barrera de corrupción de la persecución digital (Capítulo 1): una pared de datos corruptos que
## avanza detrás de Kai. Reglas:
## 1. Si toca a Kai le quita vida (damage), con un empujón hacia adelante.
## 2. Nunca lo derrota de un solo golpe: es un golpe común (y después hay invulnerabilidad breve,
##    la de PlayerDamage: nunca daño en cada cuadro).
## 3. No pasa de stop_x (el comienzo de la zona segura del tramo).
## 4. disable() la apaga para siempre (antes del combate final).
## Avanza con la física (como Kai). Su borde derecho es la posición x del nodo; se dibuja hacia atrás.

signal touched_player

const MAGENTA := Color("ff3ea5")
const VIOLET := Color("8a3eff")

@export var height := 420.0
## Píxeles por segundo mientras avanza.
@export var speed := 55.0
## Integridad que quita (se convierte al golpe de enemigo de PlayerDamage).
@export var damage := 1.0
@export var knockback := Vector2(260, -160)

## Si está avanzando.
var advancing := false
## Hasta dónde puede llegar su borde (el comienzo de la zona segura).
var stop_x := INF
var disabled := false

var _time := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2  # Capa del jugador
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, height)
	shape.shape = rect
	shape.position = Vector2(-20, -height / 2.0 + 60.0)
	add_child(shape)


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if Engine.is_editor_hint() or disabled:
		return
	if advancing:
		position.x = minf(position.x + speed * delta, stop_x)
		if position.x >= stop_x:
			advancing = false
	for body in get_overlapping_bodies():
		if body is Player:
			_hit(body as Player)


## La pone en x, quieta, lista para el tramo.
func place(x: float, new_speed: float, limit: float) -> void:
	position.x = x
	speed = new_speed
	stop_x = limit
	advancing = false
	visible = not disabled


func start() -> void:
	if not disabled:
		advancing = true


func halt() -> void:
	advancing = false


## Se apaga para siempre (antes del combate final).
func disable() -> void:
	disabled = true
	advancing = false
	visible = false
	set_deferred(&"monitoring", false)


func _hit(player: Player) -> void:
	if player.is_invulnerable() or player.health.is_dead():
		return
	var hit := HitData.new()
	# PlayerDamage escala el daño de los golpes comunes: se compensa para quitar exactamente damage.
	hit.damage = damage / maxf(player.damage.enemy_damage_scale, 0.01)
	hit.knockback = knockback
	player.damage._on_hit_received(hit)
	touched_player.emit()


func _draw() -> void:
	var top := -height + 60.0
	var flicker := 0.85 + 0.15 * sin(_time * 13.0)
	# Cuerpo: franjas de datos corruptos que se deshacen hacia la izquierda.
	for k in 6:
		var w := 26.0 + k * 22.0
		draw_rect(Rect2(-w, top, w, height), Color(VIOLET, 0.08 * flicker))
	draw_rect(Rect2(-40, top, 40, height), Color(MAGENTA, 0.35 * flicker))
	for i in int(height / 14.0):
		var y := top + i * 14.0
		var jitter := sin(_time * 7.0 + i * 1.7) * 10.0
		draw_rect(Rect2(-18 + jitter, y, 18 - jitter * 0.5, 6), Color(MAGENTA, 0.55))
		if (i + int(_time * 6.0)) % 4 == 0:
			draw_rect(Rect2(-60 + jitter * 2.0, y + 2, 10, 3), Color(VIOLET, 0.5))
	draw_line(Vector2(0, top), Vector2(0, top + height), Color(1, 0.75, 0.9, flicker), 2.0)
