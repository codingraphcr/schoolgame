class_name LandingScene
extends Node
## El aterrizaje después de la caída (Capítulo 3, primera vez en el Bosque de Fibra), hijo de la sala. Si la partida
## está en step_id de quest_id: Kai cae desde arriba sobre su entrada, se levanta, y un Fibroluz se acerca y parece
## burlarse de él (una línea de Kai, una risita, otra línea...). Después, «NUEVA REGIÓN · BOSQUE DE FIBRA», y el paso
## se completa (ahora hay que buscar otra salida). Kai no pierde nada: la caída es una escena.

## Kai ya conoce el Bosque de Fibra (la caída es la única forma de descubrirlo).
const DISCOVERED_FLAG := &"bosque_descubierto"

@export var fibroluz: Fibroluz
## Las líneas de Kai, una por una (entre cada una, el Fibroluz se ríe).
@export var kai_lines: Array[Dialogue] = []
@export var region_title := "BOSQUE DE FIBRA"
@export var region_subtitle := "NUEVA REGIÓN"
@export var quest_id: StringName = &"contagio_digital"
@export var step_id: StringName = &"investigar_conexion"
@export var quick := false

var playing := false


func _ready() -> void:
	_start.call_deferred()


func _start() -> void:
	await get_tree().process_frame
	if _state().get_current_step(quest_id) != step_id:
		return
	playing = true
	var room := _room()
	var player := room.player
	player.controls_locked = true
	var floor_y := player.global_position.y
	player.global_position.y = floor_y - 260.0
	player.set_physics_process(false)
	var drop := create_tween()
	drop.tween_property(player, "global_position:y", floor_y, 0.2 if quick else 0.55).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await drop.finished
	player.set_physics_process(true)
	Sfx.play(&"enemy_hit")
	if room.camera and room.camera.has_method(&"shake"):
		room.camera.shake(6.0, 0.3)
	await _wait(0.8)
	if fibroluz:
		var approach := create_tween()
		approach.tween_property(fibroluz, "global_position:x", player.global_position.x + 46.0, 0.4 if quick else 1.2)
		await approach.finished
	for i in kai_lines.size():
		await StoryHelper.say(self, kai_lines[i])
		if fibroluz and i < kai_lines.size() - 1:
			fibroluz.giggle(0.4 if quick else 1.1)
			await _wait(1.0)
	var card := _title_card()
	if card:
		card.show_title(region_title, region_subtitle)
	_state().set_flag(DISCOVERED_FLAG)
	_state().complete_step(quest_id, step_id)
	player.controls_locked = false
	playing = false


func _room() -> Room:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node as Room


func _title_card() -> TitleCard:
	for node in _room().find_children("*", "TitleCard", true, false):
		return node as TitleCard
	return null


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds * (0.1 if quick else 1.0), false, true).timeout


func _state() -> Node:
	return get_node("/root/GameState")
