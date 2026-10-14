class_name ClassScene
extends Node
## Capítulo 1, nivel 1, escenas 1.1 y 1.2 (en la Sala 3): la clase del profesor con los compañeros, el
## registro de eventos en la computadora del puesto de Kai (y el desafío «Comportamiento anómalo») y una
## cinemática corta: Kai mira con la Visión Digital, la cámara va a los monitores y ve a Chip y Glitch
## alterando las computadoras; se dan cuenta de que los ve y escapan por la puerta. Ahí empieza la
## persecución corta del pasillo (SiblingRun).
##
## Pasos de «Una clase diferente»: ir_a_clase → revisar_registro → ver_fallas (la cinemática) →
## seguir_criaturas. Si la partida se cargó a mitad de la cinemática (paso ver_fallas), se repite.

const QUEST := &"una_clase_diferente"

@export var chip: SiblingActor
@export var glitch: SiblingActor
## Terminal del puesto de Kai (paso revisar_registro; no completa el paso sola).
@export var terminal: TerminalStation
@export var anomaly_challenge: ChoiceChallenge
## El arte del aula (ClassroomProps): las computadoras fallan durante la clase.
@export var props: Node2D
@export var intro_dialogue: Dialogue
@export var resolved_dialogue: Dialogue
@export var creatures_dialogue: Dialogue
@export var escape_dialogue: Dialogue
## Monitores donde saltan Chip y Glitch (la cámara mira al centro de estos puntos).
@export var hop_points: Array[Vector2] = []
## Por dónde escapan (la puerta del pasillo).
@export var exit_point := Vector2(40, 296)

var _busy := false
var _hopping := false


func _ready() -> void:
	chip.vanish()
	glitch.vanish()
	terminal.solved.connect(_on_registro_solved)
	_on_enter.call_deferred()


func is_busy() -> bool:
	return _busy


func _on_enter() -> void:
	match _state().get_current_step(QUEST):
		&"ir_a_clase":
			_busy = true
			await _say(intro_dialogue)
			_set_glitching(true)
			_state().complete_step(QUEST, &"ir_a_clase")
			get_tree().call_group(&"toast", &"show_message", "Revisa el registro en la computadora de tu puesto (E).", 3.0)
			_busy = false
		&"revisar_registro":
			_set_glitching(true)
		&"ver_fallas":
			_set_glitching(true)
			await _cinematic()


## Después de leer el registro en la terminal: el desafío del comportamiento anómalo y la cinemática.
func _on_registro_solved() -> void:
	if _busy or _state().get_current_step(QUEST) != &"revisar_registro":
		return
	_busy = true
	await StoryHelper.choose_until_done(self, anomaly_challenge)
	_state().set_flag(&"cap1_registro_revisado")
	await _say(resolved_dialogue)
	_state().complete_step(QUEST, &"revisar_registro")
	_busy = false
	await _cinematic()


## Kai mira con la Visión Digital: la cámara va a los monitores, Chip y Glitch saltan entre ellos, se
## dan cuenta de que Kai los ve y escapan por la puerta. Las computadoras vuelven a la normalidad.
func _cinematic() -> void:
	if _busy:
		return
	_busy = true
	var room := owner as Room
	var player := room.player
	player.controls_locked = true
	player.velocity = Vector2.ZERO
	get_node("/root/DigitalVision").activate(true)
	var center := player.global_position
	if not hop_points.is_empty():
		center = Vector2.ZERO
		for point in hop_points:
			center += point
		center /= hop_points.size()
	await _pan_camera(room.camera, center + Vector2(0, 20))
	_start_hopping()
	await get_tree().create_timer(1.6, false, true).timeout
	await _say(creatures_dialogue)
	_hopping = false
	for actor in [chip, glitch]:
		actor.only_with_vision = false
		actor.appear()
		actor.run_to(exit_point, 220.0)
	await get_tree().create_timer(1.4, false, true).timeout
	chip.vanish()
	glitch.vanish()
	_set_glitching(false)
	get_node("/root/DigitalVision").deactivate()
	await _pan_camera(room.camera, player.global_position + Vector2(0, room.camera.vertical_offset))
	room.camera.target = player
	await _say(escape_dialogue)
	player.controls_locked = false
	_state().complete_step(QUEST, &"ver_fallas")
	get_tree().call_group(&"toast", &"show_message", "¡Síguelos! Salieron al pasillo.", 3.0)
	_busy = false


## Mueve la cámara (sin seguir a Kai) hasta target.
func _pan_camera(camera: GameCamera, target: Vector2) -> void:
	camera.target = null
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(camera, "global_position", target, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


## Chip y Glitch saltan entre los monitores (solo se ven con la Visión Digital).
func _start_hopping() -> void:
	_hopping = true
	for k in 2:
		var actor: SiblingActor = [chip, glitch][k]
		actor.only_with_vision = true
		if not hop_points.is_empty():
			actor.position = hop_points[(k * 2) % hop_points.size()]
		actor.appear()
	var k := 1
	while _hopping and is_inside_tree() and not hop_points.is_empty():
		chip.run_to(hop_points[k % hop_points.size()])
		await glitch.run_to(hop_points[(k + 2) % hop_points.size()] + Vector2(0, 2))
		if not _hopping:
			break
		await get_tree().create_timer(0.4, false, true).timeout
		k += 1


func _set_glitching(value: bool) -> void:
	if props and "glitching" in props:
		props.glitching = value


func _say(dialogue: Dialogue) -> void:
	await StoryHelper.say(self, dialogue)


func _state() -> Node:
	return get_node("/root/GameState")
