class_name SiblingRun
extends Node
## Persecución corta de Chip y Glitch (Capítulo 1, nivel 1): los hermanos van delante por un camino
## (path) y avanzan al siguiente punto cuando Kai se acerca (trigger_distance); al llegar al último
## desaparecen (siguieron a la sala siguiente). Solo mientras la misión está en quest_id / step_id.
## Sin daño ni temporizador: es la presentación de las persecuciones.

@export var quest_id: StringName = &"una_clase_diferente"
@export var step_id: StringName = &"seguir_criaturas"
@export var actors: Array[SiblingActor] = []
## Puntos del camino (el primero es donde esperan).
@export var path: Array[Vector2] = []
@export var trigger_distance := 150.0
## Lo que dicen la primera vez que Kai se acerca (una sola vez: played_flag).
@export var start_dialogue: Dialogue
@export var played_flag: StringName = &""

var index := 0
var _moving := false
var _active := false


func _ready() -> void:
	for actor in actors:
		actor.vanish()


func _physics_process(_delta: float) -> void:
	var on_step: bool = get_node("/root/GameState").get_current_step(quest_id) == step_id
	if on_step and not _active and index == 0 and not path.is_empty():
		_active = true
		for k in actors.size():
			actors[k].position = path[0] + Vector2(-26.0 * k, 0)
			actors[k].appear()
	if not on_step:
		if _active:
			_active = false
			for actor in actors:
				actor.vanish()
		return
	if _moving or index >= path.size() or actors.is_empty():
		return
	var player := StoryHelper.room_player(self)
	if player and player.global_position.distance_to(actors[0].global_position) < trigger_distance:
		_advance()


func is_done() -> bool:
	return index >= path.size()


func _advance() -> void:
	_moving = true
	var state := get_node("/root/GameState")
	if index == 0 and start_dialogue and (played_flag == &"" or not state.has_flag(played_flag)):
		if played_flag != &"":
			state.set_flag(played_flag)
		await StoryHelper.say(self, start_dialogue)
	index += 1
	if index >= path.size():
		for actor in actors:
			actor.vanish()
		_moving = false
		return
	# Corren todos a la vez; se espera al último.
	for k in actors.size() - 1:
		actors[k].run_to(path[index] + Vector2(-26.0 * k, 0), 170.0)
	await actors[actors.size() - 1].run_to(path[index] + Vector2(-26.0 * (actors.size() - 1), 0), 170.0)
	if index == path.size() - 1:
		index += 1
		for actor in actors:
			actor.vanish()
	_moving = false
