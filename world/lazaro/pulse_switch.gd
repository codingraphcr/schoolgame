@tool
class_name PulseSwitch
extends Node2D
## Un interruptor de emergencia que solo se activa con Aegis Pulse (Capítulo 3, el escape de la Estación Lázaro): está
## lejos o detrás de algo, Kai no lo alcanza, pero Aegis sí. Es un blanco válido (grupo «aegis_target»). Al recibir el
## disparo deja on_flag (que abre una LazaroGate) y se ilumina. El origen es el centro del interruptor.

const CYAN := Color("3ef2ff")
const RED := Color("ff4a5a")

@export var on_flag: StringName = &""

var _clock := 0.0


func _ready() -> void:
	if not Engine.is_editor_hint() and not is_on():
		add_to_group(&"aegis_target")


func is_on() -> bool:
	return not Engine.is_editor_hint() and on_flag != &"" and get_node("/root/GameState").has_flag(on_flag)


## Lo llama el disparo de Aegis al llegar.
func pulse_hit() -> void:
	if is_on():
		return
	get_node("/root/GameState").set_flag(on_flag)
	remove_from_group(&"aegis_target")
	Sfx.play(&"terminal_ok")


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	var on := is_on()
	draw_circle(Vector2.ZERO, 12.0, Color("dfe6f0"))
	draw_circle(Vector2.ZERO, 12.0, Color("3a7adf"), false, 2.0)
	var color := CYAN if on else RED
	draw_circle(Vector2.ZERO, 6.0 + (0.0 if on else sin(_clock * 6.0)), color)
	if not on:
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 16, Color(RED, 0.3 + 0.2 * sin(_clock * 6.0)), 1.5)
