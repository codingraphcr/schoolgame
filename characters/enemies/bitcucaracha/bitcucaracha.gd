class_name Bitcucaracha
extends EnemyBase
## Bitcucaracha (nombre provisional; Capítulo 3, la estabilización del núcleo de Aegis): un insecto robótico chiquito,
## rápido y frágil que se alimenta de residuos digitales. Corre por el piso hacia el núcleo (target_x); si llega, se
## «come» un poco de su estabilidad (reached_core) y se va. Si Kai está muy cerca, lo choca (daño de contacto chico).
## No es un jefe ni tiene historia: comportamiento simple. Dibujo provisional por código.

signal reached_core(bug: Bitcucaracha)

@export var target_x := 480.0
@export var speed := 95.0

var _clock := 0.0
var _hop := 0.0


func _init() -> void:
	display_name = "Bitcucaracha"
	max_health = 1.0
	contact_damage = 0.5
	body_size = Vector2(16, 8)
	rank = Rank.COMUN
	ecos_reward = 1
	hurt_time = 0.15
	death_colors = [Color("8a94a8"), Color("3ef2ff"), Color("5a6474")]


func _ai(delta: float) -> void:
	_clock += delta
	var direction := signf(target_x - global_position.x)
	velocity.x = direction * speed
	# Saltitos al azar: cuesta más darles.
	_hop -= delta
	if _hop <= 0.0 and is_on_floor():
		_hop = randf_range(0.8, 1.8)
		if randf() < 0.45:
			velocity.y = -200.0
	if absf(target_x - global_position.x) < 14.0:
		reached_core.emit(self)
		is_dead = true
		queue_free()


func _draw() -> void:
	var face := -1.0 if velocity.x < 0.0 else 1.0
	var wiggle := sin(_clock * 30.0) * 1.5
	# Caparazón metálico, cabeza con antenas y seis patitas.
	draw_rect(Rect2(-8, -8, 16, 6), Color("5a6474"))
	draw_rect(Rect2(-7, -9, 14, 2), Color("8a94a8"))
	draw_line(Vector2(0, -8), Vector2(0, -2), Color("3a4250"), 1.0)
	draw_circle(Vector2(face * 9.0, -5), 3.0, Color("3a4250"))
	draw_circle(Vector2(face * 10.0, -6), 1.0, Color("3ef2ff"))
	draw_line(Vector2(face * 10.0, -7), Vector2(face * 15.0, -12 + wiggle), Color("8a94a8"), 1.0)
	draw_line(Vector2(face * 9.0, -7), Vector2(face * 13.0, -13 - wiggle), Color("8a94a8"), 1.0)
	for k in 3:
		var x := -5.0 + k * 5.0
		draw_line(Vector2(x, -2), Vector2(x - 2.0 + (wiggle if k % 2 else -wiggle), 0), Color("3a4250"), 1.0)


func _process(_delta: float) -> void:
	queue_redraw()
