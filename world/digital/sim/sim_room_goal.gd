class_name SimRoomGoal
extends Node
## Objetivo de una sala del simulador (Capítulo 2): cuando la pieza source emite su señal (la puerta se
## abre, el puente queda, el quiosco termina), completa el paso de la misión y avisa. Si la partida ya
## pasó ese paso (se volvió a la sala), deja la sala resuelta: pone solved_values en las variables.

@export var quest_id: StringName = &""
@export var step_id: StringName = &""
@export var source: Node
@export var signal_name: StringName = &"opened"
@export var variables: SimVariables
@export var solved_values: Dictionary[StringName, Variant] = {}
@export var message := ""


func _ready() -> void:
	if source and source.has_signal(signal_name):
		source.connect(signal_name, _on_goal)
	_restore.call_deferred()


func _restore() -> void:
	var state := get_node("/root/GameState")
	var passed: bool = state.has_reached_step(quest_id, step_id) and state.get_current_step(quest_id) != step_id
	if passed and variables:
		for variable in solved_values:
			variables.set_value(variable, solved_values[variable])


func _on_goal(_a: Variant = null, _b: Variant = null) -> void:
	var state := get_node("/root/GameState")
	if state.get_current_step(quest_id) != step_id:
		return
	state.complete_step(quest_id, step_id)
	if not message.is_empty():
		get_tree().call_group(&"toast", &"show_message", message, 2.6)
