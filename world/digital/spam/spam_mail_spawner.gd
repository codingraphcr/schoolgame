@tool
class_name SpamMailSpawner
extends Node2D
## Lluvia de correos SPAM: deja caer SpamMail en una franja horizontal, solo mientras Kai está cerca.
## La mayoría apunta a donde estaba Kai hace un instante (aim_delay): quedarse quieto es peligroso,
## moverse los esquiva. El resto cae al azar para cubrir la zona.
## El origen es el extremo izquierdo de la franja, a la altura desde donde caen.

@export var width := 320.0:
	set(value):
		width = maxf(value, 16.0)
		queue_redraw()
@export var interval := 1.1
@export var fall_speed := 140.0
## Proporción de correos que apuntan a Kai (0 = todos al azar, 1 = todos apuntados).
@export_range(0.0, 1.0) var aimed_ratio := 0.7
## Segundos de "retraso" del apuntado: el correo cae donde estaba Kai hace este tiempo.
@export var aim_delay := 0.15
## Desvío al azar (px) alrededor del punto apuntado.
@export var aim_spread := 10.0
## Altura (global) donde los correos se deshacen.
@export var floor_y := 304.0
## Solo caen correos si Kai está a menos de esta distancia horizontal de la franja.
@export var active_margin := 160.0

var _timer := 0.5
var _rng := RandomNumberGenerator.new()
## Posiciones recientes de Kai: [[tiempo, x], ...]
var _trail: Array = []
var _clock := 0.0


func _ready() -> void:
	_rng.randomize()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return
	var x := player.global_position.x
	_clock += delta
	_trail.append([_clock, x])
	while _trail.size() > 2 and _clock - _trail[0][0] > aim_delay * 2.0:
		_trail.pop_front()
	if x < global_position.x - active_margin or x > global_position.x + width + active_margin:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = interval
		spawn_mail(_next_x())


## Dónde cae el próximo correo (local a la franja): sobre donde estaba Kai hace aim_delay, o al azar.
func _next_x() -> float:
	if _rng.randf() < aimed_ratio and not _trail.is_empty():
		var past_x: float = _trail[0][1]
		for entry in _trail:
			if _clock - entry[0] <= aim_delay:
				break
			past_x = entry[1]
		var local_x := past_x - global_position.x + _rng.randf_range(-aim_spread, aim_spread)
		return clampf(local_x, 6.0, width - 6.0)
	return _rng.randf_range(6.0, width - 6.0)


## Deja caer un correo en la posición x (local a la franja).
func spawn_mail(x: float) -> SpamMail:
	var mail := SpamMail.new()
	mail.fall_speed = fall_speed
	mail.floor_y = floor_y
	mail.position = Vector2(x, 0)
	add_child(mail)
	return mail


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_line(Vector2.ZERO, Vector2(width, 0), Color(1.0, 0.25, 0.65, 0.8), 1.0)
		draw_line(Vector2(0, -4), Vector2(0, 4), Color(1.0, 0.25, 0.65, 0.8), 1.0)
		draw_line(Vector2(width, -4), Vector2(width, 4), Color(1.0, 0.25, 0.65, 0.8), 1.0)
