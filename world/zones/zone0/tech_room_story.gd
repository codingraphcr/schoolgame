class_name TechRoomStory
extends Node
## Capítulo 1 en el cuarto técnico.
## - Escena 2.1 (paso revisar_servidor, al llegar): el servidor en rojo; Chip y Glitch se ríen desde
##   el monitor y se meten en la computadora. Después aparece la conexión (Inmersión Digital).
## - Escena 2.7 (paso hablar_profesor): Kai vuelve de la red y habla con el profesor. Cuando Kai se va,
##   el profesor se queda solo frente al monitor y aparece GENESIS_ARCHIVE (sin diálogo). Corte.
##   Se completa la misión: «FIN DEL CAPÍTULO 1».
## El servidor deja de estar en rojo cuando Chip y Glitch quedaron neutralizados.

const QUEST := &"travesuras_en_el_sistema"
const ENDING_FLAG := &"cap1_genesis_visto"

@export var chip: SiblingActor
@export var glitch: SiblingActor
@export var props: Node2D
@export var monitor_point := Vector2(470, 252)
@export var server_dialogue: Dialogue
## El profesor (Npc): su conversación del paso hablar_profesor no completa el paso; lo completa el final.
@export var profesor: Npc
## Hacia dónde se va Kai al terminar de hablar (antes de la salida: no cambia de sala).
@export var leave_point := Vector2(596, 304)
## Saltear las pausas (solo pruebas).
@export var quick := false

var ending_played := false


func _ready() -> void:
	chip.vanish()
	glitch.vanish()
	var state := _state()
	props.alert = not state.has_flag(&"cap1_hermanos_vencidos")
	props.genesis = false
	if profesor:
		profesor.talked.connect(_on_profesor_talked)
	_on_enter.call_deferred()


func _on_enter() -> void:
	if _state().get_current_step(QUEST) != &"revisar_servidor":
		return
	for k in 2:
		var actor: SiblingActor = [chip, glitch][k]
		actor.position = monitor_point + Vector2(-20 + k * 40, 52)
		actor.appear()
	await StoryHelper.say(self, server_dialogue)
	for actor in [chip, glitch]:
		actor.run_to(monitor_point, 160.0)
	await get_tree().create_timer(0.5 if quick else 0.8, false, true).timeout
	chip.vanish()
	glitch.vanish()
	_state().complete_step(QUEST, &"revisar_servidor")


func _on_profesor_talked(_first_time: bool) -> void:
	if ending_played or _state().get_current_step(QUEST) != &"hablar_profesor":
		return
	ending_played = true
	await _genesis_ending()


## Kai se va; el profesor mira el monitor y aparece GENESIS_ARCHIVE. Corte a negro y fin del capítulo.
func _genesis_ending() -> void:
	var room := get_parent() as Room
	var player := room.player
	player.controls_locked = true
	var camera := room.camera
	camera.target = null
	var tween := player.create_tween()
	tween.tween_property(player, "global_position:x", leave_point.x, 0.4 if quick else 1.6)
	tween.parallel().tween_property(player, "modulate:a", 0.0, 0.4 if quick else 1.6)
	await tween.finished
	await get_tree().create_timer(0.2 if quick else 1.0, false, true).timeout
	props.genesis = true
	await get_tree().create_timer(0.4 if quick else 3.0, false, true).timeout
	_state().set_flag(ENDING_FLAG)
	await get_node("/root/SceneManager").transition(func() -> void:
		props.genesis = false
		player.modulate.a = 1.0
		player.global_position = Vector2(leave_point.x - 60.0, player.global_position.y)
		camera.target = player)
	player.controls_locked = false
	# Termina la misión: «FIN DEL CAPÍTULO 1».
	_state().complete_step(QUEST, &"hablar_profesor")


func _state() -> Node:
	return get_node("/root/GameState")
