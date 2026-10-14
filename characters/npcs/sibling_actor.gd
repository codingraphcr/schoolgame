@tool
class_name SiblingActor
extends Node2D
## Chip o Glitch como personaje de una escena (Capítulo 1, nivel 1): no pelean ni hacen daño; corren,
## saltan entre monitores, se ríen y se esconden. Solo Kai los ve: aparecen con la Visión Digital
## (only_with_vision) o cuando la historia los muestra. Mismo dibujo que el jefe (SiblingArt: los
## sprites de la hoja de Ariel).
## Uso: await actor.run_to(Vector2(x, y))  ·  actor.vanish()  ·  actor.appear()

enum Kind { CHIP, GLITCH }

@export var kind := Kind.CHIP:
	set(value):
		kind = value
		queue_redraw()
## Píxeles por segundo al correr.
@export var speed := 150.0
## Si solo se ven con la Visión Digital activa (en el mundo real: los demás no los ven).
@export var only_with_vision := false

var face := 1.0
var _clock := 0.0
var _hidden := false
var _tween: Tween


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()
	if Engine.is_editor_hint():
		return
	var shown := not _hidden
	if only_with_vision:
		shown = shown and get_node("/root/DigitalVision").is_active()
	modulate.a = move_toward(modulate.a, 1.0 if shown else 0.0, delta * 4.0)


## Corre hasta target (con un saltito si cambia de altura). Termina al llegar. Una carrera nueva
## corta la anterior (la anterior ya no termina).
func run_to(target: Vector2, run_speed := -1.0) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	var velocity := run_speed if run_speed > 0.0 else speed
	face = 1.0 if target.x >= position.x else -1.0
	var start := position
	var duration := maxf(start.distance_to(target) / velocity, 0.05)
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_method(func(t: float) -> void:
		position = start.lerp(target, t) + Vector2(0, -sin(t * PI) * minf(24.0, absf(target.y - start.y) + 8.0)), 0.0, 1.0, duration)
	await _tween.finished


func vanish() -> void:
	_hidden = true


func appear() -> void:
	_hidden = false
	if not only_with_vision:
		modulate.a = 1.0


func is_shown() -> bool:
	return modulate.a > 0.5


func _draw() -> void:
	# Un pequeño rebote al estar quietos (los dos corren y saltan con los pies en el suelo).
	var bob := Vector2(0, -absf(sin(_clock * 3.0)) * 1.0)
	SiblingArt.draw_twin(self, &"chip" if kind == Kind.CHIP else &"glitch", _clock, face, { "offset": bob })
