class_name ClassScene
extends Node
## Capítulo 1, nivel 1, escenas 1.1 y 1.2 (en el laboratorio): la clase del profesor, Chip y Glitch
## alterando las computadoras de práctica (solo se ven con la Visión Digital) y el registro de
## eventos en la terminal del puesto de Kai (después, el desafío «Comportamiento anómalo»).
##
## Pasos de «Una clase diferente»: ir_a_clase → ver_fallas → revisar_registro → seguir_criaturas.

const QUEST := &"una_clase_diferente"

@export var chip: SiblingActor
@export var glitch: SiblingActor
## Terminal del puesto de Kai (paso revisar_registro; no completa el paso sola).
@export var terminal: TerminalStation
@export var anomaly_challenge: ChoiceChallenge
@export var intro_dialogue: Dialogue
@export var creatures_dialogue: Dialogue
@export var registro_dialogue: Dialogue
@export var resolved_dialogue: Dialogue
## Monitores y racks donde saltan Chip y Glitch.
@export var hop_points: Array[Vector2] = []
## Por dónde escapan (la puerta del pasillo).
@export var exit_point := Vector2(-30, 290)

var _busy := false
var _hopping := false


func _ready() -> void:
	chip.vanish()
	glitch.vanish()
	terminal.solved.connect(_on_registro_solved)
	_on_enter.call_deferred()


func _process(_delta: float) -> void:
	var step: StringName = _state().get_current_step(QUEST)
	if step == &"ver_fallas":
		if not _hopping:
			_start_hopping()
		if not _busy and get_node("/root/DigitalVision").is_active():
			_discovered()


func _on_enter() -> void:
	if _state().get_current_step(QUEST) == &"ir_a_clase":
		_busy = true
		await _say(intro_dialogue)
		_state().complete_step(QUEST, &"ir_a_clase")
		get_tree().call_group(&"toast", &"show_message", "Algo hace fallar las computadoras... Usa la Visión Digital (Q).", 3.0)
		_busy = false


## Chip y Glitch saltan entre los monitores (solo se ven con la Visión Digital).
func _start_hopping() -> void:
	_hopping = true
	for actor in [chip, glitch]:
		actor.only_with_vision = true
		actor.appear()
	var k := 0
	while _hopping and is_inside_tree() and _state().get_current_step(QUEST) == &"ver_fallas" and not _busy and not hop_points.is_empty():
		chip.run_to(hop_points[k % hop_points.size()])
		await glitch.run_to(hop_points[(k + 2) % hop_points.size()] + Vector2(0, 2))
		await get_tree().create_timer(0.5, false, true).timeout
		k += 1


## Kai los ve con la Visión: se dan cuenta y escapan.
func _discovered() -> void:
	_busy = true
	_hopping = false
	await _say(creatures_dialogue)
	for actor in [chip, glitch]:
		actor.only_with_vision = false
		actor.appear()
		actor.run_to(exit_point, 220.0)
	await get_tree().create_timer(1.2, false, true).timeout
	chip.vanish()
	glitch.vanish()
	_state().complete_step(QUEST, &"ver_fallas")
	await _say(registro_dialogue)
	_busy = false


## Después de leer el registro en la terminal: el desafío del comportamiento anómalo.
func _on_registro_solved() -> void:
	if _state().get_current_step(QUEST) != &"revisar_registro":
		return
	await StoryHelper.choose_until_done(self, anomaly_challenge)
	_state().set_flag(&"cap1_registro_revisado")
	await _say(resolved_dialogue)
	_state().complete_step(QUEST, &"revisar_registro")


func _say(dialogue: Dialogue) -> void:
	await StoryHelper.say(self, dialogue)


func _state() -> Node:
	return get_node("/root/GameState")
