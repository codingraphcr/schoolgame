class_name FiberStory
extends Node
## La misión «El bosque que dejó de brillar» (antes «Sin señal en el barrio») dentro del Bosque de Fibra (una por sala, hija de la sala):
## - Raíces del barrio: durante ayudar_fibroluz, cuando Kai se acerca al Fibroluz, le habla (guide_dialogue) y
##   el Fibroluz lo guía hacia el claro (guide_points).
## - El claro: el Fibroluz espera junto al corte, apagado. Al reconectar (circuit.solved), queda la marca
##   RESTORED_FLAG (el bosque y la caja del barrio se encienden), se oye fibra_reconectada y el Fibroluz se
##   lleva su paquete de luz hacia el barrio (guide_points y desaparece).
## Con la conexión ya restaurada, el Fibroluz patrulla tranquilo con su paquete.

const QUEST := &"senal_del_barrio"
const RESTORED_FLAG := &"bosque_fibra_enlace_restaurado"

@export var fibroluz: Fibroluz
@export var circuit: FiberCircuit
@export var guide_dialogue: Dialogue
@export var solved_dialogue: Dialogue
@export var guide_points: Array[Vector2] = []
@export var guide_distance := 90.0

var _guiding := false


func _ready() -> void:
	if circuit:
		circuit.solved.connect(_on_solved)
	var state := _state()
	var restored: bool = state.has_flag(RESTORED_FLAG)
	if fibroluz:
		fibroluz.carrying = restored or circuit == null
		if circuit and not restored:
			fibroluz.patrol = []
			fibroluz.state = DigitalCreature.State.REPOSO
			fibroluz._timer = 9999.0


func _physics_process(_delta: float) -> void:
	if _guiding or circuit or fibroluz == null:
		return
	if _state().get_current_step(QUEST) != &"ayudar_fibroluz":
		return
	var player := StoryHelper.room_player(self)
	if player and not player.controls_locked and player.global_position.distance_to(fibroluz.global_position) < guide_distance:
		_start_guide()


func _start_guide() -> void:
	_guiding = true
	if guide_dialogue:
		await StoryHelper.say(self, guide_dialogue)
	var points: Array[Vector2] = guide_points.duplicate()
	fibroluz.guide(points)


func _on_solved() -> void:
	_state().set_flag(RESTORED_FLAG)
	if solved_dialogue:
		await StoryHelper.say(self, solved_dialogue)
	if fibroluz:
		fibroluz.carrying = true
		var points: Array[Vector2] = guide_points.duplicate()
		fibroluz.guide(points)
		await fibroluz.guide_finished
		var tween := fibroluz.create_tween()
		tween.tween_property(fibroluz, "modulate:a", 0.0, 0.5)


func _state() -> Node:
	return get_node("/root/GameState")
