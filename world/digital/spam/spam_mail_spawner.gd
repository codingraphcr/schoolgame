@tool
class_name SpamMailSpawner
extends Node2D
## Lluvia de correos SPAM: deja caer SpamMail en una franja horizontal, solo mientras Kai está cerca.
## El origen es el extremo izquierdo de la franja, a la altura desde donde caen.

@export var width := 320.0:
	set(value):
		width = maxf(value, 16.0)
		queue_redraw()
@export var interval := 1.1
@export var fall_speed := 90.0
## Altura (global) donde los correos se deshacen.
@export var floor_y := 304.0
## Solo caen correos si Kai está a menos de esta distancia horizontal de la franja.
@export var active_margin := 160.0

var _timer := 0.5
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return
	var x := player.global_position.x
	if x < global_position.x - active_margin or x > global_position.x + width + active_margin:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = interval
		spawn_mail(_rng.randf_range(6.0, width - 6.0))


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
